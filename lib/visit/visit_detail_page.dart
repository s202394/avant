import 'package:flutter/material.dart';

class VisitDetailsPage extends StatelessWidget {
  final String schoolName;
  final String address;
  final String visitDate;
  final String visitBy;
  final String visitPurpose;
  final String jointVisit;
  final String personMet;
  final List<Map<String, String>> samples;
  final String followUpAction;
  final String followUpDate;
  final String visitFeedback;

  VisitDetailsPage({
    required this.schoolName,
    required this.address,
    required this.visitDate,
    required this.visitBy,
    required this.visitPurpose,
    required this.jointVisit,
    required this.personMet,
    required this.samples,
    required this.followUpAction,
    required this.followUpDate,
    required this.visitFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFF8E1),
        title: Text('Last Visit Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schoolName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(address),
            SizedBox(height: 16.0),
            Text('Visit Date: $visitDate'),
            Text('Visit By: $visitBy'),
            Text('Visit Purpose: $visitPurpose'),
            Text('Joint Visit: $jointVisit'),
            Text('Person Met: $personMet'),
            SizedBox(height: 16.0),
            Text('Sampling Done:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (var sample in samples)
              Text('${sample['name']} - ${sample['subject']} (${sample['type']}) Qty: ${sample['quantity']}'),
            SizedBox(height: 16.0),
            Text('Follow Up Action:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Action for: $followUpAction'),
            Text('Target Date: $followUpDate'),
            SizedBox(height: 16.0),
            Text('Visit Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(visitFeedback),
          ],
        ),
      ),
    );
  }
}