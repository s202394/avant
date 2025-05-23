import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:avant/service/fetch_location_task.dart';
import 'package:avant/service/location_service.dart';
import 'package:avant/views/custom_text.dart';
import 'package:avant/visit/customer_search.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:avant/visit/self_stock_entry.dart';
import 'package:avant/visit/visit_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'customer/customer_list.dart';
import 'model/check_in_check_out_response.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late SharedPreferences prefs;
  final ToastMessage _toastMessage = ToastMessage();
  DatabaseHelper databaseHelper = DatabaseHelper();

  Future<List<MenuData>> futureMenuData = Future.value([]);
  Future<PlanResponse> futurePlanResponse = Future.value(
      PlanResponse(status: "Success", todayPlan: [], tomorrowPlan: []));
  late String? token;
  int? profileId;
  int? userId;
  String? profileName;
  int? executiveId;
  String? executiveName;
  String? profileCode;
  String? executiveCode;
  String? mobileNumber;
  String? upHierarchy;
  String? downHierarchy;

  bool _hasInternet = true;
  bool isPunchedIn = false;

  bool _isPermissionRequesting = false;

  Timer? _timer;

  Position? currentLocation;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    _initialize();

    _loadPunchState();

    // _requestLocationPermission();
  }

  Future<void> _startTracking() async {
    await Workmanager().registerPeriodicTask(
      "locationTask",
      "trackLocation",
      frequency: const Duration(minutes: 1),
    );
  }

  Future<void> _stopTracking() async {
    await Workmanager().cancelAll();
  }

/*  Future<void> _initForegroundTask() async {
    if (kDebugMode) {
      print('Initializing Location Foreground Task');
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'dart_crm',
        channelName: 'DART CRM',
        channelDescription: 'This is a foreground service channel',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // Task run interval in milliseconds
        autoRunOnBoot: true, // Optionally auto-start task on boot
        allowWakeLock: true, // Optional
        allowWifiLock: true, // Optional
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    // Check if location permission is already granted
    if (await Permission.location.isGranted) {
      if (kDebugMode) {
        print("Location permission already granted");
      }
      _initForegroundTask();
    } else {
      // Request location permission
      var status = await Permission.location.request();

      if (status.isGranted) {
        if (kDebugMode) {
          print("Location permission granted");
        }
        _initForegroundTask();
      } else if (status.isDenied) {
        if (kDebugMode) {
          print("Location permission denied");
        }
        // Optionally: Prompt user to open app settings to grant permission
      } else if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          print(
              "Location permission permanently denied. Open settings to change permission.");
        }
        await openAppSettings(); // Open app settings
      }
    }
  }

  Future<void> _requestBackgroundLocationPermission() async {
    var status = await Permission.locationAlways.request();

    if (status.isGranted) {
      if (kDebugMode) {
        print("Background location permission granted");
        _initForegroundTask();
      }
    } else if (status.isDenied) {
      if (kDebugMode) {
        print("Background location permission denied");
      }
    } else if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        print(
            "Background location permission permanently denied. Open settings to change permission.");
      }
      await openAppSettings();
    }
  }

  void handleLocationPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.location.isGranted) {
        if (kDebugMode) {
          print("Location permission already granted.");
        }
        _initForegroundTask();
      } else {
        var status = await Permission.location.request();

        if (status.isGranted) {
          // Extract the major Android version number and convert it to an integer
          int androidVersion =
              int.tryParse(Platform.version.split('.')[0]) ?? 0;

          // API level 29 (Android 10) and higher requires background location permission
          if (androidVersion >= 29) {
            await _requestBackgroundLocationPermission();
          }
        } else {
          if (kDebugMode) {
            print("Location permission denied.");
          }
        }
      }
    }
  }

  void requestLocationPermission() async {
    if (Platform.isAndroid) {
      // Extract major Android version (first part of the string)
      int androidVersion = int.tryParse(Platform.version.split('.')[0]) ?? 0;

      // Compare Android version
      if (androidVersion >= 29) {
        await Permission.locationAlways
            .request(); // Request background location permission for Android 10+
      } else {
        await Permission.location
            .request(); // Request regular location permission for older versions
      }
    }
  }*/

  /*@override
  void dispose() {
    if (kDebugMode) {
      print('Location dispose');
    }
    WidgetsBinding.instance.removeObserver(this);
    stopForegroundTask();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (kDebugMode) {
        print('Location Foreground Service Start paused');
      }
      // App is in background, start foreground service
      startForegroundService();
    } else if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('Location Foreground Task Stop resumed');
      }
      // App is in foreground, stop foreground service and start Timer
      stopForegroundTask();
    }
  }*/

  void startForegroundTask() {
    if (kDebugMode) {
      print('Location Foreground Task Start');
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Your task to be performed every minute
      fetchLocation();
    });
  }

  void stopForegroundTask() {
    if (kDebugMode) {
      print('Location Foreground Service Stop');
    }
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void fetchLocation() async {
    prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token') ?? '';
    executiveId = await getExecutiveId() ?? 0;
    userId = await getUserId() ?? 0;
    isPunchedIn = prefs.getBool('isPunchedIn') ?? false;
    if (isPunchedIn) {
      print("Fetching location...");
      LocationService()
          .sendLocationToServer(executiveId ?? 0, userId ?? 0, token ?? '');
    }
  }

  Future<void> startForegroundService() async {
    if (!mounted) {
      return;
    }
    if (_isPermissionRequesting) return; // Prevent duplicate requests
    _isPermissionRequesting = true;

    try {
      if (await Permission.notification.isDenied) {
        PermissionStatus status = await Permission.notification.request();

        if (!status.isGranted) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Permission Required"),
                content: const Text(
                    "Notification permission is required for this feature."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return; // Exit if permission was not granted
        }
      }

      if (await Permission.notification.isGranted) {
        await FlutterForegroundTask.startService(
            notificationTitle: 'DART CRM',
            notificationText: 'Location Tracking');
        return;
      }
    } catch (e) {
      debugPrint("Error starting foreground service: $e");
    } finally {
      _isPermissionRequesting = false; // Reset flag
    }
  }

  void startCallback() {
    if (kDebugMode) {
      print('Location startCallback');
    }
    FlutterForegroundTask.setTaskHandler(FetchLocationTask());
  }

  void _initialize() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    userId = await getUserId();
    profileId = await getProfileId();
    profileName = await getProfileName() ?? '';
    executiveId = await getExecutiveId();
    executiveName = await getExecutiveName() ?? '';
    mobileNumber = await getExecutiveMobile();
    profileCode = await getProfileCode() ?? '';
    executiveCode = await getExecutiveCode() ?? '';
    _hasInternet = await checkInternetConnection();

    checkPunchStateOnAppStart();

    if (_hasInternet) {
      // Load the menu data from the database
      List<MenuData> menuDataList = await DatabaseHelper().getMenuDataFromDB();

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

    if (kDebugMode) {
      print('executiveId:$executiveId');
    }

    await SetupValuesService().setupValues(token ?? '');

    setState(() {});
  }

  // Load Punch State from SharedPreferences
  Future<void> _loadPunchState() async {
    if (kDebugMode) {
      print('Location _loadPunchState');
    }
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isPunchedIn = prefs.getBool('isPunchedIn') ?? false;
    });

    /*if (isPunchedIn) {
      if (kDebugMode) {
        print('Location startForegroundTask');
      }
      WidgetsBinding.instance.addObserver(this);
      startForegroundTask();
    }*/

    checkTracking();
  }

  // Update Punch State in SharedPreferences
  Future<void> _updatePunchState(bool punchedIn) async {
    // Get the current date and time
    final DateTime currentTime = DateTime.now();

    // Update punch-in state and set shared preferences
    setState(() {
      isPunchedIn = punchedIn;
    });

    if (punchedIn) {
      // If punched in, store the current time as punch-in time
      await prefs.setString('punchInTime', currentTime.toIso8601String());
    } else {
      // If punched out, reset the punch-in time to 0
      await prefs.setString('punchInTime', '0');
    }

    if (!punchedIn) {
      if (kDebugMode) {
        print('Location punchedIn false DART CRM cancel');
      }
      // await Workmanager().cancelByUniqueName("DART CRM");
    }

    // Store the punch-in state
    await prefs.setBool('isPunchedIn', punchedIn);

    checkTracking();
  }

  Future<void> checkPunchStateOnAppStart() async {
    // Retrieve the stored punch-in time
    String? punchInTime = prefs.getString('punchInTime');

    if (punchInTime != null && punchInTime != '0') {
      // Parse the stored punch-in time
      DateTime lastPunchInTime = DateTime.parse(punchInTime);
      DateTime currentTime = DateTime.now();

      // Check if the dates are different (i.e., a new day has started)
      if (currentTime.day != lastPunchInTime.day ||
          currentTime.month != lastPunchInTime.month ||
          currentTime.year != lastPunchInTime.year) {
        // If the date has changed, reset punch-in state to false
        setState(() {
          isPunchedIn = false;
        });
        if (kDebugMode) {
          print('Date changed isPunchedIn : $isPunchedIn');
        }
        await _updatePunchState(false);
      }
    }
  }

  // Method to handle Punch In
  void punchIn() async {
    await _updatePunchState(true);

    if (kDebugMode) {
      print('Location punchedIn true startForegroundTask');
    }
    // WidgetsBinding.instance.addObserver(this);
    // startForegroundTask();

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
                Navigator.of(context).pop();
                logout();
              },
              onCancel: () {
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

  String getProfileNameWithCode() {
    return '$profileName ($profileCode)';
  }

  String getExecutiveNameWithCode() {
    return '$executiveName ($executiveCode)';
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
            title: Image.asset('images/dart_logo.png', height: 30),
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Image.asset('images/avant-logo.png', height: 30),
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
                      CustomText(executiveName ?? "", color: Colors.black),
                      CustomText(profileName ?? "", color: Colors.black),
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
                        accountName: Text(getExecutiveNameWithCode(),
                            style: const TextStyle(color: Colors.white)),
                        accountEmail: Text(getProfileNameWithCode(),
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
                          title: CustomText(
                            menuName,
                            fontSize: 14,
                          ),
                          children: groupedMenuData[menuName]!.map((childMenu) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ListTile(
                                title: CustomText(
                                  childMenu.childMenuName,
                                  fontSize: 12,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (childMenu.menuName == 'Customer') {
                                    if (childMenu.childMenuName ==
                                        'School List') {
                                      gotoNewCustomer('School');
                                    } else if (childMenu.childMenuName ==
                                        'Institute List') {
                                      // gotoNewCustomer('Institute');
                                    } else if (childMenu.childMenuName ==
                                        'Trade List') {
                                      gotoNewCustomer('Trade');
                                    } else if (childMenu.childMenuName ==
                                        'Library List') {
                                      gotoNewCustomer('Library');
                                    }
                                  } else {
                                    gotoWebView(childMenu.linkURL);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      ListTile(
                        title: const CustomText('Visit DSR', fontSize: 14),
                        onTap: () {
                          Navigator.pop(context);
                          goToCustomerSearchVisit();
                        },
                      ),
                      ListTile(
                        title: const CustomText('Customer Sample Request',
                            fontSize: 14),
                        onTap: () {
                          Navigator.pop(context);
                          goToCustomerSearchSampling();
                        },
                      ),
                      ListTile(
                        title: const CustomText('Self Stock Sample Request',
                            fontSize: 14),
                        onTap: () {
                          Navigator.pop(context);
                          goToSelfStockEntry();
                        },
                      ),
                      ListTile(
                        title: const CustomText(customerSampleApproval,
                            fontSize: 14),
                        onTap: () {
                          Navigator.pop(context);
                          gotoCustomerSampleApproval();
                        },
                      ),
                      ListTile(
                        title: const CustomText('Self Stock Request Approval',
                            fontSize: 14),
                        onTap: () {
                          Navigator.pop(context);
                          gotoSelfStockRequestApproval();
                        },
                      ),
                      ListTile(
                        title: const CustomText('Logout', fontSize: 14),
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
            child: CustomText(
              'Travel Plan',
              textAlign: TextAlign.start,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
          title: const CustomText('Confirm Exit'),
          content: const CustomText('Do you really want to exit the app?',
              fontSize: 14),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const CustomText('Cancel', fontSize: 14),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const CustomText('Exit', fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  void gotoNewCustomer(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerList(type: type)),
    );
  }

  void gotoWebView(String linkURL) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => WebViewScreen(url: linkURL)));
  }

  void goToCustomerSearchVisit() {
    deleteAllCartItems();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerSearch(
          type: 'Visit',
          title: 'DSR Entry',
        ),
      ),
    );
  }

  void goToCustomerSearchSampling() {
    deleteAllCartItems();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerSearch(
            type: 'Sampling', title: 'Customer Sample Request'),
      ),
    );
  }

  void goToSelfStockEntry() {
    deleteAllCartItems();
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SelfStockEntry()));
  }

  void gotoCustomerSampleApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const ApprovalListForm(type: customerSampleApproval)),
    );
  }

  void gotoSelfStockRequestApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const ApprovalListForm(type: 'Self Stock Request Approval')),
    );
  }

  void deleteAllCartItems() {
    databaseHelper.deleteAllCartItems();
    databaseHelper.deleteAllFollowUpActionCarts();
  }

  void checkTracking() {
    if (isPunchedIn) {
      // _startTracking();
      startListeningLocation();
    } else {
      // _stopTracking();
      subscription?.cancel();
    }
  }

  locationPermission({VoidCallback? isSuccess}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.openAppSettings();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return Future.error(
          'Location permission is permanently denied, we annot request permissions.');
    }
    {
      isSuccess?.call();
    }
  }

  startListeningLocation() {
    locationPermission(isSuccess: () async {
      subscription = Geolocator.getPositionStream(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                foregroundNotificationConfig:
                    const ForegroundNotificationConfig(
                        notificationTitle: "Location fetching in background.",
                        notificationText:
                            "Your current location is listed in background.",
                        enableWakeLock: true))
            : AppleSettings(
                accuracy: LocationAccuracy.high,
                activityType: ActivityType.fitness,
                pauseLocationUpdatesAutomatically: false,
                showBackgroundLocationIndicator: false),
      ).listen((event) async {
        currentLocation = event;
        log(currentLocation.toString(), name: 'currentLocation');

        sendLocationToServer();
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> sendLocationToServer() async {
    log('sendLocationToServer called');
    CheckInCheckOutService service = CheckInCheckOutService();

    String executiveLocationXml =
        "<DocumentElement><ExecutiveLocation><DateTime>${getCurrentDateTimeWithSecond()}</DateTime><Lat>${currentLocation?.latitude ?? 0.0}</Lat><Long>${currentLocation?.longitude ?? 0.0}</Long></ExecutiveLocation></DocumentElement>";

    CheckInCheckOutResponse responseData = await service.fetchExecutiveLocation(
        executiveId ?? 0, userId ?? 0, executiveLocationXml, token ?? '');

    if (responseData.status == 'Success') {
      String msgType = responseData.success.msgType;
      String msgText = responseData.success.msgText;
      if (msgType.isNotEmpty && msgType == 's') {
        log(msgText);
      } else if (msgType.isNotEmpty && msgType == 'e') {
        log('Failed to send location : $msgText');
      } else {
        log('Failed to send location $msgType $msgText');
      }
    } else {
      log('Failed to send location ${responseData.status}');
    }
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
                    title: CustomText(
                      '${plan.customerName} (${plan.customerCode})',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(plan.address, fontSize: 14),
                        CustomText(plan.city, fontSize: 14),
                        CustomText(plan.state, fontSize: 14),
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
          return const Center(child: CustomText('No data available'));
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
                    title: CustomText(
                      '${plan.customerName} (${plan.customerCode})',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(plan.address, fontSize: 14),
                        CustomText(plan.city, fontSize: 14),
                        CustomText(plan.state, fontSize: 14),
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
          return const Center(child: CustomText('No data available'));
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
        title: const CustomText('WebView'),
      ),
      body: Center(
        child: CustomText('Load URL: $url', fontSize: 14),
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
          const CustomText('No Internet Connection',
              fontSize: 16, fontWeight: FontWeight.bold),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const CustomText('Retry'),
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
          const CustomText('Server Error',
              fontSize: 16, fontWeight: FontWeight.bold),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const CustomText('Retry'),
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
