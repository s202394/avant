import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String label;
  final String? value;
  final double labelFontSize;
  final double valueFontSize;

  const LabeledText({
    super.key,
    required this.label,
    this.value,
    this.labelFontSize = 14.0,
    this.valueFontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: labelFontSize),
          ),
          TextSpan(
            text: value ?? '',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontSize: valueFontSize),
          ),
        ],
      ),
    );
  }
}
