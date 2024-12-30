import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/customer/dynamic_form_page.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/location.dart';
import '../common/utils.dart';
import '../model/contact_detail_model.dart';
import '../model/login_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class CustomerContactSchoolForm extends StatefulWidget {
  final String type;
  final int customerId;
  final bool isEdit;
  final String? action;

  const CustomerContactSchoolForm({
    super.key,
    required this.type,
    required this.customerId,
    this.isEdit = false,
    this.action = '',
  });

  @override
  CustomerContactFormState createState() => CustomerContactFormState();
}

class CustomerContactFormState extends State<CustomerContactSchoolForm> {
  late Future<CustomerEntryMasterResponse> futureData;

  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _anniversaryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _pinCodeFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _emailIdFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  final FocusNode _anniversaryFocusNode = FocusNode();

  final _firstNameFieldKey = GlobalKey<FormFieldState>();
  final _lastNameFieldKey = GlobalKey<FormFieldState>();
  final _phoneNumberFieldKey = GlobalKey<FormFieldState>();
  final _emailIdFieldKey = GlobalKey<FormFieldState>();
  final _dobFieldKey = GlobalKey<FormFieldState>();
  final _anniversaryFieldKey = GlobalKey<FormFieldState>();
  final _contactDesignationFieldKey = GlobalKey<FormFieldState>();
  final _salutationFieldKey = GlobalKey<FormFieldState>();
  final _addressFieldKey = GlobalKey<FormFieldState>();
  final _pinCodeFieldKey = GlobalKey<FormFieldState>();
  final _dataSourceFieldKey = GlobalKey<FormFieldState>();

  String _cityAccess = '';

  late int? userId;

  Geography? _selectedCountry;
  Geography? _selectedState;
  Geography? _selectedDistrict;
  Geography? _selectedCity;

  List<Geography> _filteredCountries = [];
  List<Geography> _filteredStates = [];
  List<Geography> _filteredDistricts = [];
  List<Geography> _filteredCities = [];

  List<Geography> _allGeographies = [];

  bool? _selectedPrimaryContact;
  bool? _selectedContactStatus;

  String? _selectedContactDesignation;
  int? _selectedContactDesignationId;
  String? _selectedSalutation;
  int? _selectedSalutationId;
  String? _selectedDataSource;
  int? _selectedDataSourceId;

  bool _isLoading = false;
  bool _isSubmitted = false;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  String validated = 'A';

  int contactId = 0;

  String? mandatorySettingEmailMobile;
  String? mandatoryCustomerContactFirstLastName;

  bool hasCheckedForEdit = false;

  late GoogleMapController mapController;
  LatLng? _currentPosition;
  Marker? _currentMarker;
  bool isMapControllerInitialized = false;
  int retryCount = 0;

  late CustomerEntryMasterResponse customerEntryMasterResponse;
  late CustomerContactDetailsSchoolResponse contactDetailsResponse;

  List<FormRowData> selectedRows = [];

  final GlobalKey<DynamicFormWidgetState> _dynamicFormKey =
      GlobalKey<DynamicFormWidgetState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _phoneNumberController.dispose();
    _emailIdController.dispose();
    _dobController.dispose();
    _anniversaryController.dispose();
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
    mandatorySettingEmailMobile =
        await dbHelper.getTeacherMobileEmailMandatory();
    debugPrint('mandatorySettingEmailMobile:$mandatorySettingEmailMobile');
    mandatoryCustomerContactFirstLastName =
        await dbHelper.getCustomerContactFirstLastNameMandatory();
    debugPrint(
        'mandatoryCustomerContactFirstLastName:$mandatoryCustomerContactFirstLastName');

    prefs = await SharedPreferences.getInstance();
    userId = await getUserId();
    executiveId = await getExecutiveId() ?? 0;
    setState(() {
      token = prefs.getString('token') ?? '';
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
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _getUserLocation();
      });
    }
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
    debugPrint('Contact address ${_addressController.text.toString()}');
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
        debugPrint('Contact address ${_addressController.text.toString()}');
        debugPrint(
            'Add contact address _currentPosition ${_currentPosition?.latitude} ${_currentPosition?.longitude}');
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
        '${_addressController.text.toString().trim()}, ${_pinCodeController.text.toString().trim()}';
    debugPrint('Edit contact address $address');
    try {
      List<Location> locations = await locationFromAddress(address);
      debugPrint('Edit contact address locations size ${locations.length}');
      if (locations.isNotEmpty) {
        // Use the first matched location
        Location addressLocation = locations.first;
        debugPrint(
            'Edit contact address latitude ${addressLocation.latitude}, longitude : ${addressLocation.longitude}');
        LatLng initialPosition =
            LatLng(addressLocation.latitude, addressLocation.longitude);
        debugPrint(
            'Edit contact initialPosition latitude ${initialPosition.latitude}, longitude : ${initialPosition.longitude}');

        // Update marker and position
        _currentPosition = initialPosition;
        debugPrint(
            'Edit contact _currentPosition latitude ${_currentPosition?.latitude}, longitude : ${_currentPosition?.longitude}');

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
          debugPrint(
              "_currentMarker markerId ${_currentMarker?.markerId.value}");
        });

        debugPrint(
            "_currentMarker ${_currentMarker?.position.latitude} ${_currentMarker?.position.longitude}");
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

      setState(() {
        _currentMarker = _currentMarker!.copyWith(positionParam: position);
      });
      getAddress(placemarks, position);
    } catch (e) {
      if (kDebugMode) {
        print("Error retrieving address: $e");
      }
      setState(() {
        _addressController.text = '';
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
    getAddress(placemarks, position);
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
      appBar: CommonAppBar(title: '$type Contact - ${widget.type}'),
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
    Map<String, int> contactDesignationMap = {
      for (var item in data.contactDesignationList)
        item.contactDesignationName: item.contactDesignationId,
    };
    Map<String, int> salutationMap = {
      for (var item in data.salutationMasterList)
        item.salutationName: item.salutationId,
    };
    Map<String, int> dataSourceMap = {
      for (var item in data.dataSourceList)
        item.dataSourceName: item.dataSourceId,
    };
    return Column(
      children: [
        // Scrollable area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText('Primary Contact:'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const CustomText('Yes'),
                          value: true,
                          groupValue: _selectedPrimaryContact,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedPrimaryContact = newValue;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const CustomText('No'),
                          value: false,
                          groupValue: _selectedPrimaryContact,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedPrimaryContact = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const CustomText('Contact Status:'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const CustomText('Active'),
                          value: true,
                          groupValue: _selectedContactStatus,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedContactStatus = newValue;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const CustomText('Inactive'),
                          value: false,
                          groupValue: _selectedContactStatus,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedContactStatus = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  buildDropdownField(
                    label: 'Salutation',
                    value: _selectedSalutation,
                    items: salutationMap.keys.toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSalutation = value;
                        _selectedSalutationId = salutationMap[value];
                      });
                    },
                    fieldKey: _salutationFieldKey,
                  ),
                  _buildTextField('First Name', _firstNameController,
                      _firstNameFieldKey, _firstNameFocusNode),
                  _buildTextField('Last Name', _lastNameController,
                      _lastNameFieldKey, _lastNameFocusNode),
                  buildDropdownField(
                    label: 'Designation',
                    value: _selectedContactDesignation,
                    items: contactDesignationMap.keys.toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedContactDesignation = value;
                        _selectedContactDesignationId =
                            contactDesignationMap[value];
                      });
                    },
                    fieldKey: _contactDesignationFieldKey,
                  ),
                  _buildTextField('Email', _emailIdController, _emailIdFieldKey,
                      _emailIdFocusNode),
                  _buildTextField('Mobile Number', _phoneNumberController,
                      _phoneNumberFieldKey, _phoneNumberFocusNode),
                  _buildTextField('Date of Birth', _dobController, _dobFieldKey,
                      _dobFocusNode),
                  _buildTextField('Anniversary', _anniversaryController,
                      _anniversaryFieldKey, _anniversaryFocusNode),
                  const SizedBox(height: 10),
                  _buildMapContainer(),
                  const SizedBox(height: 10),
                  _buildTextField('Address', _addressController,
                      _addressFieldKey, _addressFocusNode,
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
                      validate();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildTextField('Pin Code', _pinCodeController,
                      _pinCodeFieldKey, _pinCodeFocusNode),
                  buildDropdownField(
                    label: 'Data Source',
                    value: _selectedDataSource,
                    items: dataSourceMap.keys.toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDataSource = value;
                        _selectedDataSourceId = dataSourceMap[value];
                      });
                    },
                    fieldKey: _dataSourceFieldKey,
                  ),
                  const SizedBox(height: 8),
                  DynamicFormWidget(
                    key: _dynamicFormKey,
                    subjectList: data.subjectList,
                    classesList: data.classesList,
                    onSubmit: (rows) {
                      // Update the selected rows when dynamic form changes
                      setState(() {
                        selectedRows = rows;
                      });
                    },
                    initialRows: selectedRows.isEmpty ? [] : selectedRows,
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _submitForm();
          },
          child: Container(
            height: 50,
            width: double.infinity,
            color: Colors.blue,
            child: GestureDetector(
              onTap: () {
                _submitForm();
              },
              child: const Center(
                child: Text(
                  'Submit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void validate() {
    if (_isSubmitted) {
      _formKey.currentState!.validate();
    }
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();
    _isSubmitted = true;

    if (_formKey.currentState!.validate()) {
      if (_selectedPrimaryContact == null) {
        _toastMessage.showToastMessage("Please enter Primary Contact");
      } else if (_selectedContactStatus == null) {
        _toastMessage.showToastMessage("Please select Contact Status");
      } else if (selectedRows.isEmpty) {
        submitContact();
      } else {
        debugPrint("_submitForm clicked ${selectedRows.length}");
        for (int i = 0; i < selectedRows.length; i++) {
          FormRowData row = selectedRows[i];

          // Check if at least one field in the row is filled
          bool isAnyFieldFilled = row.subjectId != null ||
              (row.selectedClasses != null &&
                  row.selectedClasses!.isNotEmpty) ||
              row.decisionMaker != null;

          // If any field is filled, all fields are mandatory
          if (isAnyFieldFilled) {
            if (row.subjectId == null ||
                row.selectedClasses == null ||
                row.selectedClasses!.isEmpty ||
                row.decisionMaker == null) {
              debugPrint("Row ${i + 1} has unselected fields.");

              // Show an alert dialog for missing fields
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Missing Selection"),
                    content:
                        Text("Please select all fields for S.NO ${i + 1}."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
              return; // Stop further execution
            }

            // Log the valid row's values
            debugPrint("Row ${i + 1}: Subject=${row.subjectId}, "
                "Classes=${row.selectedClasses!.map((cls) => cls.className).join(", ")}, "
                "Decision Maker=${row.decisionMaker}");
          }
        }

        // If all rows are valid, you can proceed with further actions
        debugPrint("All rows are valid. Proceeding with form submission.");

        submitContact();
      }
    } else {
      // Focus on the first field with an error
      List<FocusNode> focusNodes = [
        _lastNameFocusNode,
        _emailIdFocusNode,
        _phoneNumberFocusNode,
        _addressFocusNode,
        _pinCodeFocusNode,
      ];

      for (FocusNode focusNode in focusNodes) {
        if (focusNode.hasFocus) {
          focusNode.requestFocus();
          break;
        }
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode, {
    int maxLines = 1,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    bool isDateField = label == "Date of Birth" || label == "Anniversary";

    // Calculate the maximum selectable date for Date of Birth
    DateTime maxDate = label == "Date of Birth"
        ? DateTime.now().subtract(const Duration(days: 365 * 18))
        : DateTime.now();

    DateTime initialDate = label == "Date of Birth" ? maxDate : DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isDateField
            ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1970, 1, 1),
                  lastDate: maxDate,
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light(),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  controller.text = DateFormat('dd MMM yyyy').format(picked);
                  fieldKey.currentState?.validate();
                }
              }
            : null,
        child: IgnorePointer(
          ignoring: isDateField,
          child: TextFormField(
            key: fieldKey,
            style: TextStyle(fontSize: textFontSize),
            controller: controller,
            keyboardType: (label == 'Mobile Number' ||
                    label == 'Phone Number' ||
                    label == 'Phone' ||
                    label == 'Mobile' ||
                    label == 'Pin Code')
                ? TextInputType.phone
                : TextInputType.text,
            inputFormatters: getInputFormatters(label),
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: labelFontSize),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? const Icon(Icons.calendar_month) : null,
            ),
            textAlign: TextAlign.start,
            maxLines: maxLines,
            validator: (value) {
              if (_isSubmitted) {
                if ((value == null || value.isEmpty) &&
                    (label == 'First Name' || (label == 'Last Name'))) {
                  return validateName(
                      label, value, mandatoryCustomerContactFirstLastName);
                } else if ((value == null || value.isEmpty) &&
                    (_addressController.text.isNotEmpty &&
                        label == 'Pin Code')) {
                  return 'Please enter $label';
                } else if (label == 'Mobile Number' ||
                    label == 'Phone Number' ||
                    label == 'Phone' ||
                    label == 'Mobile') {
                  return validatePhoneNumber(
                      label, value, mandatorySettingEmailMobile);
                } else if (label == 'Email' || label == 'Email Id') {
                  return validateEmail(
                      label,
                      value,
                      mandatorySettingEmailMobile,
                      _phoneNumberController.text.isEmpty);
                } else if (label == 'Pin Code' &&
                    _addressController.text.isNotEmpty &&
                    value != null &&
                    value.isNotEmpty &&
                    value.length < 6) {
                  return 'Please enter valid $label';
                }
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                fieldKey.currentState?.validate();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required GlobalKey<FormFieldState> fieldKey,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: CustomText('Select'),
          ),
          ...items.map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: CustomText(item, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (newValue) {
          onChanged(newValue);
          fieldKey.currentState?.validate();
        },
        validator: (newValue) {
          if (_isSubmitted &&
              (newValue == null || newValue.isEmpty) &&
              (label == 'Designation')) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Future<void> checkForEdit() async {
    try {
      contactId = extractNumericPart(widget.action ?? '');
      validated = extractStringPart(widget.action ?? '');

      CustomerListService service = CustomerListService();
      contactDetailsResponse = await service.contactDetailsSchool(
          widget.type, contactId, validated, token);

      _populateCustomerDetails(contactDetailsResponse.contactDetails);
    } catch (e) {
      debugPrint('Error in checkForEdit: $e');
    }
  }

  void _populateCustomerDetails(SchoolContactDetails? details) {
    if (details == null) return;
    _firstNameController.text = details.firstName;
    _lastNameController.text = details.lastName;
    _addressController.text = details.resAddress;
    _pinCodeController.text = details.resPincode;
    _phoneNumberController.text = details.contactMobile;
    _emailIdController.text = details.contactEmailId;
    _dobController.text = details.birthDay;
    _anniversaryController.text = details.anniversary;
    _selectedPrimaryContact = details.primaryContact == 'Y';
    _selectedContactStatus = details.contactStatus == 'Active';
    try {
      // Ensure all lists are of the same length
      if (details.classNumId.isEmpty &&
          details.decisionId.isEmpty &&
          details.subjectId.isEmpty) {
        throw Exception("0 lengths of ClassNumId, DecisionId, or SubjectId.");
      }
      // Parse ClassNumId, DecisionId, and SubjectId from the response
      List<String> classNumIds = details.classNumId.split(',');
      List<String> decisionIds = details.decisionId.split(',');
      List<String> subjectIds = details.subjectId.split(',');

      // Ensure all lists are of the same length
      if (classNumIds.isEmpty && decisionIds.isEmpty && subjectIds.isEmpty) {
        throw Exception("0 lengths of ClassNumId, DecisionId, or SubjectId.");
      }
      if (classNumIds.length != decisionIds.length ||
          classNumIds.length != subjectIds.length) {
        throw Exception(
            "Mismatched lengths of ClassNumId, DecisionId, or SubjectId.");
      }

      // Dynamically create rows based on parsed data
      List<FormRowData> newRows = [];
      for (int i = 0; i < classNumIds.length; i++) {
        List<String> classes = classNumIds[i].split('~');
        String decision = decisionIds[i];
        String subject = subjectIds[i];

        // Map class names to classNumId
        List<Classes> selectedClasses = classes.map((cls) {
          // Find the class object that matches the class name
          final classObj = customerEntryMasterResponse.classesList.firstWhere(
            (classItem) => classItem.classNumId == int.parse(cls),
            orElse: () => Classes(classNumId: 0, className: ''),
          );

          return classObj;
        }).toList();

        // Create the row with mapped class details
        newRows.add(FormRowData(
          subjectId: int.tryParse(subject),
          selectedClasses: selectedClasses,
          decisionMaker: decision == 'Y' ? 'Yes' : 'No',
        ));
      }
      setState(() {
        selectedRows = newRows;
        debugPrint('selectedRows : $selectedRows');
        debugPrint('selectedRows size : ${selectedRows.length}');
      });

      _dynamicFormKey.currentState?.updateRows(newRows);
    } catch (e) {
      debugPrint('Error in classNumId: $e');
    }

    try {
      debugPrint(
          'salutationMasterList size : ${customerEntryMasterResponse.salutationMasterList.length}');
      if (details.salutationId > 0 &&
          customerEntryMasterResponse.salutationMasterList.isNotEmpty) {
        final salutation =
            customerEntryMasterResponse.salutationMasterList.firstWhere(
          (b) => b.salutationId == details.salutationId,
          orElse: () {
            debugPrint(
                'Edit SalutationId ID ${details.salutationId} not found.');
            return SalutationMaster(salutationId: 0, salutationName: '');
          },
        );
        if (salutation.salutationId > 0) {
          debugPrint('salutationName ${salutation.salutationName}');
          setState(() {
            _selectedSalutation = salutation.salutationName;
            _selectedSalutationId = salutation.salutationId;
          });
        } else {
          debugPrint('Edit salutation 0');
        }
      }
    } catch (e) {
      debugPrint('Error in salutationId: $e');
    }
    debugPrint(
        'contactDesignationList size : ${customerEntryMasterResponse.contactDesignationList.length}');
    if (details.contactDesignationId > 0 &&
        customerEntryMasterResponse.contactDesignationList.isNotEmpty) {
      final contactDesignation =
          customerEntryMasterResponse.contactDesignationList.firstWhere(
        (b) => b.contactDesignationId == details.contactDesignationId,
        orElse: () {
          debugPrint(
              'Edit Designation ID ${details.contactDesignationId} not found.');
          return ContactDesignation(
              contactDesignationId: 0, contactDesignationName: '');
        },
      );
      if (contactDesignation.contactDesignationId > 0) {
        debugPrint(
            'contactDesignationName ${contactDesignation.contactDesignationName}');
        setState(() {
          _selectedContactDesignation =
              contactDesignation.contactDesignationName;
          _selectedContactDesignationId =
              contactDesignation.contactDesignationId;
        });
      } else {
        debugPrint('Edit contactDesignation 0');
      }
    }

    debugPrint(
        'dataSourceList size : ${customerEntryMasterResponse.dataSourceList.length}');
    if (details.dataSourceId > 0 &&
        customerEntryMasterResponse.dataSourceList.isNotEmpty) {
      final dataSource = customerEntryMasterResponse.dataSourceList.firstWhere(
        (b) => b.dataSourceId == details.dataSourceId,
        orElse: () {
          debugPrint('Edit Data Source ID ${details.dataSourceId} not found.');
          return DataSource(dataSourceId: 0, dataSourceName: '');
        },
      );
      if (dataSource.dataSourceId > 0) {
        debugPrint('dataSource ${dataSource.dataSourceName}');
        setState(() {
          _selectedDataSource = dataSource.dataSourceName;
          _selectedDataSourceId = dataSource.dataSourceId;
        });
      } else {
        debugPrint('Edit dataSource 0');
      }
    }

    if (details.resCountry > 0) {
      final selectedCountry = _findCountryById(details.resCountry);
      if (selectedCountry.countryId == 0) {
        debugPrint('selectedCountry 0');
      } else {
        _onCountryChanged(selectedCountry);

        final selectedState = _findStateById(details.resState);
        if (selectedState.stateId == 0) {
          debugPrint('selectedState 0');
        } else {
          _onStateChanged(selectedState);

          final selectedDistrict = _findDistrictById(details.resDistrict);
          if (selectedDistrict.districtId == 0) {
            debugPrint('selectedDistrict 0');
          } else {
            _onDistrictChanged(selectedDistrict);

            if (_filteredCities.isNotEmpty) {
              _selectedCity = _filteredCities.firstWhere(
                (geo) => geo.cityId == details.resCity,
                orElse: () => _filteredCities.first,
              );
            }

            final selectedCity = _findCityById(details.resCity);
            if (selectedCity.cityId == 0) {
              debugPrint('selectedCity 0');
            } else {
              _selectedCity = selectedCity;
            }
          }
        }
      }
    }

    _formKey.currentState!.validate();

    if (details.resAddress.isNotEmpty) {
      editAddress();
    }
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
    validate();
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
    validate();
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
    validate();
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
      validator: (value) =>
          _addressController.text.isNotEmpty && _isSubmitted && value == null
              ? 'Please select $label'
              : null,
    );
  }

  void unableToGetAddress() async {
    final address =
        '${_selectedCity?.city ?? ''}, ${_selectedState?.state ?? ''}, ${_selectedState?.district ?? ''}, ${_selectedCountry?.country ?? ''}}';
    debugPrint('Edit contact address 2 $address');
    try {
      List<Location> locations = await locationFromAddress(address);
      debugPrint('Edit contact address locations size ${locations.length}');
      if (locations.isNotEmpty) {
        // Use the first matched location
        Location addressLocation = locations.first;
        debugPrint(
            'Edit contact address latitude ${addressLocation.latitude}, longitude : ${addressLocation.longitude}');
        LatLng initialPosition =
            LatLng(addressLocation.latitude, addressLocation.longitude);
        debugPrint(
            'Edit contact initialPosition latitude ${initialPosition.latitude}, longitude : ${initialPosition.longitude}');

        // Update marker and position
        _currentPosition = initialPosition;
        debugPrint(
            'Edit contact _currentPosition latitude ${_currentPosition?.latitude}, longitude : ${_currentPosition?.longitude}');

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
          const Duration(seconds: 10),
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
    debugPrint('Edit contact address 3 $address');
    try {
      List<Location> locations = await locationFromAddress(address);
      debugPrint('Edit contact address locations size ${locations.length}');
      if (locations.isNotEmpty) {
        // Use the first matched location
        Location addressLocation = locations.first;
        debugPrint(
            'Edit contact address latitude ${addressLocation.latitude}, longitude : ${addressLocation.longitude}');
        LatLng initialPosition =
            LatLng(addressLocation.latitude, addressLocation.longitude);
        debugPrint(
            'Edit contact initialPosition latitude ${initialPosition.latitude}, longitude : ${initialPosition.longitude}');

        // Update marker and position
        _currentPosition = initialPosition;
        debugPrint(
            'Edit contact _currentPosition latitude ${_currentPosition?.latitude}, longitude : ${_currentPosition?.longitude}');

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

  void submitContact() async {
    FocusScope.of(context).unfocus();

    if (!await _checkInternetConnection()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final type = widget.isEdit ? 'Editing' : 'Adding';
    try {
      debugPrint('contactId : $contactId');
      final responseData = await CustomerListService()
          .insertOrUpdateCustomerContact(
              widget.type,
              (_selectedPrimaryContact == true) ? 'Y' : 'N',
              _selectedSalutationId ?? 0,
              _selectedContactDesignationId ?? 0,
              _firstNameController.text.toString().trim(),
              _lastNameController.text.toString().trim(),
              _emailIdController.text.toString().trim(),
              _phoneNumberController.text.toString().trim(),
              _selectedContactStatus == true ? 'Active' : 'Inactive',
              userId ?? 0,
              widget.customerId,
              validated,
              _addressController.text.toString().trim(),
              _selectedCity?.cityId ?? 0,
              _pinCodeController.text.toString().trim(),
              _dobController.text.toString().trim(),
              _anniversaryController.text.toString().trim(),
              contactId,
              generateXml(),
              _selectedDataSourceId ?? 0,
              token);

      if (responseData.status == 'Success') {
        String s = responseData.s;
        String w = responseData.w;
        debugPrint('s:$s');
        debugPrint('w:$w');
        if (w.isNotEmpty) {
          debugPrint('$type Contact: $w');
          _toastMessage.showWarnToastMessage(w);
        } else if (s.isNotEmpty) {
          debugPrint('$type Contact: $s');
          _toastMessage.showInfoToastMessage(s);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          if (kDebugMode) {
            print('${widget.type} contact error s or w is empty');
          }
          _toastMessage.showToastMessage(
              "An error occurred while ${type.toLowerCase()} ${widget.type.toLowerCase()} contact.");
        }
      } else {
        if (kDebugMode) {
          print(
              'Update contact error ${type.toLowerCase()} ${responseData.status}');
        }
        _toastMessage.showToastMessage(
            "An error occurred while ${type.toLowerCase()} ${widget.type}.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('$type Contact Error $e');
      }
      _toastMessage.showToastMessage(
          "An error occurred while ${type.toLowerCase()} ${widget.type.toLowerCase()}.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String generateXml() {
    if (selectedRows.isEmpty) {
      return "";
    }
    StringBuffer xml = StringBuffer();

    xml.write('<dataRow_CCD>');
    for (var row in selectedRows) {
      if (row.subjectId != null &&
          row.selectedClasses != null &&
          row.decisionMaker != null) {
        for (var selectedClass in row.selectedClasses!) {
          xml.write('<data_CCD>');
          xml.write('<SubjectId>${row.subjectId}</SubjectId>');
          xml.write('<ClassNumId>${selectedClass.classNumId}</ClassNumId>');

          // Transform decisionMaker to "Y" for "Yes" and "N" for "No"
          String decisionValue = row.decisionMaker == "Yes" ? "Y" : "N";
          xml.write('<DecisionId>$decisionValue</DecisionId>');

          xml.write('</data_CCD>');
        }
      }
    }
    xml.write('</dataRow_CCD>');

    return xml.toString();
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }
}
