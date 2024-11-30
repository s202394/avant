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
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
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
  final String fileName;

  const VisitDsrSeriesTitleWise({
    super.key,
    required this.visitDsrData,
    required this.selectedIndex,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
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
    required this.fileName,
  });

  @override
  VisitDsrSeriesTitleWiseState createState() => VisitDsrSeriesTitleWiseState();
}

class VisitDsrSeriesTitleWiseState extends State<VisitDsrSeriesTitleWise>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  int samplingCustomerMaxQtyAllowed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.selectedIndex;

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });
    _fetchSamplingCustomerMaxQtyAllowed();
    _fetchBooksCount();
    _fetchData();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('state:dispose');
    }
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      print('state:didChangeDependencies');
    }
    _updateQuantityIfCartNotEmpty();
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

        _loadQuantitiesFromDatabase();
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

        _loadQuantitiesFromDatabase();
      }
    } catch (e) {
      setState(() {
        if (mounted) {
          errorMessage = e.toString();
          isLoading = false;
        }
      });
    }
  }

  Future<void> _fetchSamplingCustomerMaxQtyAllowed() async {
    final int? result = await databaseHelper.getSamplingCustomerMaxQtyAllowed();
    setState(() {
      samplingCustomerMaxQtyAllowed = result ?? 0;
      if (kDebugMode) {
        print('samplingCustomerMaxQtyAllowed:$samplingCustomerMaxQtyAllowed');
      }
    });
  }

  Future<void> _fetchBooksCount() async {
    int count = await databaseHelper.getItemCount();
    setState(() {
      _cartBooksCount = count;
    });

    _loadQuantitiesFromDatabase();
  }

  Future<void> _loadQuantitiesFromDatabase() async {
    for (var book in books) {
      book.quantity = await databaseHelper.getQuantityForBook(book.bookId);
    }
  }

  Future<void> _updateQuantityIfCartNotEmpty() async {
    await _fetchBooksCount();

    if (kDebugMode) {
      print('_cartBooksCount: $_cartBooksCount');
    }

    if (_cartBooksCount > 0) {
      final cartItems = await databaseHelper.getAllCarts();

      setState(() {
        for (var cartItem in cartItems) {
          final bookId = cartItem['BookId'] as int?;
          final quantity = cartItem['RequestedQty'] as int?;

          if (kDebugMode) {
            print('BookId: $bookId, RequestedQty: $quantity');
          }

          // Only update if a matching book exists
          try {
            var matchingBook =
                books.firstWhere((book) => book.bookId == bookId);

            if (quantity != null) {
              if (kDebugMode) {
                print('matchingBook : ${matchingBook.isbn}');
              }
              matchingBook.updateItemQuantity(matchingBook, quantity);
            }
          } catch (e) {
            // Book not found in the list, so skip updating
            if (kDebugMode) {
              print('BookId: $bookId not found in the list, skipping update.');
            }
          }
        }
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
    if (selectedSampleGiven == null || selectedSampleToId == 0) {
      return; // No need to fetch if no sampleGiven is selected
    }

    setState(() {
      isFetchingShipTo = true;
    });

    try {
      final response = await GetVisitDsrService().getShipTo(
        widget.customerId,
        selectedSampleToId ?? 0,
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
    return WillPopScope(
      onWillPop: () async {
        if (kDebugMode) {
          print('WillPopScope called');
        }
        _updateQuantityIfCartNotEmpty();
        return true;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: const CommonAppBar(title: 'DSR Entry'),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: CustomText('Error: $errorMessage'))
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
                                LabeledText(
                                    label: 'Visit Date',
                                    value: widget.visitDate),
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
                                    value:
                                        widget.followUpAction ? 'Yes' : 'No'),
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
      ),
    );
  }

  Widget _buildSeriesTitleTab() {
    final samplingTypeItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: CustomText('Select', fontSize: 12),
      ),
      ...samplingTypes.map((value) {
        return DropdownMenuItem<String>(
          value: value.samplingTypeValue,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: CustomText(value.samplingTypeValue, fontSize: 12),
          ),
        );
      }),
    ];
    final sampleGivenItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: CustomText('Select', fontSize: 12),
      ),
      ...sampleGivens.map((value) {
        return DropdownMenuItem<String>(
          value: value.sampleGiven,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: CustomText(value.sampleGiven, fontSize: 12),
          ),
        );
      }),
    ];

    final sampleToItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: CustomText('Select', fontSize: 12),
      ),
      ...sampleTos.map((value) {
        return DropdownMenuItem<String>(
          value: value.customerName,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: CustomText(value.customerName, fontSize: 12),
          ),
        );
      }),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
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
                    padding: const EdgeInsets.only(right: 4.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 10),
                        labelStyle: const TextStyle(fontSize: 12),
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
                    padding: const EdgeInsets.only(left: 4.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 10),
                        labelText: 'Sampling Type',
                        labelStyle: const TextStyle(fontSize: 12),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 10),
                        labelText: 'Sample Given',
                        labelStyle: const TextStyle(fontSize: 12),
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
                    padding: const EdgeInsets.only(left: 4.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 10),
                        labelText: 'Ship To',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        errorText: _submitted && selectedShipTo == null
                            ? 'Please select Ship To'
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: "", // Use an empty string instead of null
                          child: CustomText('Select', fontSize: 12),
                        ),
                        ...shipToOptions.map(
                          (shipTo) => DropdownMenuItem<String>(
                            value: shipTo,
                            child: Text(
                              shipTo,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedShipTo = value;
                          // Ensure value is not null before accessing `indexOf`
                          int index = value != null && value.isNotEmpty
                              ? shipToOptions.indexOf(value)
                              : -1;
                          selectedShippingAddress = index != -1
                              ? shippingAddressOptions[index]
                              : null;

                          if (kDebugMode) {
                            print('selectedShipTo:$selectedShipTo');
                            print(
                                'selectedShippingAddress:$selectedShippingAddress');
                          }
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
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
                              if (kDebugMode) {
                                print(
                                    'Updating BookId:${books[index].bookId}, RequestedQty:$newQuantity');
                              }

                              _handleQuantityChange(index, newQuantity);
                            },
                            areDropdownsSelected: _areDropdownsSelected(),
                            maxQtyAllowed: samplingCustomerMaxQtyAllowed);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _cartBooksCount > 0 ? _buildThreeOption() : _buildTwoOptions(),
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
                _submitForm(false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: const CustomText('Add', color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _submitted = true;
              });
              if (_formKey.currentState?.validate() == true &&
                  _areDropdownsSelected()) {
                _submitForm(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child:
                const CustomText('Add More', color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Widget to display when book count is greater than 0
  Widget _buildThreeOption() {
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
                _submitForm(false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: const CustomText('Add', color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _submitted = true;
              });
              if (_formKey.currentState?.validate() == true &&
                  _areDropdownsSelected()) {
                _submitForm(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child:
                const CustomText('Add More', color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8), // Spacing between the buttons
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              gotoCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: const CustomText('Go to Cart',
                fontSize: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _noDataLayout() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomText('No data found.',
            fontSize: 16, fontWeight: FontWeight.bold),
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

  void _submitForm(bool isAddMore) {
    if (kDebugMode) {
      print('Form submitted!');
    }

    // Get the selected book count
    int selectedBookCount = getSelectedBookCount();

    if (kDebugMode) {
      print('Selected Book Count: $selectedBookCount');
    }

    if (selectedBookCount == 0) {
      toastMessage.showToastMessage('Please add some books to continue');
      return;
    }

    if (isAddMore) {
      Navigator.of(context).pop(false);
    } else {
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
              visitFeedback: widget.visitFeedback,
              visitDate: widget.visitDate,
              visitPurposeId: widget.visitPurposeId,
              jointVisitWithIds: widget.jointVisitWithIds,
              personMetId: widget.personMetId,
              samplingDone: widget.samplingDone,
              followUpAction: widget.followUpAction,
              fileName: widget.fileName,
            ),
          ),
        );
      } else {
        gotoCart();
      }
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
      if (kDebugMode) {
        print('selectedSampleToId:$selectedSampleToId');
      }
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
          visitFeedback: widget.visitFeedback,
          visitDate: widget.visitDate,
          visitPurposeId: widget.visitPurposeId,
          jointVisitWithIds: widget.jointVisitWithIds,
          personMetId: widget.personMetId,
          samplingDone: widget.samplingDone,
          followUpAction: widget.followUpAction,
          fileName: widget.fileName,
        ),
      ),
    );
  }
}
