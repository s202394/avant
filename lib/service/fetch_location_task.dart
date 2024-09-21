import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/login_model.dart';
import 'location_service.dart';

// Step 1: Define the background task
class FetchLocationTask extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Called when the task starts
    if (kDebugMode) {
      print('FetchLocationTask onStart called $timestamp');
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Called every repeat interval
    if (kDebugMode) {
      print('FetchLocationTask onRepeatEvent called $timestamp');
    }
    fetchLocation();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Clean up resources when the task is destroyed
    if (kDebugMode) {
      print('FetchLocationTask onDestroy called $timestamp');
    }
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) {
    if (kDebugMode) {
      print('FetchLocationTask onEvent called $timestamp');
    }
    // TODO: implement onEvent
    throw UnimplementedError();
  }

  void fetchLocation() async {
    if (kDebugMode) {
      print('FetchLocationTask fetchLocation called');
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String token = prefs.getString('token') ?? '';
    int executiveId = await getExecutiveId() ?? 0;
    int userId = await getUserId() ?? 0;
    bool isPunchedIn = prefs.getBool('isPunchedIn') ?? false;

    if (isPunchedIn) {
      if (executiveId > 0 && userId > 0) {
        await LocationService()
            .sendLocationToServer(executiveId, userId, token);
      } else {
        if (kDebugMode) {
          print(
              'Did not send location due to executiveId:$executiveId, userId:$userId');
        }
      }
    } else {
      if (kDebugMode) {
        print('Did not send location user has already check out');
      }
    }
  }
}
