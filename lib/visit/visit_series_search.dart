import 'package:avant/views/rich_text.dart';
import 'package:avant/visit/visit_dsr_series_title_wise.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/common_text.dart';
import '../common/toast.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/series_and_class_level_list_response.dart';

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
  final int personMetId;
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
    required this.jointVisitWithIds,
    required this.personMetId,
    required this.samplingDone,
    required this.followUpAction,
  });

  @override
  VisitSeriesSearchPageState createState() => VisitSeriesSearchPageState();
}

class VisitSeriesSearchPageState extends State<VisitSeriesSearch>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  ClassLevelList? selectedClassLevel;
  SeriesList? selectedSeries;
  TitleList? selectedTitle;

  List<DropdownMenuItem<ClassLevelList>> classLevelItems = [];
  List<DropdownMenuItem<SeriesList>> seriesItems = [];
  List<TitleList> titleSuggestions = [];

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  bool _submitted = false;
  bool _isLoading = true;
  bool _isFetchingTitles = false;

  final DetailText _detailText = DetailText();
  final ToastMessage _toastMessage = ToastMessage();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController _autocompleteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSeriesAndClassLevels();
    _autocompleteController.addListener(() {
      _fetchTitlesSuggestions(_autocompleteController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  (e) => DropdownMenuItem<ClassLevelList>(
                    value: e,
                    key: ValueKey(e.classLevelId),
                    child: Text(e.classLevelName),
                  ),
                )
                .toList() ??
            [];

        seriesItems = response.seriesList
                ?.map(
                  (e) => DropdownMenuItem<SeriesList>(
                    value: e,
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
        1,
        selectedSeries?.seriesId ?? 0,
        selectedClassLevel?.classLevelId ?? 0,
        query,
        token,
      );

      setState(() {
        titleSuggestions = response.titleList ?? [];
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
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.black,
                        indicatorColor: Colors.blue,
                        tabs: const [
                          Tab(text: 'Series/ Title'),
                          Tab(text: 'Title wise'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
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

    int selectedIndex = _tabController.index;
    if (selectedIndex == 0 && selectedSeries == null) {
      _toastMessage.showToastMessage("Please select series");
    } else if (selectedIndex == 1 && titleController.text.isNotEmpty) {
      _toastMessage.showToastMessage("Please select title");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitDsrSeriesTitleWise(
            selectedIndex: selectedIndex,
            customerId: widget.customerId,
            customerName: widget.customerName,
            customerType: widget.customerType,
            address: widget.address,
            selectedSeries: selectedSeries,
            selectedClassLevel: selectedClassLevel,
            selectedTitle: selectedTitle,
            visitFeedback: widget.visitFeedback,
            visitDate: widget.visitDate,
            visitPurposeId: widget.visitPurposeId,
            jointVisitWithIds: widget.jointVisitWithIds,
            personMetId: widget.personMetId,
            samplingDone: widget.samplingDone,
            followUpAction: widget.followUpAction,
          ),
        ),
      );
    }
  }

  Widget _buildSeriesTitleTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDropdownField<ClassLevelList>(
                'Class Level',
                selectedClassLevel,
                classLevelItems,
                (value) {
                  setState(() {
                    selectedClassLevel = value;
                  });
                },
                selectedId: selectedClassLevel?.classLevelId,
                onIdChanged: (id) {
                  // No longer needed
                }),
            buildDropdownField<SeriesList>(
                'Series',
                selectedSeries,
                seriesItems,
                (value) {
                  setState(() {
                    selectedSeries = value;
                  });
                },
                selectedId: selectedSeries?.seriesId,
                onIdChanged: (id) {
                  // No longer needed
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
                  title: Text(title.title),
                  onTap: () {
                    setState(() {
                      if (kDebugMode) {
                        print(title.title);
                      }
                      selectedTitle = title;
                      titleController.text = title.title;
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
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

  Widget buildDropdownField<T>(String label, T? selectedValue,
      List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged,
      {required int? selectedId, required ValueChanged<int?> onIdChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _submitted && selectedValue == null && label == 'Series'
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
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
