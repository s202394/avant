import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/new_customer/new_customer_school_form2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;
import '../common/utils.dart';
import '../model/fetch_customer_details_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class NewCustomerSchoolForm1 extends StatefulWidget {
  final String type;
  final bool isEdit;
  final String action;

  const NewCustomerSchoolForm1({
    super.key,
    required this.type,
    this.isEdit = false,
    this.action = '',
  });

  @override
  NewCustomerSchoolForm1State createState() => NewCustomerSchoolForm1State();
}

class NewCustomerSchoolForm1State extends State<NewCustomerSchoolForm1> {
  late Future<CustomerEntryMasterResponse> futureData;

  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _boardController = TextEditingController();
  final TextEditingController _chainSchoolController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();

  final _customerNameFieldKey = GlobalKey<FormFieldState>();
  final _boardFieldKey = GlobalKey<FormFieldState>();
  final _chainSchoolFieldKey = GlobalKey<FormFieldState>();
  final _addressFieldKey = GlobalKey<FormFieldState>();
  final _cityFieldKey = GlobalKey<FormFieldState>();
  final _pinCodeFieldKey = GlobalKey<FormFieldState>();
  final _phoneNumberFieldKey = GlobalKey<FormFieldState>();
  final _emailIdFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _customerNameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _pinCodeFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _emailIdFocusNode = FocusNode();
  final FocusNode _chainSchoolFocusNode = FocusNode();
  final FocusNode _boardFocusNode = FocusNode();

  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;
  BoardMaster? _selectedBoard;
  ChainSchool? _selectedChainSchool;
  bool? _selectedKeyCustomer;
  bool? _selectedCustomerStatus;

  bool _isLoading = false;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  String? mandatorySetting;

  bool hasCheckedForEdit = false;

  late GoogleMapController mapController;
  LatLng? _currentPosition;
  Marker? _currentMarker;
  bool isMapControllerInitialized = false;
  int retryCount = 0;

  late CustomerEntryMasterResponse customerEntryMasterResponse;

  @override
  void dispose() {
    _customerNameController.dispose();
    _boardController.dispose();
    _chainSchoolController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _phoneNumberController.dispose();
    _emailIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _initializeMandatorySettings();

    // if (!widget.isEdit) {
    _setInitialLocation();
    // }

    futureData = Future<CustomerEntryMasterResponse>.value(
      CustomerEntryMasterResponse(
        status: 'Default',
        boardMasterList: [],
        classesList: [],
        chainSchoolList: [],
        dataSourceList: [],
        accountableExecutiveList: [],
        salutationMasterList: [],
        contactDesignationList: [],
        subjectList: [],
        departmentList: [],
        adoptionRoleMasterList: [],
        customerCategoryList: [],
        monthsList: [],
        purchaseModeList: [],
        instituteTypeList: [],
        instituteLevelList: [],
        affiliateTypeList: [],
      ),
    );

    _fetchData();
  }

  Future<void> _initializeMandatorySettings() async {
    mandatorySetting = await dbHelper.getTeacherMobileEmailMandatory();

    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      executiveId = prefs.getInt('executiveId') ?? 0;
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
  }

  Future<void> _setInitialLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      // _addressController.text = "${position.latitude}, ${position.longitude}";
      _getUserLocation();
    });
  }

  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location(); // Using alias for location package
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return; // Exit if the user does not enable location services
      }
    }

    // Check location permissions
    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return; // Exit if the user does not grant location permissions
      }
    }
    debugPrint('Customer address ${_addressController.text.toString()}');
    // Handle edit mode and pre-filled address
    if (widget.isEdit && _addressController.text.toString().isNotEmpty) {
      editAddress();
    } else {
      addAddress();
    }
  }

  void addAddress() async {
    loc.Location location = loc.Location();
    debugPrint('Add customer address}');
    // Get current user location
    try {
      loc.LocationData locationData = await location.getLocation();
      LatLng initialPosition =
          LatLng(locationData.latitude!, locationData.longitude!);

      if (!mounted) return; // Exit if widget is no longer mounted

      setState(() {
        debugPrint('Customer address ${_addressController.text.toString()}');
        debugPrint(
            'Add customer address _currentPosition ${_currentPosition?.latitude} ${_currentPosition?.longitude}');
        _currentPosition = initialPosition;
        _currentMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: initialPosition,
          draggable: true,
          onTap: () => _onMarkerTapped(initialPosition),
          onDragEnd: (newPosition) => _onMarkerDragEnd(newPosition),
        );
        _updateAddressFromPosition(initialPosition);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user location: $e");
      }
    }
  }

  void editAddress() async {
    final address = '${_customerNameController.text.toString().trim()}, ${_addressController.text.toString().trim()}, ${_pinCodeController.text.toString().trim()}';
    debugPrint('Edit customer address $address');
    try {
      List<Location> locations = await locationFromAddress(address);
      debugPrint('Edit customer address locations size ${locations.length}');
      if (locations.isNotEmpty) {
        // Use the first matched location
        Location addressLocation = locations.first;
        debugPrint(
            'Edit customer address latitude ${addressLocation.latitude}, longitude : ${addressLocation.longitude}');
        LatLng initialPosition =
            LatLng(addressLocation.latitude, addressLocation.longitude);
        debugPrint(
            'Edit customer initialPosition latitude ${initialPosition.latitude}, longitude : ${initialPosition.longitude}');

        // Update marker and position
        _currentPosition = initialPosition;
        debugPrint(
            'Edit customer _currentPosition latitude ${_currentPosition?.latitude}, longitude : ${_currentPosition?.longitude}');

        _currentMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: initialPosition,
          draggable: true,
          onTap: () => _onMarkerTapped(initialPosition),
          onDragEnd: (newPosition) => _onMarkerDragEnd(newPosition),
        );

        await placemarkFromCoordinates(
          initialPosition.latitude,
          initialPosition.longitude,
        ).timeout(
          const Duration(seconds: 10), // Timeout duration
          onTimeout: () {
            throw TimeoutException("Geocoding timed out after 10 seconds.");
          },
        );

        setState(() {
          _currentMarker =
              _currentMarker!.copyWith(positionParam: _currentPosition);
          debugPrint("_currentMarker markerId ${_currentMarker?.markerId.value}");
        });

        debugPrint("_currentMarker ${_currentMarker?.position.latitude} ${_currentMarker?.position.longitude}");
        _animateToPosition(initialPosition);

        debugPrint("animateCamera.");
      } else {
        debugPrint("Fetching location empty.");
      }
    } catch (e) {
      debugPrint("Error fetching location from address: $e");
      addAddress();
      return;
    }
  }

  void _animateToPosition(LatLng position) {
    debugPrint("isMapControllerInitialized: $isMapControllerInitialized");
    if (isMapControllerInitialized) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    } else {
      if (kDebugMode) {
        print("Error: mapController is not initialized yet.");
      }
      if (retryCount < 3) {
        debugPrint("if retryCount: $retryCount");
        retryCount++;
        editAddress();
      } else {
        debugPrint("else retryCount: $retryCount");
      }
    }
  }

  // Update the address when the marker is tapped
  Future<void> _onMarkerTapped(LatLng position) async {
    _updateAddressFromPosition(position);
  }

  // Update the address when the marker is dragged
  Future<void> _onMarkerDragEnd(LatLng newPosition) async {
    _updateAddressFromPosition(newPosition);
  }

  Future<void> _updateAddressFromPosition(LatLng position) async {
    try {
      // Adding timeout to the geocoding request
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10), // Timeout duration
        onTimeout: () {
          throw TimeoutException("Geocoding timed out after 10 seconds.");
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        debugPrint('place : ${place.name}');
        // Dynamically building the address
        String address = '';

        // Check and add each component if available
        if (place.name != null && place.name!.isNotEmpty) {
          address += '${place.name!}, ';
        }
        /* if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street!}, ';
        }*/
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality!}, ';
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea!}, ';
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += '${place.postalCode!}, ';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += place.country!;
        }

        // Remove trailing comma if it exists
        if (address.endsWith(', ')) {
          address = address.substring(0, address.length - 2);
        }

        // Update the address field in the UI
        setState(() {
          _addressController.text = address;
          _currentMarker = _currentMarker!.copyWith(positionParam: position);
          if (kDebugMode) {
            print(address);
          }
        });
      } else {
        debugPrint('Place mark empty');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error retrieving address: $e");
      }
      setState(() {
        _addressController.text = "Unable to retrieve address";
      });
    }
  }

  Widget _buildMapContainer() {
    return GestureDetector(
      onVerticalDragUpdate: (_) {},
      child: Container(
        height: 300.0,
        decoration: BoxDecoration(
          border: Border.all(width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 14.0,
                ),
                markers: _currentMarker != null ? {_currentMarker!} : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  mapController = controller;
                  setState(() {
                    isMapControllerInitialized = true;
                  });
                },
                onTap: (LatLng tappedPosition) {
                  _updateMarkerAndAddress(tappedPosition);
                },
              ),
      ),
    );
  }

  Future<void> _updateMarkerAndAddress(LatLng position) async {
    // Update the marker position
    setState(() {
      _currentMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: position,
        draggable: true,
        onDragEnd: (newPosition) => _updateMarkerAndAddress(newPosition),
      );
    });

    // Fetch and update address based on tapped position
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String address =
          '${place.name}, ${place.administrativeArea}, ${place.street}, ${place.locality}, ${place.country}';
      setState(() {
        _addressController.text = address;
      });
    }
  }

  void _fetchData() async {
    setState(() {
      _isLoading = true; // Show loader
    });

    try {
      debugPrint('_loadGeographyData');
      // 1. Load geography data first
      await _loadGeographyData();

      debugPrint('getCustomerData');
      // 2. Fetch customer data next
      futureData = getCustomerData();
      await futureData; // Wait for the customer data response

      // 3. If it's in edit mode, then fetch additional data for edit
      /*if (widget.isEdit) {
        debugPrint('checkForEdit');
        await checkForEdit(); // Only proceed with this if edit mode
      }*/
    } catch (e) {
      debugPrint('Error during fetch or edit operations: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  Future<void> _loadGeographyData() async {
    try {
      List<Geography> dbData = await dbHelper.getGeographyDataFromDB();
      if (dbData.isNotEmpty) {
        setState(() {
          _filteredCities = dbData;
        });
        if (kDebugMode) {
          print("Loaded geography data from the database.");
        }
      } else {
        if (kDebugMode) {
          print("No data in DB, fetching from API.");
        }
        await _fetchGeographyData(); // Wait for API data
      }
    } catch (e) {
      debugPrint("Error in _loadGeographyData: $e");
      rethrow;
    }
  }

  Future<void> _fetchGeographyData() async {
    try {
      GeographyService geographyService = GeographyService();
      GeographyResponse geographyResponse =
          await geographyService.fetchGeographyData(
        _cityAccess,
        executiveId,
        token,
      );
      List<int> cityIds =
          _cityAccess.split(',').map((id) => int.parse(id)).toList();
      setState(() {
        _filteredCities = geographyResponse.geographyList
            .where((geography) => cityIds.contains(geography.cityId))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching geography data: $e");
      }
      rethrow;
    }
  }

  Future<CustomerEntryMasterResponse> getCustomerData() async {
    try {
      CustomerEntryMasterResponse? existingData =
          await dbHelper.getCustomerEntryMasterResponse();

      if (existingData != null && !isEmptyData(existingData)) {
        if (kDebugMode) {
          print("CustomerEntryMaster data found in db.");
        }
        return existingData;
      } else {
        if (kDebugMode) {
          print("CustomerEntryMaster data not found, fetching from API...");
        }
        String downHierarchy = prefs.getString('DownHierarchy') ?? '';
        CustomerEntryMasterResponse response =
            await CustomerEntryMasterService()
                .fetchCustomerEntryMaster(downHierarchy, token);

        await dbHelper.insertCustomerEntryMasterResponse(response);
        return response;
      }
    } catch (e) {
      debugPrint("Error in getCustomerData: $e");
      rethrow;
    }
  }

// Method to check if data is empty
  bool isEmptyData(CustomerEntryMasterResponse data) {
    return data.boardMasterList.isEmpty &&
        data.classesList.isEmpty &&
        data.chainSchoolList.isEmpty &&
        data.dataSourceList.isEmpty &&
        data.accountableExecutiveList.isEmpty &&
        data.salutationMasterList.isEmpty &&
        data.contactDesignationList.isEmpty &&
        data.subjectList.isEmpty &&
        data.departmentList.isEmpty &&
        data.adoptionRoleMasterList.isEmpty &&
        data.customerCategoryList.isEmpty &&
        data.monthsList.isEmpty &&
        data.purchaseModeList.isEmpty &&
        data.instituteTypeList.isEmpty &&
        data.instituteLevelList.isEmpty &&
        data.affiliateTypeList.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.isEdit ? 'Edit' : 'New';
    return Scaffold(
      appBar: CommonAppBar(title: '$type Customer - ${widget.type}'),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loader if data is still loading
          : FutureBuilder<CustomerEntryMasterResponse>(
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  // Once data is available, initialize the response
                  customerEntryMasterResponse = snapshot.data!;

                  // If in edit mode, trigger checkForEdit only once
                  if (widget.isEdit && !hasCheckedForEdit) {
                    hasCheckedForEdit = true;
                    Future.delayed(Duration.zero, () {
                      checkForEdit(); // Call checkForEdit after the build method
                    });
                  }

                  // Return the form UI
                  return buildForm(snapshot.data!);
                } else {
                  return const Center(child: Text('No data found'));
                }
              },
            ),
    );
  }

  Widget buildForm(CustomerEntryMasterResponse data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('${widget.type} Name', _customerNameController,
                _customerNameFieldKey, _customerNameFocusNode),
            const SizedBox(height: 10),
            _buildMapContainer(),
            const SizedBox(height: 10),
            _buildTextField('Address', _addressController, _addressFieldKey,
                _addressFocusNode,
                maxLines: 5),
            _buildDropdownFieldCity(
                'City', _cityController, _cityFieldKey, _cityFocusNode),
            _buildTextField('Pin Code', _pinCodeController, _pinCodeFieldKey,
                _pinCodeFocusNode),
            _buildTextField('Phone Number', _phoneNumberController,
                _phoneNumberFieldKey, _phoneNumberFocusNode),
            _buildTextField('Email Id', _emailIdController, _emailIdFieldKey,
                _emailIdFocusNode),
            _buildDropdownFieldBoard('Board', _boardController, _boardFieldKey,
                data.boardMasterList, _boardFocusNode),
            _buildDropdownFieldChainSchool(
                'Chain School',
                _chainSchoolController,
                _chainSchoolFieldKey,
                data.chainSchoolList,
                _chainSchoolFocusNode),
            const SizedBox(height: 16.0),
            const CustomText('Key Customer:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const CustomText('Yes'),
                    value: true,
                    groupValue: _selectedKeyCustomer,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedKeyCustomer = newValue;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const CustomText('No'),
                    value: false,
                    groupValue: _selectedKeyCustomer,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedKeyCustomer = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const CustomText('Customer Status:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const CustomText('Active'),
                    value: true,
                    groupValue: _selectedCustomerStatus,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCustomerStatus = newValue;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const CustomText('Inactive'),
                    value: false,
                    groupValue: _selectedCustomerStatus,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCustomerStatus = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                _submitForm();
              },
              child: Container(
                width: double.infinity,
                color: Colors.blue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedKeyCustomer == null) {
        _toastMessage.showToastMessage("Please select Key Customer");
      } else if (_selectedCustomerStatus == null) {
        _toastMessage.showToastMessage("Please select Customer Status");
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewCustomerSchoolForm2(
              type: widget.type,
              customerName: _customerNameController.text,
              address: _addressController.text,
              cityId: _selectedCity?.cityId ?? 0,
              cityName: _selectedCity?.city ?? '',
              pinCode: _pinCodeController.text,
              phoneNumber: _phoneNumberController.text,
              emailId: _emailIdController.text,
              boardId: _selectedBoard?.boardId ?? 0,
              chainSchoolId: _selectedChainSchool?.chainSchoolId ?? 0,
              keyCustomer: (_selectedKeyCustomer ?? false) ? "Y" : "N",
              customerStatus:
                  (_selectedCustomerStatus ?? false) ? "Active" : "Inactive",
            ),
          ),
        );
      }
    } else {
      // Focus on the first field with an error
      List<FocusNode> focusNodes = [
        _customerNameFocusNode,
        _addressFocusNode,
        _cityFocusNode,
        _pinCodeFocusNode,
        _phoneNumberFocusNode,
        _emailIdFocusNode,
        _boardFocusNode,
        _chainSchoolFocusNode,
      ];

      for (FocusNode focusNode in focusNodes) {
        if (focusNode.hasFocus) {
          focusNode.requestFocus();
          break;
        }
      }
    }
  }

  List<TextInputFormatter> _getInputFormatters(String label) {
    if (label == 'Phone Number' || label == 'Mobile') {
      return [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.digitsOnly,
      ];
    } else if (label == 'Pin Code') {
      return [
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter.digitsOnly,
      ];
    } else if (label == 'Email Id') {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
      ];
    } else {
      return [];
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode, {
    bool enabled = true,
    int maxLines = 1,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: label == 'Address' ? 100.0 : 0.0,
        ),
        child: TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(fontSize: textFontSize),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: labelFontSize),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true),
          enabled: enabled,
          maxLines: maxLines,
          validator: (value) {
            if (label == 'Email Id') {
              if (value == null || value.isEmpty) {
                return null;
              }
              if (!Validator.isValidEmail(value)) {
                return 'Please enter valid $label';
              }
            }
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'Pin Code' && value.length < 6) {
              return 'Please enter valid $label';
            }
            if (label == 'Phone Number' && !Validator.isValidMobile(value)) {
              return 'Please enter valid $label';
            }
            return null;
          },
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                fieldKey.currentState?.validate();
              });
            }
          },
          textAlign: TextAlign.start,
          keyboardType: (label == 'Phone Number' || label == 'Pin Code')
              ? TextInputType.phone
              : TextInputType.text,
          inputFormatters: _getInputFormatters(label),
        ),
      ),
    );
  }

  Widget _buildDropdownFieldCity(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Geography>(
        key: fieldKey,
        focusNode: focusNode,
        value: _selectedCity,
        items: [
          const DropdownMenuItem<Geography>(
            value: null,
            child: CustomText('Select'),
          ),
          ..._filteredCities.map(
            (geography) => DropdownMenuItem<Geography>(
              value: geography,
              child: CustomText(geography.city, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (Geography? value) {
          setState(() {
            _selectedCity = value;
            controller.text = value?.city ?? '';
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdownFieldBoard(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<BoardMaster> boardList,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<BoardMaster>(
        key: fieldKey,
        value: _selectedBoard,
        focusNode: focusNode,
        style: TextStyle(fontSize: textFontSize),
        items: [
          const DropdownMenuItem<BoardMaster>(
            value: null,
            child: CustomText('Select'),
          ),
          ...boardList.map(
            (board) => DropdownMenuItem<BoardMaster>(
              value: board,
              child: CustomText(board.boardName, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (BoardMaster? value) {
          setState(() {
            _selectedBoard = value;

            // Update the text controller with the selected category name
            controller.text = value?.boardName ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.boardName.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownFieldChainSchool(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<ChainSchool> chainSchoolList,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<ChainSchool>(
        key: fieldKey,
        value: _selectedChainSchool,
        focusNode: focusNode,
        style: TextStyle(fontSize: textFontSize),
        items: [
          const DropdownMenuItem<ChainSchool>(
            value: null,
            child: CustomText('Select'),
          ),
          ...chainSchoolList.map(
            (chainSchool) => DropdownMenuItem<ChainSchool>(
              value: chainSchool,
              child: CustomText(chainSchool.chainSchoolName,
                  fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (ChainSchool? value) {
          setState(() {
            _selectedChainSchool = value;

            // Update the text controller with the selected category name
            controller.text = value?.chainSchoolName ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.chainSchoolName.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Future<void> checkForEdit() async {
    try {
      int customerId = extractNumericPart(widget.action);
      String validated = extractStringPart(widget.action);

      FetchCustomerDetailsService service = FetchCustomerDetailsService();
      FetchCustomerDetailsSchoolResponse response =
          await service.fetchCustomerDetails(
              customerId,
              validated,
              widget.type,
              token,
              (json) => FetchCustomerDetailsSchoolResponse.fromJson(json));

      _populateCustomerDetails(response.schoolDetails);
    } catch (e) {
      debugPrint('Error in checkForEdit: $e');
    }
  }

  void _populateCustomerDetails(SchoolDetails? details) {
    if (details == null) return;
    debugPrint('boardId : ${details.boardId}');
    debugPrint('chainSchoolId : ${details.chainSchoolId}');
    _customerNameController.text = details.schoolName;
    _addressController.text = details.address;
    _pinCodeController.text = details.pinCode;
    _phoneNumberController.text = details.mobile;
    _emailIdController.text = details.emailId;

    _selectedKeyCustomer = details.keyCustomer == 'Y';
    _selectedCustomerStatus = details.customerStatus == 'Active';

    debugPrint(
        'boardMasterList size : ${customerEntryMasterResponse.boardMasterList.length}');
    if (customerEntryMasterResponse.boardMasterList.isNotEmpty) {
      final board = customerEntryMasterResponse.boardMasterList.firstWhere(
        (b) => b.boardId == details.boardId,
        orElse: () {
          debugPrint('Edit Board ID ${details.boardId} not found.');
          return BoardMaster(boardId: 0, boardName: '');
        },
      );
      if (board.boardId > 0) {
        debugPrint('board.boardName ${board.boardName}');
        setState(() {
          _selectedBoard = board;
          _boardController.text = board.boardName;
        });
      } else {
        debugPrint('Edit board 0');
      }
    }

    debugPrint(
        'chainSchoolList size : ${customerEntryMasterResponse.chainSchoolList.length}');
    if (customerEntryMasterResponse.chainSchoolList.isNotEmpty) {
      final chainSchool =
          customerEntryMasterResponse.chainSchoolList.firstWhere(
        (s) => s.chainSchoolId == details.chainSchoolId,
        orElse: () {
          debugPrint(
              'Edit Chain School ID ${details.chainSchoolId} not found.');
          return ChainSchool(chainSchoolId: 0, chainSchoolName: '');
        },
      );
      if (chainSchool.chainSchoolId > 0) {
        setState(() {
          _selectedChainSchool = chainSchool;
          _chainSchoolController.text = chainSchool.chainSchoolName;
        });
      } else {
        debugPrint('Edit Chain school 0');
      }
    }

    final selectedCity = _findCityById(details.cityId);
    if (selectedCity.cityId == 0) {
      _selectedCity = null;
      _cityController.text = '';
      debugPrint('City ID ${details.cityId} not found in filtered cities.');
    } else {
      debugPrint('City ID ${details.cityId} found in filtered cities.');
      _selectedCity = selectedCity;
      _cityController.text = _selectedCity?.city ?? '';
    }

    editAddress();
  }

  Geography _findCityById(int? cityId) {
    return _filteredCities.firstWhere(
      (city) => city.cityId == cityId,
      orElse: () => Geography(
        countryId: 0,
        country: '',
        stateId: 0,
        state: '',
        districtId: 0,
        district: '',
        cityId: 0,
        city: '',
      ),
    );
  }
}
