import 'dart:async';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/customer/new_customer_school_form2.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/utils.dart';
import '../map/my_map_widget.dart';
import '../model/fetch_customer_details_model.dart';
import '../model/login_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

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

  Geography? _selectedCountry;
  Geography? _selectedState;
  Geography? _selectedDistrict;
  Geography? _selectedCity;

  List<Geography> _filteredCountries = [];
  List<Geography> _filteredStates = [];
  List<Geography> _filteredDistricts = [];
  List<Geography> _filteredCities = [];

  List<Geography> _allGeographies = [];

  BoardMaster? _selectedBoard;
  ChainSchool? _selectedChainSchool;
  bool? _selectedKeyCustomer;
  bool? _selectedCustomerStatus;

  bool _isLoading = false;
  bool _isSubmitted = false;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  String validated = '';

  String? mandatorySetting;

  bool hasCheckedForEdit = false;

  late CustomerEntryMasterResponse customerEntryMasterResponse;
  late FetchCustomerDetailsSchoolResponse customerDetailsSchoolResponse;
  SchoolDetails? schoolDetails;

  final GlobalKey<MyMapWidgetState> _mapKey = GlobalKey<MyMapWidgetState>();

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
    mandatorySetting = await dbHelper.getSchoolMobileEmailMandatory();

    prefs = await SharedPreferences.getInstance();
    executiveId = await getExecutiveId() ?? 0;
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
          _initializeGeographyHierarchy();
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
        '',
        executiveId,
        token,
      );

      setState(() {
        _allGeographies = geographyResponse.geographyList;
        _initializeGeographyHierarchy();
      });
    } catch (e) {
      debugPrint("Error fetching geography data: $e");
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
            if (widget.isEdit &&
                schoolDetails != null &&
                (schoolDetails?.msgWarning ?? '') != 'N')
              Column(
                children: [
                  CustomText(schoolDetails?.msgWarning ?? '',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                  const SizedBox(height: 10),
                ],
              ),
            _buildTextField('${widget.type} Name', _customerNameController,
                _customerNameFieldKey, _customerNameFocusNode),
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
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 8),
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
                if (widget.isEdit) {
                  if (schoolDetails != null &&
                      (schoolDetails?.msgWarning ?? '') == 'N') {
                    _submitForm();
                  }
                } else {
                  _submitForm();
                }
              },
              child: Container(
                width: double.infinity,
                color: (widget.isEdit)
                    ? ((schoolDetails != null &&
                            (schoolDetails?.msgWarning ?? '') == 'N')
                        ? Colors.blue
                        : Colors.grey)
                    : Colors.blue,
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

    _isSubmitted = true;

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
              isEdit: widget.isEdit,
              validated: validated,
              customerDetailsSchoolResponse:
                  widget.isEdit ? customerDetailsSchoolResponse : null,
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
            if (_isSubmitted) {
              if (label == 'Email Id') {
                return validateEmail(label, value, mandatorySetting,
                    _phoneNumberController.text.isEmpty);
              }

              if (label == 'Phone Number') {
                return validatePhoneNumber(label, value, mandatorySetting);
              }
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == 'Pin Code' && value.length < 6) {
                return 'Please enter valid $label';
              }
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
          if (_isSubmitted && (value == null || value.boardName.isEmpty)) {
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
      ),
    );
  }

  Future<void> checkForEdit() async {
    setState(() {
      _isLoading = true; // Start loader
    });
    try {
      int customerId = extractNumericPart(widget.action);
      validated = extractStringPart(widget.action);

      FetchCustomerDetailsService service = FetchCustomerDetailsService();
      customerDetailsSchoolResponse = await service.fetchCustomerDetails(
          customerId,
          validated,
          widget.type,
          token,
          (json) => FetchCustomerDetailsSchoolResponse.fromJson(json));

      _populateCustomerDetails(customerDetailsSchoolResponse.schoolDetails);
    } catch (e) {
      debugPrint('Error in checkForEdit: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loader after fetching details
      });
    }
  }

  void _populateCustomerDetails(SchoolDetails? details) {
    if (details == null) return;
    schoolDetails = details;
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
    final address =
        '${details.schoolName}, ${details.address}, ${_selectedCity?.city}, ${_selectedCity?.district}, ${_selectedCity?.state}, ${_selectedCity?.country}, ${details.pinCode}';
    _debounceSetAddress(address);
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

  void _initializeGeographyHierarchy() {
    // Parse city access IDs
    List<int> cityIds =
        _cityAccess.split(',').map((id) => int.parse(id)).toList();
    debugPrint('cityIds:$cityIds');
    debugPrint('cityIds:${cityIds.length}');

    // Filter geography data based on city access
    _allGeographies =
        _allGeographies.where((g) => cityIds.contains(g.cityId)).toList();
    // Get unique countries
    Set<int> uniqueCountryIds = {};
    _filteredCountries = _allGeographies
        .where((g) => uniqueCountryIds.add(g.countryId))
        .toList();
    debugPrint('_filteredCountries:${_filteredCountries.length}');
    // Initialize other lists as empty
    _filteredStates = [];
    _filteredDistricts = [];
    _filteredCities = [];
  }

  Timer? _addressDebounce;

  void _debounceSetAddress(String address) {
    if (_addressDebounce?.isActive ?? false) _addressDebounce!.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_mapKey.currentState != null && address.isNotEmpty) {
        _mapKey.currentState!.setAddress(address);
      }
    });
  }

  void _onCountryChanged(Geography? selected) {
    setState(() {
      _selectedCountry = selected;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedCity = null;

      if (selected == null) {
        _filteredStates = [];
        _filteredDistricts = [];
        _filteredCities = [];
        return;
      }

      // Filter unique states for the selected country based on city access
      final Set<int> uniqueStateIds = {};
      _filteredStates = _allGeographies
          .where((geo) =>
              geo.countryId == selected.countryId &&
              uniqueStateIds.add(geo.stateId)) // Only unique states
          .toList();

      _filteredDistricts = [];
      _filteredCities = [];
    });
    _formKey.currentState?.validate();
  }

  void _onStateChanged(Geography? selected) {
    setState(() {
      _selectedState = selected;
      _selectedDistrict = null;
      _selectedCity = null;

      if (selected == null) {
        _filteredDistricts = [];
        _filteredCities = [];
        return;
      }

      // Filter unique districts for the selected state based on city access
      final Set<int> uniqueDistrictIds = {};
      _filteredDistricts = _allGeographies
          .where((geo) =>
              geo.stateId == selected.stateId &&
              uniqueDistrictIds.add(geo.districtId)) // Only unique districts
          .toList();

      _filteredCities = [];
    });
    _formKey.currentState?.validate();
  }

  void _onDistrictChanged(Geography? selected) {
    setState(() {
      _selectedDistrict = selected;
      _selectedCity = null;

      if (selected == null) {
        _filteredCities = [];
        return;
      }

      // Filter unique cities for the selected district based on city access
      final Set<int> uniqueCityIds = {};
      _filteredCities = _allGeographies
          .where((geo) =>
              geo.districtId == selected.districtId &&
              uniqueCityIds.add(geo.cityId)) // Only unique cities
          .toList();
    });
    _formKey.currentState?.validate();
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
      validator: (value) {
        if (_isSubmitted && value == null) {
          return 'Please select $label';
        }
        return null;
      },
    );
  }
}
