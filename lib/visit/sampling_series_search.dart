import 'package:avant/views/rich_text.dart';
import 'package:avant/visit/sampling_series_title_wise.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/toast.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/series_and_class_level_list_response.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class SamplingSeriesSearch extends StatefulWidget {
  final String type;
  final String title;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;

  const SamplingSeriesSearch({
    super.key,
    required this.type,
    required this.title,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
  });

  @override
  SamplingSeriesSearchPageState createState() =>
      SamplingSeriesSearchPageState();
}

class SamplingSeriesSearchPageState extends State<SamplingSeriesSearch>
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
  int? profileId;

  bool _submitted = false;
  bool _isLoading = true;
  bool _isFetchingTitles = false;
  bool _isSuggestionSelected = false;

  final ToastMessage _toastMessage = ToastMessage();

  final TextEditingController _autocompleteController = TextEditingController();
  final FocusNode _autocompleteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _fetchSeriesAndClassLevels();

    _autocompleteController.addListener(() {
      if (_isSuggestionSelected) {
        if (kDebugMode) {
          print('_isSuggestionSelected:$_isSuggestionSelected');
        }
        // Reset flag and return if a suggestion was selected
        _isSuggestionSelected = false;
        return;
      }
      if (kDebugMode) {
        print('_isSuggestionSelected:$_isSuggestionSelected');
      }
      final query = _autocompleteController.text;
      if (query.isNotEmpty) {
        if (kDebugMode) {
          print('_isSuggestionSelected:$_isSuggestionSelected query:$query');
        }
        _fetchTitlesSuggestions(query);
      } else {
        setState(() {
          titleSuggestions = [];
        });
      }
    });

    _autocompleteFocusNode.addListener(() {
      if (!_autocompleteFocusNode.hasFocus) {
        setState(() {
          titleSuggestions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autocompleteController.dispose();
    _autocompleteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSeriesAndClassLevels() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    executiveId = await getExecutiveId();
    profileId = await getProfileId();
    try {
      final response = await SeriesAndClassLevelListService()
          .getSeriesAndClassLevelList(executiveId ?? 0, profileId ?? 0, token);

      setState(() {
        classLevelItems = response.classLevelList
                ?.map(
                  (e) => DropdownMenuItem<ClassLevelList>(
                    value: e,
                    key: ValueKey(e.classLevelId),
                    child: CustomText(e.classLevelName, fontSize: 14),
                  ),
                )
                .toList() ??
            [];

        seriesItems = response.seriesList
                ?.map(
                  (e) => DropdownMenuItem<SeriesList>(
                    value: e,
                    key: ValueKey(e.seriesId),
                    child: CustomText(e.seriesName, fontSize: 14),
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
      ServerErrorScreen(onRefresh: _fetchSeriesAndClassLevels);
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
    if (kDebugMode) {
      print('_isSuggestionSelected:$_isSuggestionSelected query:$query');
    }
    try {
      final response = await GetVisitDsrService().fetchTitles(
        1,
        executiveId ?? 0,
        selectedSeries?.seriesId ?? 0,
        selectedClassLevel?.classLevelId ?? 0,
        query,
        token,
      );

      setState(() {
        if (mounted) {
          titleSuggestions = response.titleList ?? [];
          _isFetchingTitles = false;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching titles: $e');
      }
      setState(() {
        if (mounted) {
          _isFetchingTitles = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CommonAppBar(title: widget.title),
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
                          CustomText(widget.customerName,
                              fontWeight: FontWeight.bold, fontSize: 16),
                          RichTextWidget(label: widget.address),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      color: Colors.orange,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white,
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
                                child: CustomText(
                                  'Search Customer',
                                  textAlign: TextAlign.center,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
    } else if (selectedIndex == 1 && selectedTitle == null) {
      _toastMessage.showToastMessage("Please select title");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SamplingSeriesTitleWise(
            type: widget.type,
            title: widget.title,
            selectedIndex: selectedIndex,
            customerId: widget.customerId,
            customerName: widget.customerName,
            customerCode: widget.customerCode,
            customerType: widget.customerType,
            address: widget.address,
            selectedSeries: selectedSeries,
            selectedClassLevel: selectedClassLevel,
            selectedTitle: selectedTitle,
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
              },
            ),
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
              },
            ),
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
            buildTextField(
              'Title / ISBN',
              _autocompleteController,
              enabled: true,
            ),
            const SizedBox(height: 16.0),
            if (_isFetchingTitles)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_isFetchingTitles && titleSuggestions.isNotEmpty)
              ...titleSuggestions.map(
                (title) => ListTile(
                  title: CustomText(title.title),
                  onTap: () {
                    setState(() {
                      selectedTitle = title;
                      _autocompleteController.text = title.title;
                      _isSuggestionSelected = true;
                      titleSuggestions = [];
                    });
                    _autocompleteFocusNode.unfocus();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool enabled = true,
      int maxLines = 1,
      double labelFontSize = 14.0,
      double textFontSize = 14.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: textFontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
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
        focusNode: _autocompleteFocusNode,
      ),
    );
  }

  Widget buildDropdownField<T>(String label, T? selectedValue,
      List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged,
      {required int? selectedId,
      required ValueChanged<int?> onIdChanged,
      double labelFontSize = 14.0,
      double textFontSize = 14.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          errorText: _submitted && selectedValue == null && label == 'Series'
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            value: selectedValue,
            style: TextStyle(fontSize: textFontSize),
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

class ServerErrorScreen extends StatelessWidget {
  final VoidCallback onRefresh;

  const ServerErrorScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const CustomText('Server Error',
              fontSize: 16, fontWeight: FontWeight.bold),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const CustomText('Retry'),
          ),
        ],
      ),
    );
  }
}
