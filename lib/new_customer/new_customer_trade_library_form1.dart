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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewCustomerTradeLibraryForm1 extends StatefulWidget {
  final String type;

  const NewCustomerTradeLibraryForm1({super.key, required this.type});

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

  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;
  CustomerCategory? _selectedCustomerCategory;
  bool? _selectedKeyCustomer;
  bool? _selectedCustomerStatus;

  late SharedPreferences prefs;
  late String token;
  late int executiveId;

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
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      executiveId = prefs.getInt('executiveId') ?? 0;
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
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
          .fetchGeographyData(_cityAccess, executiveId, token);
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

  late GoogleMapController mapController;
  final LatLng _center = const LatLng(28.7041, 77.1025);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<CustomerEntryMasterResponse> initializePreferencesAndData() async {
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
        if (kDebugMode) {
          print("Error fetching CustomerEntryMaster data from API: $e");
        }
        rethrow;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Customer - ${widget.type}'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<CustomerEntryMasterResponse>(
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

  Widget _buildTextField(String label, TextEditingController controller,
      GlobalKey<FormFieldState> fieldKey, FocusNode focusNode,
      {bool enabled = true, int maxLines = 1}) {
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
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true),
          enabled: enabled,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'Pin Code' && value.length < 6) {
              return 'Please enter valid $label';
            }
            if (label == 'Phone Number' && !Validator.isValidMobile(value)) {
              return 'Please enter valid $label';
            }
            if (label == 'Email Id' && !Validator.isValidEmail(value)) {
              return 'Please enter valid $label';
            }
            if (label == 'PAN' && value.length < 10) {
              return 'Please enter valid $label';
            }
            if (label == 'GST' && value.length < 15) {
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

  Widget _buildDropdownFieldCity(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Geography>(
        key: fieldKey,
        value: _selectedCity,
        focusNode: focusNode,
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
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<CustomerCategory>(
        key: fieldKey,
        value: _selectedCustomerCategory,
        focusNode: focusNode,
        items: customerCategoryList
            .map((customerCategory) => DropdownMenuItem<CustomerCategory>(
                  value: customerCategory,
                  child: Text(customerCategory.customerCategoryName),
                ))
            .toList(),
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
}
