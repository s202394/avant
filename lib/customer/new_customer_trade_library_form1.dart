import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/customer/customer_contact_list.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/customer/new_customer_trade_library_form2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;
import '../common/location.dart';
import '../common/utils.dart';
import '../home.dart';
import '../model/fetch_customer_details_model.dart';
import '../model/login_model.dart';
import '../service/location_service.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import '../views/multi_selection_dropdown.dart';

class NewCustomerTradeLibraryForm1 extends StatefulWidget {
  final String type;
  final bool isEdit;
  final String action;

  const NewCustomerTradeLibraryForm1({
    super.key,
    required this.type,
    this.isEdit = false,
    this.action = '',
  });

  @override
  NewCustomerTradeLibraryForm1State createState() =>
      NewCustomerTradeLibraryForm1State();
}

class NewCustomerTradeLibraryForm1State
    extends State<NewCustomerTradeLibraryForm1> {
  int? userId;

  late Future<CustomerEntryMasterResponse> futureData;

  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();
  LocationService locationService = LocationService();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  final _customerNameFieldKey = GlobalKey<FormFieldState>();
  final _addressFieldKey = GlobalKey<FormFieldState>();
  final _pinCodeFieldKey = GlobalKey<FormFieldState>();
  final _phoneNumberFieldKey = GlobalKey<FormFieldState>();
  final _emailIdFieldKey = GlobalKey<FormFieldState>();
  final _panFieldKey = GlobalKey<FormFieldState>();
  final _gstFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _customerNameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _pinCodeFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _emailIdFocusNode = FocusNode();
  final FocusNode _customerCategoryFocusNode = FocusNode();
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _gstFocusNode = FocusNode();

  late GoogleMapController mapController;
  LatLng? _currentPosition;
  Marker? _currentMarker;

  Geography? _selectedCountry;
  Geography? _selectedState;
  Geography? _selectedDistrict;
  Geography? _selectedCity;

  List<Geography> _filteredCountries = [];
  List<Geography> _filteredStates = [];
  List<Geography> _filteredDistricts = [];
  List<Geography> _filteredCities = [];

  List<Geography> _allGeographies = [];

  String _cityAccess = '';

  bool? _selectedKeyCustomer;
  bool? _selectedCustomerStatus;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  int customerId = 0;
  String validated = '';

  String? mandatorySetting;

  bool _isLoading = false;
  bool isMapControllerInitialized = false;
  int retryCount = 0;
  bool hasCheckedForEdit = false;

  List<CustomerCategory> _selectedCustomerCategoryWithItems = [];

  late CustomerEntryMasterResponse customerEntryMasterResponse;
  CustomerDetails? customerDetails;

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _phoneNumberController.dispose();
    _emailIdController.dispose();
    _panController.dispose();
    _gstController.dispose();

    mapController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _initializeMandatorySettings();

    _setInitialLocation();

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

    userId = await getUserId();

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
    debugPrint('Add customer address');
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
    final address =
        '${_customerNameController.text.toString().trim()}, ${_addressController.text.toString().trim()}, ${_pinCodeController.text.toString().trim()}';
    debugPrint('Edit customer address 1 $address');
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
          debugPrint("_currentMarker markerId ${_currentMarker?.markerId}");
        });

        debugPrint("_currentMarker ${_currentMarker?.position.longitude}");
        _animateToPosition(initialPosition);

        debugPrint("animateCamera.");
      } else {
        debugPrint("Fetching location empty.");
      }
    } catch (e) {
      debugPrint("Error fetching location from address: $e");
      unableToGetAddress();
      return;
    }
  }

  // Relocate the map to the center
  Future<void> _relocateMapToCenter(LatLng position) async {
    if (isMapControllerInitialized) {
      await mapController.animateCamera(
        CameraUpdate.newLatLng(position),
      );
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
    _relocateMapToCenter(position);
    await _updateAddressFromPosition(position);
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

      setState(() {
        _currentMarker = _currentMarker!.copyWith(positionParam: position);
      });
      getAddress(placemarks, position);
    } catch (e) {
      if (kDebugMode) {
        print("Error retrieving address: $e");
      }
      setState(() {
        _addressController.text = "Unable to retrieve address";
      });
    }
  }

  void getAddress(List<Placemark> placemarks, LatLng position) {
    String address = buildAddress(placemarks);

    // Update the address field in the UI
    setState(() {
      _addressController.text = address;
      if (kDebugMode) {
        print(address);
      }
    });
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
    getAddress(placemarks, position);
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
          _allGeographies = dbData;
          _initializeCountries();
        });
      } else {
        await _fetchGeographyData(); // Fetch from API if DB is empty
      }
    } catch (e) {
      debugPrint("Error loading geography data: $e");
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
      setState(() {
        List<Geography> geographyList = geographyResponse.geographyList;
        _filteredCountries = geographyList
            .where((g) =>
                geographyList.indexWhere((e) => e.countryId == g.countryId) ==
                geographyList.indexOf(g))
            .toList();

        _filteredCities = geographyResponse.geographyList.toList();

        if (kDebugMode) {
          print('_filteredCities:${_filteredCities.toString()}');
        }
        if (kDebugMode) {
          print('_filteredCities unique:${_filteredCities.toString()}');
        }
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
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<CustomerEntryMasterResponse>(
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  customerEntryMasterResponse = snapshot.data!;

                  if (widget.isEdit && !hasCheckedForEdit) {
                    hasCheckedForEdit = true;
                    Future.delayed(Duration.zero, () {
                      checkForEdit();
                    });
                  }

                  return buildForm(snapshot.data!);
                } else {
                  return const Center(child: Text('No data found'));
                }
              },
            ),
    );
  }

  Widget buildForm(CustomerEntryMasterResponse data) {
    if (widget.isEdit && customerDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEdit &&
                customerDetails != null &&
                (customerDetails?.msgWarning ?? '') != 'N')
              Column(
                children: [
                  CustomText(customerDetails?.msgWarning ?? '',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                  const SizedBox(height: 10),
                ],
              ),
            _buildTextField('${widget.type} Name', _customerNameController,
                _customerNameFieldKey, _customerNameFocusNode),
            const SizedBox(height: 10),
            _buildMapContainer(),
            const SizedBox(height: 10),
            _buildTextField('Address', _addressController, _addressFieldKey,
                _addressFocusNode,
                maxLines: 5),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Country',
              selectedValue: _selectedCountry,
              items: _filteredCountries,
              displayText: (geo) => geo.country,
              onChanged: _onCountryChanged,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'State',
              selectedValue: _selectedState,
              items: _filteredStates,
              displayText: (geo) => geo.state,
              onChanged: _onStateChanged,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'District',
              selectedValue: _selectedDistrict,
              items: _filteredDistricts,
              displayText: (geo) => geo.district,
              onChanged: _onDistrictChanged,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'City',
              selectedValue: _selectedCity,
              items: _filteredCities,
              displayText: (geo) => geo.city,
              onChanged: (selected) {
                setState(() {
                  _selectedCity = selected;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildTextField('Pin Code', _pinCodeController, _pinCodeFieldKey,
                _pinCodeFocusNode),
            _buildTextField('Phone Number', _phoneNumberController,
                _phoneNumberFieldKey, _phoneNumberFocusNode),
            _buildTextField('Email Id', _emailIdController, _emailIdFieldKey,
                _emailIdFocusNode),
            MultiSelectDropdown<CustomerCategory>(
              label: 'Customer Category',
              items: customerEntryMasterResponse.customerCategoryList,
              selectedItems: _selectedCustomerCategoryWithItems,
              itemLabelBuilder: (item) => item.customerCategoryName,
              onChanged: _onCategoryChanged,
              isMandatory: true,
              isSubmitted: false,
            ),
            _buildTextField('PAN', _panController, _panFieldKey, _panFocusNode),
            _buildTextField('GST', _gstController, _gstFieldKey, _gstFocusNode),
            const SizedBox(height: 16.0),
            const Text('Key Customer:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Yes'),
                    value: true,
                    groupValue: _selectedKeyCustomer,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedKeyCustomer = newValue;
                        if (kDebugMode) {
                          print("_selectedKeyCustomer:$_selectedKeyCustomer");
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No'),
                    value: false,
                    groupValue: _selectedKeyCustomer,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedKeyCustomer = newValue;
                        if (kDebugMode) {
                          print("_selectedKeyCustomer:$_selectedKeyCustomer");
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const Text('Customer Status:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Active'),
                    value: true,
                    groupValue: _selectedCustomerStatus,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCustomerStatus = newValue;
                        if (kDebugMode) {
                          print(
                              "_selectedCustomerStatus:$_selectedCustomerStatus");
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Inactive'),
                    value: false,
                    groupValue: _selectedCustomerStatus,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCustomerStatus = newValue;
                        if (kDebugMode) {
                          print(
                              "_selectedCustomerStatus:$_selectedCustomerStatus");
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: widget.isEdit,
              child: GestureDetector(
                onTap: () {
                  goToContact();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Contact",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                        decorationThickness: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                _submitForm();
              },
              child: Container(
                width: double.infinity,
                color: Colors.blue,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Text(
                    widget.isEdit ? 'Update' : 'Next',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
      } else if (widget.isEdit) {
        updateCustomer();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewCustomerTradeLibraryForm2(
              type: widget.type,
              customerName: _customerNameController.text,
              address: _addressController.text,
              cityId: _selectedCity?.cityId ?? 0,
              pinCode: _pinCodeController.text,
              phoneNumber: _phoneNumberController.text,
              emailId: _emailIdController.text,
              customerCategoryId:
                  createDynamicXml(_selectedCustomerCategoryWithItems),
              pan: _panController.text,
              gst: _gstController.text,
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
        _customerCategoryFocusNode,
        _panFocusNode,
        _gstFocusNode,
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
    } else if (label == 'PAN') {
      return [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.allow(
            RegExp(r'^[A-Z]{0,5}[0-9]{0,4}[A-Z]?$')),
      ];
    } else if (label == 'Email Id') {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
      ];
    } else if (label == 'GST') {
      return [
        FilteringTextInputFormatter.allow(RegExp(
            r'^[0-9]{0,2}[A-Z]{0,5}[0-9]{0,4}[A-Z]{0,1}[1-9A-Z]{0,1}Z?[0-9A-Z]{0,1}$')),
        // Enforces GST format
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
          style: TextStyle(fontSize: textFontSize),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: labelFontSize),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true),
          enabled: enabled,
          maxLines: maxLines,
          validator: (value) {
            if (label == 'PAN' || label == 'GST') {
              if (value == null || value.isEmpty) {
                return null;
              }
              if (label == 'PAN' && value.length < 10) {
                return 'Please enter valid $label';
              }
              if (label == 'GST' && value.length < 15) {
                return 'Please enter valid $label';
              }
            } else if (label == 'Phone Number') {
              return _validatePhoneNumber(value);
            } else if (label == 'Email Id') {
              return _validateEmail(value);
            } else if (value == null || value.isEmpty) {
              return 'Please enter $label';
            } else if (label == 'Pin Code' && value.length < 6) {
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
          textCapitalization: (label == 'PAN' || label == 'GST')
              ? TextCapitalization.characters
              : TextCapitalization.none,
          inputFormatters: _getInputFormatters(label),
        ),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (mandatorySetting == 'M' || mandatorySetting == 'B') {
      if (value == null || value.isEmpty) {
        return 'Please enter Phone Number';
      }
      if (!Validator.isValidMobile(value)) {
        return 'Please enter valid Phone Number';
      }
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (mandatorySetting == 'E' || mandatorySetting == 'B') {
      if (value == null || value.isEmpty) {
        return 'Please enter Email Id';
      }
      if (!Validator.isValidEmail(value)) {
        return 'Please enter valid Email Id';
      }
    }
    if (mandatorySetting == 'A') {
      // Require at least one of Phone Number or Email
      if ((value == null || value.isEmpty) &&
          (_phoneNumberController.text.isEmpty)) {
        return 'Please enter at least one of Phone Number or Email';
      }
    }
    return null;
  }

  Future<void> checkForEdit() async {
    try {
      customerId = extractNumericPart(widget.action);
      validated = extractStringPart(widget.action);

      FetchCustomerDetailsService service = FetchCustomerDetailsService();
      FetchCustomerDetailsLibraryResponse response =
          await service.fetchCustomerDetails(
              customerId,
              validated,
              widget.type,
              token,
              (json) => FetchCustomerDetailsLibraryResponse.fromJson(json));

      _populateCustomerDetails(response.customerDetails);
    } catch (e) {
      debugPrint('Error in checkForEdit: $e');
    }
  }

  void _populateCustomerDetails(CustomerDetails? details) {
    if (details == null) return;
    customerDetails = details;
    _customerNameController.text = details.customerName;
    _addressController.text = details.address;
    _pinCodeController.text = details.pinCode;
    _phoneNumberController.text = details.mobile;
    _emailIdController.text = details.emailId;

    _selectedKeyCustomer = details.keyCustomer == 'Y';
    _selectedCustomerStatus = details.customerStatus == 'Active';

    debugPrint('details.countryId : ${details.countryId}');
    debugPrint('details.stateId : ${details.stateId}');
    debugPrint('details.districtId : ${details.districtId}');
    debugPrint('details.cityId : ${details.cityId}');

    final selectedCountry = _findCountryById(details.countryId);
    if (selectedCountry.countryId == 0) {
      debugPrint('selectedCountry 0');
    } else {
      _onCountryChanged(selectedCountry);

      final selectedState = _findStateById(details.stateId);
      if (selectedState.stateId == 0) {
        debugPrint('selectedState 0');
      } else {
        _onStateChanged(selectedState);

        final selectedDistrict = _findDistrictById(details.districtId);
        if (selectedDistrict.districtId == 0) {
          debugPrint('selectedDistrict 0');
        } else {
          _onDistrictChanged(selectedDistrict);

          if (_filteredCities.isNotEmpty) {
            _selectedCity = _filteredCities.firstWhere(
              (geo) => geo.cityId == details.cityId,
              orElse: () => _filteredCities.first,
            );
          }

          final selectedCity = _findCityById(details.cityId);
          if (selectedCity.cityId == 0) {
            debugPrint('selectedCity 0');
          } else {
            _selectedCity = selectedCity;
          }
        }
      }
    }

    setCustomerCategories(details);

    editAddress();
  }

  void setCustomerCategories(CustomerDetails details) {
    List<int> selectedIds = details.xmlCustomerCategoryId
        .split(',')
        .map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList();

    final selectedCategories = customerEntryMasterResponse.customerCategoryList
        .where((category) => selectedIds.contains(category.customerCategoryId))
        .toList();

    if (selectedCategories.isEmpty) {
      debugPrint("Warning: No categories matched for IDs: $selectedIds");
    }

    _onCategoryChanged(selectedCategories);
  }

  void _onCategoryChanged(List<CustomerCategory> selectedCategories) {
    setState(() {
      _selectedCustomerCategoryWithItems = selectedCategories;
    });
    debugPrint("Updated Selected Items: $_selectedCustomerCategoryWithItems");
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

  Geography _findCountryById(int? countryId) {
    return _allGeographies.firstWhere(
      (city) => city.countryId == countryId,
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

  Geography _findStateById(int? stateId) {
    return _filteredStates.firstWhere(
      (city) => city.stateId == stateId,
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

  Geography _findDistrictById(int? districtId) {
    return _filteredDistricts.firstWhere(
      (city) => city.districtId == districtId,
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

  void _initializeCountries() {
    // Get unique countries
    _filteredCountries = _allGeographies
        .where((geo) =>
            _allGeographies
                .indexWhere((item) => item.countryId == geo.countryId) ==
            _allGeographies.indexOf(geo))
        .toList();
  }

  void _onCountryChanged(Geography? selected) {
    setState(() {
      _selectedCountry = selected;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedCity = null;

      // Filter unique states for the selected country
      final Set<int> uniqueStateIds = {};
      _filteredStates = _allGeographies
          .where((geo) =>
              geo.countryId == selected?.countryId &&
              uniqueStateIds.add(geo.stateId)) // Only add unique states
          .toList();

      _filteredDistricts = []; // Clear districts when country changes
      _filteredCities = []; // Clear cities when country changes
    });
  }

  void _onStateChanged(Geography? selected) {
    setState(() {
      _selectedState = selected;
      _selectedDistrict = null;
      _selectedCity = null;

      // Filter unique cities for the selected state
      final Set<int> uniqueDistrictIds = {};
      _filteredDistricts = _allGeographies
          .where((geo) =>
              geo.stateId == selected?.stateId &&
              uniqueDistrictIds.add(geo.districtId)) // Only add unique district
          .toList();
      _filteredCities = []; // Clear cities when state changes
    });
  }

  void _onDistrictChanged(Geography? selected) {
    setState(() {
      _selectedDistrict = selected;
      _selectedCity = null;

      // Filter unique cities for the selected state
      final Set<int> uniqueCityIds = {};
      _filteredCities = _allGeographies
          .where((geo) =>
              geo.districtId == selected?.districtId &&
              uniqueCityIds.add(geo.cityId)) // Only add unique cities
          .toList();
    });
  }

  Widget _buildDropdown({
    required String label,
    required Geography? selectedValue,
    required List<Geography> items,
    required String Function(Geography) displayText,
    required ValueChanged<Geography?> onChanged,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    final uniqueItems = items.toSet().toList();
    return DropdownButtonFormField<Geography>(
      value: selectedValue,
      style: TextStyle(fontSize: textFontSize),
      items: [
        DropdownMenuItem<Geography>(
          value: null,
          child: CustomText('Select $label'),
        ),
        ...uniqueItems.map(
          (geo) => DropdownMenuItem<Geography>(
            value: geo,
            child: CustomText(displayText(geo)),
          ),
        ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: labelFontSize),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  void unableToGetAddress() async {
    final address =
        '${_selectedCity?.city ?? ''}, ${_selectedState?.state ?? ''}, ${_selectedState?.district ?? ''}, ${_selectedCountry?.country ?? ''}}';
    debugPrint('Edit customer address 2 $address');
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
          debugPrint("_currentMarker markerId ${_currentMarker?.markerId}");
        });

        debugPrint("_currentMarker ${_currentMarker?.position.longitude}");
        _animateToPosition(initialPosition);

        debugPrint("animateCamera.");
      } else {
        debugPrint("Fetching location empty.");
      }
    } catch (e) {
      debugPrint("Error fetching location from address: $e");
      unableToGetAddress2();
      return;
    }
  }

  void unableToGetAddress2() async {
    final address = _pinCodeController.text.toString().trim();
    debugPrint('Edit customer address 3 $address');
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
          debugPrint("_currentMarker markerId ${_currentMarker?.markerId}");
        });

        debugPrint("_currentMarker ${_currentMarker?.position.longitude}");
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

  void updateCustomer() async {
    FocusScope.of(context).unfocus();

    if (!await _checkInternetConnection()) return;

    setState(() {
      _isLoading = true;
    });
    final type = widget.isEdit ? 'editing' : 'adding new';

    try {
      Position position = await locationService.getCurrentLocation();
      if (kDebugMode) {
        print(
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      }

      final responseData = await UpdateCustomerService().updateCustomer(
          customerDetails?.customerId ?? 0,
          widget.type,
          _customerNameController.text.toString().trim(),
          customerDetails?.refCode ?? '',
          _emailIdController.text.toString().trim(),
          _phoneNumberController.text.toString().trim(),
          _addressController.text.toString().trim(),
          _selectedCity?.cityId ?? 0,
          int.parse(_pinCodeController.text.toString().trim()),
          (_selectedKeyCustomer ?? false) ? "Y" : "N",
          (_selectedCustomerStatus ?? false) ? "Active" : "Inactive",
          createDynamicXml(_selectedCustomerCategoryWithItems),
          customerDetails?.xmlAccountTableExecutiveId ?? '',
          "<CustomerComment/>",
          userId ?? 0,
          position.latitude,
          position.longitude,
          _gstController.text.toString().trim(),
          _panController.text.toString().trim(),
          validated,
          token);

      if (responseData.status == 'Success') {
        String s = responseData.s;
        String w = responseData.w;
        if (s.isNotEmpty || w.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (kDebugMode) {
            print('$type customer error s or w is empty');
          }
          _toastMessage
              .showToastMessage("An error occurred while $type customer.");
        }
      } else {
        if (kDebugMode) {
          print('$type customer error ${responseData.status}');
        }
        _toastMessage
            .showToastMessage("An error occurred while $type customer.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('$type customer error $e');
      }
      _toastMessage.showToastMessage("An error occurred while $type customer.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String createDynamicXml(List<CustomerCategory> customerCategories) {
    // Create the base XML structure
    StringBuffer xmlBuffer = StringBuffer();
    xmlBuffer.write('<CustomerCategory_Data>');

    // Loop through the list of CustomerCategory objects and add each one to the XML structure
    for (var category in customerCategories) {
      xmlBuffer.write('<CustomerCategory>');
      xmlBuffer.write(
          '<CustomerCategoryId>${category.customerCategoryId}</CustomerCategoryId>');
      xmlBuffer.write('</CustomerCategory>');
    }

    // Close the XML structure
    xmlBuffer.write('</CustomerCategory_Data>');

    return xmlBuffer.toString();
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  void goToContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerContactList(
            type: widget.type, customerId: customerId, validated: validated),
      ),
    );
  }
}
