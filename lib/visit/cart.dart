import 'package:avant/db/db_helper.dart';
import 'package:avant/views/custom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/common.dart';
import '../common/common_text.dart';
import '../common/toast.dart';
import '../home.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../model/self_stock_request_response.dart';
import '../service/location_service.dart';
import '../views/book_list_item.dart';
import '../views/common_app_bar.dart';
import '../views/rich_text.dart';

class Cart extends StatefulWidget {
  final String type;
  final String title;
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
  final String fileName;

  const Cart({
    super.key,
    required this.type,
    required this.title,
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
    required this.fileName,
  });

  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> with TickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _shippingInstructionsController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  int? userId;

  bool _isLoading = false;

  late Position position;
  late String address;

  List<Map<String, dynamic>> _seriesItems = [];
  List<Map<String, dynamic>> _titleItems = [];

  final DetailText _detailText = DetailText();
  DatabaseHelper databaseHelper = DatabaseHelper();
  LocationService locationService = LocationService();
  ToastMessage toastMessage = ToastMessage();

  late Future<SelfStockRequestResponse> _selfStockRequestData;

  int tabCount = 0;

  String? selectedShipmentMode;
  int? selectedShipmentModeId;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 0, vsync: this);

    getAddressData();

    _fetchCartData();

    _selfStockRequestData = _fetchSelfStockData();
  }

  Future<SelfStockRequestResponse> _fetchSelfStockData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    userId = await getUserId();

    return await SelfStockRequestService().getSelfStockRequest(token);
  }

  Future<void> _fetchCartData() async {
    final seriesItems = await databaseHelper.getCartItemsWithSeries();
    final titleItems = await databaseHelper.getCartItemsWithTitle();

    setState(() {
      _titleItems = titleItems;
      setState(() {
        _seriesItems = List.from(seriesItems.map((item) => Map<String, dynamic>.from(item))); // Make a mutable copy
      });

      tabCount = 0; // Reset tabCount to avoid old values.

      if (widget.samplingDone && _seriesItems.isNotEmpty) {
        tabCount++;
      }
      if (widget.samplingDone && _titleItems.isNotEmpty) {
        tabCount++;
      }
      if (widget.followUpAction) {
        tabCount++;
      }

      // Dispose the old controller only if it exists to avoid disposing uninitialized controllers.
      _tabController.dispose();

      // Initialize a new TabController based on the new tab count.
      _tabController =
          TabController(length: tabCount > 0 ? tabCount : 1, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: CommonAppBar(title: widget.title),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_tabController == null)
                ? const Center(child: Text('Loading...')) // Loading placeholder
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
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            RichTextWidget(label: widget.address),
                            Visibility(
                              visible: widget.type == 'Visit',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
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
                            tabs: _tabs()),
                      ),
                      Expanded(
                        child: TabBarView(
                            controller: _tabController,
                            children: _tabsAction()),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.type == 'Visit') {
                                  _submitVisitForm();
                                } else {
                                  openDialog(context);
                                }
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

  List<Widget> _tabs() {
    List<Widget> list = [];
    if (widget.samplingDone && _seriesItems.isNotEmpty) {
      list.add(const Tab(text: 'Series/ Title'));
    }
    if (widget.samplingDone && _titleItems.isNotEmpty) {
      list.add(const Tab(text: 'Title wise'));
    }
    if (widget.followUpAction) {
      list.add(const Tab(text: 'Follow Up Action'));
    }
    return list;
  }

  List<Widget> _tabsAction() {
    List<Widget> list = [];
    if (widget.samplingDone && _seriesItems.isNotEmpty) {
      list.add(_buildSeriesTitleTab());
    }
    if (widget.samplingDone && _titleItems.isNotEmpty) {
      list.add(_buildTitleWiseTab());
    }
    if (widget.followUpAction) {
      list.add(_buildFollowUpActionTab());
    }
    return list;
  }

  Widget _buildSeriesTitleTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _seriesItems.isEmpty
          ? _noDataLayout() // Replace with your no data layout widget
          : ListView.builder(
        itemCount: _seriesItems.length,
        itemBuilder: (context, index) {
          final item = _seriesItems[index]; // Get the current item
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
            quantity: item['RequestedQty'], // Current quantity
          );

          return BookListItem(
            book: titleList,
            onQuantityChanged: (newQuantity) {
              _handleQuantityChange(index, newQuantity);
            },
            areDropdownsSelected: true,
          );
        },
      ),
    );
  }

  void _handleQuantityChange(int index, int newQuantity) {
    setState(() {
      // Create a mutable copy of the item
      Map<String, dynamic> updatedItem = Map<String, dynamic>.from(_seriesItems[index]);

      updatedItem['RequestedQty'] = newQuantity; // Update the quantity

      // Update the books list with the modified item
      _seriesItems[index] = updatedItem; // Assign the updated item back to the list
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
      'BookId': _seriesItems[index]['BookId'],
      'SeriesId': _seriesItems[index]['SeriesId'],
      'Title': _seriesItems[index]['Title'],
      'ISBN': _seriesItems[index]['ISBN'],
      'Author': _seriesItems[index]['Author'],
      'Price': _seriesItems[index]['Price'],
      'ListPrice': _seriesItems[index]['ListPrice'],
      'BookNum': _seriesItems[index]['BookNum'],
      'Image': _seriesItems[index]['Image'],
      'BookType': _seriesItems[index]['BookType'],
      'ImageUrl': _seriesItems[index]['ImageUrl'],
      'PhysicalStock': _seriesItems[index]['PhysicalStock'],
      'RequestedQty': newQuantity,
      'ShipTo': _seriesItems[index]['ShipTo'],
      'ShippingAddress': _seriesItems[index]['ShippingAddress'],
      'SamplingType': _seriesItems[index]['SamplingType'],
      'SampleTo': _seriesItems[index]['SampleTo'],
      'SampleGiven': _seriesItems[index]['SampleGiven'],
      'MRP': _seriesItems[index]['ListPrice'],
    });
  }

  Future<void> deleteItem(int index) async {
    // Delete the item from the database
    await databaseHelper.deleteCartItem(_seriesItems[index]['BookId']);

    // Now remove the item from the mutable list
    setState(() {
      _seriesItems.removeAt(index); // Remove from mutable list
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

  Widget _buildTitleWiseTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _titleItems.map((item) {
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

  Widget _buildFollowUpActionTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: databaseHelper.getAllFollowUpActionCarts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No follow-up actions found.'));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                    4: FixedColumnWidth(48.0),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Date'),
                        _buildTableHeader('Executive'),
                        _buildTableHeader('Department'),
                        _buildTableHeader('Follow Up Action'),
                        _buildTableHeader(''),
                      ],
                    ),
                    ...data.map(
                      (row) {
                        final id = row['Id'] as int?;
                        return TableRow(
                          children: [
                            _buildTableCell(row['FollowUpDate']),
                            _buildTableCell(row['FollowUpExecutive']),
                            _buildTableCell(row['Department']),
                            _buildTableCell(row['FollowUpAction']),
                            _buildTableCellAction(id, _deleteFollowUpAction),
                            // Action cell
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFollowUpAction(int id) async {
    databaseHelper.deleteFollowUpActionCart(id);

    // Refresh the data after deletion
    _fetchCartData();
    setState(() {});
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(dynamic value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(value?.toString() ?? ''),
    );
  }

  Widget _buildTableCellAction(dynamic id, Function(int) onDelete) {
    if (id == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          onDelete(id as int);
        },
      ),
    );
  }

  void _submitVisitForm() async {
    try {
      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print("_submitVisitForm clicked");
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

        int totalRequestedQty = await databaseHelper.getTotalRequestedQty();
        double totalPrice = await databaseHelper.getTotalPrice();

        String uploadedDocumentXML =
            "<DocumentElement><UploadedDocument><DocumentName>${widget.fileName}</DocumentName><FileName>${widget.fileName}</FileName><FileSize>89135</FileSize></UploadedDocument></DocumentElement>";

        final responseData = await VisitEntryService().visitEntry(
            executiveId ?? 0,
            widget.customerType,
            widget.customerId,
            executiveId ?? 0,
            address,
            profileCode ?? '',
            position.latitude,
            position.longitude,
            1,
            widget.visitFeedback,
            widget.visitDate,
            widget.visitPurposeId,
            widget.personMetId,
            widget.jointVisitWithIds,
            uploadedDocumentXML,
            "",
            "",
            "",
            "",
            totalPrice,
            totalRequestedQty,
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

  void _submitSamplingForm() async {
    try {
      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print("_submitSamplingForm clicked");
        }

        List<Map<String, dynamic>> generateCartList = [];
        generateCartList.addAll(_seriesItems);
        generateCartList.addAll(_titleItems);
        String cartXML = generateCartXmlSampling(generateCartList);

        int itemCount = await databaseHelper.getItemCount();
        double totalPrice = await databaseHelper.getTotalPrice();

        final responseData = await CustomerSamplingService()
            .submitCustomerSampling(
                widget.customerId,
                executiveId ?? 0,
                profileCode ?? '',
                executiveId ?? 0,
                cartXML,
                widget.customerType,
                _remarksController.text,
                _shippingInstructionsController.text,
                selectedShipmentModeId ?? 0,
                totalPrice,
                itemCount,
                userId ?? 0,
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
                  'Submit sampling request msgType : $msgType, msgText : $msgText');
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
                  'Submit sampling request msgType : $msgType, msgText : $msgText');
            }
            toastMessage.showInfoToastMessage(msgText);
          } else {
            if (kDebugMode) {
              print('Submit sampling request $msgType');
            }
            toastMessage
                .showToastMessage("An error occurred submit sampling request.");
          }
        } else {
          if (kDebugMode) {
            print('Submit sampling request error ${responseData.status}');
          }
          toastMessage.showToastMessage(
              "An error occurred while submit sampling request.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to sending sampling request : $e");
        }
        toastMessage.showToastMessage(
            "An error occurred while submit sampling request.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to submit sampling request: $e");
      }
      toastMessage
          .showToastMessage("An error occurred while submit sampling request.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String generateCartXmlSampling(List<Map<String, dynamic>> cartItems) {
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
          "<MRP>${item['MRP']}</MRP>"
          "</CustomerSamplingRequestDetails>";
    }

    // Close the XML root element
    xmlString += "</DocumentElement>";

    return xmlString;
  }

  void openDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<SelfStockRequestResponse>(
                future: _selfStockRequestData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No data found'));
                  }

                  final selfStockRequestData = snapshot.data!;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Dropdown field for shipment mode
                      _buildDropdownField(
                        'Shipment Mode',
                        selectedShipmentMode,
                        {
                          for (var item in selfStockRequestData.shipmentMode)
                            item.shipmentMode: item.shipmentModeId,
                        },
                        (value) =>
                            _onShipmentModeChanged(value, selfStockRequestData),
                      ),
                      _buildTextField(
                        'Shipping Instructions',
                        _shippingInstructionsController,
                        maxLines: 3,
                      ),
                      _buildTextField('Remarks', _remarksController,
                          maxLines: 3),
                      const SizedBox(height: 8.0),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Center(
                              child: ElevatedButton(
                                onPressed: () async {
                                  submitSamplingRequest();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlueAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0, vertical: 12.0),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Builds a Dropdown Field with validation
  Widget _buildDropdownField(String label, String? selectedValue,
      Map<String, int> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          labelStyle: const TextStyle(fontSize: 14),
          border: const OutlineInputBorder(),
        ),
        value: selectedValue,
        items: items.keys.map((key) {
          return DropdownMenuItem<String>(
            value: key,
            child: CustomText(key),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool enabled = true,
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: textFontSize),
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
          labelStyle: TextStyle(fontSize: labelFontSize),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        ),
      ),
    );
  }

  // Handles Shipment Mode Change
  void _onShipmentModeChanged(
      String? value, SelfStockRequestResponse response) {
    setState(() {
      selectedShipmentMode = value;
      selectedShipmentModeId = response.shipmentMode
          .firstWhere((item) => item.shipmentMode == value)
          .shipmentModeId;
    });
  }

  void submitSamplingRequest() {
    if (selectedShipmentMode == null) {
      toastMessage.showToastMessage('Please select Shipment Mode');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();

      _submitSamplingForm();
    }
  }
}
