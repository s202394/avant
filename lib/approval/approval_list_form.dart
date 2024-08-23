import 'package:avant/api/api_service.dart';
import 'package:avant/approval/approval_detail_form.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/error_layout.dart';
import 'package:avant/common/no_data_layout.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/home.dart';
import 'package:avant/model/approval_list_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/common/constants.dart';
class ApprovalListForm extends StatefulWidget {
  final String type;

  ApprovalListForm({
    required this.type,
  });

  @override
  _ApprovalListFormState createState() => _ApprovalListFormState();
}

class _ApprovalListFormState extends State<ApprovalListForm> {
  final TextEditingController _commentController = TextEditingController();
  final _commentFieldKey = GlobalKey<FormFieldState>();

  late Future<List<ApprovalList>> futureRequests;

  final ToastMessage _toastMessage = ToastMessage();

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
    super.dispose();
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
          // Handle error if necessary
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.type} Approval'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isConnected
          ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<ApprovalList>>(
              future: futureRequests,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return ErrorLayout();
                } else if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return NoDataLayout();
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
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
                                  checkedRequests.remove(
                                      snapshot.data![index]);
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
                          key: _commentFieldKey,
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            labelText: 'Add your comments here',
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
                          child: Text(
                            _selectionError!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      )
          : NoInternetLayout(type: widget.type),
      bottomNavigationBar: Visibility(
        visible: hasData,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRequest(context, "Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Approve',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRequest(context, "Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
    setState(() {
      // Validate comment field
      if (_commentController.text.isEmpty) {
        _commentError = 'Please enter a comment before $action.';
      } else {
        _commentError = null;
      }

      // Validate that at least one item is selected
      if (checkedRequests.isEmpty) {
        _selectionError = 'Please select at least one item to $action.';
      } else {
        _selectionError = null;
      }
    });

    // Stop if there are validation errors
    if (_commentError != null || _selectionError != null) {
      return;
    }

    if (checkedRequests.length == 0) {
      _toastMessage
          .showToastMessage("Please select any item to take an action.");
      return;
    }
    FocusScope.of(context).unfocus();

    if (!await _checkInternetConnection()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      String requestIds = "";
      for (var request in checkedRequests) {
        if (requestIds.isNotEmpty)
          requestIds = requestIds + ",${request.requestId}";
        else
          requestIds = "${request.requestId}";
      }

      final response;
      if (widget.type == CUSTOMER_SAMPLE_APPROVAL) {
        response = await SubmitRequestApprovalService()
            .submitCustomerSamplingRequestApproved(
          widget.type,
          true,
          action,
          profileCode ?? "",
          "$executiveId",
          "$userId",
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
          "$executiveId",
          "$userId",
          requestIds,
          "",
          _commentController.text,
          token,
        );
      }

      Navigator.of(context).pop();
      print(
          'Approval ${widget.type} successful: ${response.returnMessage.msgText}');
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
          print('$action ${widget.type} Error s empty');
          _toastMessage.showToastMessage(
              "An error occurred while $action ${widget.type}.");
        }
      } else {
        print('Add  ${widget.type} Error ${response.status}');
        _toastMessage.showToastMessage(
            "An error occurred while $action  ${widget.type}.");
      }
    } catch (error) {
      Navigator.of(context).pop();
      // Handle the error (e.g., show error message)
      print('Failed to  ${widget.type} $action: $error');
      _toastMessage
          .showToastMessage("An error occurred while $action  ${widget.type}.");
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

  RequestCard(
      {required this.request, required this.onChecked, required this.type});

  @override
  _RequestCardState createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
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
              TextSpan(
                text: 'Request No: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: widget.request.requestNumber,
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
                  TextSpan(
                    text: 'Executive Name: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.request.executiveName,
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Request Date: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.request.requestDate,
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Address: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.request.address,
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Request Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.request.requestStatus,
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

  NoInternetLayout({required this.type});

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
                  builder: (context) => ApprovalListForm(type: widget.type),
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
