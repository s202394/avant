import 'package:avant/db/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../common/common.dart';
import '../common/common_text.dart';
import '../common/toast.dart';
import '../home.dart';
import '../model/fetch_titles_model.dart';
import '../model/login_model.dart';
import '../service/location_service.dart';
import '../views/book_list_item.dart';
import '../views/rich_text.dart';

class Cart extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;
  final String visitFeedback;
  final String visitDate;
  final int visitPurposeId;
  final String jointVisitWithIds;
  final int personMetId;
  final bool samplingDone;
  final bool followUpAction;

  const Cart({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    required this.city,
    required this.state,
    required this.visitFeedback,
    required this.visitDate,
    required this.visitPurposeId,
    required this.jointVisitWithIds,
    required this.personMetId,
    required this.samplingDone,
    required this.followUpAction,
  });

  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  late SharedPreferences prefs;
  late String token;
  int? executiveId;
  String? profileCode;

  int? userId;

  bool _submitted = false;
  bool _isLoading = true;

  late Position position;
  late String address;

  List<Map<String, dynamic>> _seriesItems = [];
  List<Map<String, dynamic>> _titleItems = [];

  final DetailText _detailText = DetailText();
  DatabaseHelper databaseHelper = DatabaseHelper();
  LocationService locationService = LocationService();
  ToastMessage toastMessage = ToastMessage();

  @override
  void initState() {
    super.initState();
    _fetchCartDetails();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    final seriesItems = await databaseHelper.getCartItemsWithSeries();
    final titleItems = await databaseHelper.getCartItemsWithTitle();

    setState(() {
      _seriesItems = seriesItems;
      _titleItems = titleItems;

      int tabCount = 0;
      if (widget.samplingDone && _seriesItems.isNotEmpty) {
        tabCount++;
      }
      if (widget.samplingDone && _titleItems.isNotEmpty) {
        tabCount++;
      }
      if (widget.followUpAction) {
        tabCount++;
      }

      if (tabCount > 0) {
        _tabController = TabController(length: tabCount, vsync: this);
      } else {
        _tabController = TabController(length: 1, vsync: this); // Fallback to at least one tab
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartDetails() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
    });
    executiveId = await getExecutiveId();
    profileCode = await getProfileCode();
    userId = await getUserId();

    try {
      _isLoading = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[100],
          title: const Text('DSR Entry'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          RichTextWidget(label: widget.address),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _detailText.buildDetailText(
                            'Sampling Done: ',
                            widget.samplingDone ? 'Yes' : 'No',
                          ),
                          _detailText.buildDetailText(
                            'Follow up Action: ',
                            widget.followUpAction ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.orange,
                      child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          indicatorColor: Colors.blue,
                          tabs: _tabs()),
                    ),
                    Expanded(
                      child: TabBarView(
                          controller: _tabController, children: _tabsAction()),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _submitted = true;
                              });
                              if (_formKey.currentState!.validate()) {
                                _submitForm();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              color: Colors.blue,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16),
                                child: Text(
                                  'Submit',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _tabs() {
    List<Widget> list = [];
    if (widget.samplingDone && _seriesItems.isNotEmpty) {
      list.add(const Tab(text: 'Series/ Title'));
    }
    if (widget.samplingDone && _titleItems.isNotEmpty) {
      list.add(const Tab(text: 'Title wise'));
    }
    if (widget.followUpAction) {
      list.add(const Tab(text: 'Follow Up Action'));
    }
    return list;
  }

  List<Widget> _tabsAction() {
    List<Widget> list = [];
    if (widget.samplingDone && _seriesItems.isNotEmpty) {
      list.add(_buildSeriesTitleTab());
    }
    if (widget.samplingDone && _titleItems.isNotEmpty) {
      list.add(_buildTitleWiseTab());
    }
    if (widget.followUpAction) {
      list.add(_buildFollowUpActionTab());
    }
    return list;
  }

  Widget _buildSeriesTitleTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _seriesItems.map((item) {
            final titleList = TitleList(
              bookId: item['BookId'],
              title: item['Title'],
              isbn: item['ISBN'],
              author: item['Author'],
              price: item['Price'],
              listPrice: item['ListPrice'],
              bookNum: item['BookNum'],
              image: item['Image'],
              bookType: item['BookType'],
              imageUrl: item['ImageUrl'],
              physicalStock: item['PhysicalStock'],
              quantity: item['RequestedQty'],
            );
            return BookListItem(
              book: titleList,
              onQuantityChanged: (quantity) {
                setState(() {
                  item['RequestedQty'] = quantity;
                });
              },
              areDropdownsSelected: true,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTitleWiseTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _titleItems.map((item) {
            final titleList = TitleList(
              bookId: item['BookId'],
              title: item['Title'],
              isbn: item['ISBN'],
              author: item['Author'],
              price: item['Price'],
              listPrice: item['ListPrice'],
              bookNum: item['BookNum'],
              image: item['Image'],
              bookType: item['BookType'],
              imageUrl: item['ImageUrl'],
              physicalStock: item['PhysicalStock'],
              quantity: item['RequestedQty'],
            );
            return BookListItem(
              book: titleList,
              onQuantityChanged: (quantity) {
                setState(() {
                  item['RequestedQty'] = quantity;
                });
              },
              areDropdownsSelected: true,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFollowUpActionTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: databaseHelper.getAllFollowUpActionCarts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No follow-up actions found.'));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                    4: FixedColumnWidth(48.0),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Date'),
                        _buildTableHeader('Executive'),
                        _buildTableHeader('Department'),
                        _buildTableHeader('Action'),
                        _buildTableHeader(''),
                      ],
                    ),
                    ...data.map(
                      (row) {
                        final id = row['id'] as int?;
                        return TableRow(
                          children: [
                            _buildTableCell(row['FollowUpDate']),
                            _buildTableCell(row['FollowUpExecutive']),
                            _buildTableCell(row['Department']),
                            _buildTableCell(row['FollowUpAction']),
                            _buildTableCellAction(id, _deleteFollowUpAction),
                            // Action cell
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFollowUpAction(int id) async {
    final db = await databaseHelper.database;
    await db.delete('FollowUpActionCart', where: 'id = ?', whereArgs: [id]);

    // Refresh the data after deletion
    _fetchCartData();
    setState(() {});
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(dynamic value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(value?.toString() ?? ''),
    );
  }

  Widget _buildTableCellAction(dynamic id, Function(int) onDelete) {
    if (id == null) {
      return const SizedBox
          .shrink(); // Or handle the case where id is null in some other way
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          onDelete(id as int);
        },
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
        ),
        enabled: enabled,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onChanged: (text) {
          if (_formKey.currentState != null) {
            _formKey.currentState!.validate();
          }
        },
      ),
    );
  }

  Widget buildDropdownField<T>(String label, T? selectedValue,
      List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged,
      {required int? selectedId, required ValueChanged<int?> onIdChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _submitted && selectedValue == null && label == 'Series'
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            value: selectedValue,
            items: items,
            onChanged: (value) {
              if (value == null) return;

              onChanged(value);
              final selectedItem =
                  items.firstWhere((item) => item.value == value);
              onIdChanged((selectedItem.key as ValueKey).value as int);

              setState(() {
                if (_submitted) {
                  _formKey.currentState?.validate();
                }
              });
            },
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    try {
      FocusScope.of(context).unfocus();

      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print("_submitForm clicked");
        }

        /*String followUpAction =
            "<DocumentElement><FollowUpAction><Department>$selectedDepartmentId</Department><FollowUpExecutive>$selectedExecutiveId</FollowUpExecutive><FollowUpAction>${_visitFollowUpActionController.text}</FollowUpAction><FollowUpDate>${_dateController.text}</FollowUpDate></FollowUpAction></DocumentElement>";*/
        final responseData = await VisitEntryService().visitEntry(
            executiveId ?? 0,
            widget.customerType,
            widget.customerId,
            executiveId ?? 0,
            address,
            profileCode ?? '',
            position.latitude,
            position.longitude,
            1,
            widget.visitFeedback,
            "",
            widget.visitPurposeId,
            widget.personMetId,
            widget.jointVisitWithIds,
            "",
            "",
            "",
            "",
            "",
            0,
            0,
            userId ?? 0,
            "",
            "",
            'No',
            "",
            "",
            false,
            "",
            "",
            token);

        if (responseData.status == 'Success') {
          String s = responseData.s;
          if (kDebugMode) {
            print(s);
          }
          if (s.isNotEmpty) {
            if (kDebugMode) {
              print('Add Visit DSR Error s not empty');
            }
            toastMessage.showInfoToastMessage(s);
            if (s.contains('::')) {
              toastMessage.showInfoToastMessage(
                  'Please check the customer details and try again.');
            } else {
              toastMessage.showInfoToastMessage(
                  'Failed to add DSR entry. Please try again.');
            }
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to add DSR entry: $e");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to add DSR entry: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void getAddressData() async {
    position = await locationService.getCurrentLocation();
    if (kDebugMode) {
      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    }

    address = await locationService.getAddressFromLocation();
    if (kDebugMode) {
      print("address: $address");
    }
  }
}
