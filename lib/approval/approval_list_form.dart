import 'package:avant/api/api_service.dart';
import 'package:avant/approval/approval_detail_form.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/constants.dart';
import 'package:avant/common/error_layout.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/home.dart';
import 'package:avant/model/approval_list_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/views/custom_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/submit_approval_model.dart';
import '../views/common_app_bar.dart';

class ApprovalListForm extends StatefulWidget {
  final String type;

  const ApprovalListForm({
    super.key,
    required this.type,
  });

  @override
  ApprovalListFormState createState() => ApprovalListFormState();
}

class ApprovalListFormState extends State<ApprovalListForm> {
  final TextEditingController _commentController = TextEditingController();
  final _commentFieldKey = GlobalKey<FormFieldState>();

  late Future<List<ApprovalList>> futureRequests;

  final ToastMessage _toastMessage = ToastMessage();

  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _commentScrollController = ScrollController();

  late String token;
  late int? executiveId;
  late String? profileCode;
  late int? userId;

  bool hasData = false;
  bool isLoading = true;
  bool isConnected = true;
  List<ApprovalList> checkedRequests = [];

  String? _commentError;
  String? _selectionError;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _commentScrollController.dispose();
    super.dispose();
  }

  void _focusAndScroll() {
    _commentFocusNode.requestFocus();

    _commentScrollController.animateTo(
      _commentScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
    });

    userId = await getUserId();
    profileCode = await getProfileCode();
    executiveId = await getExecutiveId();

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
        isLoading = false;
      });
    } else {
      setState(() {
        isConnected = true;
        isLoading = true;

        futureRequests = CustomerSamplingApprovalListService()
            .fetchCustomerSamplingApprovalList(
                widget.type, executiveId ?? 0, "Approval", token)
            .then((response) {
          setState(() {
            if (response.approvalList.isEmpty) {
              hasData = false;
            } else {
              hasData = true;
            }
            isLoading = false;
          });
          return response.approvalList;
        }).catchError((error) {
          setState(() {
            isLoading = false;
          });
          return <ApprovalList>[];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.type),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isConnected
              ? FutureBuilder<List<ApprovalList>>(
                  future: futureRequests,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const ErrorLayout();
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const NoDataLayout();
                    } else {
                      return SingleChildScrollView(
                        controller: _commentScrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                return RequestCard(
                                  type: widget.type,
                                  request: snapshot.data![index],
                                  onChecked: (bool isChecked) {
                                    setState(() {
                                      if (isChecked) {
                                        checkedRequests
                                            .add(snapshot.data![index]);
                                      } else {
                                        checkedRequests
                                            .remove(snapshot.data![index]);
                                      }
                                      if (checkedRequests.isNotEmpty) {
                                        _selectionError = null;
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                key: _commentFieldKey,
                                controller: _commentController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelStyle: const TextStyle(fontSize: 14),
                                  border: const OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  labelText: 'Remarks',
                                  errorText: _commentError,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _commentError = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_selectionError != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomText(_selectionError!,
                                    color: Colors.red),
                              ),
                          ],
                        ),
                      );
                    }
                  },
                )
              : NoInternetLayout(type: widget.type),
      bottomNavigationBar: Visibility(
        visible: hasData,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRequest(context, "Approve"),
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
                  onPressed: () => _handleRequest(context, "Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  child: const CustomText(
                    'Reject',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRequest(BuildContext context, String action) async {
    // Validate inputs
    setState(() {
      if (action == 'Reject' && _commentController.text.isEmpty) {
        _commentError = 'Please enter comment before $action.';
      } else {
        _commentError = null;
      }

      if (checkedRequests.isEmpty) {
        _selectionError = 'Please select at least one item to $action.';
      } else {
        _selectionError = null;
      }
    });

    _focusAndScroll();

    if (_commentError != null || _selectionError != null) {
      return;
    }

    if (checkedRequests.isEmpty) {
      _toastMessage
          .showToastMessage("Please select any item to take an action.");
      return;
    }

    FocusScope.of(context).unfocus();

    if (!await _checkInternetConnection()) return;

    // Capture context for later use
    final BuildContext dialogContext = context;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    try {
      String requestIds =
          checkedRequests.map((request) => request.requestId).join(',');

      final SubmitRequestApprovalResponse response;
      if (widget.type == customerSampleApproval) {
        response = await SubmitRequestApprovalService()
            .submitCustomerSamplingRequestApproved(
          widget.type,
          true,
          action,
          profileCode ?? "",
          executiveId ?? 0,
          userId ?? 0,
          requestIds,
          "",
          _commentController.text,
          token,
        );
      } else {
        response =
            await SubmitRequestApprovalService().submitSelfStockRequestApproved(
          widget.type,
          true,
          action,
          profileCode ?? "",
          executiveId ?? 0,
          userId ?? 0,
          requestIds,
          "",
          _commentController.text,
          token,
        );
      }

      // Dismiss the loading dialog if mounted
      if (mounted) {
        Navigator.of(dialogContext).pop(); // Dismiss the loading dialog
      }

      if (kDebugMode) {
        print(
            'Approval ${widget.type} successful: ${response.returnMessage.msgText}');
      }

      if (response.status == 'Success') {
        String message = response.returnMessage.msgText;
        if (message.isNotEmpty) {
          _toastMessage.showInfoToastMessage(message);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (kDebugMode) {
            print('$action ${widget.type} Error: message is empty');
          }
          _toastMessage.showToastMessage(
              "An error occurred while $action ${widget.type}.");
        }
      } else {
        if (kDebugMode) {
          print('Add ${widget.type} Error: ${response.status}');
        }
        _toastMessage.showToastMessage(
            "An error occurred while $action ${widget.type}.");
      }
    } catch (error) {
      // Dismiss the loading dialog if mounted
      if (mounted) {
        Navigator.of(dialogContext).pop(); // Dismiss the loading dialog
      }
      if (kDebugMode) {
        print('Failed to ${widget.type} $action: $error');
      }
      _toastMessage
          .showToastMessage("An error occurred while $action ${widget.type}.");
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }
}

class RequestCard extends StatefulWidget {
  final ApprovalList request;
  final Function(bool) onChecked;
  final String type;

  const RequestCard(
      {super.key,
      required this.request,
      required this.onChecked,
      required this.type});

  @override
  RequestCardState createState() => RequestCardState();
}

class RequestCardState extends State<RequestCard> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value ?? false;
            });
            widget.onChecked(isChecked);
          },
        ),
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Request No: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextSpan(
                text: widget.request.requestNumber,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Executive Name: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text: widget.request.executiveName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Request Date: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text: widget.request.requestDate,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Address: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text: widget.request.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Request Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text: widget.request.requestStatus,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to the next screen when the item is clicked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovalDetailForm(
                type: widget.type,
                requestId: widget.request.requestId,
                customerId: widget.request.customerId,
                customerType: widget.request.customerType,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoInternetLayout extends StatefulWidget {
  final String type;

  const NoInternetLayout({super.key, required this.type});

  @override
  NoInternetLayoutState createState() => NoInternetLayoutState();
}

class NoInternetLayoutState extends State<NoInternetLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const CustomText(
                    'No Internet Connection',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Retry connection check
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              ApprovalListForm(type: widget.type),
                        ),
                      );
                    },
                    child: const CustomText('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
