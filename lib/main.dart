import 'dart:async';

import 'package:avant/home.dart';
import 'package:avant/login.dart';
import 'package:avant/service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api/api_service.dart';
import 'common/common.dart';
import 'dialog/custom_alert_dialog.dart';
import 'model/login_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask(
    "DART CRM",
    "DART CRM",
    frequency: const Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
    ),
  );

  runApp(
    MaterialApp(
      title: 'DART CRM',
      theme: ThemeData(
        primaryColor: const Color(0xFFFCF2DB),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  late SharedPreferences prefs;

  bool _isAlreadyLogin = false;
  String emailOrPhone = '';
  String password = '';
  String token = '';

  _loadData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAlreadyLogin = prefs.getBool('is_already_login') ?? false;
      emailOrPhone=  prefs.getString('username')??'';
      password= prefs.getString('password')??'';
      token= prefs.getString('token')??'';
    });
  }

  @override
  void initState() {
    super.initState();

    _loadData();
    Timer(const Duration(seconds: 3), () {
      if(_isAlreadyLogin){
        _loginUser(emailOrPhone,password);
      }else{
        _navigateToHomePage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: AssetImage('images/dart_logo.png')),
              SizedBox(height: 50),
              Image(image: AssetImage('images/avant-logo.png'), height: 30),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _loginUser(String emailOrPhone, String password) async {
    final String ipAddress = await getIpAddress();
    final String deviceInfo = await getDeviceInfo();
    final String deviceId = await getDeviceId();

    if (kDebugMode) {
      print(
          'Login details ipAddress : $ipAddress , deviceInfo : $deviceInfo , deviceId : $deviceId');
    }

    final responseData = await LoginService().login(
        emailOrPhone, password, ipAddress, deviceId, deviceInfo, token);
    final loginResponse = await LoginResponse.fromJson(responseData);
    if (loginResponse.executiveData.loginBlocked == 'N') {
      final String? userId = prefs.getString('userId');

      if (kDebugMode) {
        print('Login successful! User ID: $userId');
      }
      _saveData(emailOrPhone, password, true);
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SingleAlertDialog(
              title: "Alert",
              content: "You are not allowed to login. Please contact to admin.",
              onOk: () {
                // Handle ok action
                Navigator.of(context).pop();
              },
            );
          },
        );
      }
    }
  }

  Future<void> _saveData(
      String emailOrPhone, String password, bool value) async {
    prefs.setString('username', emailOrPhone);
    prefs.setString('password', password);
    prefs.setBool('is_already_login', value);

    _navigateToHomePage();
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
        _isAlreadyLogin ? const HomePage() : const LoginPage(),
      ),
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String token = prefs.getString('token') ?? '';
    int executiveId = await getExecutiveId() ?? 0;
    int userId = await getUserId() ?? 0;
    bool isPunchedIn = prefs.getBool('isPunchedIn') ?? false;

    if (!isPunchedIn) {
      await Workmanager().cancelByUniqueName("DART CRM");
    } else {
      if (executiveId > 0 && userId > 0) {
        await LocationService()
            .sendLocationToServer(executiveId, userId, token);
      } else {
        if (kDebugMode) {
          print(
              'Did not send location due to executiveId:$executiveId, userId:$userId');
        }
      }
    }
    return Future.value(true);
  });
}
