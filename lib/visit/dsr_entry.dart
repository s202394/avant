import 'package:avant/api/api_service.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';

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

  bool _submitted = false;

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

  @override
  void initState() {
    super.initState();
    _visitDsrData = _fetchVisitDsrData();
  }

  Future<GetVisitDsrResponse> _fetchVisitDsrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int? executiveId = await getExecutiveId();
    executiveName = await getExecutiveName();
    int customerId = widget.customerId;
    String customerType = widget.customerType;
    String upHierarchy = prefs.getString('UpHierarchy') ?? '';
    String downHierarchy = prefs.getString('DownHierarchy') ?? '';

    return await GetVisitDsrService().getVisitDsr(
      executiveId??0,
      customerId,
      customerType,
      upHierarchy,
      downHierarchy,
      token,
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
                        buildDateTextField('Visit Date'),
                        buildTextField('Visit By',
                            initialValue: executiveName??'', enabled: false),
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
                        buildImageButton(),
                        buildTextField('Visit Feedback', maxLines: 3),
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
                          if (_formKey.currentState!.validate() &&
                              selectedVisitPurpose != null) {
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

  void _submitForm() {
    // Handle form submission logic here
    print('Form submitted!');
    // You can access form fields using their controllers or values stored in state variables
  }

  Widget buildDateTextField(String label,
      {String initialValue = '', bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: InkWell(
            onTap: () async {
              // Show date picker
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

              // Update selected date in the text field
              if (picked != null && picked != DateTime.now()) {
                setState(() {
                  _dateController.text = dateFormat.format(picked);
                });
              }
            },
            child: Icon(Icons.calendar_month),
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
        ),
        controller: _dateController,
        enabled: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
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

  Widget buildImageButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('Click Image:'),
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              // Handle image capture
            },
          ),
        ],
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
}
