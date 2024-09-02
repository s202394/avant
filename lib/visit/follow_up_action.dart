import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/home.dart';
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

  List<Executive> executivesList = [];

  bool _submitted = false;
  bool _isLoading = false;
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
        title: const Text('DSR Entry'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        RichTextWidget(
                          label: widget.address,
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
                            _submitForm();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          color: Colors.blue,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: Text(
                              'Submit',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
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

  void _submitForm() async {
    try {
      FocusScope.of(context).unfocus();

      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print("_submitForm clicked");
        }

        String followUpAction =
            "<DocumentElement><FollowUpAction><Department>$selectedDepartmentId</Department><FollowUpExecutive>$selectedExecutiveId</FollowUpExecutive><FollowUpAction>${_visitFollowUpActionController
            .text}</FollowUpAction><FollowUpDate>${_dateController
            .text}</FollowUpDate></FollowUpAction></DocumentElement>";
        final responseData = await VisitEntryService().visitEntry(
            executiveId ?? 0,
            widget.customerType,
            widget.customerId,
            executiveId ?? 0,
            address,
            profileCode ?? '',
            position.latitude,
            position.longitude,
            1,
            widget.visitFeedback,
            _dateController.text,
            widget.visitPurposeId,
            widget.personMetId,
            widget.jointVisitWithIds,
            "",
            "",
            "",
            "",
            "",
            0,
            0,
            userId ?? 0,
            followUpAction,
            "",
            'No',
            "",
            "",
            false,
            "",
            "",
            token ?? "");

        if (responseData.status == 'Success') {
          String s = responseData.s;
          if (kDebugMode) {
            print(s);
          }
          if (s.isNotEmpty) {
            if (kDebugMode) {
              print('Add Visit DSR Error s not empty');
            }
            toastMessage.showInfoToastMessage(s);
            if (s.contains('::')) {
              toastMessage.showInfoToastMessage(
                  'Please check the customer details and try again.');
            } else {
              toastMessage.showInfoToastMessage(
                  'Failed to add DSR entry. Please try again.');
            }
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to add DSR entry: $e");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to add DSR entry: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
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
              child: Text(key),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1970, 1, 1),
                  lastDate: DateTime.now(),
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
            decoration: InputDecoration(
              labelText: label,
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
}
