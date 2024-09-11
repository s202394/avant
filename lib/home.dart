import 'package:avant/api/api_service.dart';
import 'package:avant/approval/approval_list_form.dart';
import 'package:avant/checked_in.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/constants.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/dialog/custom_alert_dialog.dart';
import 'package:avant/login.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/travel_plan_model.dart';
import 'package:avant/new_customer/new_customer_school_form1.dart';
import 'package:avant/visit/customer_search.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:avant/visit/visit_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/setup_values.dart';
import 'new_customer/new_customer_trade_library_form1.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late SharedPreferences prefs;
  final ToastMessage _toastMessage = ToastMessage();

  Future<List<MenuData>> futureMenuData = Future.value([]);
  Future<PlanResponse> futurePlanResponse = Future.value(
      PlanResponse(status: "Success", todayPlan: [], tomorrowPlan: []));
  late String? token;
  int? profileId;
  int? userId;
  String? profileName;
  int? executiveId;
  String? executiveName;
  String? mobileNumber;
  String? upHierarchy;
  String? downHierarchy;

  bool _hasInternet = true;
  bool isPunchedIn = false;

  @override
  void initState() {
    super.initState();
    _initialize();

    _loadPunchState();
  }

  void _initialize() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    userId = await getUserId();
    profileId = await getProfileId();
    profileName = await getProfileName();
    executiveId = await getExecutiveId();
    executiveName = await getExecutiveName();
    mobileNumber = await getExecutiveMobile();
    _hasInternet = await checkInternetConnection();

    if (_hasInternet) {
      // Load the menu data from the database
      List<MenuData> menuDataList = await DatabaseHelper().getMenuDataFromDB();
      if (kDebugMode) {
        print('Menu data from DB: $menuDataList');
      }

      if (menuDataList.isEmpty) {
        if (kDebugMode) {
          print('No menu data in DB, fetching from API.');
        }
        // Fetch data from API if no data in DB
        futureMenuData = MenuService().getMenus(profileId!, token!);
      } else {
        if (kDebugMode) {
          print('Menu data found in DB.');
        }
        futureMenuData = Future.value(menuDataList);
      }

      // Fetch setup values from SetupValuesService
      /*try {
        List<SetupValues> setupValuesList =
            await SetupValuesService().setupValues(token!);
        if (kDebugMode) {
          print('Setup values: $setupValuesList');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching setup values: $e');
        }
      }
*/
      if (executiveId != null) {
        futurePlanResponse =
            TravelPlanService().fetchTravelPlans(executiveId!, token!);
      }
    } else {
      if (kDebugMode) {
        print('No Internet');
      }
      futureMenuData = DatabaseHelper().getMenuDataFromDB();
      futurePlanResponse = Future.value(
          PlanResponse(status: "Success", todayPlan: [], tomorrowPlan: []));
    }
    setState(() {});
  }

  // Load Punch State from SharedPreferences
  Future<void> _loadPunchState() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isPunchedIn = prefs.getBool('isPunchedIn') ?? false;
    });
  }

  // Update Punch State in SharedPreferences
  Future<void> _updatePunchState(bool punchedIn) async {
    setState(() {
      isPunchedIn = punchedIn;
    });
    await prefs.setBool('isPunchedIn', punchedIn);
  }

  // Method to handle Punch In
  void punchIn() async {
    // You can also trigger an API call here if needed
    await _updatePunchState(true);
    if (kDebugMode) {
      print("You have punched in.");
    }
  }

  // Method to handle Punch Out
  void punchOut() async {
    await _updatePunchState(false);
    if (kDebugMode) {
      print("You have punched out.");
    }
  }

  Future<void> _logout() async {
    if (!await _checkInternetConnection()) return;

    try {
      if (kDebugMode) {
        print('GOING TO LOGOUT');
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: "Logout",
              content: "You are sure you want to logout.",
              onConfirm: () {
                // Handle confirm action
                Navigator.of(context).pop();
                logout();
              },
              onCancel: () {
                // Handle cancel action
                Navigator.of(context).pop();
              },
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Logout Error $e');
      }
      clearDataAfterLogout();
    }
  }

  void logout() async {
    await LoginService().logout(userId ?? 0, token ?? "");
    clearDataAfterLogout();
  }

  void clearDataAfterLogout() async {
    await DatabaseHelper().clearDatabase();
    await clearSharedPreferences();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when back button is pressed
        return await _showExitConfirmationDialog(context) ?? false;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Image.asset('images/dart_crm.jpeg', height: 30),
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Image.asset('images/logo.png', height: 30),
            ),
            backgroundColor: const Color(0xFFFFF8E1),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(30.0),
              child: Container(
                color: const Color(0xFFFFE082),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(executiveName ?? "",
                          style: const TextStyle(color: Colors.black)),
                      Text(profileName ?? "",
                          style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          endDrawer: Drawer(
            child: FutureBuilder<List<MenuData>>(
              future: futureMenuData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No menu data available'));
                } else {
                  final groupedMenuData = _groupMenuData(snapshot.data!);
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      UserAccountsDrawerHeader(
                        accountName: Text(executiveName ?? "",
                            style: const TextStyle(color: Colors.white)),
                        accountEmail: Text(mobileNumber ?? "",
                            style: const TextStyle(color: Colors.white)),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            (executiveName?.isNotEmpty == true)
                                ? executiveName![0]
                                : '',
                            style: const TextStyle(
                                fontSize: 40.0, color: Colors.blue),
                          ),
                        ),
                        decoration: const BoxDecoration(color: Colors.blue),
                      ),
                      PunchInToggleSwitch(isPunchedIn: isPunchedIn),
                      ...groupedMenuData.keys.map((menuName) {
                        return ExpansionTile(
                          title: Text(menuName),
                          children: groupedMenuData[menuName]!.map((childMenu) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ListTile(
                                title: Text(childMenu.childMenuName),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (childMenu.menuName == 'Customer') {
                                    if (childMenu.childMenuName ==
                                        'School List') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NewCustomerSchoolForm1(
                                                  type: 'School'),
                                        ),
                                      );
                                    } else if (childMenu.childMenuName ==
                                        'Institute List') {
                                    } else if (childMenu.childMenuName ==
                                        'Trade List') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NewCustomerTradeLibraryForm1(
                                                  type: 'Trade'),
                                        ),
                                      );
                                    } else if (childMenu.childMenuName ==
                                        'Library List') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NewCustomerTradeLibraryForm1(
                                                  type: 'Library'),
                                        ),
                                      );
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebViewScreen(
                                            url: childMenu.linkURL),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      ListTile(
                        title: const Text('Visit DSR'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerSearch(
                                type: 'Visit',
                                title: 'DSR Entry',
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Customer Sample Request'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerSearch(
                                  type: 'Sampling',
                                  title: 'Customer Sample Request'),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text(customerSampleApproval),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ApprovalListForm(
                                    type: customerSampleApproval)),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Self Stock Request Approval'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ApprovalListForm(
                                    type: 'Self Stock Request Approval')),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Logout'),
                        onTap: _logout,
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          body: _hasInternet
              ? _buildContent()
              : NoInternetScreen(onRefresh: _initialize),
          bottomNavigationBar: const BottomAppBar(
            height: 40,
            color: Color(0xFFFFF8E1),
            child: Center(
              child: Text(
                '© 2024 Avant WebTech Pvt. Ltd.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Text(
              'Travel Plan',
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const TabBar(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.blue,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: "Today's Plan"),
            Tab(text: "Tomorrow's Plan"),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              TodayPlanList(
                futurePlanResponse: futurePlanResponse,
                onRefresh: _initialize,
              ),
              TomorrowPlanList(
                futurePlanResponse: futurePlanResponse,
                onRefresh: _initialize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, List<MenuData>> _groupMenuData(List<MenuData> menuDataList) {
    Map<String, List<MenuData>> groupedMenuData = {};
    for (var menuData in menuDataList) {
      if (groupedMenuData.containsKey(menuData.menuName)) {
        groupedMenuData[menuData.menuName]!.add(menuData);
      } else {
        groupedMenuData[menuData.menuName] = [menuData];
      }
    }
    return groupedMenuData;
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Exit'),
          content: const Text('Do you really want to exit the app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Do not exit
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}

class TodayPlanList extends StatelessWidget {
  final Future<PlanResponse> futurePlanResponse;
  final VoidCallback onRefresh;

  const TodayPlanList(
      {super.key, required this.futurePlanResponse, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanResponse>(
      future: futurePlanResponse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          if (kDebugMode) {
            print('Error: ${snapshot.error}');
          }
          return ServerErrorScreen(onRefresh: onRefresh);
        } else if (snapshot.hasData && snapshot.data!.todayPlan.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.todayPlan.length,
            itemBuilder: (context, index) {
              var plan = snapshot.data!.todayPlan[index];
              return Column(
                children: [
                  ListTile(
                    title: Text('${plan.customerName} (${plan.customerCode})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.address),
                        Text(plan.city),
                        Text(plan.state),
                      ],
                    ),
                    trailing: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DsrEntry(
                              customerId: plan.customerId,
                              customerName: plan.customerName,
                              customerCode: plan.customerCode,
                              customerType: plan.customerType,
                              address: plan.address,
                              city: plan.city,
                              state: plan.state,
                            ),
                          ),
                        );
                      },
                      child: Image.asset('images/travel.png',
                          height: 30, width: 30),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitDetailsPage(
                              customerId: plan.customerId,
                              visitId: 0,
                              isTodayPlan: true),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }
}

class TomorrowPlanList extends StatelessWidget {
  final Future<PlanResponse> futurePlanResponse;
  final Function() onRefresh;

  const TomorrowPlanList(
      {super.key, required this.futurePlanResponse, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanResponse>(
      future: futurePlanResponse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          if (kDebugMode) {
            print('Error: ${snapshot.error}');
          }
          return ServerErrorScreen(onRefresh: onRefresh);
        } else if (snapshot.hasData && snapshot.data!.tomorrowPlan.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.tomorrowPlan.length,
            itemBuilder: (context, index) {
              var plan = snapshot.data!.tomorrowPlan[index];
              return Column(
                children: [
                  ListTile(
                    title: Text('${plan.customerName} (${plan.customerCode})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.address),
                        Text(plan.city),
                        Text(plan.state),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitDetailsPage(
                              customerId: plan.customerId,
                              visitId: 0,
                              isTodayPlan: false),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Implement WebView to load the given URL
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
      ),
      body: Center(
        child: Text('Load URL: $url'),
      ),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRefresh;

  const NoInternetScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ServerErrorScreen extends StatelessWidget {
  final VoidCallback onRefresh;

  const ServerErrorScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Server Error',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void testDatabase() async {
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.checkMenuData();
}
