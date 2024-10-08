import 'package:flutter/material.dart';

class ErrorLayout extends StatelessWidget {
  const ErrorLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
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