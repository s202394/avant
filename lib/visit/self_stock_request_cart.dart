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

    getAddressData();

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
        appBar: AppBar(
          backgroundColor: Colors.amber[100],
          title: Text(widget.title),
        ),
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
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
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
                              child: Text(
                                'Submit',
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

        List<Map<String, dynamic>> followUpActionCarts =
            await databaseHelper.getAllFollowUpActionCarts();
        String followUpActionXML = getFollowUpActions(followUpActionCarts);

        List<Map<String, dynamic>> generateSampleGivenCartList =
            await databaseHelper.getCartItemsWithSampleGiven("Sample Given");
        String generateSampleGivenCartXML =
            generateCartXmlSampleGiven(generateSampleGivenCartList);
        List<Map<String, dynamic>> generateToBeDispatchedCartList =
            await databaseHelper
                .getCartItemsWithSampleGiven("To Be Dispatched");
        String generateToBeDispatchedCartXML =
            generateCartXmlSampleGiven(generateToBeDispatchedCartList);

        int itemCount = await databaseHelper.getItemCount();
        double totalPrice = await databaseHelper.getTotalPrice();

        final responseData = await VisitEntryService().visitEntry(
            executiveId ?? 0,
            '',
            0,
            executiveId ?? 0,
            address,
            profileCode ?? '',
            position.latitude,
            position.longitude,
            1,
            '',
            '',
            0,
            0,
            '',
            "",
            "",
            "",
            "",
            "",
            totalPrice,
            itemCount,
            userId ?? 0,
            followUpActionXML,
            generateSampleGivenCartXML,
            'No',
            "",
            "",
            false,
            "",
            generateToBeDispatchedCartXML,
            token);

        if (responseData.status == 'Success') {
          String s = responseData.s;
          if (kDebugMode) {
            print(s);
          }
          if (s.isNotEmpty) {
            if (kDebugMode) {
              print('Add Visit DSR Error s not empty');
            }
            toastMessage.showInfoToastMessage(s);

            databaseHelper.deleteAllCartItems();
            databaseHelper.deleteAllFollowUpActionCarts();

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
              );
            }
          } else if (responseData.e.isNotEmpty) {
            if (kDebugMode) {
              print('Add Visit DSR Error e not empty');
            }
            toastMessage.showToastMessage(responseData.e);
          } else {
            if (kDebugMode) {
              print('Add Visit DSR Error s & e empty');
            }
            toastMessage
                .showToastMessage("An error occurred while adding visit.");
          }
        } else {
          if (kDebugMode) {
            print('Add Visit DSR Error ${responseData.status}');
          }
          toastMessage
              .showToastMessage("An error occurred while adding visit.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to add DSR entry: $e");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to add DSR entry from cart: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getFollowUpActions(List<Map<String, dynamic>> followUpActionCarts) {
    // Start building the XML string
    String followUpActionsXml = "<DocumentElement>";

    // Loop through each follow-up action cart and append it to the XML string
    for (var actionCart in followUpActionCarts) {
      followUpActionsXml += "<FollowUpAction>"
          "<Department>${actionCart['DepartmentId']}</Department>"
          "<FollowUpExecutive>${actionCart['FollowUpExecutiveId']}</FollowUpExecutive>"
          "<FollowUpAction>${actionCart['FollowUpAction']}</FollowUpAction>"
          "<FollowUpDate>${actionCart['FollowUpDate']}</FollowUpDate>"
          "</FollowUpAction>";
    }

    // Close the XML root element
    followUpActionsXml += "</DocumentElement>";

    return followUpActionsXml;
  }

  String generateCartXmlToBeDispatched(List<Map<String, dynamic>> cartItems) {
    // Start building the XML string
    String xmlString = "<DocumentElement>";

    // Loop through each item in the cart
    for (var item in cartItems) {
      xmlString += "<CustomerSamplingRequestDetails>"
          "<SeriesId>${item['SeriesId']}</SeriesId>"
          "<BookId>${item['BookId']}</BookId>"
          "<RequestedQty>${item['RequestedQty'].toString().padLeft(2, '0')}</RequestedQty>"
          "<ShipTo>${item['ShipTo']}</ShipTo>"
          "<ShippingAddress>${item['ShippingAddress']}</ShippingAddress>"
          "<SamplingType>${item['SamplingType']}</SamplingType>"
          "<SampleTo>${item['SampleTo']}</SampleTo>"
          "<SampleGiven>${item['SampleGiven']}</SampleGiven>"
          "<MRP>${item['MRP']}</MRP>"
          "</CustomerSamplingRequestDetails>";
    }

    // Close the XML root element
    xmlString += "</DocumentElement>";

    return xmlString;
  }

  String generateCartXmlSampleGiven(List<Map<String, dynamic>> cartItems) {
    // Start building the XML string
    String xmlString = "<DocumentElement>";

    // Loop through each item in the cart
    for (var item in cartItems) {
      xmlString += "<CustomerSamplingRequestDetails>"
          "<SeriesId>${item['SeriesId']}</SeriesId>"
          "<BookId>${item['BookId']}</BookId>"
          "<RequestedQty>${item['RequestedQty'].toString().padLeft(2, '0')}</RequestedQty>"
          "<ShipTo>${item['ShipTo']}</ShipTo>"
          "<ShippingAddress>${item['ShippingAddress']}</ShippingAddress>"
          "<SamplingType>${item['SamplingType']}</SamplingType>"
          "<SampleTo>${item['SampleTo']}</SampleTo>"
          "<SampleGiven>${item['SampleGiven']}</SampleGiven>"
          "<MRP>${item['MRP']}</MRP>"
          "</CustomerSamplingRequestDetails>";
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

  void getAddressData() async {
    position = await locationService.getCurrentLocation();
    if (kDebugMode) {
      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    }

    address = await locationService.getAddressFromLocation();
    if (kDebugMode) {
      print("address: $address");
    }
  }
}
