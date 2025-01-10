import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  _LocationTrackingPageState createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  bool _tracking = false;

  Future<void> _startTracking() async {
    await Workmanager().registerPeriodicTask(
      "locationTask",
      "trackLocation",
      frequency: Duration(minutes: 1),
    );
    setState(() {
      _tracking = true;
    });
  }

  Future<void> _stopTracking() async {
    await Workmanager().cancelAll();
    setState(() {
      _tracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_tracking ? "Tracking Enabled" : "Tracking Disabled"),
            ElevatedButton(
              onPressed: _tracking ? _stopTracking : _startTracking,
              child: Text(_tracking ? "Stop Tracking" : "Start Tracking"),
            ),
          ],
        ),
      ),
    );
  }
}