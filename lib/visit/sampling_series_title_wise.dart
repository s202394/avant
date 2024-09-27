import 'package:avant/db/db_helper.dart';
import 'package:avant/views/label_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/sampling_details_response.dart';
import '../model/series_and_class_level_list_response.dart';
import '../views/book_list_item.dart';
import '../views/custom_text.dart';
import '../views/rich_text.dart';
import 'cart.dart';

class SamplingSeriesTitleWise extends StatefulWidget {
  final String type;
  final String title;
  final int selectedIndex;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final SeriesList? selectedSeries;
  final ClassLevelList? selectedClassLevel;
  final TitleList? selectedTitle;

  const SamplingSeriesTitleWise({
    super.key,
    required this.type,
    required this.title,
    required this.selectedIndex,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    required this.selectedSeries,
    required this.selectedClassLevel,
    required this.selectedTitle,
  });

  @override
  SamplingSeriesTitleWiseState createState() => SamplingSeriesTitleWiseState();
}

class SamplingSeriesTitleWiseState extends State<SamplingSeriesTitleWise>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? selectedSamplingType;
  String? selectedSampleTo;
  int? selectedSampleToId;
  String? selectedShipTo;
  String? selectedShippingAddress;

  bool _submitted = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DatabaseHelper databaseHelper = DatabaseHelper();

  List<TitleList> books = [];
  List<SamplingType> samplingTypes = [];
  List<SampleTo> sampleTos = [];

  List<String> shipToOptions = [];
  List<String> shippingAddressOptions = [];

  bool isFetchingShipTo = false;
  bool isLoading = true;
  String? errorMessage;

  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late int? profileId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.selectedIndex;

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });

    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });

    executiveId = await getExecutiveId();
    profileId = await getProfileId();

    try {
      if (widget.selectedIndex == 0) {
        // Call both APIs asynchronously
        final futures = [
          GetVisitDsrService().fetchTitles(
            widget.selectedIndex,
            executiveId ?? 0,
            widget.selectedSeries?.seriesId ?? 0,
            widget.selectedClassLevel?.classLevelId ?? 0,
            widget.selectedTitle?.title ?? '',
            token,
          ),
          GetVisitDsrService().samplingDetails(
            widget.customerId,
            'visit',
            profileId ?? 0,
            widget.customerType,
            executiveId ?? 0,
            widget.selectedSeries?.seriesId ?? 0,
            widget.selectedClassLevel?.classLevelId ?? 0,
            widget.selectedTitle?.bookId ?? 0,
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
          sampleTos = samplingResponse.sampleTo ?? [];
          isLoading = false;
        });
      } else {
        // Await the sampling details API call
        final samplingResponse = await GetVisitDsrService().samplingDetails(
          widget.customerId,
          'visit',
          profileId ?? 0,
          widget.customerType,
          executiveId ?? 0,
          widget.selectedSeries?.seriesId ?? 0,
          widget.selectedClassLevel?.classLevelId ?? 0,
          widget.selectedTitle?.bookId ?? 0,
          token,
        );

        setState(() {
          // Add selected title to the books list
          if (widget.selectedTitle != null) {
            books = List.from(books)..add(widget.selectedTitle!);
          }

          samplingTypes = samplingResponse.samplingType ?? [];
          sampleTos = samplingResponse.sampleTo ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _handleTabChange(int newIndex) {
    if (widget.selectedIndex == 0 && newIndex == 1) {
      // Prevent switching to the second tab if selectedIndex is 0
      _tabController.index = 0;
    } else if (widget.selectedIndex == 1 && newIndex == 0) {
      // Prevent switching to the first tab if selectedIndex is 1
      _tabController.index = 1;
    }
  }

  Future<void> _fetchShipToData() async {
    setState(() {
      isFetchingShipTo = true;
    });

    try {
      final response = await GetVisitDsrService().getShipTo(
        widget.customerId,
        selectedSampleToId ?? 0,
        'To be Dispatched',
        executiveId ?? 0,
        token,
      );

      // Initialize the shipToOptions list
      shipToOptions = [];
      shippingAddressOptions = [];

      // Safely access and check the properties
      final resAddress = response.shipTo?.resAddress;
      final officeAddress = response.shipTo?.officeAddress;

      if (resAddress != null && resAddress.isNotEmpty) {
        shipToOptions.add("Residential Address");
        shippingAddressOptions.add(response.shipTo?.resAddress ?? '');
      }
      if (officeAddress != null && officeAddress.isNotEmpty) {
        shipToOptions.add("Official Address");
        shippingAddressOptions.add(response.shipTo?.officeAddress ?? '');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isFetchingShipTo = false;
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
          title: CustomText(widget.title),
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
                              CustomText(
                                widget.customerName,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              RichTextWidget(label: widget.address),
                            ],
                          ),
                        ),
                        Container(
                          color: Colors.orange,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white,
                            indicatorColor: Colors.blue,
                            tabs: [
                              AbsorbPointer(
                                absorbing: widget.selectedIndex == 1,
                                // Disable if selectedIndex is 1
                                child: const Tab(text: 'Series/ Title'),
                              ),
                              AbsorbPointer(
                                absorbing: widget.selectedIndex == 0,
                                // Disable if selectedIndex is 0
                                child: const Tab(text: 'Title wise'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _tabController,
                            children: [
                              _buildSeriesTitleTab(),
                              _buildSeriesTitleTab(),
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
    final samplingTypeItems = samplingTypes.map((type) {
      return DropdownMenuItem<String>(
        value: type.samplingTypeValue,
        child: CustomText(type.samplingType, fontSize: 14),
      );
    }).toList();

    final sampleToItems = sampleTos.map((value) {
      return DropdownMenuItem<String>(
        value: value.customerName,
        child: CustomText(value.customerName, fontSize: 14),
      );
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: widget.selectedIndex == 0,
              child: LabeledText(
                  label: 'Series Name',
                  value: widget.selectedSeries?.seriesName ?? ''),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sample To',
                        labelStyle: const TextStyle(fontSize: 14.0),
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedSampleTo == null
                            ? 'Please select Sample To'
                            : null,
                      ),
                      items: sampleToItems,
                      style: const TextStyle(fontSize: 14),
                      onChanged: _onSampleToChanged,
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
                        labelStyle: const TextStyle(fontSize: 14.0),
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedSamplingType == null
                            ? 'Please select Sampling Type'
                            : null,
                      ),
                      items: samplingTypeItems,
                      style: const TextStyle(fontSize: 14),
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
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Ship To',
                        labelStyle: const TextStyle(fontSize: 14.0),
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedShipTo == null
                            ? 'Please select Ship To'
                            : null,
                      ),
                      style: const TextStyle(fontSize: 14),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: CustomText('Select'),
                        ),
                        ...shipToOptions.map(
                          (shipTo) => DropdownMenuItem<String>(
                            value: shipTo,
                            child: Text(shipTo,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedShipTo = value;
                          // Find the index of the selected item in shipToOptions
                          int index = shipToOptions.indexOf(value!);
                          // Use the index to select the corresponding shipping address
                          selectedShippingAddress = index != -1
                              ? shippingAddressOptions[index]
                              : null;
                        });
                      },
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(padding: EdgeInsets.only(left: 8.0)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: (books.isEmpty)
                  ? _noDataLayout()
                  : ListView.builder(
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return BookListItem(
                            book: books[index],
                            onQuantityChanged: (newQuantity) {
                              _handleQuantityChange(index, newQuantity);
                            },
                            areDropdownsSelected: _areDropdownsSelected());
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _submitted = true;
            });
            if (_formKey.currentState?.validate() == true &&
                _areDropdownsSelected()) {
              _submitForm();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart),
              SizedBox(width: 8),
              CustomText('Next'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noDataLayout() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomText('No data found.',
            fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleQuantityChange(int index, int newQuantity) {
    setState(() {
      books[index].quantity = newQuantity;
    });

    // Perform the database operation outside of setState
    if (newQuantity == 0) {
      deleteItem(index);
    } else {
      _updateCartItem(index, newQuantity);
    }
  }

  Future<void> _updateCartItem(int index, int newQuantity) async {
    await databaseHelper.insertCartItem({
      'BookId': books[index].bookId,
      'SeriesId': widget.selectedSeries?.seriesId ?? 0,
      'Title': books[index].title,
      'ISBN': books[index].isbn,
      'Author': books[index].author,
      'Price': books[index].price,
      'ListPrice': books[index].listPrice,
      'BookNum': books[index].bookNum,
      'Image': books[index].image,
      'BookType': books[index].bookType,
      'ImageUrl': books[index].imageUrl,
      'PhysicalStock': books[index].physicalStock,
      'RequestedQty': newQuantity,
      'ShipTo': selectedShipTo,
      'ShippingAddress': selectedShippingAddress,
      'SamplingType': selectedSamplingType,
      'SampleTo': selectedSampleToId,
      'SampleGiven': '',
      'MRP': books[index].listPrice,
    });
  }

  Future<void> deleteItem(int index) async {
    await databaseHelper.deleteCartItem(books[index].bookId);
  }

  void _submitForm() {
    if (kDebugMode) {
      print('Form submitted!');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          type: widget.type,
          title: widget.title,
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerCode: widget.customerCode,
          customerType: widget.customerType,
          address: widget.address,
          city: '',
          state: '',
          visitFeedback: '',
          visitDate: '',
          visitPurposeId: 0,
          jointVisitWithIds: '',
          personMetId: 0,
          samplingDone: true,
          followUpAction: false,
        ),
      ),
    );
  }

  bool _areDropdownsSelected() {
    return selectedSampleTo != null &&
        selectedSamplingType != null &&
        selectedShipTo != null;
  }

  void _onSampleToChanged(String? value) {
    setState(() {
      selectedSampleTo = value;

      SampleTo? selectedSampleToObj = sampleTos.firstWhere(
        (sampleTo) => sampleTo.customerName == value,
        orElse: () => SampleTo(customerName: '', customerContactId: 0),
      );
      selectedSampleToId = selectedSampleToObj.customerContactId;

      _fetchShipToData();
    });
  }
}
