import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/customer/customer_list.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/utils.dart';
import '../model/search_bookseller_response.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class NewCustomerSchoolForm4 extends StatefulWidget {
  final String type;
  final String customerName;
  final String address;
  final int cityId;
  final String cityName;
  final String pinCode;
  final String phoneNumber;
  final String emailId;
  final int boardId;
  final int chainSchoolId;
  final String keyCustomer;
  final String customerStatus;
  final int startClassId;
  final int endClassId;
  final int samplingMonthId;
  final int decisionMonthId;
  final String medium;
  final String ranking;
  final String pan;
  final String gst;
  final String purchaseMode;
  final List<BookSellers> bookseller;
  final String xmlClassName;

  final String validated;


  const NewCustomerSchoolForm4(
      {super.key,
      required this.type,
      required this.customerName,
      required this.address,
      required this.cityId,
      required this.cityName,
      required this.pinCode,
      required this.phoneNumber,
      required this.emailId,
      required this.boardId,
      required this.chainSchoolId,
      required this.keyCustomer,
      required this.customerStatus,
      required this.startClassId,
      required this.endClassId,
      required this.samplingMonthId,
      required this.decisionMonthId,
      required this.medium,
      required this.ranking,
      required this.pan,
      required this.gst,
      required this.purchaseMode,
      required this.bookseller,
      required this.xmlClassName,
      required this.validated,
   });

  @override
  NewCustomerSchoolForm4State createState() => NewCustomerSchoolForm4State();
}

class NewCustomerSchoolForm4State extends State<NewCustomerSchoolForm4> {
  late Future<CustomerEntryMasterResponse> futureData;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _contactFirstNameController =
      TextEditingController();
  final TextEditingController _contactLastNameController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _anniversaryController = TextEditingController();
  final TextEditingController _contactAddressController =
      TextEditingController();
  final TextEditingController _contactCityController = TextEditingController();
  final TextEditingController _contactPinCodeController =
      TextEditingController();

  final _contactFirstNameFieldKey = GlobalKey<FormFieldState>();
  final _contactLastNameFieldKey = GlobalKey<FormFieldState>();
  final _phoneNumberFieldKey = GlobalKey<FormFieldState>();
  final _emailIdFieldKey = GlobalKey<FormFieldState>();
  final _dobFieldKey = GlobalKey<FormFieldState>();
  final _anniversaryFieldKey = GlobalKey<FormFieldState>();
  final _contactDesignationFieldKey = GlobalKey<FormFieldState>();
  final _salutationFieldKey = GlobalKey<FormFieldState>();
  final _contactAddressFieldKey = GlobalKey<FormFieldState>();
  final _contactCityFieldKey = GlobalKey<FormFieldState>();
  final _contactPinCodeFieldKey = GlobalKey<FormFieldState>();
  final _dataSourceFieldKey = GlobalKey<FormFieldState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();
  LocationService locationService = LocationService();

  int? executiveId;
  int? userId;

  String? _selectedContactDesignation;
  int? _selectedContactDesignationId;
  String? _selectedSalutation;
  int? _selectedSalutationId;
  String? _selectedDataSource;
  int? _selectedDataSourceId;
  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;

  late SharedPreferences prefs;
  late String token;

  bool _isLoading = false;

  String? mandatorySettingEmailMobile;
  String? mandatoryCustomerContactFirstLastName;

  late CustomerEntryMasterResponse customerEntryMasterResponse;

  @override
  void initState() {
    super.initState();
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
    _fetchCityAccess();
  }

  Future<CustomerEntryMasterResponse> initializePreferencesAndData() async {
    mandatorySettingEmailMobile =
        await dbHelper.getTeacherMobileEmailMandatory();
    debugPrint('mandatorySettingEmailMobile:$mandatorySettingEmailMobile');
    mandatoryCustomerContactFirstLastName =
        await dbHelper.getCustomerContactFirstLastNameMandatory();
    debugPrint(
        'mandatoryCustomerContactFirstLastName:$mandatoryCustomerContactFirstLastName');

    // Check if data exists in the database
    CustomerEntryMasterResponse? existingData =
        await dbHelper.getCustomerEntryMasterResponse();

    if (existingData != null && !isEmptyData(existingData)) {
      // Data exists in the database, return it
      if (kDebugMode) {
        print(
            "CustomerEntryMaster data found in db: ${existingData.salutationMasterList}");
      }
      return existingData;
    } else {
      String downHierarchy = prefs.getString('DownHierarchy') ?? '';

      // Data does not exist in the database, fetch from API
      if (kDebugMode) {
        print("CustomerEntryMaster data not found in db. Fetching from API...");
      }

      try {
        CustomerEntryMasterResponse response =
            await CustomerEntryMasterService()
                .fetchCustomerEntryMaster(downHierarchy, token);
        if (kDebugMode) {
          print(
              "CustomerEntryMaster data fetched from API and saved to db. $response");
        }
        // Save the fetched data to the database
        await dbHelper.insertCustomerEntryMasterResponse(response);

        if (kDebugMode) {
          print(
              "CustomerEntryMaster data fetched from API and saved to db. $response");
        }
        return response;
      } catch (e) {
        // Handle API fetch error
        if (kDebugMode) {
          print("Error fetching CustomerEntryMaster data from API: $e");
        }
        rethrow; // Re-throw the error if needed
      }
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
  void dispose() {
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactAddressController.dispose();
    _contactCityController.dispose();
    _contactPinCodeController.dispose();
    _phoneNumberController.dispose();
    _emailIdController.dispose();
    _dobController.dispose();
    _anniversaryController.dispose();
    super.dispose();
  }

  void _fetchCityAccess() async {
    executiveId = await getExecutiveId();

    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
    userId = await getUserId();
    _loadGeographyData();
    futureData = initializePreferencesAndData();
  }

  void _loadGeographyData() async {
    // Retrieve geography data from the database
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
      _fetchGeographyData();
    }
  }

  void _fetchGeographyData() async {
    GeographyService geographyService = GeographyService();
    try {
      GeographyResponse geographyResponse = await geographyService
          .fetchGeographyData(_cityAccess, executiveId ?? 0, token);
      List<int> cityIds =
          _cityAccess.split(',').map((id) => int.parse(id)).toList();
      setState(() {
        _filteredCities = geographyResponse.geographyList
            .where((geography) => cityIds.contains(geography.cityId))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'New Customer - ${widget.type}'),
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
                  // Once data is available, initialize the response
                  customerEntryMasterResponse = snapshot.data!;
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
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  textAlign: TextAlign.center,
                  widget.customerName,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  textAlign: TextAlign.center,
                  widget.address,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  textAlign: TextAlign.center,
                  '${widget.cityName} - ${widget.pinCode}',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const CustomText(
                      textAlign: TextAlign.center,
                      'Primary Contact',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField('Contact First Name',
                        _contactFirstNameController, _contactFirstNameFieldKey),
                    _buildTextField('Contact Last Name',
                        _contactLastNameController, _contactLastNameFieldKey),
                    buildDropdownField(
                      label: 'Contact Designation',
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
                    _buildTextField(
                        'Mobile', _phoneNumberController, _phoneNumberFieldKey),
                    _buildTextField(
                        'Email', _emailIdController, _emailIdFieldKey),
                    _buildTextField(
                        'Date of Birth', _dobController, _dobFieldKey),
                    _buildTextField('Anniversary', _anniversaryController,
                        _anniversaryFieldKey),
                    _buildTextField('Address', _contactAddressController,
                        _contactAddressFieldKey,
                        maxLines: 5),
                    _buildDropdownFieldCity(
                        'City', _contactCityController, _contactCityFieldKey),
                    _buildTextField('Pin Code', _contactPinCodeController,
                        _contactPinCodeFieldKey),
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
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      if (kDebugMode) {
                        print("Add ${widget.type} data API");
                      }
                      _submitForm(data.classesList);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16),
                      child: Text(
                        'Add ${widget.type}',
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
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  void _submitForm(List<Classes> classesList) async {
    FocusScope.of(context).unfocus();

    if (_emailIdController.text.isEmpty &&
        _phoneNumberController.text.isEmpty) {
      _toastMessage.showToastMessage('Please enter Email or Mobile');
      return;
    }

    if (!await _checkInternetConnection()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (kDebugMode) {
        print("${widget.type} _submitForm clicked");
      }
      Position position = await locationService.getCurrentLocation();
      if (kDebugMode) {
        print(
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      }
      int bookseller1Id = 0;
      int bookseller2Id = 0;
      if (widget.purchaseMode == 'Bookseller') {
        if (widget.bookseller.length == 1) {
          bookseller1Id = widget.bookseller[0].action;
        }
        if (widget.bookseller.length == 2) {
          bookseller1Id = widget.bookseller[0].action;
          bookseller2Id = widget.bookseller[1].action;
        }
      }

      String xmlClassName = widget.xmlClassName;
      if (kDebugMode) {
        print(xmlClassName);
        print('bookseller1Id:$bookseller1Id');
        print('bookseller2Id:$bookseller2Id');
      }
      final responseData = await CreateNewCustomerService().createNewCustomerSchool(
          widget.type,
          widget.customerName.trim(),
          "",
          widget.emailId,
          widget.phoneNumber,
          widget.address,
          widget.cityId,
          int.parse(widget.pinCode),
          widget.keyCustomer,
          widget.customerStatus,
          "",
          "<CustomerExecutive_Data><CustomerExecutive><AccountTableExecutiveId>${executiveId ?? 0}</AccountTableExecutiveId></CustomerExecutive></CustomerExecutive_Data>",
          "<CustomerComment/>",
          userId ?? 0,
          _contactFirstNameController.text,
          _contactLastNameController.text,
          _emailIdController.text,
          _phoneNumberController.text,
          "Active",
          "Y",
          _contactAddressController.text,
          _selectedCity?.cityId ?? 0,
          _contactPinCodeController.text.isNotEmpty
              ? int.parse(_contactPinCodeController.text)
              : 0,
          _selectedSalutationId ?? 0,
          _selectedContactDesignationId ?? 0,
          position.latitude,
          position.longitude,
          widget.ranking,
          widget.boardId,
          widget.chainSchoolId,
          widget.endClassId,
          widget.startClassId,
          widget.medium,
          widget.samplingMonthId,
          widget.decisionMonthId,
          widget.purchaseMode,
          "",
          xmlClassName,
          _selectedDataSourceId ?? 0,
          bookseller1Id,
          bookseller2Id,
          widget.gst,
          widget.pan,
          _dobController.text,
          _anniversaryController.text,
          token);

      if (responseData.status == 'Success') {
        String s = responseData.s;
        if (kDebugMode) {
          print(s);
        }
        if (s.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerList(type: widget.type),
              ),
                  (route) => route.isFirst,
            );
          }
        } else {
          if (kDebugMode) {
            print('Add New ${widget.type} Error s empty');
          }
          _toastMessage.showToastMessage(
              "An error occurred while adding new ${widget.type}.");
        }
      } else {
        if (kDebugMode) {
          print('Add New Customer Error ${responseData.status}');
        }
        _toastMessage.showToastMessage(
            "An error occurred while adding new ${widget.type}.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Add New Customer Error $e');
      }
      _toastMessage.showToastMessage(
          "An error occurred while adding new ${widget.type}.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              (label == 'Contact Designation')) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey, {
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
            inputFormatters: getInputFormatters(label),
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
                  (label == 'Contact First Name' ||
                      label == 'Contact Last Name')) {
                return validateName(
                    label, value, mandatoryCustomerContactFirstLastName);
              } else if ((value == null || value.isEmpty) &&
                  (_contactAddressController.text.isNotEmpty &&
                      label == 'Pin Code')) {
                return 'Please enter $label';
              } else if (label == 'Mobile Number') {
                return validatePhoneNumber(
                    label, value, mandatorySettingEmailMobile);
              } else if (label == 'Email') {
                return validateEmail(label, value, mandatorySettingEmailMobile,
                    _phoneNumberController.text.isEmpty);
              } else if (label == 'Pin Code' &&
                  _contactAddressController.text.isNotEmpty &&
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

  Widget _buildDropdownFieldCity(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Geography>(
        key: fieldKey,
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
          if ((value == null || value.city.isEmpty) &&
              (_contactAddressController.text.isNotEmpty)) {
            return 'Please select $label';
          }
          return null;
        },
      ),
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
}
