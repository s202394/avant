import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/common/toast.dart';

class NewCustomerTradeLibraryForm2 extends StatefulWidget {
  final String type;
  final String customerName;
  final String address;
  final int cityId;
  final String pinCode;
  final String phoneNumber;
  final String emailId;
  final int customerCategoryId;
  final String pan;
  final String gst;
  final String keyCustomer;
  final String customerStatus;

  NewCustomerTradeLibraryForm2({
    required this.type,
    required this.customerName,
    required this.address,
    required this.cityId,
    required this.pinCode,
    required this.phoneNumber,
    required this.emailId,
    required this.customerCategoryId,
    required this.pan,
    required this.gst,
    required this.keyCustomer,
    required this.customerStatus,
  });

  @override
  _NewCustomerTradeLibraryForm2State createState() =>
      _NewCustomerTradeLibraryForm2State();
}

class _NewCustomerTradeLibraryForm2State
    extends State<NewCustomerTradeLibraryForm2> {
  final _formKey = GlobalKey<FormState>();
  late Future<CustomerEntryMasterResponse> futureData;

  DateFormat dateFormat = DateFormat('dd MMM yyyy');

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

  final ToastMessage _toastMessage = ToastMessage();

  int? executiveId;
  int? userId;

  String? _selectedContactDesignation;
  int? _selectedContactDesignationId;
  String? _selectedSalutation;
  int? _selectedSalutationId;
  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;

  late SharedPreferences prefs;
  late String token;

  bool _isLoading = false;

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

  void _fetchCityAccess() async {
    executiveId = await getExecutiveId();

    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
    _fetchGeographyData();
    futureData = initializePreferencesAndData();

    // final response = CustomerEntryMasterResponse.fromJson(jsonData);
    // await DatabaseHelper().insertCustomerEntryMasterResponse(response);
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
      print(e);
    }
  }

  Future<CustomerEntryMasterResponse> initializePreferencesAndData() async {
    // Create an instance of DatabaseHelper
    DatabaseHelper dbHelper = DatabaseHelper();

    // Check if data exists in the database
    CustomerEntryMasterResponse? existingData =
        await dbHelper.getCustomerEntryMasterResponse();

    if (existingData != null && !isEmptyData(existingData)) {
      // Data exists in the database, return it
      print(
          "CustomerEntryMaster data found in db: ${existingData.salutationMasterList}");
      return existingData;
    } else {
      String downHierarchy = prefs.getString('DownHierarchy') ?? '';

      // Data does not exist in the database, fetch from API
      print("CustomerEntryMaster data not found in db. Fetching from API...");

      try {
        CustomerEntryMasterResponse response =
            await CustomerEntryMasterService()
                .fetchCustomerEntryMaster(downHierarchy, token);
        print(
            "CustomerEntryMaster data fetched from API and saved to db. $response");
        // Save the fetched data to the database
        await dbHelper.insertCustomerEntryMasterResponse(response);

        print(
            "CustomerEntryMaster data fetched from API and saved to db. $response");
        return response;
      } catch (e) {
        // Handle API fetch error
        print("Error fetching CustomerEntryMaster data from API: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Customer - ${widget.type}'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<CustomerEntryMasterResponse>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return buildForm(snapshot.data!);
          } else {
            return Center(child: Text('No data found'));
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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Contact First Name',
                    _contactFirstNameController, _contactFirstNameFieldKey),
                _buildTextField('Contact Last Name', _contactLastNameController,
                    _contactLastNameFieldKey),
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
                _buildTextField('Email', _emailIdController, _emailIdFieldKey),
                _buildTextField('Date of Birth', _dobController, _dobFieldKey),
                _buildTextField('Anniversary', _anniversaryController,
                    _anniversaryFieldKey),
                _buildTextField('Address', _contactAddressController,
                    _contactAddressFieldKey,
                    maxLines: 5),
                _buildDropdownFieldCity(
                    'City', _contactCityController, _contactCityFieldKey),
                _buildTextField('Pin Code', _contactPinCodeController,
                    _contactPinCodeFieldKey),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      print("Add ${widget.type} data API");
                      _submitForm();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.blue,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                      child: Text(
                        'Add ${widget.type}',
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
        ),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!await _checkInternetConnection()) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final responseData = await CreateNewCustomerService().createNewCustomer(
          widget.type,
          widget.customerName,
          "",
          widget.emailId,
          widget.phoneNumber,
          widget.address,
          widget.cityId,
          int.parse(widget.pinCode),
          widget.keyCustomer,
          widget.customerStatus,
          "<CustomerCategory_Data><CustomerCategory><CustomerCategoryId>${widget.customerCategoryId}</CustomerCategoryId></CustomerCategory></CustomerCategory_Data>",
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
          int.parse(_contactPinCodeController.text),
          _selectedSalutationId ?? 0,
          _selectedContactDesignationId ?? 0,
          "28.535517",
          "77.391029",
          token ?? "");

      if (responseData.status == 'Success') {
        String s = responseData.s;
        if (s.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          print('Add New Customer Error s empty');
          _toastMessage
              .showToastMessage("An error occurred while adding new customer.");
        }
      } else {
        print('Add New Customer Error ${responseData.status}');
        _toastMessage
            .showToastMessage("An error occurred while adding new customer.");
      }
    } catch (e) {
      print('Add New Customer Error $e');
      _toastMessage
          .showToastMessage("An error occurred while adding new customer.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required GlobalKey<FormFieldState> fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          onChanged(newValue);
          fieldKey.currentState?.validate();
        },
        validator: (newValue) {
          if (newValue == null || newValue.isEmpty) {
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
  }) {
    bool isDateField = label == "Date of Birth" || label == "Anniversary";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isDateField
            ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
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
            controller: controller,
            keyboardType: (label == 'Mobile' || label == 'Pin Code')
                ? TextInputType.phone
                : TextInputType.text,
            inputFormatters: _getInputFormatters(label),
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? Icon(Icons.calendar_month) : null,
            ),
            textAlign: TextAlign.start,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == 'Mobile' && !Validator.isValidMobile(value)) {
                return 'Please enter valid $label';
              }
              if (label == 'Email' && !Validator.isValidEmail(value)) {
                return 'Please enter valid $label';
              }
              if (label == 'Pin Code' && value.length < 6) {
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

  List<TextInputFormatter> _getInputFormatters(String label) {
    if (label == 'Mobile') {
      return [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.digitsOnly,
      ];
    } else if (label == 'Pin Code') {
      return [
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter.digitsOnly,
      ];
    } else if (label == 'Email') {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
      ];
    } else if (label == 'PAN') {
      return [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.allow(
            RegExp(r'^[A-Z]{0,5}[0-9]{0,4}[A-Z]?$')),
      ];
    } else if (label == 'GST') {
      return [
        FilteringTextInputFormatter.allow(RegExp(
            r'^[0-9]{0,2}[A-Z]{0,5}[0-9]{0,4}[A-Z]{0,1}[1-9A-Z]{0,1}Z?[0-9A-Z]{0,1}$')),
      ];
    } else {
      return [];
    }
  }

  Widget _buildDropdownFieldCity(String label, TextEditingController controller,
      GlobalKey<FormFieldState> fieldKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Geography>(
        key: fieldKey,
        value: _selectedCity,
        items: _filteredCities
            .map(
              (geography) => DropdownMenuItem<Geography>(
                value: geography,
                child: Text(geography.city),
              ),
            )
            .toList(),
        onChanged: (Geography? value) {
          setState(() {
            _selectedCity = value;

            // Update the text controller with the selected city name
            controller.text = value?.city ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
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

  void _showErrorMessage(String message) {
    _toastMessage.showToastMessage(message);
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
