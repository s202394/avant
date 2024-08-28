import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/new_customer/new_customer_school_form3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const NewCustomerSchoolForm2({super.key,
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
  });

  @override
  _NewCustomerSchoolForm2State createState() => _NewCustomerSchoolForm2State();
}

class _NewCustomerSchoolForm2State extends State<NewCustomerSchoolForm2> {
  late SharedPreferences prefs;
  late Future<CustomerEntryMasterResponse> futureData;

  late String token;

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

  @override
  void initState() {
    super.initState();
    futureData = initializePreferencesAndData();
  }

  Future<CustomerEntryMasterResponse> initializePreferencesAndData() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString('token') ?? '';
    });

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
    endClassController.dispose();
    startClassController.dispose();
    decisionMonthController.dispose();
    samplingMonthController.dispose();
    panController.dispose();
    gstController.dispose();
    mediumController.dispose();
    rankingController.dispose();
    super.dispose();
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
            Text(
              textAlign: TextAlign.center,
              widget.customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              textAlign: TextAlign.center,
              widget.address,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              textAlign: TextAlign.center,
              '${widget.cityName} - ${widget.pinCode}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, // Full width
              height: 1, // Height of the line
              color: Colors.grey, // Line color
            ),
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
            _buildTextField('PAN', panController, _panFieldKey, _panFocusNode),
            _buildTextField('GST', gstController, _gstFieldKey, _gstFocusNode),
            buildPurchaseModeField(data.purchaseModeList),
            const SizedBox(height: 16),
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

  Widget _buildDropdownRankingField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    List<String> rankingList,
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        value: _selectedRanking,
        focusNode: focusNode,
        items: rankingList
            .map((ranking) => DropdownMenuItem<String>(
                  value: ranking,
                  child: Text(ranking),
                ))
            .toList(),
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
          const Text('Purchase Mode:'),
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
      title: Text(label),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Classes>(
        key: fieldKey,
        value: isStartClass ? _selectedStartClass : _selectedEndClass,
        focusNode: focusNode,
        items: classesList
            .map((classes) => DropdownMenuItem<Classes>(
                  value: classes,
                  child: Text(classes.className),
                ))
            .toList(),
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
          border: const OutlineInputBorder(),
        ),
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
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Months>(
        key: fieldKey,
        value: (label == "Sampling Month")
            ? _selectedSamplingMonth
            : _selectedDecisionMonth,
        focusNode: focusNode,
        items: monthsList
            .map((month) => DropdownMenuItem<Months>(
                  value: month,
                  child: Text(month.name),
                ))
            .toList(),
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

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedPurchaseMode == null) {
        _toastMessage.showToastMessage("Please select Purchase Mode");
      } else {
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
            ),
          ),
        );
      }
    } else {
      // Focus on the first field with an error
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
  }
}
