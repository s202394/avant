import 'package:flutter/material.dart';

class RichTextWidget extends StatelessWidget {
  final String label;

  const RichTextWidget({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: label
            .replaceAll('\\r', '')
            .split('\\n')
            .map((line) => TextSpan(text: '$line\n'))
            .toList(),
      ),
    );
  }
}
