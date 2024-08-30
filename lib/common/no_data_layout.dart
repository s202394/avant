import 'package:flutter/material.dart';

class NoDataLayout extends StatelessWidget {
  const NoDataLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, size: 60, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "No data available",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}