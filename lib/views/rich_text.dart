import 'package:flutter/material.dart';

class RichTextWidget extends StatelessWidget {
  final String label;
  final double fontSize;

  const RichTextWidget({
    super.key,
    required this.label,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: fontSize),
        children: label
            .replaceAll('\\r', '')
            .split('\\n')
            .map((line) => TextSpan(text: '$line\n'))
            .toList(),
      ),
    );
  }
}
