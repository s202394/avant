import 'package:avant/db/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/common.dart';
import '../common/toast.dart';
import '../home.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../service/location_service.dart';
import '../views/book_list_item.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import '../views/rich_text.dart';

class SelfStockRequestCart extends StatefulWidget {
  final String type;
  final String title;
  final String customerName;
  final String address;
  final int shipmentModeId;
  final String shipToId;
  final int deliveryTradeId;
  final String shippingInstructions;
  final String remarks;

  const SelfStockRequestCart({
    super.key,
    required this.type,
    required this.title,
    required this.customerName,
    required this.address,
    required this.shipmentModeId,
    required this.shipToId,
    required this.deliveryTradeId,
    required this.shippingInstructions,
    required this.remarks,
  });

  @override
  SelfStockRequestCartState createState() => SelfStockRequestCartState();
}

class SelfStockRequestCartState extends State<SelfStockRequestCart>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  int? userId;

  bool _isLoading = true;

  late Position position;
  late String address;

  int samplingSelfStockMaxQtyAllowed = 0;

  List<Map<String, dynamic>> _cartItems = [];

  DatabaseHelper databaseHelper = DatabaseHelper();
  LocationService locationService = LocationService();
  ToastMessage toastMessage = ToastMessage();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);

    _fetchSamplingSelfStockMaxQtyAllowed();
    _fetchCartDetails();
    _fetchCartData();
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

  Future<void> _fetchCartData() async {
    final cartItems = await databaseHelper.getAllCarts();

    int itemCount = await databaseHelper.getItemCount();
    if (kDebugMode) {
      print('cartItems:${cartItems.length}');
    }
    if (kDebugMode) {
      print('itemCount:$itemCount');
    }
    setState(() {
      _cartItems =
          List.from(cartItems.map((item) => Map<String, dynamic>.from(item)));

      _tabController = TabController(length: 1, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartDetails() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    userId = await getUserId();

    try {
      _isLoading = false;
    } catch (e) {
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
      length: 1,
      child: Scaffold(
        appBar: CommonAppBar(title: widget.title),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                        Tab(text: "Sampling Titles"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabController, children: [
                      _buildTab(),
                    ]),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _submitForm();
                          },
                          child: Container(
                            width: double.infinity,
                            color: Colors.blue,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16),
                              child: CustomText(
                                'Submit',
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
    );
  }

  Widget _buildTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _cartItems.isEmpty
          ? _noDataLayout() // Replace with your no data layout widget
          : ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index]; // Get the current item
                TitleList titleList = TitleList(
                  bookId: item['BookId'],
                  title: item['Title'],
                  isbn: item['ISBN'],
                  author: item['Author'],
                  price: item['Price'],
                  listPrice: item['ListPrice'],
                  bookNum: item['BookNum'],
                  image: item['Image'],
                  bookType: item['BookType'],
                  imageUrl: item['ImageUrl'],
                  physicalStock: item['PhysicalStock'],
                  quantity: item['RequestedQty'],
                );

                return BookListItem(
                    book: titleList,
                    onQuantityChanged: (newQuantity) {
                      _handleQuantityChange(index, newQuantity);
                    },
                    areDropdownsSelected: true,
                    maxQtyAllowed: samplingSelfStockMaxQtyAllowed);
              },
            ),
    );
  }

  void _handleQuantityChange(int index, int newQuantity) {
    setState(() {
      // Create a mutable copy of the item
      Map<String, dynamic> updatedItem =
          Map<String, dynamic>.from(_cartItems[index]);

      updatedItem['RequestedQty'] = newQuantity;

      _cartItems[index] = updatedItem;
    });

    if (newQuantity == 0) {
      deleteItem(index);
    } else {
      _updateCartItem(index, newQuantity);
    }
  }

  Future<void> _updateCartItem(int index, int newQuantity) async {
    await databaseHelper.insertCartItem({
      'BookId': _cartItems[index]['BookId'],
      'SeriesId': _cartItems[index]['SeriesId'],
      'Title': _cartItems[index]['Title'],
      'ISBN': _cartItems[index]['ISBN'],
      'Author': _cartItems[index]['Author'],
      'Price': _cartItems[index]['Price'],
      'ListPrice': _cartItems[index]['ListPrice'],
      'BookNum': _cartItems[index]['BookNum'],
      'Image': _cartItems[index]['Image'],
      'BookType': _cartItems[index]['BookType'],
      'ImageUrl': _cartItems[index]['ImageUrl'],
      'PhysicalStock': _cartItems[index]['PhysicalStock'],
      'RequestedQty': newQuantity,
      'ShipTo': _cartItems[index]['ShipTo'],
      'ShippingAddress': _cartItems[index]['ShippingAddress'],
      'SamplingType': _cartItems[index]['SamplingType'],
      'SampleTo': _cartItems[index]['SampleTo'],
      'SampleGiven': _cartItems[index]['SampleGiven'],
      'MRP': _cartItems[index]['ListPrice'],
    });
  }

  Future<void> deleteItem(int index) async {
    // Delete the item from the database
    await databaseHelper.deleteCartItem(_cartItems[index]['BookId']);

    // Now remove the item from the mutable list
    setState(() {
      _cartItems.removeAt(index); // Remove from mutable list
    });
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

  void _submitForm() async {
    try {
      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print("_submitForm clicked");
        }

        String cartXml = generateCartXml(_cartItems);

        final responseData = await SelfStockSamplingService()
            .submitSelfStockSampling(
                executiveId ?? 0,
                profileCode ?? '',
                executiveId ?? 0,
                cartXml,
                widget.address,
                widget.shipToId,
                widget.shipmentModeId,
                userId ?? 0,
                widget.deliveryTradeId,
                widget.shippingInstructions,
                widget.remarks,
                token);

        if (responseData.status == 'Success') {
          String msgType = responseData.returnMessage.msgType;
          String msgText = responseData.returnMessage.msgText;
          if (kDebugMode) {
            print(msgType);
          }
          if (msgType == 's' ||
              (msgType == 'e' &&
                  msgText.toLowerCase().contains('submitted successfully'))) {
            if (kDebugMode) {
              print(
                  'Submit self stock request msgType : $msgType, msgText : $msgText');
            }
            toastMessage.showInfoToastMessage(msgText);

            databaseHelper.deleteAllCartItems();
            databaseHelper.deleteAllFollowUpActionCarts();

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
              );
            }
          } else if (msgType == 'e') {
            if (kDebugMode) {
              print(
                  'Submit self stock request msgType : $msgType, msgText : $msgText');
            }
            toastMessage.showInfoToastMessage(msgText);
          } else {
            if (kDebugMode) {
              print('Submit self stock request $msgType');
            }
            toastMessage.showToastMessage(
                "An error occurred submit self stock request.");
          }
        } else {
          if (kDebugMode) {
            print('Submit self stock request error ${responseData.status}');
          }
          toastMessage.showToastMessage(
              "An error occurred while submit self stock request.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to submit self stock request : $e");
        }
        toastMessage.showToastMessage(
            "An error occurred while submit self stock request.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to submit self stock request: $e");
      }
      toastMessage.showToastMessage(
          "An error occurred while submit self stock request.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String generateCartXml(List<Map<String, dynamic>> cartItems) {
    // Start building the XML string
    String xmlString = "<DocumentElement>";

    // Loop through each item in the cart
    for (var item in cartItems) {
      xmlString += "<SelfStockRequestDetails>"
          "<SubjectId>0</SubjectId>"
          "<SeriesId>${item['SeriesId']}</SeriesId>"
          "<BookId>${item['BookId']}</BookId>"
          "<RequestedQty>${item['RequestedQty'].toString().padLeft(2, '0')}</RequestedQty>"
          "</SelfStockRequestDetails>";
    }

    // Close the XML root element
    xmlString += "</DocumentElement>";

    return xmlString;
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }
}
