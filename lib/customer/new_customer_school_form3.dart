import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/fetch_customer_details_model.dart';
import '../model/search_bookseller_response.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import 'customer_list.dart';
import 'new_customer_school_form4.dart';

class NewCustomerSchoolForm3 extends StatefulWidget {
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

  final bool isEdit;
  final String validated;
  final FetchCustomerDetailsSchoolResponse? customerDetailsSchoolResponse;

  const NewCustomerSchoolForm3({
    super.key,
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
    required this.isEdit,
    required this.validated,
    this.customerDetailsSchoolResponse,
  });

  @override
  NewCustomerSchoolForm3State createState() => NewCustomerSchoolForm3State();
}

class NewCustomerSchoolForm3State extends State<NewCustomerSchoolForm3> {
  late Future<CustomerEntryMasterResponse> futureData;
  final _formKey = GlobalKey<FormState>();

  final ToastMessage _toastMessage = ToastMessage();

  DatabaseHelper dbHelper = DatabaseHelper();
  LocationService locationService = LocationService();

  int? executiveId;
  int? userId;

  late SharedPreferences prefs;
  late String token;

  bool _isLoading = false;

  final Map<int, TextEditingController> _gridControllers = {};
  final Map<int, String> _classValues = {};

  bool hasCheckedForEdit = false;

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
    for (var controller in _gridControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fetchCityAccess() async {
    executiveId = await getExecutiveId();

    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    userId = await getUserId();
    futureData = initializePreferencesAndData();
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
                Container(
                    width: double.infinity, height: 1, color: Colors.grey),
                const SizedBox(height: 10),
                const CustomText(
                  textAlign: TextAlign.center,
                  'Enrolment',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                  ),
                  itemCount: data.classesList.length,
                  itemBuilder: (context, index) {
                    final classItem = data.classesList[index];
                    final isEnabled = _isClassInRange(classItem);

                    // Initialize or reuse the controller
                    if (!_gridControllers.containsKey(classItem.classNumId)) {
                      _gridControllers[classItem.classNumId] =
                          TextEditingController(
                        text: isEnabled
                            ? _classValues[classItem.classNumId] ?? ''
                            : '0',
                      );
                    }

                    final controller = _gridControllers[classItem.classNumId]!;

                    return Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 40,
                          child: Center(
                            child: CustomText(
                              textAlign: TextAlign.center,
                              classItem.classNumId >= 0
                                  ? 'Class ${classItem.className}'
                                  : classItem.className,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5.0),
                              child: TextField(
                                controller: controller,
                                enabled: isEnabled,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isEnabled ? Colors.black : Colors.grey,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  counterText: "",
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: isEnabled
                                      ? Colors.white
                                      : Colors.grey[200],
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _classValues[classItem.classNumId] = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      if (kDebugMode) {
                        print("Add ${widget.type} data API");
                      }
                      if (widget.isEdit) {
                        _updateForm(data.classesList);
                      } else {
                        nextPage(data.classesList);
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16),
                      child: Text(
                        widget.isEdit
                            ? 'Update ${widget.type}'
                            : 'Add ${widget.type}',
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

  bool _isClassInRange(Classes classItem) {
    if (widget.startClassId == 0 || widget.endClassId == 0) {
      return false;
    }
    return classItem.classNumId >= widget.startClassId &&
        classItem.classNumId <= widget.endClassId;
  }

  void _updateForm(List<Classes> classesList) async {
    FocusScope.of(context).unfocus();

    if (!isAllClassQuantityEntered(classesList)) {
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

      String xmlClassName = _generateXmlFromClassValues(classesList);
      if (kDebugMode) {
        print(xmlClassName);
        print('bookseller1Id:$bookseller1Id');
        print('bookseller2Id:$bookseller2Id');
      }
      final responseData = await UpdateCustomerService().updateCustomerSchool(
          widget.customerDetailsSchoolResponse?.schoolDetails?.schoolId ?? 0,
          widget.type,
          widget.customerName,
          widget.customerDetailsSchoolResponse?.schoolDetails?.refCode ?? '',
          widget.emailId,
          widget.phoneNumber,
          widget.address,
          widget.cityId,
          int.parse(widget.pinCode),
          widget.keyCustomer,
          widget.customerStatus,
          "",
          "<CustomerExecutive_Data><CustomerExecutive><AccountTableExecutiveId>${widget.customerDetailsSchoolResponse?.schoolDetails?.xmlAccountTableExecutiveId ?? 0}</AccountTableExecutiveId></CustomerExecutive></CustomerExecutive_Data>",
          "<CustomerComment/>",
          userId ?? 0,
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
          xmlClassName,
          bookseller1Id,
          bookseller2Id,
          widget.gst,
          widget.pan,
          widget.validated,
          token);

      if (responseData.status == 'Success') {
        String s = responseData.s;
        String w = responseData.w;
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
        } else if (w.isNotEmpty) {
          _toastMessage.showWarnToastMessage(w);
        } else {
          if (kDebugMode) {
            print('Update ${widget.type} Error s empty');
          }
          _toastMessage.showToastMessage(
              "An error occurred while update new ${widget.type}.");
        }
      } else {
        if (kDebugMode) {
          print('Update Customer Error ${responseData.status}');
        }
        _toastMessage.showToastMessage(
            "An error occurred while updating ${widget.type}.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update Customer Error $e');
      }
      _toastMessage
          .showToastMessage("An error occurred while updating ${widget.type}.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generateXmlFromClassValues(List<Classes> classesList) {
    StringBuffer xmlBuffer = StringBuffer();
    xmlBuffer.write("<row_ClassName>");

    // Iterate over the classesList
    for (var classItem in classesList) {
      int classId = classItem.classNumId;

      // Get the quantity from _classValues or default to '0'
      String qty =
          _classValues.containsKey(classId) ? _classValues[classId]! : '0';

      xmlBuffer.write("<ClassName>");
      xmlBuffer.write("<ClassId>$classId</ClassId>");
      xmlBuffer.write("<Enrolment>${qty.isEmpty ? '0' : qty}</Enrolment>");
      xmlBuffer.write("</ClassName>");
    }

    xmlBuffer.write("</row_ClassName>");
    return xmlBuffer.toString();
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  void checkForEdit() {
    final customerData = widget.customerDetailsSchoolResponse;

    if (customerData != null) {
      for (final enrolment in customerData.enrolmentList) {
        _classValues[enrolment.classNumId] = enrolment.enrolValue.toString();

        // Update the controller if it already exists
        if (_gridControllers.containsKey(enrolment.classNumId)) {
          _gridControllers[enrolment.classNumId]!.text =
              enrolment.enrolValue.toString();
        } else {
          // Initialize a new controller if not present
          _gridControllers[enrolment.classNumId] = TextEditingController(
            text: enrolment.enrolValue.toString(),
          );
        }
      }
      setState(() {}); // Trigger a UI rebuild
    }
  }

  bool isAllClassQuantityEntered(List<Classes> classesList) {
    bool isAllClassQuantityEntered = true;

    for (var classItem in classesList) {
      int classId = classItem.classNumId;

      // Get the quantity from _classValues or default to '0'
      String qty =
          _classValues.containsKey(classId) ? _classValues[classId]! : '';

      // Check only if the field is enabled for the class
      if (_isClassInRange(classItem) && qty.isEmpty) {
        isAllClassQuantityEntered = false;
        _toastMessage.showToastMessage(
            'Please enter quantity for Class ${classItem.className}');
        break;
      }
    }
    return isAllClassQuantityEntered;
  }

  void nextPage(List<Classes> classesList) async {
    FocusScope.of(context).unfocus();

    if (!isAllClassQuantityEntered(classesList)) {
      return;
    }

    if (!await _checkInternetConnection()) return;

    if (!mounted) {
      return;
    }

    String xmlClassName = _generateXmlFromClassValues(classesList);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewCustomerSchoolForm4(
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
          startClassId: widget.startClassId,
          endClassId: widget.endClassId,
          samplingMonthId: widget.samplingMonthId,
          decisionMonthId: widget.decisionMonthId,
          medium: widget.medium,
          ranking: widget.ranking,
          pan: widget.pan,
          gst: widget.gst,
          purchaseMode: widget.purchaseMode,
          bookseller: widget.bookseller,
          xmlClassName: xmlClassName,
          validated: widget.validated,
        ),
      ),
    );
  }
}
