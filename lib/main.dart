import 'dart:async';

import 'package:avant/home.dart';
import 'package:avant/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Splash Screen',
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
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
            builder: (context) => _isAlreadyLogin ? HomePage() : LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image(image: AssetImage('images/logo.png')),
        ),
      ),
    );
  }
}
