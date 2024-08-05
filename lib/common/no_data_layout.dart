import 'package:flutter/material.dart';

class NoDataLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info, size: 60, color: Colors.grey),
        SizedBox(height: 20),
        Text(
          "No data available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}