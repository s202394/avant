import 'package:avant/views/label_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/sampling_details_response.dart';
import '../views/rich_text.dart';

class VisitDsrSeriesTitleWise extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerType;
  final String address;
  final String series;
  final int seriesId;
  final String classLevel;
  final int classLevelId;
  final String title;
  final int titleId;
  final String visitFeedback;
  final String visitDate;
  final int visitPurposeId;
  final String jointVisitWithIds;
  final bool samplingDone;
  final bool followUpAction;

  const VisitDsrSeriesTitleWise({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.address,
    required this.series,
    required this.seriesId,
    required this.classLevel,
    required this.classLevelId,
    required this.title,
    required this.titleId,
    required this.visitFeedback,
    required this.visitDate,
    required this.visitPurposeId,
    required this.jointVisitWithIds,
    required this.samplingDone,
    required this.followUpAction,
  });

  @override
  VisitDsrSeriesTitleWiseState createState() => VisitDsrSeriesTitleWiseState();
}

class VisitDsrSeriesTitleWiseState extends State<VisitDsrSeriesTitleWise> {
  String? selectedSamplingType;
  String? selectedSampleGiven;
  String? selectedSampleTo;
  String? selectedShipTo;

  bool _submitted = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<TitleList> books = [];
  List<SamplingType> samplingTypes = [];
  List<SampleGiven> sampleGivens = [];

  bool isLoading = true;
  String? errorMessage;

  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late int? profileId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });

    executiveId = await getExecutiveId();
    profileId = await getProfileId();

    try {
      // Call both APIs asynchronously
      final futures = [
        GetVisitDsrService().fetchTitles(
          widget.seriesId,
          widget.classLevelId,
          widget.title,
          token,
        ),
        GetVisitDsrService().samplingDetails(
          widget.customerId,
          'visit',
          profileId??0,
          widget.customerType,
          executiveId??0,
          widget.seriesId,
          widget.classLevelId,
          widget.titleId, // titleId
          token,
        ),
      ];

      final responses = await Future.wait(futures);

      // Process the responses
      final titlesResponse = responses[0] as FetchTitlesResponse;
      final samplingResponse = responses[1] as SamplingDetailsResponse;

      setState(() {
        books = titlesResponse.titleList ?? [];
        samplingTypes = samplingResponse.samplingType ?? [];
        sampleGivens = samplingResponse.sampleGiven ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text('Error: $errorMessage'))
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
                    const SizedBox(height: 8),
                    LabeledText(
                        label: 'Visit Date', value: widget.visitDate),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LabeledText(
                        label: 'Sampling Done',
                        value: widget.samplingDone ? 'Yes' : 'No'),
                    LabeledText(
                        label: 'Follow up Action',
                        value: widget.followUpAction ? 'Yes' : 'No'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesTitleTab() {
    // Convert your data into DropdownMenuItems
    final samplingTypeItems = samplingTypes.map((type) {
      return DropdownMenuItem<String>(
        value: type.samplingTypeValue,
        child: Text(type.samplingType),
      );
    }).toList();

    final sampleGivenItems = sampleGivens.map((given) {
      return DropdownMenuItem<String>(
        value: given.sampleGivenValue,
        child: Text(given.sampleGiven),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledText(label: 'Series Name', value: widget.series),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sample To',
                            border: const OutlineInputBorder(),
                            errorText: _submitted && selectedSampleTo == null
                                ? 'Please select Sample To'
                                : null,
                          ),
                          items: ['Mr. Sanjay Banerjee', 'Rajesh Ranjan']
                              .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSampleTo = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sampling Type',
                            border: const OutlineInputBorder(),
                            errorText:
                            _submitted && selectedSamplingType == null
                                ? 'Please select Sampling Type'
                                : null,
                          ),
                          items: samplingTypeItems,
                          onChanged: (value) {
                            setState(() {
                              selectedSamplingType = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sample Given',
                            border: const OutlineInputBorder(),
                            errorText: _submitted && selectedSampleGiven == null
                                ? 'Please select Sample Given'
                                : null,
                          ),
                          items: sampleGivenItems,
                          onChanged: (value) {
                            setState(() {
                              selectedSampleGiven = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Ship To',
                            border: const OutlineInputBorder(),
                            errorText: _submitted && selectedShipTo == null
                                ? 'Please select Ship To'
                                : null,
                          ),
                          items: ['Official Address', 'Personal Address']
                              .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedShipTo = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookListItem(
                book: books[index],
                onQuantityChanged: (newQuantity) {
                  _handleQuantityChange(index, newQuantity);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _submitted = true;
                });
                if (_formKey.currentState?.validate() == true &&
                    selectedSampleTo != null &&
                    selectedSampleGiven != null &&
                    selectedSamplingType != null &&
                    selectedShipTo != null) {
                  _submitForm();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text('Submit/ Next'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleWiseTab() {
    return Center(
      child: Text('Title wise content goes here'),
    );
  }

  void _handleQuantityChange(int index, int newQuantity) {
    setState(() {
      books[index].quantity = newQuantity;
    });
  }

  void _submitForm() {
    if (kDebugMode) {
      print('Form submitted!');
    }
    if (widget.samplingDone) {
    } else {}
  }
}

class BookListItem extends StatefulWidget {
  final TitleList book;
  final ValueChanged<int> onQuantityChanged;

  const BookListItem({
    Key? key,
    required this.book,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  _BookListItemState createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.book.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.book.title),
      subtitle: Text('ISBN: ${widget.book.isbn}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (_quantity > 0) {
                setState(() {
                  _quantity--;
                });
                widget.onQuantityChanged(_quantity);
              }
            },
          ),
          Text('$_quantity'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _quantity++;
              });
              widget.onQuantityChanged(_quantity);
            },
          ),
        ],
      ),
    );
  }
}
