import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/utils.dart';
import '../model/contact_detail_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class CustomerContactSchoolForm extends StatefulWidget {
  final String type;
  final bool isEdit;
  final String? action;

  const CustomerContactSchoolForm({
    super.key,
    required this.type,
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

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  String validated = '';

  String? mandatorySetting;

  bool hasCheckedForEdit = false;

  late GoogleMapController mapController;
  LatLng? _currentPosition;
  Marker? _currentMarker;
  bool isMapControllerInitialized = false;
  int retryCount = 0;

  late CustomerEntryMasterResponse customerEntryMasterResponse;
  late CustomerContactDetailsSchoolResponse contactDetailsResponse;

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
    debugPrint('Add customer address}');
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
    return SingleChildScrollView(
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
            const CustomText('Customer Status:'),
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
            _buildTextField('Last Name', _lastNameController, _lastNameFieldKey,
                _lastNameFocusNode),
            buildDropdownField(
              label: 'Designation',
              value: _selectedContactDesignation,
              items: contactDesignationMap.keys.toList(),
              onChanged: (value) {
                setState(() {
                  _selectedContactDesignation = value;
                  _selectedContactDesignationId = contactDesignationMap[value];
                });
              },
              fieldKey: _contactDesignationFieldKey,
            ),
            _buildTextField('Email', _emailIdController, _emailIdFieldKey,
                _emailIdFocusNode),
            _buildTextField('Mobile Number', _phoneNumberController,
                _phoneNumberFieldKey, _phoneNumberFocusNode),
            _buildTextField(
                'Date of Birth', _dobController, _dobFieldKey, _dobFocusNode),
            _buildTextField('Anniversary', _anniversaryController,
                _anniversaryFieldKey, _anniversaryFocusNode),
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
                    'Submit',
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
      if (_selectedPrimaryContact == null) {
        _toastMessage.showToastMessage("Please enter Primary Contact");
      } else if (_selectedContactStatus == null) {
        _toastMessage.showToastMessage("Please select Contact Status");
      } else {
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
            keyboardType: (label == 'Mobile' || label == 'Pin Code')
                ? TextInputType.phone
                : TextInputType.text,
            inputFormatters: _getInputFormatters(label),
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
              if ((value == null || value.isEmpty) &&
                  (label == 'Last Name' ||
                      (_addressController.text.isNotEmpty &&
                          label == 'Pin Code'))) {
                return 'Please enter $label';
              }
              if (label == 'Mobile Number' &&
                  value != null &&
                  value.isNotEmpty &&
                  !Validator.isValidMobile(value)) {
                return 'Please enter valid $label';
              }
              if (label == 'Email' &&
                  value != null &&
                  value.isNotEmpty &&
                  !Validator.isValidEmail(value)) {
                return 'Please enter valid $label';
              }
              if (label == 'Pin Code' &&
                  _addressController.text.isNotEmpty &&
                  value != null &&
                  value.isNotEmpty &&
                  value.length < 6) {
                return 'Please enter valid $label';
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
          if ((newValue == null || newValue.isEmpty) &&
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
      int contactId = extractNumericPart(widget.action ?? '');
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

    debugPrint(
        'salutationMasterList size : ${customerEntryMasterResponse.salutationMasterList.length}');
    if (customerEntryMasterResponse.salutationMasterList.isNotEmpty) {
      final salutation =
          customerEntryMasterResponse.salutationMasterList.firstWhere(
        (b) => b.salutationId == details.salutationId,
        orElse: () {
          debugPrint('Edit SalutationId ID ${details.salutationId} not found.');
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

    debugPrint(
        'contactDesignationList size : ${customerEntryMasterResponse.contactDesignationList.length}');
    if (customerEntryMasterResponse.contactDesignationList.isNotEmpty) {
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
    if (customerEntryMasterResponse.dataSourceList.isNotEmpty) {
      final dataSource = customerEntryMasterResponse.dataSourceList.firstWhere(
        (b) => b.dataSourceId == details.dataSourceId,
        orElse: () {
          debugPrint(
              'Edit Data Source ID ${details.contactDesignationId} not found.');
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

    debugPrint('details.countryId : ${details.resCountry}');
    debugPrint('details.stateId : ${details.resState}');
    debugPrint('details.districtId : ${details.resDistrict}');
    debugPrint('details.cityId : ${details.resCity}');

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

  void submitContact() {}
}
