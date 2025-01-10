import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel = MethodChannel('foreground_service');

  static void start() {
    _channel.invokeMethod('startService');
  }

  static void stop() {
    _channel.invokeMethod('stopService');
  }
}
