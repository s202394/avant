import 'package:flutter/material.dart';

class ErrorLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info, size: 60, color: Colors.red),
        SizedBox(height: 20),
        Text(
          "Error while getting response from server.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}