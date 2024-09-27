import 'package:flutter/cupertino.dart';

class DetailText {
  Widget buildDetailText(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}