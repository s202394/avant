import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  CustomAlertDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        ElevatedButton(
          onPressed: onCancel,
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text("Confirm"),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18.0,
      ),
    );
  }
}
class SingleAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onOk;

  SingleAlertDialog({
    required this.title,
    required this.content,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        ElevatedButton(
          onPressed: onOk,
          child: Text("OK"),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18.0,
      ),
    );
  }
}