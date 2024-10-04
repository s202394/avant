import 'package:flutter/cupertino.dart';

class DetailText {
  Widget buildDetailText(String label, String value,
      {double labelFontSize = 14.0, double valueFontSize = 12.0}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: labelFontSize),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontSize: valueFontSize),
          ),
        ],
      ),
    );
  }
}
