import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String label;
  final String? value;

  const LabeledText({
    Key? key,
    required this.label,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Adjust color as needed
            ),
          ),
          TextSpan(
            text: value ?? '',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black, // Adjust color as needed
            ),
          ),
        ],
      ),
    );
  }
}
