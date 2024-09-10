import 'package:avant/visit/visit_detail_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../model/login_model.dart';
import '../model/search_customer_result_response.dart';
import '../views/rich_text.dart';
import 'dsr_entry.dart';

class CustomerSearchVisitList extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String contactName;
  final String cityId;
  final String cityName;

  const CustomerSearchVisitList({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.contactName,
    required this.cityId,
    required this.cityName,
  });

  @override
  CustomerSearchVisitListPageState createState() =>
      CustomerSearchVisitListPageState();
}

class CustomerSearchVisitListPageState extends State<CustomerSearchVisitList> {
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
        'school',
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
        title: const Text('Visit DSR'),
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
                      },
                      child: Image.asset('images/travel.png',
                          height: 30, width: 30),
                    ),
                    onTap: () {
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
