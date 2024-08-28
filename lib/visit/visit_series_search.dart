import 'package:avant/views/rich_text.dart';
import 'package:avant/visit/visit_dsr_series_title_wise.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/common_text.dart';
import '../model/login_model.dart';

class VisitSeriesSearch extends StatefulWidget {
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
  final bool samplingDone;
  final bool followUpAction;

  const VisitSeriesSearch({
    super.key,
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
    required this.samplingDone,
    required this.jointVisitWithIds,
    required this.followUpAction,
  });

  @override
  VisitSeriesSearchPageState createState() => VisitSeriesSearchPageState();
}

class VisitSeriesSearchPageState extends State<VisitSeriesSearch> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedClassLevel;
  String? selectedSeries;

  List<DropdownMenuItem<String>> classLevelItems = [];
  List<DropdownMenuItem<String>> seriesItems = [];

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  bool _submitted = false;
  bool _isLoading = true;

  final DetailText _detailText = DetailText();

  final TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSeriesAndClassLevels();
  }

  Future<void> _fetchSeriesAndClassLevels() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    try {
      final response = await SeriesAndClassLevelListService()
          .getSeriesAndClassLevelList(
              executiveId ?? 0, profileCode ?? '', token);

      setState(() {
        classLevelItems = response.classLevelList
                ?.map(
                  (e) => DropdownMenuItem(
                    value: e.classLevelName,
                    child: Text(e.classLevelName),
                  ),
                )
                .toList() ??
            [];

        seriesItems = response.seriesList
                ?.map(
                  (e) => DropdownMenuItem(
                    value: e.seriesName,
                    child: Text(e.seriesName),
                  ),
                )
                .toList() ??
            [];
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[100],
          title: const Text('DSR Entry'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          RichTextWidget(label: widget.address),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _detailText.buildDetailText(
                            'Sampling Done: ',
                            widget.samplingDone ? 'Yes' : 'No',
                          ),
                          _detailText.buildDetailText(
                            'Follow up Action: ',
                            widget.followUpAction ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.orange,
                      child: const TabBar(
                        labelColor: Colors.black,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Series/ Title'),
                          Tab(text: 'Title wise'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSeriesTitleTab(),
                          _buildTitleWiseTab(),
                        ],
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
                                  selectedClassLevel != null &&
                                  selectedSeries != null) {
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
                                  'Search Customer',
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
      ),
    );
  }

  void _submitForm() {
    if (kDebugMode) {
      print('Form submitted!');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitDsrSeriesTitleWise(
          customerName: widget.customerName,
          address: widget.address,
          series: selectedSeries ?? '',
          classLevel: selectedClassLevel ?? '',
          title: titleController.text,
          visitFeedback: widget.visitFeedback,
          visitDate: widget.visitDate,
          visitPurposeId: widget.visitPurposeId,
          jointVisitWithIds: widget.jointVisitWithIds,
          samplingDone: widget.samplingDone,
          followUpAction: widget.followUpAction,
        ),
      ),
    );
  }

  Widget _buildSeriesTitleTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDropdownField('Series', selectedSeries, seriesItems, (value) {
              setState(() {
                selectedSeries = value;
                if (_submitted) {
                  // Clear error messages if a valid selection is made
                  _formKey.currentState?.validate();
                }
              });
            }),
            buildDropdownField(
                'Class Level', selectedClassLevel, classLevelItems, (value) {
              setState(() {
                selectedClassLevel = value;
                if (_submitted) {
                  _formKey.currentState?.validate();
                }
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleWiseTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTextField('Title / ISBN', titleController,
                initialValue: '', enabled: true),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {String initialValue = '', bool enabled = true, int maxLines = 1}) {
    controller = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          alignLabelWithHint: true,
        ),
        enabled: enabled,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onChanged: (text) {
          if (_formKey.currentState != null) {
            _formKey.currentState!.validate();
          }
        },
      ),
    );
  }

  Widget buildDropdownField(String label, String? selectedValue,
      List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText:
              _submitted && selectedSeries == null && selectedClassLevel == null
                  ? 'Please select a $label'
                  : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: items,
            onChanged: (value) {
              onChanged(value);
              setState(() {
                if (_submitted) {
                  _formKey.currentState?.validate();
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
