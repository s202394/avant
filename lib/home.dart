import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/db/application_setup_db.dart';
import 'package:avant/login.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/travel_plan_model.dart';
import 'package:avant/self_stock_request_approval/self_stock_request_approval_form.dart';
import 'package:avant/visit/customer_search_visit.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:avant/visit/visit_detail_page.dart';
import 'package:avant/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/dialog/custom_alert_dialog.dart';
import 'package:avant/new_customer/new_customer_form.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  void initState() {
    super.initState();
    _initialize();
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
      setState(() {
        if (profileId != null) {
          futureMenuData = MenuService().getMenus(profileId!, token!);
        }
        if (executiveId != null) {
          futurePlanResponse =
              TravelPlanService().fetchTravelPlans(executiveId!, token!);
        }
      });
    } else {
      setState(() {
        futureMenuData = DatabaseHelper().getMenuDataFromDB();
        futurePlanResponse = Future.value(
            PlanResponse(status: "Success", todayPlan: [], tomorrowPlan: []));
      });
    }
  }

  Future<void> _logout() async {
    if (!await _checkInternetConnection()) return;

    try {
      print('GOING TO LOGOUT');
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
    } catch (e) {
      print('Logout Error $e');
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all previous routes
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("DART CRM"),
          leading: Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Image.asset(
              'images/logo.png', // Add your logo image to assets
              height: 30,
            ),
          ),
          backgroundColor: Color(0xFFFFF8E1),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(30.0),
            child: Container(
              color: Color(0xFFFFE082), // Slightly darker color
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      executiveName ?? "",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      profileName ?? "",
                      style: TextStyle(color: Colors.black),
                    ),
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
                print("ConnectionState.waiting");
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print('No menu data available');
                return Center(child: Text('No menu data available'));
              } else {
                print('data : ${snapshot.data!.length}');
                final groupedMenuData = _groupMenuData(snapshot.data!);
                print('data : ${groupedMenuData.length}');
                return ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    UserAccountsDrawerHeader(
                      accountName: Text(executiveName ?? ""),
                      accountEmail: Text(mobileNumber ?? ""),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: AssetImage('images/clock.png'),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                    ),
                    ...groupedMenuData.keys.map((menuName) {
                      return ExpansionTile(
                        title: Text(menuName),
                        children: groupedMenuData[menuName]!.map((childMenu) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            // Adjust the padding value as needed
                            child: ListTile(
                              title: Text(childMenu.childMenuName),
                              onTap: () {
                                Navigator.pop(context);
                                // Handle navigation based on menuName and childMenuName
                                if (childMenu.menuName == 'Visit/ DSR' &&
                                    childMenu.childMenuName ==
                                        'FollowUp Action Taken') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerSearchVisit()),
                                  );
                                } else if (childMenu.menuName ==
                                    'Self Stock Approval') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SelfStockRequestApprovalForm()),
                                  );
                                } else if (childMenu.menuName == 'Customer' &&
                                    (childMenu.childMenuName == 'School List' ||
                                        childMenu.childMenuName ==
                                            'Institute List' ||
                                        childMenu.childMenuName ==
                                            'Trade List' ||
                                        childMenu.childMenuName ==
                                            'Library List')) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NewCustomerForm(
                                           customerType:  childMenu.childMenuName)),
                                  );
                                } else {
                                  // Handle other menu items or navigate to a web view
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => WebViewScreen(
                                            url: childMenu.linkURL)),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                    ListTile(
                      title: Text('Logout'),
                      onTap: () async {
                        _logout();
                      },
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
        bottomNavigationBar: BottomAppBar(
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
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue,
          child: Padding(
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
        TabBar(
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
              TodayPlanList(futurePlanResponse: futurePlanResponse),
              TomorrowPlanList(futurePlanResponse: futurePlanResponse),
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
}

class TodayPlanList extends StatelessWidget {
  final Future<PlanResponse> futurePlanResponse;

  TodayPlanList({required this.futurePlanResponse});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanResponse>(
      future: futurePlanResponse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.todayPlan.length > 0) {
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
                            schoolName:
                                '${plan.customerName} (${plan.customerCode})',
                            address:
                                '${plan.address}, ${plan.city} - ${plan.state}',
                            visitDate: '16-Jun 2024',
                            visitBy: 'Sanjay Chawla',
                            visitPurpose: plan.visitPurpose,
                            jointVisit: 'Abhishek Srivastava',
                            personMet: 'Mrs. Sonal Verma',
                            samples: [
                              {
                                'name': 'Mrs. S. Banerjee',
                                'subject': 'English',
                                'type': 'Promotional Copy',
                                'quantity': '1'
                              },
                              {
                                'name': 'Mr. Sanjeev Singh',
                                'subject': 'Maths',
                                'type': 'Promotional Copy',
                                'quantity': '1'
                              },
                            ],
                            followUpAction:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                            followUpDate: '30 Jun 24',
                            visitFeedback:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut elit tellus, luctus nec ullamcorper mattis, pulvinar dapibus leo.',
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                ],
              );
            },
          );
        } else {
          return Center(child: Text('No data available'));
        }
      },
    );
  }
}

class TomorrowPlanList extends StatelessWidget {
  final Future<PlanResponse> futurePlanResponse;

  TomorrowPlanList({required this.futurePlanResponse});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanResponse>(
      future: futurePlanResponse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.tomorrowPlan.length > 0) {
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
                            schoolName:
                                '${plan.customerName} (${plan.customerCode})',
                            address:
                                '${plan.address}, ${plan.city} - ${plan.state}',
                            visitDate: '17-Jun 2024',
                            visitBy: 'Sanjay Chawla',
                            visitPurpose: plan.visitPurpose,
                            jointVisit: 'Abhishek Srivastava',
                            personMet: 'Mrs. Sonal Verma',
                            samples: [
                              {
                                'name': 'Mrs. S. Banerjee',
                                'subject': 'English',
                                'type': 'Promotional Copy',
                                'quantity': '1'
                              },
                              {
                                'name': 'Mr. Sanjeev Singh',
                                'subject': 'Maths',
                                'type': 'Promotional Copy',
                                'quantity': '1'
                              },
                            ],
                            followUpAction:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                            followUpDate: '01 Jul 24',
                            visitFeedback:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut elit tellus, luctus nec ullamcorper mattis, pulvinar dapibus leo.',
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                ],
              );
            },
          );
        } else {
          return Center(child: Text('No data available'));
        }
      },
    );
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  WebViewScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    // Implement WebView to load the given URL
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView'),
      ),
      body: Center(
        child: Text('Load URL: $url'),
      ),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRefresh;

  NoInternetScreen({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: Text('Retry'),
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
