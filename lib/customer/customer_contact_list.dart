import 'package:avant/api/api_service.dart';
import 'package:avant/customer/customer_contact_form.dart';
import 'package:avant/customer/customer_contact_school_form.dart';
import 'package:avant/model/customer_list_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/common.dart';
import '../common/common_text.dart';
import '../common/toast.dart';
import '../common/utils.dart';
import '../model/login_model.dart';
import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class CustomerContactList extends StatefulWidget {
  final String type;
  final int customerId;
  final String validated;

  const CustomerContactList(
      {super.key,
      required this.type,
      required this.customerId,
      required this.validated});

  @override
  CustomerContactListState createState() => CustomerContactListState();
}

class CustomerContactListState extends State<CustomerContactList> {
  late SharedPreferences prefs;
  late String token;
  late int? executiveId;
  late int? userId;
  late String? profileCode;
  late String downHierarchy;

  bool _hasError = false;

  ToastMessage toastMessage = ToastMessage();

  List<ContactList> contactList = [];

  int pageNumber = 1;
  final int pageSize = 10;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    downHierarchy = prefs.getString('DownHierarchy') ?? '';
    userId = await getUserId() ?? 0;
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    await _fetchContactData();
  }

  Future<void> _fetchContactData() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
      _hasError = false;
    });

    try {
      // Check network connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No Internet Connection');
      }

      var response = await CustomerListService().customerContactList(
        pageSize,
        pageNumber,
        widget.customerId,
        widget.type,
        widget.validated,
        token,
      );
      setState(() {
        contactList.addAll(response.contactList);
        hasMore = response.contactList.length == pageSize;
        pageNumber++;
      });
    } catch (e) {
      setState(() {
        _hasError = true; // Set error state
      });
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'List Of Contacts'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              CustomText(
                'Failed to load ${widget.type.toLowerCase()} data. Please try again.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _fetchContactData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'List Of Contacts'),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              hasMore &&
              !isLoading) {
            _fetchContactData();
          }
          return true;
        },
        child: contactList.isEmpty && !isLoading
            ? const Center(
                child: Text('No contact found.'),
              )
            : ListView.builder(
                itemCount: contactList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == contactList.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  var contact = contactList[index];
                  return _buildContactTile(contact);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addContact();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactTile(ContactList contact) {
    return Column(
      children: [
        ListTile(
          title: CustomText(contact.contactName.trim()),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(contact.designation.trim()),
              Visibility(
                visible: contact.mobile.isNotEmpty,
                child: CustomText(contact.mobile.trim()),
              ),
              Visibility(
                visible: contact.email.isNotEmpty,
                child: CustomText(contact.email.trim()),
              ),
              DetailText().buildDetailText(
                  'Primary Contact: ', contact.primaryContact,
                  labelFontSize: 14, valueFontSize: 12),
              DetailText().buildDetailText(
                  'Validation: ', contact.validationStatus,
                  labelFontSize: 14, valueFontSize: 12),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (kDebugMode) {
                    print('Edit tapped');
                  }
                  editContact(contact);
                },
                child: const Icon(Icons.edit, size: 30, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  deleteCustomerDialog(contact);
                },
                child: const Icon(Icons.delete, size: 30, color: Colors.red),
              ),
            ],
          ),
          onTap: () {},
        ),
        const Divider(),
      ],
    );
  }

  void deleteContact(ContactList contact) async {
    try {
      if (!await _checkInternetConnection()) return;

      debugPrint("contact.delete : ${contact.delete}");
      int contactId = extractNumericPart(contact.delete);
      String validated = extractStringPart(contact.delete);

      if (contactId == 0) {
        contactId = extractNumericPart(contact.edit);
        validated = extractStringPart(contact.edit);
      }

      if (contactId == 0) {
        toastMessage
            .showToastMessage("Contact id dose not exist in this contact.");
        return;
      }

      final responseData = await DeleteCustomerService().deleteCustomerContact(
          executiveId ?? 0,
          widget.customerId,
          contactId,
          userId ?? 0,
          validated,
          widget.type,
          token);

      if (responseData.status == 'Success') {
        String msgType = responseData.returnMessage?.msgText ?? '';
        String message = responseData.returnMessage?.msgText ??
            'An error occurred while deleting the contact.';

        if (kDebugMode) {
          print(message);
        }

        // Show a success toast
        toastMessage.showInfoToastMessage(message);
        if (msgType.isNotEmpty && msgType == 'w') {
          // Remove the customer from the local list and refresh the UI
          setState(() {
            contactList.remove(contact);
            if (contactList.isEmpty) {
              // Optionally, reset pagination and re-fetch data if list becomes empty
              pageNumber = 1;
              hasMore = true;
              _fetchContactData();
            }
          });
        }
      } else {
        toastMessage
            .showToastMessage("An error occurred while deleting the contact.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete contact error: $e');
      }
      toastMessage.showToastMessage("An error occurred: $e");
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  void deleteCustomerDialog(ContactList contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete ${widget.type.toLowerCase()}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (kDebugMode) {
                  print('Delete confirmed');
                }
                deleteContact(contact);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void navigateToContactForm({required bool isEdit, ContactList? customer}) {
    final form = widget.type == 'School'
        ? CustomerContactSchoolForm(
            type: widget.type,
            isEdit: isEdit,
            action: isEdit ? customer?.edit : '')
        : CustomerContactForm(
            type: widget.type,
            isEdit: isEdit,
            action: isEdit ? customer?.edit : '');

    Navigator.push(context, MaterialPageRoute(builder: (context) => form));
  }

  void addContact() {
    navigateToContactForm(isEdit: false);
  }

  void editContact(ContactList customer) {
    navigateToContactForm(isEdit: true, customer: customer);
  }
}
