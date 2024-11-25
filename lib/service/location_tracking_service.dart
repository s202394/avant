import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class LocationTrackingService extends StatefulWidget {
  const LocationTrackingService({super.key});

  @override
  _LocationTrackingServiceState createState() => _LocationTrackingServiceState();
}

class _LocationTrackingServiceState extends State<LocationTrackingService> {
  bool isCheckedIn = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCheckInState();
    _requestLocationPermission();
    if (isCheckedIn) {
      _startLocationTracking();
    }
  }

  Future<void> _loadCheckInState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    });
  }

  Future<void> _startLocationTracking() async {
    if (await Permission.location.isGranted) {
      _initForegroundTask();
      _timer = Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
        _sendLocationToApi();
      });
    }
  }

  Future<void> _sendLocationToApi() async {

  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_channel',
        channelName: 'Location Tracking',
        channelDescription: 'Tracking user location in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(),
    );

    // FlutterForegroundTask.startService();
  }

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.isGranted) {
      if (await Permission.locationAlways.isGranted || await Permission.locationWhenInUse.isGranted) {
        if (isCheckedIn) {
          _startLocationTracking();
        }
      }
    } else {
      var status = await Permission.location.request();
      if (status.isGranted) {
        _startLocationTracking();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    FlutterForegroundTask.stopService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking Service'),
      ),
      body: Center(
        child: SwitchListTile(
          title: const Text('Checked In'),
          value: isCheckedIn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            setState(() {
              isCheckedIn = value;
              prefs.setBool('isCheckedIn', value);
            });
            if (isCheckedIn) {
              _startLocationTracking();
            } else {
              FlutterForegroundTask.stopService();
            }
          },
        ),
      ),
    );
  }
}
