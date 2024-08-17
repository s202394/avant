import 'package:flutter/material.dart';
import 'package:avant/visit/visit_detail_page.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:avant/visit/visit_series_search.dart';
import 'package:intl/intl.dart';

class CustomerSearchVisitList extends StatefulWidget {
  final String? customerName;
  final String? customerCode;
  final String? principalName;
  final String? city;
  final int? cityId;

  CustomerSearchVisitList(
      {required this.customerName,
        required this.customerCode,
        required this.principalName,
        required this.city,
        required this.cityId,
      });

  @override
  _CustomerSearchVisitListPageState createState() =>
      _CustomerSearchVisitListPageState();
}

class _CustomerSearchVisitListPageState extends State<CustomerSearchVisitList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFF8E1),
        title: Text('Visit DSR'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Color(0xFFF49B20),
            child: Padding(
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
                      title: Text('ASN Sr. Secondary School (SCH654)'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mayur Vihar Phase 1'),
                          Text('New Delhi - 110001'),
                          Text('Delhi'),
                        ],
                      ),
                      trailing: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisitSeriesSearch(
                                schoolName: 'ASN Sr. Secondary School (SCH654)',
                                address: 'Mayur Vihar Phase 1, New Delhi - 110001, Delhi',
                              ),
                            ),
                          );
                        },
                        child: Image.asset('images/travel.png', height: 30, width: 30),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitDetailsPage(
                              schoolName: 'ASN Sr. Secondary School (SCH654)',
                              address: 'Mayur Vihar Phase 1, New Delhi - 110001, Delhi',
                              visitDate: '16-Jun 2024',
                              visitBy: 'Sanjay Chawla',
                              visitPurpose: 'Sampling',
                              jointVisit: 'Abhishek Srivastava',
                              personMet: 'Mrs. Sonal Verma',
                              samples: [
                                {
                                  'name': 'Mrs. S. Banerjee',
                                  'subject': 'English',
                                  'type': 'Promotional Copy',
                                  'quantity': '1'
                                },
                                {
                                  'name': 'Mr. Sanjeev Singh',
                                  'subject': 'Maths',
                                  'type': 'Promotional Copy',
                                  'quantity': '1'
                                },
                              ],
                              followUpAction: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                              followUpDate: '30 Jun 24',
                              visitFeedback: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut elit tellus, luctus nec ullamcorper mattis, pulvinar dapibus leo.',
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(), // Add Divider here
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