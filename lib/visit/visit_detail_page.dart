import 'package:avant/api/api_service.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/model/visit_details_model.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:avant/common/label_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitDetailsPage extends StatefulWidget {
  final int customerId;
  final int visitId;
  final bool isTodayPlan;

  VisitDetailsPage({
    required this.customerId,
    required this.visitId,
    required this.isTodayPlan,
  });

  @override
  _VisitDetailsPageState createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> {
  late Future<VisitDetailsResponse> futureVisitDetails;
  late SharedPreferences prefs;
  final ToastMessage _toastMessage = ToastMessage();

  @override
  void initState() {
    super.initState();
    futureVisitDetails = _initializeAndFetchVisitDetails();
  }

  Future<VisitDetailsResponse> _initializeAndFetchVisitDetails() async {
    prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return VisitDetailsService()
        .visitDetails(widget.customerId, widget.visitId, token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Last Visit Details'),
      ),
      body: FutureBuilder<VisitDetailsResponse>(
        future: futureVisitDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty()) {
            return Center(child: Text("No Data Found"));
          } else {
            return buildVisitDetails(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget buildVisitDetails(VisitDetailsResponse data) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              data.customerDetails?.customerName ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text(
              data.customerDetails?.address.replaceAll('<br>', '\n') ?? '',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
              textAlign: TextAlign.left, // Adjust alignment as needed
            ),
            trailing: Visibility(
              visible: widget.isTodayPlan,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DsrEntry(
                        customerId: data.customerDetails?.customerId ?? 0,
                        customerName: data.customerDetails?.customerName ?? '',
                        customerCode: '',
                        customerType: data.visitDetails?.customerType ?? '',
                        address: data.customerDetails?.address ?? '',
                        city: '',
                        state: '',
                      ),
                    ),
                  );
                },
                child: Image.asset('images/travel.png', height: 30, width: 30),
              ),
            ),
          ),
          Divider(),
          SizedBox(height: 16.0),
          LabeledText(label: 'Visit Date', value: data.visitDetails?.visitDate),
          LabeledText(
              label: 'Visit By', value: data.visitDetails?.executiveName),
          LabeledText(
              label: 'Visit Purpose', value: data.visitDetails?.visitPurpose),
          LabeledText(
              label: 'Joint Visit', value: data.visitDetails?.jointVisitWith),
          LabeledText(label: 'Person Met', value: data.visitDetails?.personMet),
          SizedBox(height: 16.0),
          Visibility(
            visible: data.promotionalDetails != null &&
                data.promotionalDetails!.isNotEmpty,
            child: Column(
              children: [
                Text('Sampling Done:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                for (var sample in data.promotionalDetails ?? [])
                  Text(
                      '${sample.title} - ${sample.samplingType} (${sample.isbn}) Qty: ${sample.requestedQty}'),
                SizedBox(height: 16.0),
              ],
            ),
          ),
          Text('Visit Feedback:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(data.visitDetails?.visitFeedback ?? ''),
        ],
      ),
    );
  }
}
