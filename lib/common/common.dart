import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Validator {
  //Check Valid Email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  //Check Valid Mobile Number
  static bool isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^\d{10}$');
    return mobileRegex.hasMatch(mobile);
  }
}

//Get Ip Address
Future<String> getIpAddress() async {
  try {
    final response =
        await http.get(Uri.parse('https://api.ipify.org?format=json'));
    if (response.statusCode == 200) {
      final ip = jsonDecode(response.body)['ip'];
      return ip;
    } else {
      print('Failed to fetch IP address');
      return 'Unknown';
    }
  } catch (e) {
    print('Error fetching IP address: $e');
    return 'Unknown';
  }
}

//Get Device Information
Future<String> getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceInfoString;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceInfoString =
        'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), '
        '${androidInfo.brand} ${androidInfo.model}';
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceInfoString = '${iosInfo.name}, iOS ${iosInfo.systemVersion}, '
        '${iosInfo.model}, ${iosInfo.utsname.machine}';
  } else {
    deviceInfoString = 'Unknown device';
  }

  return deviceInfoString;
}

//Get Device Information
String getPlatformName() {
  if (Platform.isAndroid) {
    return 'Android';
  } else if (Platform.isIOS) {
    return 'iOS';
  } else if (Platform.isLinux) {
    return 'Linux';
  } else if (Platform.isMacOS) {
    return 'MacOS';
  } else if (Platform.isWindows) {
    return 'Windows';
  } else {
    return 'Unknown';
  }
}

Future<String> getDeviceId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id ?? 'Unknown'; // Unique ID on Android
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? 'Unknown'; // Unique ID on iOS
  } else {
    deviceId = 'Unsupported platform';
  }

  return deviceId;
}

//Check Internet Connection
Future<bool> checkInternetConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());

  print('checkInternetConnection : $connectivityResult');

  if (connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi ||
      connectivityResult == ConnectivityResult.ethernet) {
    return true;
  } else {
    return false;
  }
}

String getCurrentDate({String format = 'dd MMM yyyy'}) {
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat(format);
  return formatter.format(now);
}

String getCurrentDateTime({String format = 'dd MMM yyyy HH:MM a'}) {
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat(format);
  return formatter.format(now);
}
