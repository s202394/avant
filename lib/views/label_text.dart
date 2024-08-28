import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String label;
  final String? value;

  const LabeledText({
    super.key,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Adjust color as needed
            ),
          ),
          TextSpan(
            text: value ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black, // Adjust color as needed
            ),
          ),
        ],
      ),
    );
  }
}
