import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/customer/new_customer_school_form3.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/utils.dart';
import '../model/fetch_customer_details_model.dart';
import '../model/geography_model.dart';
import '../model/login_model.dart';
import '../model/search_bookseller_response.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class NewCustomerSchoolForm2 extends StatefulWidget {
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
  final bool isEdit;
  final String validated;
  final FetchCustomerDetailsSchoolResponse? customerDetailsSchoolResponse;


  const NewCustomerSchoolForm2(
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
      required this.isEdit,
      required this.validated,
      this.customerDetailsSchoolResponse,});

  @override
  NewCustomerSchoolForm2State createState() => NewCustomerSchoolForm2State();
}

class NewCustomerSchoolForm2State extends State<NewCustomerSchoolForm2> {
  late SharedPreferences prefs;
  late Future<CustomerEntryMasterResponse> futureData;

  late String token;
  late int executiveId;
  bool _isLoading = true;
  bool _submitted = false;

  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  Classes? _selectedStartClass;
  Classes? _selectedEndClass;
  Months? _selectedSamplingMonth;
  Months? _selectedDecisionMonth;
  String? _selectedRanking;
  String? _selectedPurchaseMode;

  final TextEditingController endClassController = TextEditingController();
  final TextEditingController startClassController = TextEditingController();
  final TextEditingController samplingMonthController = TextEditingController();
  final TextEditingController decisionMonthController = TextEditingController();
  final TextEditingController mediumController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController rankingController = TextEditingController();

  //Bookseller bottom sheet controllers
  final TextEditingController _booksellerNameController =
      TextEditingController();
  final TextEditingController _booksellerCodeController =
      TextEditingController();
  final TextEditingController _booksellerCityController =
      TextEditingController();

  final FocusNode _cityFocusNode = FocusNode();

  final _cityFieldKey = GlobalKey<FormFieldState>();

  final _endClassFieldKey = GlobalKey<FormFieldState>();
  final _startClassFieldKey = GlobalKey<FormFieldState>();
  final _samplingMonthFieldKey = GlobalKey<FormFieldState>();
  final _decisionMonthFieldKey = GlobalKey<FormFieldState>();
  final _panFieldKey = GlobalKey<FormFieldState>();
  final _gstFieldKey = GlobalKey<FormFieldState>();
  final _mediumFieldKey = GlobalKey<FormFieldState>();
  final _rankingFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _endClassFocusNode = FocusNode();
  final FocusNode _startClassFocusNode = FocusNode();
  final FocusNode _samplingMonthFocusNode = FocusNode();
  final FocusNode _decisionMonthFocusNode = FocusNode();
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _gstFocusNode = FocusNode();
  final FocusNode _mediumFocusNode = FocusNode();
  final FocusNode _rankingFocusNode = FocusNode();

  DatabaseHelper dbHelper = DatabaseHelper();

  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;

  final List<BookSellers> _booksellers = [];

  bool hasCheckedForEdit = false;

  final List<BookSellers> _selectedBooksellers = [];

  late CustomerEntryMasterResponse customerEntryMasterResponse;

  @override
  void initState() {
    super.initState();

    initialize();
    futureData = initializePreferencesAndData();

    _loadGeographyData();
  }

  void initialize() async {
    prefs = await SharedPreferences.getInstance();
    executiveId = await getExecutiveId() ?? 0;
    setState(() {
      token = prefs.getString('token') ?? '';
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
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

  void _loadGeographyData() async {
    // Retrieve geography data from the database
    List<Geography> dbData = await dbHelper.getGeographyDataFromDB();
    if (dbData.isNotEmpty) {
      setState(() {
        _filteredCities = dbData;
        _isLoading = false;
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
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    endClassController.dispose();
    startClassController.dispose();
    decisionMonthController.dispose();
    samplingMonthController.dispose();
    panController.dispose();
    gstController.dispose();
    mediumController.dispose();
    rankingController.dispose();
    _booksellerNameController.dispose();
    _booksellerCodeController.dispose();
    _booksellerCityController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
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
            CustomText(
              textAlign: TextAlign.center,
              widget.customerName,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            CustomText(
              textAlign: TextAlign.center,
              widget.address,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            CustomText(
              textAlign: TextAlign.center,
              '${widget.cityName} - ${widget.pinCode}',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
            Container(width: double.infinity, height: 1, color: Colors.grey),
            const SizedBox(height: 10),
            _buildDropdownClassesField('Start Class', startClassController,
                _startClassFieldKey, data.classesList, _startClassFocusNode,
                isStartClass: true),
            _buildDropdownClassesField('End Class', endClassController,
                _endClassFieldKey, data.classesList, _endClassFocusNode,
                isStartClass: false),
            _buildDropdownMonthField(
                'Sampling Month',
                samplingMonthController,
                _samplingMonthFieldKey,
                data.monthsList,
                _samplingMonthFocusNode),
            _buildDropdownMonthField(
                'Decision Month',
                decisionMonthController,
                _decisionMonthFieldKey,
                data.monthsList,
                _decisionMonthFocusNode),
            _buildTextField(
                'Medium', mediumController, _mediumFieldKey, _mediumFocusNode),
            _buildDropdownRankingField('Ranking', rankingController,
                _rankingFieldKey, ['A', 'B', 'C'], _rankingFocusNode),
            _buildTextField(
                'PAN Number', panController, _panFieldKey, _panFocusNode),
            _buildTextField(
                'GST Number', gstController, _gstFieldKey, _gstFocusNode),
            buildPurchaseModeField(data.purchaseModeList),
            Visibility(
              visible: (_selectedPurchaseMode == 'Book Seller' ||
                  _selectedPurchaseMode == 'Bookseller'),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bookseller Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => {_showBooksellerSearchModal()},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const CustomText(
                          '+ Add Bookseller',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading) ...[
                    const CircularProgressIndicator(),
                  ] else if (_booksellers.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _booksellers.length,
                      itemBuilder: (context, index) {
                        final bookseller = _booksellers[index];
                        final isSelected =
                            _selectedBooksellers.contains(bookseller);

                        return GestureDetector(
                          onTap: () => _toggleSelection(bookseller),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  _toggleSelection(bookseller);
                                },
                              ),
                              title: Text(bookseller.bookSellerName),
                              subtitle: Text(
                                  "${bookseller.address}\n${bookseller.city}\n${bookseller.state}, ${bookseller.country}"),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Text('No booksellers found.'),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
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

  void _toggleSelection(BookSellers bookseller) {
    setState(() {
      if (_selectedBooksellers.contains(bookseller)) {
        _selectedBooksellers.remove(bookseller);
      } else {
        if (_selectedBooksellers.length < 2) {
          _selectedBooksellers.add(bookseller);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can select a maximum of 2 items."),
            ),
          );
        }
      }
    });
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
            if (label == 'PAN Number' || label == 'GST Number') {
              if (value == null || value.isEmpty) {
                return null;
              }
              if (label == 'PAN Number' && value.length < 10) {
                return 'Please enter valid $label';
              }
              if (label == 'GST Number' && value.length < 15) {
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
            if (label == 'Email Id' && !Validator.isValidEmail(value)) {
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
          textCapitalization: (label == 'PAN Number' || label == 'GST Number')
              ? TextCapitalization.characters
              : TextCapitalization.none,
          inputFormatters: getInputFormatters(label),
        ),
      ),
    );
  }

  Widget _buildDropdownRankingField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<String> rankingList,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        style: TextStyle(fontSize: textFontSize),
        value: _selectedRanking,
        focusNode: focusNode,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: CustomText('Select'),
          ),
          ...rankingList.map(
            (ranking) => DropdownMenuItem<String>(
              value: ranking,
              child: CustomText(ranking, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedRanking = value;

            // Update the text controller with the selected category name
            controller.text = value ?? '';

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
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildPurchaseModeField(List<PurchaseMode> purchaseModeList) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText('Purchase Mode:'),
          Column(
            children: purchaseModeList.map((mode) {
              return buildRadioOption(mode.modeName, mode.modeValue);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: CustomText(label),
      value: value,
      groupValue: _selectedPurchaseMode,
      onChanged: (newValue) {
        setState(() {
          _selectedPurchaseMode = newValue;
        });
      },
    );
  }

  Widget _buildDropdownClassesField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<Classes> classesList,
    FocusNode focusNode, {
    required bool isStartClass,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Classes>(
        key: fieldKey,
        value: isStartClass ? _selectedStartClass : _selectedEndClass,
        focusNode: focusNode,
        style: TextStyle(fontSize: textFontSize),
        items: [
          const DropdownMenuItem<Classes>(
            value: null,
            child: CustomText('Select'),
          ),
          ...classesList.map(
            (classes) => DropdownMenuItem<Classes>(
              value: classes,
              child: CustomText(classes.className, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (Classes? value) {
          setState(() {
            if (isStartClass) {
              _selectedStartClass = value;
              startClassController.text = value?.className ?? '';
              _validateEndClass();
            } else {
              _selectedEndClass = value;
              endClassController.text = value?.className ?? '';
            }
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: labelFontSize),
            border: const OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.className.isEmpty) {
            return 'Please select $label';
          }
          if (!isStartClass &&
              _selectedStartClass != null &&
              _selectedEndClass != null) {
            if (_selectedEndClass!.classNumId <
                _selectedStartClass!.classNumId) {
              return 'End Class must be greater than or equal to Start Class';
            }
          }
          return null;
        },
      ),
    );
  }

  void _validateEndClass() {
    // Trigger validation for end class if start class is selected
    if (_selectedStartClass != null) {
      _endClassFieldKey.currentState?.validate();
    }
  }

  Widget _buildDropdownMonthField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<Months> monthsList,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Months>(
        key: fieldKey,
        value: (label == "Sampling Month")
            ? _selectedSamplingMonth
            : _selectedDecisionMonth,
        focusNode: focusNode,
        style: TextStyle(fontSize: textFontSize),
        items: [
          const DropdownMenuItem<Months>(
            value: null,
            child: CustomText('Select'),
          ),
          ...monthsList.map(
            (month) => DropdownMenuItem<Months>(
              value: month,
              child: CustomText(month.name, fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (Months? value) {
          setState(() {
            if (label == "Sampling Month") {
              _selectedSamplingMonth = value;
            } else {
              _selectedDecisionMonth = value;
            }

            // Update the text controller with the selected category name
            controller.text = value?.name ?? '';

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
          if (value == null || value.name.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _handlePurchaseMode();
    } else {
      _focusOnErrorField();
    }
  }

  void _handlePurchaseMode() {
    if (_selectedPurchaseMode == null) {
      _toastMessage.showToastMessage("Please select Purchase Mode");
    } else if ((_selectedPurchaseMode == 'Book Seller' ||
            _selectedPurchaseMode == 'Bookseller') &&
        _selectedBooksellers.isEmpty) {
      if (_booksellers.isEmpty) {
        _showBooksellerSearchModal();
      } else {
        _toastMessage.showInfoToastMessage("Please select bookseller");
      }
    } else {
      nextPage();
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  void _showBooksellerSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CustomText(
                    'Search Bookseller',
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  buildTextField('Name', _booksellerNameController, _submitted),
                  buildTextField('Code', _booksellerCodeController, _submitted),
                  _buildDropdownFieldCity('City', _booksellerCityController,
                      _cityFieldKey, _cityFocusNode),
                  const SizedBox(height: 20),
                  _buildSearchButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          setState(() {
            _submitted = true;
          });
          // if (_formKey.currentState!.validate()) {
          searchBookseller();
          // }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Text(
          'Search',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _focusOnErrorField() {
    List<FocusNode> focusNodes = [
      _startClassFocusNode,
      _endClassFocusNode,
      _samplingMonthFocusNode,
      _decisionMonthFocusNode,
      _mediumFocusNode,
      _rankingFocusNode,
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

  Widget buildTextField(
    String label,
    TextEditingController controller,
    bool submitted, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: TextStyle(fontSize: textFontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          /*errorText: label == 'Code' && submitted && controller.text.isEmpty
              ? 'Please enter $label'
              : null,*/
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          alignLabelWithHint: true,
        ),
        controller: controller,
        onChanged: (text) {
          if (_submitted && text.isNotEmpty) {
            setState(() {});
          }
        },
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
        validator: (value) {
          if (value == null || value.city.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  void searchBookseller() async {
    if (!await _checkInternetConnection()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await BooksellerService().fetchBooksellerData(
        _selectedCity?.cityId ?? 0,
        _booksellerCodeController.text,
        _booksellerNameController.text,
        token,
      );

      setState(() {
        _isLoading = false;
        // If the response contains booksellers, append them to the existing list
        if (response.bookSellers != null) {
          for (var newBookseller in response.bookSellers!) {
            if (!_booksellers.any((existingBookseller) =>
                existingBookseller.action == newBookseller.action &&
                existingBookseller.bookSellerName ==
                    newBookseller.bookSellerName)) {
              _booksellers.add(newBookseller);
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _toastMessage.showToastMessage('Error fetching booksellers: $e');
    }
  }

  void nextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewCustomerSchoolForm3(
            type: widget.type,
            customerName: widget.customerName,
            address: widget.address,
            cityId: widget.cityId,
            cityName: widget.cityName,
            pinCode: widget.pinCode,
            phoneNumber: widget.phoneNumber,
            emailId: widget.emailId,
            boardId: widget.boardId,
            chainSchoolId: widget.chainSchoolId,
            keyCustomer: widget.keyCustomer,
            customerStatus: widget.customerStatus,
            startClassId: _selectedStartClass?.classNumId ?? 0,
            endClassId: _selectedEndClass?.classNumId ?? 0,
            samplingMonthId: _selectedSamplingMonth?.id ?? 0,
            decisionMonthId: _selectedDecisionMonth?.id ?? 0,
            medium: mediumController.text,
            ranking: _selectedRanking ?? '',
            pan: panController.text,
            gst: gstController.text,
            purchaseMode: _selectedPurchaseMode ?? '',
            bookseller: _selectedBooksellers,
            isEdit: widget.isEdit,
            validated: widget.validated,
            customerDetailsSchoolResponse:
                widget.customerDetailsSchoolResponse,
        ),
      ),
    );
  }

  void checkForEdit() {
    final customerData = widget.customerDetailsSchoolResponse;

    _booksellers.addAll(customerData?.bookSellerList ?? []);
    _selectedBooksellers.addAll(customerData?.bookSellerList ?? []);

    if (customerData != null && customerData.schoolDetails != null) {
      final schoolDetails = customerData.schoolDetails;
      // Set controller values

      final startClasses = customerEntryMasterResponse.classesList.firstWhere(
        (b) => b.classNumId == schoolDetails?.startClassId,
        orElse: () {
          debugPrint(
              'Edit Start Class ID ${schoolDetails?.startClassId} not found.');
          return Classes(classNumId: 0, className: '');
        },
      );
      if (startClasses.classNumId == 0) {
        debugPrint('Edit startClasses class 0');
      } else {
        debugPrint('startClasses.className ${startClasses.className}');
        setState(() {
          _selectedStartClass = startClasses;
          startClassController.text = startClasses.className;
        });
      }

      final endClasses = customerEntryMasterResponse.classesList.firstWhere(
        (b) => b.classNumId == schoolDetails?.endClassId,
        orElse: () {
          debugPrint(
              'Edit End Class ID ${schoolDetails?.endClassId} not found.');
          return Classes(classNumId: 0, className: '');
        },
      );
      if (endClasses.classNumId == 0) {
        debugPrint('Edit endClasses class 0');
      } else {
        debugPrint('endClasses.className ${endClasses.className}');
        setState(() {
          _selectedEndClass = endClasses;
          endClassController.text = endClasses.className;
        });
      }

      final samplingMonth = customerEntryMasterResponse.monthsList.firstWhere(
        (b) => b.id == schoolDetails?.samplingMonth,
        orElse: () {
          debugPrint(
              'Edit Sampling Month ID ${schoolDetails?.samplingMonth} not found.');
          return Months(id: 0, name: '');
        },
      );
      if (samplingMonth.id > 0) {
        debugPrint('samplingMonth ${samplingMonth.name}');
        setState(() {
          _selectedSamplingMonth = samplingMonth;
          samplingMonthController.text = samplingMonth.name;
        });
      } else {
        debugPrint('Edit samplingMonth 0');
      }

      final decisionMonth = customerEntryMasterResponse.monthsList.firstWhere(
        (b) => b.id == schoolDetails?.decisionMonth,
        orElse: () {
          debugPrint(
              'Edit Decision Month ID ${schoolDetails?.decisionMonth} not found.');
          return Months(id: 0, name: '');
        },
      );
      if (decisionMonth.id > 0) {
        debugPrint('decisionMonth ${decisionMonth.name}');
        setState(() {
          _selectedDecisionMonth = decisionMonth;
          decisionMonthController.text = decisionMonth.name;
        });
      } else {
        debugPrint('Edit decisionMonth 0');
      }

      String mode = schoolDetails?.purchaseMode ?? '';
      if (mode.isNotEmpty && schoolDetails?.purchaseMode == 'Bookseller') {
        mode = 'Book Seller';
      }
      final purchaseMode =
          customerEntryMasterResponse.purchaseModeList.firstWhere(
        (b) => b.modeValue == mode,
        orElse: () {
          debugPrint(
              'Edit Purchase Mode ID ${schoolDetails?.purchaseMode} not found.');
          return PurchaseMode(modeName: '', modeValue: '');
        },
      );
      if (purchaseMode.modeName.isNotEmpty) {
        debugPrint('purchaseMode ${purchaseMode.modeValue}');
        setState(() {
          _selectedPurchaseMode = purchaseMode.modeValue;
        });
      } else {
        debugPrint('Edit purchaseMode 0');
      }

      final ranking = ["A", "B", "C"].firstWhere(
        (b) => b == schoolDetails?.ranking,
        orElse: () {
          debugPrint('Edit Ranking ${schoolDetails?.ranking} not found.');
          return '';
        },
      );
      if (ranking.isNotEmpty) {
        debugPrint('ranking $ranking');
        setState(() {
          _selectedRanking = ranking;
          rankingController.text = schoolDetails?.ranking ?? '';
        });
      } else {
        debugPrint('Edit ranking not available');
      }

      mediumController.text = schoolDetails?.mediumInstruction ?? '';
      panController.text = schoolDetails?.panNumber ?? '';
      gstController.text = schoolDetails?.gstNumber ?? '';

      // Initialize Bookseller list (if needed)
      if (_selectedPurchaseMode == 'Book Seller' ||
          _selectedPurchaseMode == 'Bookseller') {
        //_booksellers = schoolDetails.bookSeller1 ?? [];
      }
    }
  }
}
