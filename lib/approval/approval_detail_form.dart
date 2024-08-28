import 'package:avant/api/api_service.dart';
import 'package:avant/common/error_layout.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/common/common_text.dart';
import 'package:avant/home.dart';
import 'package:avant/model/approval_details_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/common/constants.dart';

class ApprovalDetailForm extends StatefulWidget {
  final String type;
  final int requestId;
  final int customerId;
  final String customerType;

  const ApprovalDetailForm({
    super.key,
    required this.type,
    required this.requestId,
    required this.customerId,
    required this.customerType,
  });

  @override
  _ApprovalDetailFormState createState() => _ApprovalDetailFormState();
}

class _ApprovalDetailFormState extends State<ApprovalDetailForm> {
  late Future<ApprovalDetailsResponse> futureRequestDetails;

  List<TitleDetails> _titleDetails = [];

  final ToastMessage _toastMessage = ToastMessage();
  final DetailText _detailText = DetailText();

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
        futureRequestDetails = ApprovalDetailsService()
            .fetchApprovalDetails(
                widget.type,
                widget.customerId,
                widget.customerType,
                widget.requestId,
                widget.type == CUSTOMER_SAMPLE_APPROVAL
                    ? 'CustomerSampling'
                    : 'Approval',
                token)
            .then((response) {
          setState(() {
            hasData = response.titleDetails?.isNotEmpty ?? false;
            _titleDetails = response.titleDetails ?? [];
            print('_titleDetails size:${_titleDetails.length}');
            isLoading = false;
          });
          return response;
        }).catchError((error) {
          setState(() {
            isLoading = false;
            hasData = false;
          });
          print("Error occurred: $error");
          return ApprovalDetailsResponse();
        });
      });
    }
  }

  void _handleRequest(BuildContext context, String approvalFor,
      List<TitleDetails> titleDetailsList) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    print('titleDetailsList size:${titleDetailsList.length}');

    try {
      final response;
      if (widget.type == CUSTOMER_SAMPLE_APPROVAL) {
        response = await SubmitRequestApprovalService()
            .submitCustomerSamplingRequestApproved(
          widget.type,
          false,
          approvalFor,
          profileCode ?? "",
          "${executiveId ?? 0}",
          "$userId",
          "${widget.requestId}",
          generateTitleDetailsXML(titleDetailsList),
          "",
          token,
        );
      } else {
        response =
            await SubmitRequestApprovalService().submitSelfStockRequestApproved(
          widget.type,
          false,
          approvalFor,
          profileCode ?? "",
          "${executiveId ?? 0}",
          "$userId",
          "${widget.requestId}",
          generateTitleDetailsXML(titleDetailsList),
          "",
          token,
        );
      }

      // Close the loading indicator
      Navigator.of(context).pop();

      print(
          'Approval ${widget.type} successful: ${response.returnMessage.msgText}');
      if (response.status == 'Success') {
        String s = response.returnMessage.msgText;
        if (s.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          print('$approvalFor ${widget.type} Error s empty');
          _toastMessage.showToastMessage(
              "An error occurred while $approvalFor ${widget.type}.");
        }
      } else {
        print('Add ${widget.type} Error ${response.status}');
        _toastMessage.showToastMessage(
            "An error occurred while $approvalFor ${widget.type}.");
      }
    } catch (error) {
      // Close the loading indicator
      Navigator.of(context).pop();

      // Handle the error (e.g., show error message)
      print('Failed to approve: $error');
      _toastMessage.showToastMessage(
          "An error occurred while $approvalFor ${widget.type}.");
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
            ? const CircularProgressIndicator()
            : isConnected
                ? FutureBuilder<ApprovalDetailsResponse>(
                    future: futureRequestDetails,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return ErrorLayout();
                      } else if (!hasData) {
                        return NoDataLayout();
                      } else if (snapshot.hasData) {
                        var response = snapshot.data!;
                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            ListTile(
                              title: const Text(
                                'Request Details',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailText.buildDetailText(
                                    'Request No: ',
                                    response.requestDetails?.requestNumber ??
                                        '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Request Date: ',
                                    response.requestDetails?.requestDate ?? '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Executive Name: ',
                                    response.requestDetails?.executiveName ??
                                        '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Request Status: ',
                                    response.requestDetails?.requestStatus ??
                                        '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Shipment Mode: ',
                                    response.requestDetails?.shipmentMode ?? '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Ship To: ',
                                    response.requestDetails?.wareHouseName ??
                                        '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Shipping Address: ',
                                    response.requestDetails?.shippingAddress ??
                                        '',
                                  ),
                                  _detailText.buildDetailText(
                                    'Request Remarks: ',
                                    response.requestDetails?.requestRemarks ??
                                        '',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Visibility(
                              visible: (response.titleDetails?.length ?? 0) > 0,
                              child: Column(
                                children: [
                                  _buildSectionTitle('Title Details'),
                                  const Row(
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
                                          Center(
                                            child: Text(
                                              textAlign: TextAlign.center,
                                              'Req Qty',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          Center(
                                            child: Text(
                                              textAlign: TextAlign.center,
                                              'Appr Qty',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                          ),
                                          SizedBox(width: 5.0),
                                          Center(
                                            child: Text(
                                              textAlign: TextAlign.center,
                                              'Reject',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount:
                                        response.titleDetails?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      return buildTitleListItem(
                                          response.titleDetails![index], index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible:
                                  (response.approvalMatrix?.length ?? 0) > 0,
                              child: Column(
                                children: [
                                  const SizedBox(height: 8.0),
                                  _buildSectionTitle('Approval Matrix'),
                                  const SizedBox(height: 8.0),
                                  Table(
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
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.only(
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
                                            padding: EdgeInsets.only(
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
                                            padding: EdgeInsets.only(
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
                                            padding: EdgeInsets.only(
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
                                            response.approvalMatrix![index],
                                            index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
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
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: const Text(
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
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  response.clarificationList?.length ?? 0,
                              itemBuilder: (context, index) {
                                var clarification =
                                    response.clarificationList![index];
                                return ListTile(
                                  title: Text(
                                      clarification.clarificationQuery ?? ''),
                                  subtitle: Text(
                                      clarification.clarificationResponse ??
                                          ''),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return const Text("Unexpected state");
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
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text(
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
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text(
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleDetails.author,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    titleDetails.isbn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    titleDetails.series,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹ ${titleDetails.price}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    '${titleDetails.requestedQty}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
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
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
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
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  // Handle delete action
                },
                child: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 35,
                ),
              ),
              const SizedBox(width: 5.0),
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
            style: const TextStyle(
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(approvalMatrix.entryDate),
              Text(approvalMatrix.profileCode),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            approvalMatrix.approvalLevel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            approvalMatrix.remarks,
            style: const TextStyle(fontSize: 12.0),
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
          Text(
            '${approvalMatrix.sequenceNo}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approvalMatrix.executiveName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(approvalMatrix.entryDate),
                Text(approvalMatrix.profileCode),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            approvalMatrix.approvalLevel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(approvalMatrix.remarks, textAlign: TextAlign.end),
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
              const Text(
                'Raise Query',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16.0),
              const Text(
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Query',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Add your submission logic here
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

  const NoInternetLayout({
    super.key,
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
          const Icon(Icons.wifi_off, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
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
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
