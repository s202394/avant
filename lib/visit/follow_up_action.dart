import 'package:avant/api/api_service.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/views/rich_text.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/followup_action_model.dart';
import '../service/location_service.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import 'cart.dart';

class FollowUpAction extends StatefulWidget {
  final GetVisitDsrResponse visitDsrData;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
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
      appBar: const CommonAppBar(title: 'DSR Entry'),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(widget.customerName,
                    fontWeight: FontWeight.bold, fontSize: 16),
                RichTextWidget(label: widget.address, fontSize: 14),
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
                _buildTextField('Action Date', _dateController, _dateFieldKey),
                _buildTextField('Follow Up Action',
                    _visitFollowUpActionController, _visitFeedbackFieldKey,
                    maxLines: 3),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => addMoreFollowUp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                child: const CustomText('Add More',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => addFollowUp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                child: const CustomText('Add',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ],
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

  Widget buildDropdownField(
    String label,
    String? selectedValue,
    Map<String, int> items,
    ValueChanged<String?>? onChanged, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    // Validate that the selected value exists in the items map
    final effectiveSelectedValue =
        items.containsKey(selectedValue) ? selectedValue : null;

    return DropdownButtonFormField<String>(
      value: effectiveSelectedValue,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: CustomText('Select', fontSize: textFontSize),
        ),
        ...items.keys.map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: CustomText(item, fontSize: textFontSize),
          ),
        ),
      ],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: labelFontSize),
        border: const OutlineInputBorder(),
        errorText: _submitted && effectiveSelectedValue == null
            ? 'Please select $label'
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
                return 'Please enter $label';
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

  addMoreFollowUp() {
    setState(() {
      _submitted = true;
    });
    if (_formKey.currentState!.validate()) {
      _updateCartItem();
      toastMessage.showInfoToastMessage('Followup Action Added');

      setState(() {
        _dateController.clear();
        _visitFollowUpActionController.clear();

        selectedDepartment = null;
        selectedDepartmentId = null;
        selectedExecutive = null;
        selectedExecutiveId = null;

        _submitted = false;
      });
    }
  }

  addFollowUp() {
    setState(() {
      _submitted = true;
    });
    if (_formKey.currentState!.validate()) {
      _updateCartItem();
      goToCart();
    }
  }
}
