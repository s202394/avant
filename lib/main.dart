import 'dart:async';

import 'package:avant/home.dart';
import 'package:avant/login.dart';
import 'package:avant/service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'model/login_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask("DART CRM", "DART CRM",
      frequency: const Duration(minutes: 1));

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

  _loadData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAlreadyLogin = prefs.getBool('is_already_login') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadData();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              _isAlreadyLogin ? const HomePage() : const LoginPage(),
        ),
      );
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
