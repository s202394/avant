import 'package:flutter/material.dart';

class DetailText {
  Widget buildDetailText(
    String label,
    String value, {
    double labelFontSize = 14.0,
    double valueFontSize = 12.0,
    Color labelColor = Colors.black,
    Color valueColor = Colors.black,
    Color backgroundColor = Colors.transparent,
  }) {
    return Container(
      color: backgroundColor, // Set the background color
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: labelFontSize,
                color: labelColor, // Set the label text color
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: valueFontSize,
                color: valueColor, // Set the value text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
