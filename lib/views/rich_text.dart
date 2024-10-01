import 'package:flutter/material.dart';

class RichTextWidget extends StatelessWidget {
  final String label;
  final double fontSize;

  const RichTextWidget({super.key, required this.label, this.fontSize = 14.0});

  @override
  Widget build(BuildContext context) {
    List<String> lines = label.replaceAll('\\r', '').split('\\n');

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: fontSize),
        children: [
          for (int i = 0; i < lines.length; i++)
            TextSpan(text: lines[i] + (i < lines.length - 1 ? '\n' : '')),
        ],
      ),
    );
  }
}
