import 'package:avant/visit/visit_detail_page.dart';
import 'package:avant/visit/visit_series_search.dart';
import 'package:flutter/material.dart';

import '../views/rich_text.dart';

class CustomerSearchVisitList extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;

  const CustomerSearchVisitList({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    required this.city,
    required this.state,
  });

  @override
  CustomerSearchVisitListPageState createState() =>
      CustomerSearchVisitListPageState();
}

class CustomerSearchVisitListPageState extends State<CustomerSearchVisitList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text('Visit DSR'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF49B20),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Text(
                'Search Costumer - Visit',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        widget.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: RichTextWidget(label: widget.address),
                      trailing: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisitSeriesSearch(
                                customerId: widget.customerId,
                                customerName: widget.customerName,
                                customerCode: widget.customerCode,
                                customerType: widget.customerType,
                                address: widget.address,
                                city: widget.city,
                                state: widget.state,
                                visitFeedback: '',
                                visitDate: '',
                                visitPurposeId: 0,
                                jointVisitWithIds: '',
                                samplingDone: false,
                                followUpAction: false,
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
                            builder: (context) => const VisitDetailsPage(
                              customerId: 0,
                              visitId: 0,
                              isTodayPlan: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(), // Add Divider here
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
