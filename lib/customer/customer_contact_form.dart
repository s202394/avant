import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/utils.dart';
import '../map/my_map_widget.dart';
import '../model/contact_detail_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class CustomerContactForm extends StatefulWidget {
  final String type;
  final int customerId;
  final bool isEdit;
  final String? action;

  const CustomerContactForm({
    super.key,
    required this.type,
    required this.customerId,
    this.isEdit = false,
    this.action = '',
  });

  @override
  CustomerContactFormState createState() => CustomerContactFormState();
}

class CustomerContactFormState extends State<CustomerContactForm> {
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

  bool _isLoading = false;
  bool _isSubmitted = false;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;
  late int? userId;

  int contactId = 0;

  String validated = 'A';

  String? mandatorySettingEmailMobile;
  String? mandatoryCustomerContactFirstLastName;

  String? profileCode;

  bool hasCheckedForEdit = false;

  late CustomerEntryMasterResponse customerEntryMasterResponse;
  late CustomerContactDetailsResponse contactDetailsResponse;

  final GlobalKey<MyMapWidgetState> _mapKey = GlobalKey<MyMapWidgetState>();

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

    mandatoryCustomerContactFirstLastName =
        await dbHelper.getCustomerContactFirstLastNameMandatory();

    prefs = await SharedPreferences.getInstance();
    userId = await getUserId();
    executiveId = await getExecutiveId() ?? 0;
    profileCode = await getProfileCode() ?? '';
    setState(() {
      token = prefs.getString('token') ?? '';
      _cityAccess = prefs.getString('CityAccess') ?? '';
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
            MyMapWidget(
              key: _mapKey,
              onAddressSelected: (address) {
                setState(() {
                  _addressController.text = address;
                });
              },
            ),
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
                _formKey.currentState!.validate();
              },
            ),
            const SizedBox(height: 8),
            _buildTextField('Pin Code', _pinCodeController, _pinCodeFieldKey,
                _pinCodeFocusNode),
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

    _isSubmitted = true;

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
        _firstNameFocusNode,
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
      contactDetailsResponse = await service.contactDetails(
          widget.type, contactId, validated, token);

      _populateCustomerDetails(contactDetailsResponse.contactDetails);
    } catch (e) {
      debugPrint('Error in checkForEdit: $e');
    }
  }

  void _populateCustomerDetails(CustomerContactDetails? details) {
    if (details == null) return;
    _firstNameController.text = details.firstName;
    _lastNameController.text = details.lastName;
    _addressController.text = details.resAddress;
    _pinCodeController.text = details.resPincode;
    _phoneNumberController.text = details.contactMobile;
    _emailIdController.text = details.contactEmailId;
    if (details.birthDay.isNotEmpty) {
      _dobController.text = details.birthDay;
    }
    if (details.anniversary.isNotEmpty) {
      _anniversaryController.text = details.anniversary;
    }

    _selectedPrimaryContact =
        details.primaryContact == 'Yes' || details.primaryContact == 'Y';
    _selectedContactStatus = details.contactStatus == 'Active';

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

    if (details.resAddress.isNotEmpty) {
      final address = '${details.resAddress}, ${details.resPincode}';
      if (_mapKey.currentState != null && address.isNotEmpty) {
        _mapKey.currentState!.setAddress(address);
      }
    }
    // editAddress();
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

    _formKey.currentState!.validate();
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

    _formKey.currentState!.validate();
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

    _formKey.currentState!.validate();
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
          _isSubmitted && value == null ? 'Please select $label' : null,
    );
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
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
              '',
              0,
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
}
