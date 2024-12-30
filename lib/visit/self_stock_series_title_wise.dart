import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/views/label_text.dart';
import 'package:avant/visit/self_stock_request_cart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/series_and_class_level_list_response.dart';
import '../views/book_list_item.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import '../views/rich_text.dart';

class SelfStockSeriesTitleWise extends StatefulWidget {
  final String type;
  final String title;
  final int selectedIndex;
  final String customerName;
  final int shipmentModeId;
  final String shipToId;
  final int deliveryTradeId;
  final String shippingInstructions;
  final String remarks;
  final String address;
  final SeriesList? selectedSeries;
  final ClassLevelList? selectedClassLevel;
  final TitleList? selectedTitle;

  const SelfStockSeriesTitleWise({
    super.key,
    required this.type,
    required this.title,
    required this.selectedIndex,
    required this.customerName,
    required this.shipmentModeId,
    required this.shipToId,
    required this.deliveryTradeId,
    required this.shippingInstructions,
    required this.remarks,
    required this.address,
    required this.selectedSeries,
    required this.selectedClassLevel,
    required this.selectedTitle,
  });

  @override
  SelfStockSeriesTitleWiseState createState() =>
      SelfStockSeriesTitleWiseState();
}

class SelfStockSeriesTitleWiseState extends State<SelfStockSeriesTitleWise>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DatabaseHelper databaseHelper = DatabaseHelper();
  ToastMessage toastMessage = ToastMessage();

  List<TitleList> books = [];

  bool isLoading = true;
  String? errorMessage;

  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late int? profileId;

  int _cartBooksCount = 0;
  int samplingSelfStockMaxQtyAllowed = 0;

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
    _fetchSamplingSelfStockMaxQtyAllowed();
    _fetchBooksCount();
    _fetchData();
  }

  Future<void> _fetchSamplingSelfStockMaxQtyAllowed() async {
    final int? result = await databaseHelper.getSamplingCustomerMaxQtyAllowed();
    setState(() {
      samplingSelfStockMaxQtyAllowed = result ?? 0;
      if (kDebugMode) {
        print('samplingSelfStockMaxQtyAllowed:$samplingSelfStockMaxQtyAllowed');
      }
    });
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
        final responses = await GetVisitDsrService().fetchTitles(
          widget.selectedIndex,
          executiveId ?? 0,
          widget.selectedSeries?.seriesId ?? 0,
          widget.selectedClassLevel?.classLevelId ?? 0,
          widget.selectedTitle?.title ?? '',
          token,
        );

        setState(() {
          books = responses.titleList ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          // Add selected title to the books list
          if (widget.selectedTitle != null) {
            books = List.from(books)..add(widget.selectedTitle!);
          }

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CommonAppBar(title: widget.title),
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
    if (kDebugMode) {
      print('books size :${books.length}');
    }
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
                            areDropdownsSelected: true,
                            maxQtyAllowed: samplingSelfStockMaxQtyAllowed);
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
              if (_formKey.currentState?.validate() == true) {
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
              if (_formKey.currentState?.validate() == true) {
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
              if (_formKey.currentState?.validate() == true) {
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
              if (_formKey.currentState?.validate() == true) {
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

  Future<void> _fetchBooksCount() async {
    int count = await databaseHelper.getItemCount();
    setState(() {
      _cartBooksCount = count;
    });
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
      'ShipTo': 0,
      'ShippingAddress': '',
      'SamplingType': '',
      'SampleTo': '',
      'SampleGiven': '',
      'MRP': books[index].listPrice,
    });
  }

  Future<void> deleteItem(int index) async {
    await databaseHelper.deleteCartItem(books[index].bookId);
  }

  int getSelectedBookCount() {
    return books.where((book) => book.quantity > 0).length;
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
      gotoCart();
    }
  }

  void gotoCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfStockRequestCart(
          type: widget.type,
          title: widget.title,
          customerName: widget.customerName,
          address: widget.address,
          shipmentModeId: widget.shipmentModeId,
          shipToId: widget.shipToId,
          deliveryTradeId: widget.deliveryTradeId,
          shippingInstructions: widget.shippingInstructions,
          remarks: widget.remarks,
        ),
      ),
    );
  }
}
