import 'package:flutter/material.dart';

class PunchInToggleSwitch extends StatefulWidget {
  @override
  _PunchInToggleSwitchState createState() => _PunchInToggleSwitchState();
}

class _PunchInToggleSwitchState extends State<PunchInToggleSwitch> {
  bool isPunchedIn = false; // Initial state

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850], // Background color
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPunchedIn ? 'Punched-In' : 'Not Punched-In', // Toggle text
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isPunchedIn ? 'Swipe to Punch-out' : 'Swipe to Punch-in', // Toggle subtext
                style: TextStyle(
                  color: Colors.white70, // Slightly faded text
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch(
            value: isPunchedIn,
            onChanged: (value) {
              setState(() {
                isPunchedIn = value; // Update state on swipe
              });
            },
            activeColor: Colors.green, // Color when punched in
            inactiveThumbColor: Colors.red, // Color when not punched in
            inactiveTrackColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
