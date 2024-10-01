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

  List<Map<String, dynamic>> _cartItems = [];

  DatabaseHelper databaseHelper = DatabaseHelper();
  LocationService locationService = LocationService();
  ToastMessage toastMessage = ToastMessage();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);

    _fetchCartDetails();
    _fetchCartData();
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
      _cartItems = cartItems;

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
    if (kDebugMode) {
      print('_cartItems : ${_cartItems.length}');
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _cartItems.map((item) {
            final titleList = TitleList(
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
              onQuantityChanged: (quantity) {
                setState(() {
                  item['RequestedQty'] = quantity;
                });
              },
              areDropdownsSelected: true,
            );
          }).toList(),
        ),
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

        List<Map<String, dynamic>> generateCartList =
            await databaseHelper.getAllCarts();
        String cartXml = generateCartXml(generateCartList);

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
                token);

        if (responseData.status == 'Success') {
          String msgType = responseData.returnMessage.msgType;
          String msgText = responseData.returnMessage.msgText;
          if (kDebugMode) {
            print(msgType);
          }
          if (msgType == 's' ||
              (msgType == 'e' && msgText.toLowerCase().contains('submitted successfully'))) {
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
