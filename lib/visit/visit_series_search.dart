import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avant/visit/customer_search_visit.dart';
import 'package:avant/visit/customer_search_visit_list.dart';
import 'package:avant/visit/visit_dsr_series_title_wise.dart';

class VisitSeriesSearch extends StatefulWidget {
  final String schoolName;
  final String address;

  VisitSeriesSearch({required this.schoolName, required this.address});

  @override
  _VisitSeriesSearchPageState createState() => _VisitSeriesSearchPageState();
}

class _VisitSeriesSearchPageState extends State<VisitSeriesSearch> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedClassLevel;
  String? selectedSeries;

  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[100],
          title: Text('DSR Entry'),
        ),
        body: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ASN Sr. Secondary School (SCH654)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Mayur Vihar Phase 1\nNew Delhi - 110001\nDelhi'),
                    SizedBox(height: 8),
                    Text('Visit Date: 24 Jun 2024',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sampling Done: Yes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Follow up Action: No',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                color: Colors.orange,
                child: TabBar(
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
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                          child: Text(
                            'Search Costumer',
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
    print('Form submitted!');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitDsrSeriesTitleWise(
          schoolName: widget.schoolName,
          address: widget.address,
          series: selectedSeries ?? '',
          classLevel: selectedClassLevel ?? '',
        ),
      ),
    );
  }

  Widget buildDropdownField(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
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
            items: [
              DropdownMenuItem(child: Text('Option 1'), value: 'Option 1'),
              DropdownMenuItem(child: Text('Option 2'), value: 'Option 2'),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSeriesTitleTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDropdownField('Series', selectedSeries, (value) {
              setState(() {
                selectedSeries = value;
              });
            }),
            buildDropdownField('Class Level', selectedClassLevel, (value) {
              setState(() {
                selectedClassLevel = value;
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
            buildTextField('Title / ISBN',
                initialValue: '', enabled: true),
          ],
        ),
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
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
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
}
