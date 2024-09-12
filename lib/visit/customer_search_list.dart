import 'package:avant/visit/sampling_series_search.dart';
import 'package:avant/visit/visit_detail_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/login_model.dart';
import '../model/search_customer_result_response.dart';
import '../views/rich_text.dart';
import 'dsr_entry.dart';

class CustomerSearchList extends StatefulWidget {
  final String type;
  final String title;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String contactName;
  final String cityId;
  final String cityName;
  final String customerType;

  const CustomerSearchList({
    super.key,
    required this.type,
    required this.title,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.contactName,
    required this.cityId,
    required this.cityName,
    required this.customerType,
  });

  @override
  CustomerSearchListPageState createState() => CustomerSearchListPageState();
}

class CustomerSearchListPageState extends State<CustomerSearchList> {
  late Future<SearchCustomerResultResponse> _customerData;
  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late String downHierarchy;

  @override
  void initState() {
    super.initState();
    _customerData = _fetchCustomerData();
  }

  Future<SearchCustomerResultResponse> _fetchCustomerData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      downHierarchy = prefs.getString('DownHierarchy') ?? '';
    });
    executiveId = await getExecutiveId();

    // Check network connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No Internet Connection');
    }

    // Call your API service
    try {
      var response = await SearchCustomerResultService().searchCustomerResult(
        executiveId ?? 0,
        downHierarchy,
        widget.customerName,
        widget.cityId,
        widget.customerType,
        widget.customerCode,
        widget.contactName,
        token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        title: Text(widget.title),
      ),
      body: FutureBuilder<SearchCustomerResultResponse>(
        future: _customerData,
        builder: (context, snapshot) {
          // Show loader while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          else if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Handle empty data state
          else if (!snapshot.hasData || snapshot.data!.result.isEmpty) {
            return const Center(child: Text('No Data Available'));
          }

          // Build the list once data is available
          return ListView.builder(
            itemCount: snapshot.data!.result.length,
            itemBuilder: (context, index) {
              var customer = snapshot.data!.result[index];
              return Column(
                children: [
                  ListTile(
                    title: Text(customer.customerName),
                    subtitle: RichTextWidget(
                      label: customer.address,
                    ),
                    trailing: InkWell(
                      onTap: () {
                        if (widget.type == 'Visit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DsrEntry(
                                customerId: customer.customerId,
                                customerName: customer.customerName,
                                customerCode: '',
                                customerType: customer.customerType,
                                address: customer.address,
                                city: '',
                                state: '',
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SamplingSeriesSearch(
                                type: widget.type,
                                title: widget.title,
                                customerId: customer.customerId,
                                customerName: customer.customerName,
                                customerCode: '',
                                customerType: customer.customerType,
                                address: customer.address,
                              ),
                            ),
                          );
                        }
                      },
                      child: Image.asset(
                          widget.type == 'Visit'
                              ? 'images/travel.png'
                              : 'images/ic_book.png',
                          height: 30,
                          width: 30),
                    ),
                    onTap: () {
                      if (widget.type == 'Visit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitDetailsPage(
                              customerId: customer.customerId,
                              visitId: 0,
                              isTodayPlan: true,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
