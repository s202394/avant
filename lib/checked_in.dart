import 'package:avant/api/api_service.dart';
import 'package:avant/service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/common.dart';
import 'common/toast.dart';
import 'home.dart';
import 'model/login_model.dart';

class PunchInToggleSwitch extends StatefulWidget {
  final bool isPunchedIn;

  const PunchInToggleSwitch({super.key, required this.isPunchedIn});

  @override
  PunchInToggleSwitchState createState() => PunchInToggleSwitchState();
}

class PunchInToggleSwitchState extends State<PunchInToggleSwitch> {
  bool isPunchedIn = false;

  final ToastMessage _toastMessage = ToastMessage();
  final LocationService locationService = LocationService();

  late SharedPreferences prefs;
  late String token;

  bool _isLoading = false;

  int? executiveId;
  int? userId;

  @override
  void initState() {
    super.initState();

    isPunchedIn = widget.isPunchedIn;
    _initialize();
  }

  void _initialize() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    executiveId = await getExecutiveId();
    userId = await getUserId();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<HomePageState>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(color: Colors.grey[850]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPunchedIn ? 'Punched-In' : 'Not Punched-In',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                isPunchedIn ? 'Swipe to Punch-out' : 'Swipe to Punch-in',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          _isLoading
              ? const CircularProgressIndicator()
              : Switch(
                  value: isPunchedIn,
                  onChanged: (value) {
                    setState(() {
                      _submit(value, homeState);
                    });
                  },
                  activeColor: Colors.green,
                  // Color when punched in
                  inactiveThumbColor: Colors.red,
                  // Color when not punched in
                  inactiveTrackColor: Colors.grey,
                ),
        ],
      ),
    );
  }

  void _submit(bool newState, HomePageState? homeState) async {
    if (!await _checkInternetConnection()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String currentDate = getCurrentDate();
      String currentDateTime = getCurrentDateTime();

      Position position = await locationService.getCurrentLocation();

      final responseData = await CheckInCheckOutService().checkInCheckOut(
          executiveId ?? 0,
          userId ?? 0,
          currentDate,
          newState ? 'CheckIn' : 'CheckOut',
          currentDateTime,
          '${position.latitude}',
          '${position.longitude}',
          token);

      if (responseData.status == 'Success') {
        String msgType = responseData.success.msgType;
        if (msgType.isNotEmpty) {
          _toastMessage.showInfoToastMessage(responseData.success.msgText);
          // Update the state based on the success response
          setState(() {
            isPunchedIn = newState;

            if (isPunchedIn) {
              homeState?.punchIn();
            } else {
              homeState?.punchOut();
            }
          });
        } else {
          _toastMessage.showToastMessage(
              "An error occurred while ${newState ? 'CheckIn' : 'CheckOut'}");
        }
      } else {
        _toastMessage.showToastMessage(
            "An error occurred while ${newState ? 'CheckIn' : 'CheckOut'}");
      }
    } catch (e) {
      _toastMessage.showToastMessage(
          "An error occurred while ${newState ? 'CheckIn' : 'CheckOut'}");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
}
