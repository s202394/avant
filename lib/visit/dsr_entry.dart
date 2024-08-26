import 'dart:io';

import 'package:avant/api/api_service.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:avant/common/common.dart';
import 'package:avant/home.dart';
import 'package:avant/home.dart';
import 'package:avant/service/location_service.dart';

class DsrEntry extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;

  DsrEntry(
      {required this.customerId,
      required this.customerName,
      required this.customerCode,
      required this.customerType,
      required this.address,
      required this.city,
      required this.state});

  @override
  _DsrEntryPageState createState() => _DsrEntryPageState();
}

class _DsrEntryPageState extends State<DsrEntry> {
  String? selectedVisitPurpose;
  String? selectedJointVisit;
  String? selectedPersonMet;
  bool? samplingDone;
  bool? followUpAction;
  DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? executiveId;
  String? profileCode;
  String? upHierarchy;
  String? downHierarchy;
  String? token;

  ToastMessage toastMessage = new ToastMessage();
  LocationService locationService = LocationService();

  bool _submitted = false;
  bool _isLoading = false;

  late String? executiveName;

  late Future<GetVisitDsrResponse> _visitDsrData;

  TextEditingController _dateController = TextEditingController();
  TextEditingController _visitPurposeController = TextEditingController();
  TextEditingController _jointVisitController = TextEditingController();
  TextEditingController _personMetController = TextEditingController();
  TextEditingController _visitFeedbackController = TextEditingController();

  final _dateFieldKey = GlobalKey<FormFieldState>();
  final _visitPurposeFieldKey = GlobalKey<FormFieldState>();
  final _jointVisitFieldKey = GlobalKey<FormFieldState>();
  final _personMetFieldKey = GlobalKey<FormFieldState>();
  final _visitFeedbackFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _dateFocusNode = FocusNode();
  final FocusNode _visitPurposeFocusNode = FocusNode();
  final FocusNode _jointVisitFocusNode = FocusNode();
  final FocusNode _personMetFocusNode = FocusNode();
  final FocusNode _visitFeedbackFocusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        _imageFile = photo;
      });
    } catch (e) {
      // Handle error
      print('Error picking image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _visitDsrData = _fetchVisitDsrData();
  }

  Future<GetVisitDsrResponse> _fetchVisitDsrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    executiveName = await getExecutiveName();
    upHierarchy = prefs.getString('UpHierarchy') ?? '';
    downHierarchy = prefs.getString('DownHierarchy') ?? '';

    return await GetVisitDsrService().getVisitDsr(
      executiveId ?? 0,
      widget.customerId,
      widget.customerType,
      upHierarchy ?? '',
      downHierarchy ?? '',
      token ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DSR Entry'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<GetVisitDsrResponse>(
        future: _visitDsrData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          final visitDsrData = snapshot.data!;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Text(
                          visitDsrData.customerSummery.customerName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: visitDsrData.customerSummery.address
                                .replaceAll('\\r', '')
                                .split('\\n')
                                .map((line) => TextSpan(text: line + '\n'))
                                .toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                            'Visit Date', _dateController, _dateFieldKey),
                        buildTextField('Visit By',
                            initialValue: executiveName ?? '', enabled: false),
                        buildDropdownField(
                          'Visit Purpose',
                          selectedVisitPurpose,
                          visitDsrData.visitPurposeList
                              .map((e) => e.visitPurpose)
                              .toList(),
                          (value) {
                            setState(() {
                              selectedVisitPurpose = value;
                            });
                          },
                        ),
                        buildDropdownField(
                          'Joint Visit',
                          selectedJointVisit,
                          visitDsrData.joinVisitList
                              .map((e) => e.executiveName)
                              .toList(),
                          (value) {
                            setState(() {
                              selectedJointVisit = value;
                            });
                          },
                        ),
                        buildDropdownField(
                          'Person Met',
                          selectedPersonMet,
                          visitDsrData.personMetList
                              .map((e) => e.customerContactName)
                              .toList(),
                          (value) {
                            setState(() {
                              selectedPersonMet = value;
                            });
                          },
                        ),
                        buildRadioButtons('Sampling Done', samplingDone,
                            (value) {
                          setState(() {
                            samplingDone = value;
                          });
                        }),
                        buildRadioButtons('Follow Up Action', followUpAction,
                            (value) {
                          setState(() {
                            followUpAction = value;
                          });
                        }),
                        Text(
                          'Capture Image',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        buildCaptureImage(),
                        _buildTextField('Visit Feedback',
                            _visitFeedbackController, _visitFeedbackFieldKey,
                            maxLines: 3),
                        SizedBox(height: 16),
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
                          child: Padding(
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
          );
        },
      ),
    );
  }

  void _submitForm() async {
    if (samplingDone == null) {
      toastMessage.showToastMessage('PLease select Sampling Done.');
    } else if (followUpAction == null) {
      toastMessage.showToastMessage('PLease select Follow Up Action.');
    } else if (_imageFile == null) {
      toastMessage.showToastMessage('PLease capture image first.');
    } else {
      try {
        FocusScope.of(context).unfocus();

        if (!await _checkInternetConnection()) return;

        setState(() {
          _isLoading = true;
        });

        Position position = await locationService.getCurrentLocation(context);
        print(
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}");

        try {
          print("_submitForm clicked");
          final responseData = await VisitEntryService().visitEntry(
              executiveId ?? 0,
              widget.customerType,
              widget.customerId,
              executiveId ?? 0,
              "",
              profileCode ?? '',
              "${position.latitude}",
              "${position.longitude}",
              "",
              _visitFeedbackController.text,
              _dateController.text,
              _visitPurposeController.text,
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              token ?? "");

          if (responseData.status == 'Success') {
            String s = responseData.s;
            print(s);
            if (s.isNotEmpty) {
              toastMessage.showInfoToastMessage(s);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
              );
            } else {
              print('Add Visit DSR Error s empty');
              toastMessage
                  .showToastMessage("An error occurred while adding visit.");
            }
          } else {
            print('Add Visit DSR Error ${responseData.status}');
            toastMessage
                .showToastMessage("An error occurred while adding visit.");
          }
        } catch (e) {
          print("Error fetching location: $e");
        }
      } catch (e) {
        print('Add Visit DSR Error $e');
        toastMessage.showToastMessage("An error occurred while adding visit.");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  Widget buildTextField(String label,
      {String initialValue = '', bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
        ),
        initialValue: initialValue,
        enabled: enabled,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildDropdownField(String label, String? selectedValue,
      List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: _submitted && selectedValue == null
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget buildRadioButtons(
      String label, bool? groupValue, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                Text('Yes'),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                Text('No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _imageFile = null;
    });
  }

  Widget buildCaptureImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: _imageFile == null
            ? OutlinedButton(
                onPressed: _takePhoto,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey, width: 2),
                  // Border color and width
                  minimumSize: Size(double.infinity, 300),
                  // Match parent width and height 300
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.grey, // Icon color
                  size: 50, // Size of the camera icon
                ),
              )
            : Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                      image: DecorationImage(
                        image: FileImage(File(_imageFile!.path)),
                        // Convert XFile to File
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.red, size: 30),
                      onPressed: _removePhoto,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey, {
    int maxLines = 1,
  }) {
    bool isDateField = label == "Visit Date";

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
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? Icon(Icons.calendar_month) : null,
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

  @override
  void dispose() {
    _dateController.dispose();
    _visitPurposeController.dispose();
    _jointVisitController.dispose();
    _personMetController.dispose();
    _visitFeedbackController.dispose();
    super.dispose();
  }

  Widget _buildDropdownFieldVisitPurpose(
      String label,
      TextEditingController controller,
      GlobalKey<FormFieldState> fieldKey,
      List<VisitPurpose> purposeList,
      FocusNode focusNode,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<VisitPurpose>(
        key: fieldKey,
        value: _selectedBoard,
        focusNode: focusNode,
        items: purposeList
            .map((visitPurpose) => DropdownMenuItem<VisitPurpose>(
          value: visitPurpose,
          child: Text(visitPurpose.visitPurpose),
        ))
            .toList(),
        onChanged: (VisitPurpose? value) {
          setState(() {
            _selectedBoard = value;

            // Update the text controller with the selected category name
            controller.text = value?.visitPurpose ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.visitPurpose.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
