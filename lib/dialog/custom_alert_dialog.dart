import 'package:avant/views/custom_text.dart';
import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(title, fontSize: 16),
      content: CustomText(content, fontSize: 14),
      actions: <Widget>[
        ElevatedButton(
          onPressed: onCancel,
          child: const CustomText("Cancel", fontSize: 14),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const CustomText("Confirm", fontSize: 14),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 14.0,
      ),
    );
  }
}

class SingleAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onOk;

  const SingleAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(title, fontSize: 16),
      content: CustomText(content, fontSize: 14),
      actions: <Widget>[
        ElevatedButton(
          onPressed: onOk,
          child: const CustomText("OK", fontSize: 14),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 14.0,
      ),
    );
  }
}
