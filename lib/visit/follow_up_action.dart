import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/views/rich_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/followup_action_model.dart';
import '../service/location_service.dart';
import '../views/custom_text.dart';
import 'cart.dart';

class FollowUpAction extends StatefulWidget {
  final GetVisitDsrResponse visitDsrData;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;
  final String visitFeedback;
  final String visitDate;
  final int visitPurposeId;
  final String jointVisitWithIds;
  final int personMetId;
  final bool samplingDone;
  final bool followUpAction;
  final String fileName;

  const FollowUpAction({
    super.key,
    required this.visitDsrData,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    required this.city,
    required this.state,
    required this.visitFeedback,
    required this.visitDate,
    required this.visitPurposeId,
    required this.jointVisitWithIds,
    required this.personMetId,
    required this.samplingDone,
    required this.followUpAction,
    required this.fileName,
  });

  @override
  FollowUpActionState createState() => FollowUpActionState();
}

class FollowUpActionState extends State<FollowUpAction> {
  String? selectedDepartment;
  int? selectedDepartmentId;
  String? selectedExecutive;
  int? selectedExecutiveId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? executiveId;
  int? userId;
  String? profileCode;
  String? upHierarchy;
  String? downHierarchy;
  String? token;

  ToastMessage toastMessage = ToastMessage();
  LocationService locationService = LocationService();
  DatabaseHelper databaseHelper = DatabaseHelper();

  List<Executive> executivesList = [];

  bool _submitted = false;
  bool isFetchingExecutive = false;
  String? errorMessage;

  late Position position;
  late String address;
  late String? executiveName;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _visitFollowUpActionController =
      TextEditingController();

  final _dateFieldKey = GlobalKey<FormFieldState>();
  final _visitFeedbackFieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    initData();
    getAddressData();
  }

  void initData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    executiveId = await getExecutiveId();
    userId = await getUserId();
    profileCode = await getProfileCode();
    executiveName = await getExecutiveName();
    upHierarchy = prefs.getString('UpHierarchy') ?? '';
    downHierarchy = prefs.getString('DownHierarchy') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText('DSR Entry'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomText(
                        widget.customerName,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      RichTextWidget(
                        label: widget.address,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 16),
                      buildDropdownField(
                        'Department',
                        selectedDepartment,
                        {
                          for (var item in widget.visitDsrData.departmentList)
                            item.executiveDepartmentName: item.id
                        },
                        (value) async {
                          setState(() {
                            selectedDepartment = value;
                            selectedDepartmentId = value != null
                                ? {
                                    for (var item
                                        in widget.visitDsrData.departmentList)
                                      item.executiveDepartmentName: item.id
                                  }[value]
                                : null;
                          });

                          if (selectedDepartmentId != null) {
                            selectedExecutive = value;
                            selectedExecutiveId = null;
                            executivesList.clear();
                            _fetchExecutivesData();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      buildDropdownField(
                        'Executive',
                        selectedExecutive,
                        {
                          for (var item in executivesList)
                            item.executiveName: item.executiveId
                        },
                        (value) {
                          setState(() {
                            selectedExecutive = value;
                            selectedExecutiveId = value != null
                                ? {
                                    for (var item in executivesList)
                                      item.executiveName: item.executiveId
                                  }[value]
                                : null;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                          'Action Date', _dateController, _dateFieldKey),
                      _buildTextField(
                          'Follow Up Action',
                          _visitFollowUpActionController,
                          _visitFeedbackFieldKey,
                          maxLines: 3),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _submitted = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          _updateCartItem();
                        }
                      },
                      child: Container(
                        color: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: const Center(
                            child: CustomText('Add More', color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _submitted = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          _updateCartItem();
                          goToCart();
                        }
                      },
                      child: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: const Center(
                            child: CustomText('Add', color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchExecutivesData() async {
    if (selectedDepartmentId == null) {
      return; // No need to fetch if no department is selected
    }

    setState(() {
      isFetchingExecutive = true;
    });

    try {
      final response =
          await FollowupActionExecutiveService().getFollowupActionExecutives(
        selectedDepartmentId ?? 0,
        token ?? '',
      );

      setState(() {
        executivesList.clear();
        executivesList = response.executiveList;
      });

      setState(() {
        selectedExecutive = null;
        selectedExecutiveId = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isFetchingExecutive = false;
      });
    }
  }

  void getAddressData() async {
    position = await locationService.getCurrentLocation();
    if (kDebugMode) {
      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    }

    address = await locationService.getAddressFromLocation();
    if (kDebugMode) {
      print("address: $address");
    }
  }

  Widget buildDropdownField(
    String label,
    String? selectedValue,
    Map<String, int> items,
    ValueChanged<String?>? onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.keys
          .map(
            (key) => DropdownMenuItem<String>(
              value: key,
              child: CustomText(
                key,
                color: Colors.black,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14.0),
        border: const OutlineInputBorder(),
        errorText: _submitted && selectedValue == null
            ? 'Please select a $label'
            : null,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey, {
    int maxLines = 1,
  }) {
    bool isDateField = label == "Action Date";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isDateField
            ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
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
            style: const TextStyle(fontSize: 14),
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 14.0),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? const Icon(Icons.calendar_month) : null,
            ),
            textAlign: TextAlign.start,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
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

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  Future<void> _updateCartItem() async {
    await databaseHelper.insertFollowUpActionCart({
      'FollowUpAction': _visitFollowUpActionController.text,
      'FollowUpDate': _dateController.text,
      'DepartmentId': selectedDepartmentId,
      'Department': selectedDepartment,
      'FollowUpExecutiveId': selectedExecutiveId,
      'FollowUpExecutive': selectedExecutive,
    });
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          type: 'Visit',
          title: 'DSR Entry',
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerCode: widget.customerCode,
          customerType: widget.customerType,
          address: widget.address,
          city: widget.city,
          state: widget.state,
          visitFeedback: widget.visitFeedback,
          visitDate: widget.visitDate,
          visitPurposeId: widget.visitPurposeId,
          jointVisitWithIds: widget.jointVisitWithIds,
          personMetId: widget.personMetId,
          samplingDone: widget.samplingDone,
          followUpAction: widget.followUpAction,
          fileName: widget.fileName,
        ),
      ),
    );
  }
}
