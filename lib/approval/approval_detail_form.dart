import 'package:avant/api/api_service.dart';
import 'package:avant/common/error_layout.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/common/common_text.dart';
import 'package:avant/home.dart';
import 'package:avant/model/approval_details_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/views/custom_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/common/constants.dart';

import '../common/common.dart';
import '../model/submit_approval_model.dart';
import '../views/common_app_bar.dart';
import 'approval_list_form.dart';

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
  ApprovalDetailFormState createState() => ApprovalDetailFormState();
}

class ApprovalDetailFormState extends State<ApprovalDetailForm> {
  late Future<ApprovalDetailsResponse> futureRequestDetails;

  List<TitleDetails> _titleDetails = [];

  List<ClarificationExecutivesList> clarificationExecutivesList = [];
  ClarificationExecutivesList? _selectedClarificationExecutive;

  final ToastMessage _toastMessage = ToastMessage();
  final DetailText _detailText = DetailText();

  final _clarificationExecutiveFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _clarificationExecutiveFocusNode = FocusNode();

  final TextEditingController _clarificationExecutiveController =
      TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final _remarksFieldKey = GlobalKey<FormFieldState>();

  late String token;
  late int? executiveId;
  late int? userId;
  late String downHierarchy;
  late String? profileCode;

  String? _remarksError;

  bool hasData = false;
  bool isLoading = true;
  bool isConnected = true;

  bool _submitted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  String getType() {
    return widget.type == customerSampleApproval
        ? 'CustomerSampling'
        : 'Selfstock';
  }

  Future<void> _checkConnectivity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var connectivityResult = await Connectivity().checkConnectivity();

    // Check if the widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      token = prefs.getString('token') ?? '';
      downHierarchy = prefs.getString('DownHierarchy') ?? '';
    });

    userId = await getUserId();
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();

    if (connectivityResult == ConnectivityResult.none) {
      if (!mounted) return;
      setState(() {
        isConnected = false;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        isConnected = true;
        isLoading = true;
        futureRequestDetails = ApprovalDetailsService()
            .fetchApprovalDetails(widget.type, widget.customerId,
                widget.customerType, widget.requestId, getType(), token)
            .then((response) {
          setState(() {
            hasData = response.titleDetails?.isNotEmpty ?? false;
            _titleDetails = response.titleDetails ?? [];
            clarificationExecutivesList =
                response.clarificationExecutivesList ?? [];
            if (kDebugMode) {
              print('_titleDetails size:${_titleDetails.length}');
            }
            isLoading = false;
          });
          return response;
        }).catchError((error) {
          if (mounted) {
            setState(() {
              isLoading = false;
              hasData = false;
            });
          }
          if (kDebugMode) {
            print("Error occurred: $error");
          }
          return ApprovalDetailsResponse();
        });
      });
    }
  }

  void _handleRequest(BuildContext context, String approvalFor,
      List<TitleDetails> titleDetailsList) async {
    setState(() {
      if (approvalFor == 'Reject' && _remarksController.text.isEmpty) {
        _remarksError = 'Please enter remarks before $approvalFor.';
      } else {
        _remarksError = null;
      }
    });

    if (approvalFor == 'Reject' && _remarksController.text.isEmpty) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    if (kDebugMode) {
      print('titleDetailsList size:${titleDetailsList.length}');
    }

    try {
      final SubmitRequestApprovalResponse response;
      if (widget.type == customerSampleApproval) {
        response = await SubmitRequestApprovalService()
            .submitCustomerSamplingRequestApproved(
          widget.type,
          false,
          approvalFor,
          profileCode ?? "",
          executiveId ?? 0,
          userId ?? 0,
          '${widget.requestId}',
          generateTitleDetailsXML(titleDetailsList, approvalFor),
          _remarksController.text,
          token,
        );
      } else {
        response =
            await SubmitRequestApprovalService().submitSelfStockRequestApproved(
          widget.type,
          false,
          approvalFor,
          profileCode ?? "",
          executiveId ?? 0,
          userId ?? 0,
          "${widget.requestId}",
          generateTitleDetailsXML(titleDetailsList, approvalFor),
          _remarksController.text,
          token,
        );
      }

      // Close the loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (kDebugMode) {
        print(
            'Approval ${widget.type} successful: ${response.returnMessage.msgText}');
      }
      if (response.status == 'Success') {
        String s = response.returnMessage.msgText;
        if (s.isNotEmpty) {
          _toastMessage.showInfoToastMessage(s);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (kDebugMode) {
            print('$approvalFor ${widget.type} Error s empty');
          }
          _toastMessage.showToastMessage(
              "An error occurred while $approvalFor ${widget.type}.");
        }
      } else {
        if (kDebugMode) {
          print('Add ${widget.type} Error ${response.status}');
        }
        _toastMessage.showToastMessage(
            "An error occurred while $approvalFor ${widget.type}.");
      }
    } catch (error) {
      // Close the loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      // Handle the error (e.g., show error message)
      if (kDebugMode) {
        print('Failed to approve: $error');
      }
      _toastMessage.showToastMessage(
          "An error occurred while $approvalFor ${widget.type}.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.type),
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
                        return const ErrorLayout();
                      } else if (!hasData) {
                        return const NoDataLayout();
                      } else if (snapshot.hasData) {
                        var response = snapshot.data!;
                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            ListTile(
                              title: const CustomText(
                                'Request Details',
                                fontWeight: FontWeight.bold,
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
                                          leading: CustomText(
                                            'SNo.',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          title: CustomText(
                                            'Title Details',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Center(
                                            child: CustomText(
                                                textAlign: TextAlign.center,
                                                'Req Qty',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          SizedBox(width: 8.0),
                                          Center(
                                            child: CustomText(
                                                textAlign: TextAlign.center,
                                                'Appr Qty',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          SizedBox(width: 5.0),
                                          Center(
                                            child: CustomText(
                                                textAlign: TextAlign.center,
                                                'Reject',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _titleDetails.length,
                                    itemBuilder: (context, index) {
                                      return buildTitleListItem(
                                          _titleDetails[index], index);
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
                                            color: Colors.grey[200]),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: 8.0,
                                                bottom: 8,
                                                left: 5,
                                                right: 5),
                                            child: CustomText('SNo.',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: 8.0,
                                                bottom: 8,
                                                left: 5,
                                                right: 5),
                                            child: CustomText(
                                                'Entry/Approval By',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: 8.0,
                                                bottom: 8,
                                                left: 5,
                                                right: 5),
                                            child: CustomText('Entry Type',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: 8.0,
                                                bottom: 8,
                                                left: 5,
                                                right: 5),
                                            child: CustomText('Remarks',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
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
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      {_submitted = false, openDialog(context)},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlueAccent,
                                  ),
                                  child: const CustomText('New Query',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            Visibility(
                                visible:
                                    (response.clarificationList?.length ?? 0) >
                                        0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CustomText(
                                      "Queries/Response",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                    const SizedBox(height: 5.0),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1.0),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: response
                                                .clarificationList?.length ??
                                            0,
                                        itemBuilder: (context, index) {
                                          var clarification = response
                                              .clarificationList![index];
                                          return Column(
                                            children: [
                                              ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 0.0),
                                                title:
                                                    _detailText.buildDetailText(
                                                        'Query By: ',
                                                        clarification
                                                            .clarificationQuery,
                                                        labelFontSize: 14,
                                                        valueFontSize: 14),
                                                subtitle:
                                                    _detailText.buildDetailText(
                                                        'Response By: ',
                                                        clarification
                                                            .clarificationResponse),
                                              ),
                                              if (index !=
                                                  response.clarificationList!
                                                          .length -
                                                      1)
                                                const Divider(
                                                    thickness: 1.0,
                                                    height: 0.0),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                style: const TextStyle(fontSize: 14),
                                key: _remarksFieldKey,
                                controller: _remarksController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  labelStyle: const TextStyle(fontSize: 14),
                                  labelText: 'Remarks',
                                  errorText: _remarksError,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _remarksError = null;
                                    });
                                  }
                                },
                              ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _handleRequest(context, "Approve", _titleDetails),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  child: const CustomText('Approve',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _handleRequest(context, "Reject", _titleDetails),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  child: const CustomText('Reject',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String generateTitleDetailsXML(
      List<TitleDetails> titleDetailsList, String approvalFor) {
    StringBuffer xmlBuffer = StringBuffer();
    xmlBuffer.write('<DocumentElement>');

    for (var details in titleDetailsList) {
      int approvedQty = (approvalFor == 'Reject') ? 0 : details.approvedQty;
      xmlBuffer.write('<ApprovedBooksAndQty>');
      xmlBuffer.write('<RequestId>${details.requestId}</RequestId>');
      xmlBuffer.write('<BookId>${details.bookId}</BookId>');
      xmlBuffer.write('<RequestedQty>${details.requestedQty}</RequestedQty>');
      xmlBuffer.write('<ApprovedQty>$approvedQty</ApprovedQty>');
      xmlBuffer.write('</ApprovedBooksAndQty>');
    }

    xmlBuffer.write('</DocumentElement>');
    return xmlBuffer.toString();
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CustomText(title, fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }

  Widget buildTitleListItem(TitleDetails titleDetails, int position) {
    int qty = titleDetails.approvedQty > 0
        ? titleDetails.approvedQty
        : titleDetails.requestedQty;
    TextEditingController qtyController = TextEditingController(text: "$qty");
    titleDetails.approvedQty = qty;

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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
              leading:
                  CustomText('${position + 1}', fontWeight: FontWeight.bold),
              title:
                  CustomText(titleDetails.title, fontWeight: FontWeight.bold),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(titleDetails.author,
                      fontWeight: FontWeight.bold, fontSize: 12),
                  CustomText(titleDetails.isbn,
                      fontWeight: FontWeight.bold, fontSize: 12),
                  CustomText(titleDetails.bookTypeName,
                      fontWeight: FontWeight.bold, fontSize: 12),
                  CustomText(titleDetails.seriesName,
                      fontWeight: FontWeight.bold, fontSize: 12),
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
                    child: CustomText(
                        textAlign: TextAlign.center,
                        fontSize: 14,
                        '${titleDetails.requestedQty}',
                        fontWeight: FontWeight.bold)),
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
                        fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                      labelStyle: TextStyle(fontSize: 14),
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      int? newQty = int.tryParse(value);
                      if (newQty != null) {
                        // Ensure approvedQty does not exceed requestedQty
                        if (newQty > titleDetails.requestedQty) {
                          // If greater, set it to requestedQty
                          titleDetails.approvedQty = titleDetails.requestedQty;
                          qtyController.text = '${titleDetails.requestedQty}';
                          qtyController.selection = TextSelection.fromPosition(
                            TextPosition(offset: qtyController.text.length),
                          );
                        } else {
                          titleDetails.approvedQty = newQty;
                        }
                      } else {
                        titleDetails.approvedQty = 0;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  titleDetails.approvedQty = 0;
                  qtyController.text = '${titleDetails.approvedQty}';
                },
                child: const Icon(Icons.cancel, color: Colors.red, size: 35),
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
          child: CustomText(
              textAlign: TextAlign.center,
              '${approvalMatrix.sequenceNo}',
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(approvalMatrix.executiveName,
                  fontWeight: FontWeight.bold, fontSize: 12),
              CustomText(approvalMatrix.entryDate, fontSize: 12),
              CustomText(approvalMatrix.profileCode, fontSize: 12),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomText(approvalMatrix.approvalLevel, fontSize: 12),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomText(approvalMatrix.remarks, fontSize: 12.0),
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
          CustomText('${approvalMatrix.sequenceNo}',
              fontSize: 14, fontWeight: FontWeight.bold),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(approvalMatrix.executiveName,
                    fontWeight: FontWeight.bold, fontSize: 14),
                CustomText(approvalMatrix.entryDate, fontSize: 14),
                CustomText(approvalMatrix.profileCode, fontSize: 14),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CustomText(approvalMatrix.approvalLevel,
              fontSize: 14, fontWeight: FontWeight.bold),
          const SizedBox(width: 16),
          Expanded(
            child: CustomText(approvalMatrix.remarks,
                textAlign: TextAlign.end, fontSize: 14),
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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText('Send back for Clarification',
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.cancel_outlined),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 8.0),
                  _buildDropdownFieldClarificationExecutives(
                    'Executive',
                    _clarificationExecutiveController,
                    _clarificationExecutiveFieldKey,
                    _clarificationExecutiveFocusNode,
                  ),
                  buildTextField('Query', _queryController),
                  const SizedBox(height: 8.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              _submitQuery();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 12.0),
                              textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            child: const CustomText('Send Query',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: TextStyle(fontSize: textFontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
          errorText: _submitted && controller.text.isEmpty
              ? 'Please enter $label'
              : null,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              _submitted = false;
            });
          }
        },
        controller: controller,
        maxLines: 4,
      ),
    );
  }

  Widget _buildDropdownFieldClarificationExecutives(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<ClarificationExecutivesList>(
        key: fieldKey,
        focusNode: focusNode,
        style: TextStyle(fontSize: textFontSize),
        value: _selectedClarificationExecutive,
        items: [
          const DropdownMenuItem<ClarificationExecutivesList>(
            value: null,
            child: CustomText('Select'),
          ),
          ...clarificationExecutivesList.map(
            (clarificationExecutive) =>
                DropdownMenuItem<ClarificationExecutivesList>(
              value: clarificationExecutive,
              child: CustomText(clarificationExecutive.executive,
                  fontSize: textFontSize),
            ),
          ),
        ],
        onChanged: (ClarificationExecutivesList? value) {
          setState(() {
            _selectedClarificationExecutive = value;

            // Update the text controller with the selected city name
            controller.text = value?.executive ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          errorText: _submitted && _selectedClarificationExecutive == null
              ? 'Please select a $label'
              : null,
        ),
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  Future<void> _submitQuery() async {
    if (_selectedClarificationExecutive == null) {
      _toastMessage.showToastMessage("Please select Executive");
      return;
    }
    if (_queryController.text.isEmpty) {
      _toastMessage.showToastMessage("Please enter Query");
      return;
    }

    if (!await _checkInternetConnection()) return;

    setState(() {
      _submitted = true;
      _isLoading = true;
    });

    try {
      final responseData = await SendClarificationQueryService()
          .sendClarificationQuery(
              widget.requestId,
              getType(),
              _selectedClarificationExecutive?.executiveId ?? 0,
              _queryController.text,
              executiveId ?? 0,
              userId ?? 0,
              token);

      String msgType = responseData.returnMessage.msgType;
      String msgText = responseData.returnMessage.msgText;

      if (responseData.status == 'Success') {
        if (msgType == 's' || msgType == 'e') {
          _toastMessage.showInfoToastMessage(msgText);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const ApprovalListForm(type: customerSampleApproval)),
            );
          }
        } else {
          _toastMessage
              .showToastMessage("An error occurred while sending query.");
        }
      } else {
        _toastMessage
            .showToastMessage("An error occurred while sending query.");
      }
    } catch (e) {
      _toastMessage.showToastMessage("An error occurred while sending query.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void clearData() {
    hasData = false;
    isLoading = true;
    isConnected = true;
    _submitted = false;
    _isLoading = false;
    _titleDetails = [];
    clarificationExecutivesList = [];
    _selectedClarificationExecutive = null;

    _clarificationExecutiveController.clear();
    _queryController.clear();
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
  NoInternetLayoutState createState() => NoInternetLayoutState();
}

class NoInternetLayoutState extends State<NoInternetLayout> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const CustomText('No Internet Connection',
              fontSize: 18, color: Colors.grey),
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
            child: const CustomText('Retry', fontSize: 16),
          ),
        ],
      ),
    );
  }
}
