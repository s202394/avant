import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/new_customer/new_customer_trade_library_form2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;
import '../common/utils.dart';
import '../model/fetch_customer_details_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

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
  late Future<CustomerEntryMasterResponse> futureData;

  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _customerCategoryController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  final _customerNameFieldKey = GlobalKey<FormFieldState>();
  final _customerCategoryFieldKey = GlobalKey<FormFieldState>();
  final _addressFieldKey = GlobalKey<FormFieldState>();
  final _cityFieldKey = GlobalKey<FormFieldState>();
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

  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;
  CustomerCategory? _selectedCustomerCategory;
  bool? _selectedKeyCustomer;
  bool? _selectedCustomerStatus;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  String? mandatorySetting;

  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerCategoryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _phoneNumberController.dispose();
    _emailIdController.dispose();
    _panController.dispose();
    _gstController.dispose();
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
      _addressController.text = "${position.latitude}, ${position.longitude}";
      _getUserLocation();
    });
  }

  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location(); // Using the alias
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    loc.LocationData locationData = await location.getLocation();
    LatLng initialPosition =
        LatLng(locationData.latitude!, locationData.longitude!);

    setState(() {
      _currentPosition = initialPosition;
      _currentMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: initialPosition,
        draggable: true,
        // Make the marker draggable
        onTap: () {
          _onMarkerTapped(
              initialPosition); // Update address when marker is tapped
        },
        onDragEnd: (newPosition) {
          _onMarkerDragEnd(
              newPosition); // Update address when marker is dragged
        },
      );
      _updateAddressFromPosition(initialPosition); // Set initial address
    });
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

        // Dynamically building the address
        String address = '';

        // Check and add each component if available
        if (place.name != null && place.name!.isNotEmpty) {
          address += '${place.name!}, ';
        }
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street!}, ';
        }
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
      onVerticalDragUpdate: (_) {}, // Prevents scroll interference
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
      // Load geography data
      await _loadGeographyData();

      // Fetch customer data
      futureData = getCustomerData();

      // Wait for customer data and proceed to edit
      await futureData;
      if (widget.isEdit) {
        await checkForEdit();
      }
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

        if (kDebugMode) {
          print('_filteredCities:${_filteredCities.toString()}');
        }
        _filteredCities = _filteredCities
            .where((city) =>
                _filteredCities.indexWhere((e) => e.cityId == city.cityId) ==
                _filteredCities.indexOf(city))
            .toList();

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
    return Scaffold(
      appBar: CommonAppBar(title: 'New Customer - ${widget.type}'),
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
            _buildDropdownFieldCustomerCategory(
                'Customer Category',
                _customerCategoryController,
                _customerCategoryFieldKey,
                data.customerCategoryList,
                _customerCategoryFocusNode),
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
                  _selectedCustomerCategory?.customerCategoryId ?? 0,
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
            if (label == 'Phone Number') {
              return _validatePhoneNumber(value);
            } else if (label == 'Email Id') {
              return _validateEmail(value);
            } else if (value == null || value.isEmpty) {
              return 'Please enter $label';
            } else if (label == 'Pin Code' && value.length < 6) {
              return 'Please enter valid $label';
            } else if (label == 'PAN' && value.length < 10) {
              return 'Please enter valid $label';
            } else if (label == 'GST' && value.length < 15) {
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
        validator: (value) {
          if (value == null || value.city.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownFieldCustomerCategory(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<CustomerCategory> customerCategoryList,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<CustomerCategory>(
        key: fieldKey,
        style: TextStyle(fontSize: textFontSize),
        value: _selectedCustomerCategory,
        focusNode: focusNode,
        items: [
          const DropdownMenuItem<CustomerCategory>(
            value: null,
            child: CustomText('Select'),
          ),
          ...customerCategoryList.map(
            (customerCategory) => DropdownMenuItem<CustomerCategory>(
              value: customerCategory,
              child: CustomText(customerCategory.customerCategoryName,
                  fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (CustomerCategory? value) {
          setState(() {
            _selectedCustomerCategory = value;

            // Update the text controller with the selected category name
            controller.text = value?.customerCategoryName ?? '';

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
          if (value == null || value.customerCategoryName.isEmpty) {
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
    _customerNameController.text = details.customerName;
    _addressController.text = details.address;
    _pinCodeController.text = details.pinCode;
    _phoneNumberController.text = details.mobile;
    _emailIdController.text = details.emailId;
    _panController.text = details.panNumber;
    _gstController.text = details.gstNumber;

    _selectedKeyCustomer = details.keyCustomer == 'Y';
    _selectedCustomerStatus = details.customerStatus == 'Active';

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
  }

// Use the overridden equality operator to compare Geography objects
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
