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
  int? selectedClassLevelId;
  String? selectedSeries;
  int? selectedSeriesId;
  int? selectedTitleId;

  List<DropdownMenuItem<String>> classLevelItems = [];
  List<DropdownMenuItem<String>> seriesItems = [];
  List<String> titleSuggestions = [];

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  bool _submitted = false;
  bool _isLoading = true;
  bool _isFetchingTitles = false; // To handle loading state for autocomplete

  final DetailText _detailText = DetailText();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController _autocompleteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSeriesAndClassLevels();
    _autocompleteController.addListener(() {
      _fetchTitlesSuggestions(_autocompleteController.text);
    });
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
                  (e) => DropdownMenuItem<String>(
                    value: e.classLevelName,
                    key: ValueKey(e.classLevelId),
                    child: Text(e.classLevelName),
                  ),
                )
                .toList() ??
            [];

        seriesItems = response.seriesList
                ?.map(
                  (e) => DropdownMenuItem<String>(
                    value: e.seriesName,
                    key: ValueKey(e.seriesId),
                    child: Text(e.seriesName),
                  ),
                )
                .toList() ??
            [];
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTitlesSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        titleSuggestions = [];
      });
      return;
    }

    setState(() {
      _isFetchingTitles = true;
    });

    try {
      final response = await GetVisitDsrService().fetchTitles(
        selectedSeriesId ?? 0,
        selectedClassLevelId ?? 0,
        query,
        token,
      );

      setState(() {
        titleSuggestions =
            response.titleList?.map((e) => e.title).toList() ?? [];
        _isFetchingTitles = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching titles: $e');
      }
      setState(() {
        _isFetchingTitles = false;
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
                                  (selectedClassLevel != null ||
                                      titleController.text.isNotEmpty)) {
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
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerType: widget.customerType,
          address: widget.address,
          series: selectedSeries ?? '',
          seriesId: selectedSeriesId ?? 0,
          classLevel: selectedClassLevel ?? '',
          classLevelId: selectedClassLevelId ?? 0,
          title: titleController.text,
          titleId: selectedTitleId ?? 0,
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
            buildDropdownField(
                'Series',
                selectedSeries,
                seriesItems,
                (value) {
                  setState(() {
                    selectedSeries = value;
                  });
                },
                selectedId: selectedSeriesId,
                onIdChanged: (id) {
                  setState(() {
                    selectedSeriesId = id;
                  });
                }),
            buildDropdownField(
                'Class Level',
                selectedClassLevel,
                classLevelItems,
                (value) {
                  setState(() {
                    selectedClassLevel = value;
                  });
                },
                selectedId: selectedClassLevelId,
                onIdChanged: (id) {
                  setState(() {
                    selectedClassLevelId = id;
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
            buildTextField('Title / ISBN', _autocompleteController,
                enabled: true),
            if (_isFetchingTitles)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (titleSuggestions.isNotEmpty)
              ...titleSuggestions.map(
                (title) => ListTile(
                  title: Text(title),
                  onTap: () {
                    setState(() {
                      if (kDebugMode) {
                        print(title);
                      }
                      titleController.text = title;
                      titleSuggestions = [];
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool enabled = true, int maxLines = 1}) {
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
      List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged,
      {required int? selectedId, required ValueChanged<int?> onIdChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _submitted && (selectedValue == null || selectedId == null)
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: items,
            onChanged: (value) {
              if (value == null) return;

              onChanged(value);
              final selectedItem =
                  items.firstWhere((item) => item.value == value);
              onIdChanged((selectedItem.key as ValueKey).value as int);

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
