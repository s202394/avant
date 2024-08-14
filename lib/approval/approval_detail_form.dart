import 'package:avant/api/api_service.dart';
import 'package:avant/common/error_layout.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/home.dart';
import 'package:avant/model/customer_sampling_approval_details_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApprovalDetailForm extends StatefulWidget {
  final String type;
  final int requestId;
  final int customerId;
  final String customerType;

  ApprovalDetailForm({
    required this.type,
    required this.requestId,
    required this.customerId,
    required this.customerType,
  });

  @override
  _ApprovalDetailFormState createState() => _ApprovalDetailFormState();
}

class _ApprovalDetailFormState extends State<ApprovalDetailForm> {
  late Future<CustomerSamplingApprovalDetailsResponse> futureRequestDetails;

  List<TitleDetails> _titleDetails = [];

  final ToastMessage _toastMessage = ToastMessage();

  late String token;
  late int? executiveId;
  late int? userId;
  late String downHierarchy;
  late String? profileCode;

  bool hasData = false;
  bool isLoading = true;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      token = prefs.getString('token') ?? '';
      downHierarchy = prefs.getString('DownHierarchy') ?? '';
    });

    userId = await getUserId();
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
        isLoading = false;
      });
    } else {
      setState(() {
        isConnected = true;
        isLoading = true;
        futureRequestDetails = CustomerSamplingApprovalDetailsService()
            .fetchCustomerSamplingApprovalDetails(
                widget.customerId,
                widget.customerType,
                widget.requestId,
                "CustomerSampling",
                token)
            .then((response) {
          setState(() {
            hasData = response?.titleDetails?.isNotEmpty ?? false;
            _titleDetails = response.titleDetails ?? [];
            print('_titleDetails size:${_titleDetails.length}');
            isLoading = false;
          });
          return response ?? CustomerSamplingApprovalDetailsResponse();
        }).catchError((error) {
          setState(() {
            isLoading = false;
            hasData = false;
          });
          print("Error occurred: $error");
          return CustomerSamplingApprovalDetailsResponse();
        });
      });
    }
  }

  void _handleRequest(BuildContext context, String type,
      List<TitleDetails> titleDetailsList) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    print('titleDetailsList size:${titleDetailsList.length}');

    try {
      // Call the method and pass necessary parameters
      final response = await SubmitCustomerSamplingRequestApprovalService()
          .submitCustomerSamplingRequestApproved(
        "Single",
        type,
        profileCode ?? "",
        "${executiveId ?? 0}",
        "$userId",
        "${widget.requestId}",
        generateTitleDetailsXML(titleDetailsList),
        "",
        token,
      );

      // Close the loading indicator
      Navigator.of(context).pop();

      print('Approval successful: ${response.returnMessage.msgText}');
      if (response.status == 'Success') {
        String s = response.returnMessage.msgText;
        if (s.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
          );
        } else {
          print('$type Customer Sample Approval Error s empty');
          _toastMessage.showToastMessage(
              "An error occurred while $type customer sampling request.");
        }
      } else {
        print('Add Customer Sample Approval Error ${response.status}');
        _toastMessage.showToastMessage(
            "An error occurred while $type customer sampling request.");
      }
    } catch (error) {
      // Close the loading indicator
      Navigator.of(context).pop();

      // Handle the error (e.g., show error message)
      print('Failed to approve: $error');
      _toastMessage.showToastMessage(
          "An error occurred while $type customer sampling request.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.type} Approval'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : isConnected
                ? FutureBuilder<CustomerSamplingApprovalDetailsResponse>(
                    future: futureRequestDetails,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return ErrorLayout();
                      } else if (!hasData) {
                        return NoDataLayout();
                      } else if (snapshot.hasData) {
                        var response = snapshot.data!;
                        return ListView(
                          padding: EdgeInsets.all(16.0),
                          children: [
                            ListTile(
                              title: Text(
                                'Request Details',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailText(
                                    'Request No: ',
                                    response.requestDetails?.requestNumber ??
                                        '',
                                  ),
                                  _buildDetailText(
                                    'Request Date: ',
                                    response.requestDetails?.requestDate ?? '',
                                  ),
                                  _buildDetailText(
                                    'Executive Name: ',
                                    response.requestDetails?.executiveName ??
                                        '',
                                  ),
                                  _buildDetailText(
                                    'Request Status: ',
                                    response.requestDetails?.requestStatus ??
                                        '',
                                  ),
                                  _buildDetailText(
                                    'Shipment Mode: ',
                                    response.requestDetails?.shipmentMode ?? '',
                                  ),
                                  _buildDetailText(
                                    'Ship To: ',
                                    response.requestDetails?.wareHouseName ??
                                        '',
                                  ),
                                  _buildDetailText(
                                    'Shipping Address: ',
                                    response.requestDetails?.shippingAddress ??
                                        '',
                                  ),
                                  _buildDetailText(
                                    'Request Remarks: ',
                                    response.requestDetails?.requestRemarks ??
                                        '',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.0),
                            _buildSectionTitle('Title Details'),
                            Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      leading: Text(
                                        'SNo.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      title: Text(
                                        'Title Details',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        child: Center(
                                          child: Text(
                                            textAlign: TextAlign.center,
                                            'Req Qty',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      Container(
                                        child: Center(
                                          child: Text(
                                            textAlign: TextAlign.center,
                                            'Appr Qty',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5.0),
                                      Container(
                                        child: Center(
                                          child: Text(
                                            textAlign: TextAlign.center,
                                            'Reject',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: response.titleDetails?.length ?? 0,
                              itemBuilder: (context, index) {
                                return buildTitleListItem(
                                    response.titleDetails![index], index);
                              },
                            ),
                            SizedBox(height: 8.0),
                            _buildSectionTitle('Approval Matrix'),
                            SizedBox(height: 8.0),
                            Container(
                              child: Table(
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(40.0),
                                  // Fixed width for the first column
                                  1: FlexColumnWidth(),
                                  // Flex the rest
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(),
                                },
                                border: TableBorder.all(color: Colors.grey),
                                // Table border
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0,
                                            bottom: 8,
                                            left: 5,
                                            right: 5),
                                        child: Text(
                                          'SNo.',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0,
                                            bottom: 8,
                                            left: 5,
                                            right: 5),
                                        child: Text(
                                          'Entry/Approval By',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0,
                                            bottom: 8,
                                            left: 5,
                                            right: 5),
                                        child: Text(
                                          'Entry Type',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0,
                                            bottom: 8,
                                            left: 5,
                                            right: 5),
                                        child: Text(
                                          'Remarks',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Table rows
                                  ...List.generate(
                                    response.approvalMatrix?.length ?? 0,
                                    (index) => buildMatrixTableRow(
                                        response.approvalMatrix![index], index),
                                  ),
                                ],
                              ),
                            ),
                            /*Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Sequence Number
                                  Text(
                                    'SNo.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 16), // Spacer
                                  // Executive Name and Details
                                  Text(
                                    'Entry/Approval By',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 16), // Spacer
                                  // Approval Level
                                  Text(
                                    'Entry Type',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 16), // Spacer
                                  // Remarks
                                  Expanded(
                                    child: Text(
                                      'Remarks',
                                      textAlign: TextAlign
                                          .end, // Align remarks to the right
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: response.approvalMatrix?.length ?? 0,
                              itemBuilder: (context, index) {
                                return buildMatrixListItem(
                                    response.approvalMatrix![index], index);
                              },
                            ),*/
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Certification Queries",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => openDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlueAccent,
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Text(
                                    'New Query',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount:
                                  response.clarificationList?.length ?? 0,
                              itemBuilder: (context, index) {
                                var clarification =
                                    response.clarificationList![index];
                                return ListTile(
                                  title: Text(
                                      clarification.clarificationQuery ?? ''),
                                  subtitle: Text(
                                      '${clarification.clarificationResponse}' ??
                                          ''),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return Text("Unexpected state");
                    },
                  )
                : NoInternetLayout(
                    type: widget.type,
                    requestId: widget.requestId,
                    customerId: widget.customerId,
                    customerType: widget.customerType,
                  ),
      ),
      bottomNavigationBar: Visibility(
        visible: hasData,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () =>
                  _handleRequest(context, "Approve", _titleDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(
                'Approve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleRequest(context, "Reject", _titleDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(
                'Reject',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String generateTitleDetailsXML(List<TitleDetails> titleDetailsList) {
    StringBuffer xmlBuffer = StringBuffer();
    xmlBuffer.write('<DocumentElement>');

    for (var details in titleDetailsList) {
      xmlBuffer.write('<ApprovedBooksAndQty>');
      xmlBuffer.write('<RequestId>${details.requestId}</RequestId>');
      xmlBuffer.write('<BookId>${details.bookId}</BookId>');
      xmlBuffer.write('<RequestedQty>${details.requestedQty}</RequestedQty>');
      xmlBuffer.write('<ApprovedQty>${details.approvedQty}</ApprovedQty>');
      xmlBuffer.write('</ApprovedBooksAndQty>');
    }

    xmlBuffer.write('</DocumentElement>');
    return xmlBuffer.toString();
  }

  Widget _buildDetailText(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget buildTitleListItem(TitleDetails titleDetails, int position) {
    TextEditingController qtyController =
        TextEditingController(text: "${titleDetails.approvedQty}");
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListTile(
              leading: Text(
                '${position + 1}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(
                titleDetails.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleDetails.author,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    titleDetails.isbn,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    titleDetails.series,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${titleDetails.price}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    '${titleDetails.requestedQty}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: "", // Hides the default character counter
                      contentPadding:
                          EdgeInsets.zero, // Removes default padding
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      titleDetails.approvedQty = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  // Handle delete action
                },
                child: Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 35,
                ),
              ),
              SizedBox(width: 5.0),
            ],
          ),
        ],
      ),
    );
  }

  TableRow buildMatrixTableRow(ApprovalMatrix approvalMatrix, int position) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            textAlign: TextAlign.center,
            '${approvalMatrix.sequenceNo}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                approvalMatrix.executiveName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(approvalMatrix.entryDate),
              Text(approvalMatrix.profileCode),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${approvalMatrix.approvalLevel}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${approvalMatrix.remarks}',
            style: TextStyle(fontSize: 12.0),
          ),
        ),
      ],
    );
  }

  Widget buildMatrixListItem(ApprovalMatrix approvalMatrix, int position) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Sequence Number
          Text(
            '${approvalMatrix.sequenceNo}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 32), // Spacer
          // Executive Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approvalMatrix.executiveName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(approvalMatrix.entryDate),
                Text(approvalMatrix.profileCode),
              ],
            ),
          ),
          SizedBox(width: 16), // Spacer
          // Approval Level
          Text(
            '${approvalMatrix.approvalLevel}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 16), // Spacer
          // Remarks
          Expanded(
            child: Text(
              '${approvalMatrix.remarks}',
              textAlign: TextAlign.end, // Align remarks to the right
            ),
          ),
        ],
      ),
    );
  }

  void openDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Raise Query',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              Divider(thickness: 1.5),
              SizedBox(height: 16.0),
              Text(
                'Query To',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                items: [
                  DropdownMenuItem(
                    value: 'Option 1',
                    child: Text('Option 1'),
                  ),
                  DropdownMenuItem(
                    value: 'Option 2',
                    child: Text('Option 2'),
                  ),
                ],
                onChanged: (value) {},
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Query',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Add your submission logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(
                    'Send Query',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NoInternetLayout extends StatefulWidget {
  final String type;
  final int requestId;
  final int customerId;
  final String customerType;

  NoInternetLayout({
    required this.type,
    required this.requestId,
    required this.customerId,
    required this.customerType,
  });

  @override
  _NoInternetLayoutState createState() => _NoInternetLayoutState();
}

class _NoInternetLayoutState extends State<NoInternetLayout> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Retry connection check
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ApprovalDetailForm(
                    type: widget.type,
                    requestId: widget.requestId,
                    customerId: widget.customerId,
                    customerType: widget.customerType,
                  ),
                ),
              );
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
