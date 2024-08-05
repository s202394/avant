import 'package:avant/api/api_request.dart';
import 'package:avant/model/request.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/error_layout.dart';
import 'package:flutter/material.dart';

class SelfStockRequestApprovalForm extends StatefulWidget {
  @override
  _SelfStockRequestApprovalFormState createState() =>
      _SelfStockRequestApprovalFormState();
}

class _SelfStockRequestApprovalFormState
    extends State<SelfStockRequestApprovalForm> {
  late Future<List<Request>> futureRequests;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    futureRequests = fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Self Stock Request Approval'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: Center(
        child: FutureBuilder<List<Request>>(
          future: futureRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              hasData = false;
              return ErrorLayout();
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              hasData = false;
              return NoDataLayout(); // Replace with your no data layout widget
            } else if (snapshot.hasData) {
              hasData = true;
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return RequestCard(request: snapshot.data![index]);
                },
              );
            }

            hasData = false;
            return Text("Unexpected state");
          },
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: hasData,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle approve action
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Approve'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle reject action
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Request request;

  RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Request No: ${request.requestNo}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Executive Name: ${request.executiveName}'),
            Text('Request Date: ${request.requestDate}'),
            Text('Request Status: ${request.requestStatus}'),
            Text('Last Approval By: ${request.lastApprovalBy}'),
            Text('Approval Date: ${request.approvalDate}'),
          ],
        ),
      ),
    );
  }
}
