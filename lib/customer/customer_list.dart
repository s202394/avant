import 'package:avant/api/api_service.dart';
import 'package:avant/model/customer_list_model.dart';
import 'package:avant/customer/new_customer_school_form1.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/common.dart';
import '../common/common_text.dart';
import '../common/toast.dart';
import '../common/utils.dart';
import '../model/login_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';
import '../views/rich_text.dart';
import 'new_customer_trade_library_form1.dart';

class CustomerList extends StatefulWidget {
  final String type;

  const CustomerList({super.key, required this.type});

  @override
  CustomerListState createState() => CustomerListState();
}

class CustomerListState extends State<CustomerList> {
  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late int? userId;
  late String? profileCode;
  late String downHierarchy;

  bool _hasError = false;

  ToastMessage toastMessage = ToastMessage();

  List<CommonCustomerList> customerList = [];
  int pageNumber = 1;
  final int pageSize = 10;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    downHierarchy = prefs.getString('DownHierarchy') ?? '';
    userId = await getUserId() ?? 0;
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    await _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
      _hasError = false; // Reset error state before fetching
    });

    try {
      // Check network connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No Internet Connection');
      }

      if (widget.type == 'School') {
        var response = await CustomerListService().customerList(
          pageSize,
          pageNumber,
          widget.type,
          profileCode ?? '',
          "",
          "",
          token,
        );
        setState(() {
          customerList.addAll(response.customerList
              .map((e) => CommonCustomerList.fromSchool(e)));
          hasMore = response.customerList.length == pageSize;
          pageNumber++;
        });
      } else {
        var response = await CustomerListService().customerTradeList(
          pageSize,
          pageNumber,
          widget.type,
          profileCode ?? '',
          "",
          "",
          token,
        );
        setState(() {
          customerList.addAll(response.customerList
              .map((e) => CommonCustomerList.fromTrade(e)));
          hasMore = response.customerList.length == pageSize;
          pageNumber++;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true; // Set error state
      });
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: CommonAppBar(title: '${widget.type} List'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              CustomText(
                'Failed to load ${widget.type.toLowerCase()} data. Please try again.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _fetchCustomerData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(title: '${widget.type} List'),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              hasMore &&
              !isLoading) {
            _fetchCustomerData();
          }
          return true;
        },
        child: customerList.isEmpty && !isLoading
            ? const Center(
                child: Text('No customers found.'),
              )
            : ListView.builder(
                itemCount: customerList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == customerList.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  var customer = customerList[index];
                  return _buildCustomerTile(customer);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addCustomer();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerTile(CommonCustomerList customer) {
    return Column(
      children: [
        ListTile(
          title: CustomText(customer.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichTextWidget(label: customer.address.trim()),
              Visibility(
                visible: customer.refCode.isNotEmpty,
                child: DetailText().buildDetailText(
                    'RefCode: ', customer.refCode,
                    labelFontSize: 14, valueFontSize: 12),
              ),
              DetailText().buildDetailText(
                  'Validation Status: ', customer.validationStatus,
                  labelFontSize: 14, valueFontSize: 12),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (kDebugMode) {
                    print('Edit tapped');
                  }
                  editCustomer(customer);
                },
                child: const Icon(Icons.edit, size: 30, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  deleteCustomerDialog(customer);
                },
                child: const Icon(Icons.delete, size: 30, color: Colors.red),
              ),
            ],
          ),
          onTap: () {},
        ),
        const Divider(),
      ],
    );
  }

  void deleteCustomer(CommonCustomerList customer) async {
    try {
      if (!await _checkInternetConnection()) return;

      int customerId = extractNumericPart(customer.action);
      String validated = extractStringPart(customer.action);

      final responseData = await DeleteCustomerService().deleteCustomer(
          executiveId ?? 0, customerId, userId ?? 0, validated, "", token);

      if (responseData.status == 'Success') {
        String message = responseData.returnMessage?.msgText ?? '';

        if (kDebugMode) {
          print(message);
        }

        // Show a success toast
        toastMessage.showInfoToastMessage(message);

        // Remove the customer from the local list and refresh the UI
        setState(() {
          customerList.remove(customer);
          if (customerList.isEmpty) {
            // Optionally, reset pagination and re-fetch data if list becomes empty
            pageNumber = 1;
            hasMore = true;
            _fetchCustomerData();
          }
        });
      } else {
        toastMessage
            .showToastMessage("An error occurred while deleting the customer.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete customer error: $e');
      }
      toastMessage.showToastMessage("An error occurred: $e");
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  void deleteCustomerDialog(CommonCustomerList customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete ${widget.type.toLowerCase()}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (kDebugMode) {
                  print('Delete confirmed');
                }
                deleteCustomer(customer);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void addCustomer() async {
    if (!await _checkInternetConnection()) return;
    if (widget.type == 'Trade') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                NewCustomerTradeLibraryForm1(type: widget.type)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NewCustomerSchoolForm1(type: widget.type)),
      );
    }
  }

  void editCustomer(CommonCustomerList customer) async {
    if (!await _checkInternetConnection()) return;
    if (widget.type == 'Trade' || widget.type == 'Library') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NewCustomerTradeLibraryForm1(
                type: widget.type, isEdit: true, action: customer.action)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NewCustomerSchoolForm1(
                type: widget.type, isEdit: true, action: customer.action)),
      );
    }
  }
}
