import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/views/label_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/fetch_titles_model.dart';
import '../model/get_visit_dsr_model.dart';
import '../model/login_model.dart';
import '../model/sampling_details_response.dart';
import '../model/series_and_class_level_list_response.dart';
import '../views/book_list_item.dart';
import '../views/rich_text.dart';
import 'cart.dart';
import 'follow_up_action.dart';

class VisitDsrSeriesTitleWise extends StatefulWidget {
  final GetVisitDsrResponse visitDsrData;
  final int selectedIndex;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;
  final SeriesList? selectedSeries;
  final ClassLevelList? selectedClassLevel;
  final TitleList? selectedTitle;
  final String visitFeedback;
  final String visitDate;
  final int visitPurposeId;
  final String jointVisitWithIds;
  final int personMetId;
  final bool samplingDone;
  final bool followUpAction;

  const VisitDsrSeriesTitleWise({
    super.key,
    required this.visitDsrData,
    required this.selectedIndex,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    required this.city,
    required this.state,
    required this.selectedSeries,
    required this.selectedClassLevel,
    required this.selectedTitle,
    required this.visitFeedback,
    required this.visitDate,
    required this.visitPurposeId,
    required this.jointVisitWithIds,
    required this.personMetId,
    required this.samplingDone,
    required this.followUpAction,
  });

  @override
  VisitDsrSeriesTitleWiseState createState() => VisitDsrSeriesTitleWiseState();
}

class VisitDsrSeriesTitleWiseState extends State<VisitDsrSeriesTitleWise>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? selectedSamplingType;
  String? selectedSampleGiven;
  String? selectedSampleTo;
  int? selectedSampleToId;
  String? selectedShipTo;
  String? selectedShippingAddress;

  bool _submitted = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DatabaseHelper databaseHelper = DatabaseHelper();
  ToastMessage toastMessage = ToastMessage();

  List<TitleList> books = [];
  List<SamplingType> samplingTypes = [];
  List<SampleGiven> sampleGivens = [];
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

  int _cartBooksCount = 0;

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
    _fetchBooksCount();
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooksCount() async {
    int count = await databaseHelper.getItemCount();
    setState(() {
      _cartBooksCount = count;
    });
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
          sampleGivens = samplingResponse.sampleGiven ?? [];
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
          sampleGivens = samplingResponse.sampleGiven ?? [];
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
    if (selectedSampleGiven == null) {
      return; // No need to fetch if no sampleGiven is selected
    }

    setState(() {
      isFetchingShipTo = true;
    });

    try {
      final response = await GetVisitDsrService().getShipTo(
        widget.customerId,
        widget.personMetId,
        selectedSampleGiven ?? '',
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
                                  label: 'Follow Up Action',
                                  value: widget.followUpAction ? 'Yes' : 'No'),
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
        child: Text(type.samplingType),
      );
    }).toList();

    final sampleGivenItems = sampleGivens.map((given) {
      return DropdownMenuItem<String>(
        value: given.sampleGivenValue,
        child: Text(given.sampleGiven),
      );
    }).toList();

    final sampleToItems = sampleTos.map((value) {
      return DropdownMenuItem<String>(
        value: value.customerName,
        child: Text(value.customerName),
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
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedSampleTo == null
                            ? 'Please select Sample To'
                            : null,
                      ),
                      items: sampleToItems,
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
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedSamplingType == null
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
                          selectedShipTo = null;
                          shipToOptions.clear();
                          shippingAddressOptions.clear();
                          _fetchShipToData();
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
                      items: shipToOptions
                          .map(
                            (address) => DropdownMenuItem<String>(
                              value: address,
                              child: Text(
                                address,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
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
        child: _cartBooksCount > 0 ? _buildTwoOptions() : _buildSingleOption(),
      ),
    );
  }

  // Widget to display when book count is greater than 0
  Widget _buildTwoOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
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
            child: const Text('Next'),
          ),
        ),
        const SizedBox(width: 8), // Spacing between the buttons
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              gotoCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Go to Cart'),
          ),
        ),
      ],
    );
  }

  // Widget to display when book count is 0
  Widget _buildSingleOption() {
    return ElevatedButton(
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
      child: const Text('Next'),
    );
  }

  Widget _noDataLayout() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No data found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
      'SampleGiven': selectedSampleGiven,
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

    // Get the selected book count
    int selectedBookCount = getSelectedBookCount();

    if (kDebugMode) {
      print('Selected Book Count: $selectedBookCount');
    }

    if (selectedBookCount == 0) {
      toastMessage.showToastMessage('PLease add some books to continue');
      return;
    }

    if (widget.followUpAction) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowUpAction(
            visitDsrData: widget.visitDsrData,
            customerId: widget.customerId,
            customerName: widget.customerName,
            customerCode: widget.customerCode,
            customerType: widget.customerType,
            address: widget.address,
            city: widget.city,
            state: widget.state,
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
    } else {
      gotoCart();
    }
  }

  bool _areDropdownsSelected() {
    return selectedSampleTo != null &&
        selectedSampleGiven != null &&
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
    });
  }

  int getSelectedBookCount() {
    return books.where((book) => book.quantity > 0).length;
  }

  void gotoCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          type: 'Visit',
          title: 'DSR Entry',
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerCode: widget.customerCode,
          customerType: widget.customerType,
          address: widget.address,
          city: widget.city,
          state: widget.state,
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
