import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Request {
  final String requestNo;
  final String executiveName;
  final String requestDate;
  final String requestStatus;
  final String lastApprovalBy;
  final String approvalDate;

  Request({
    required this.requestNo,
    required this.executiveName,
    required this.requestDate,
    required this.requestStatus,
    required this.lastApprovalBy,
    required this.approvalDate,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      requestNo: json['requestNo'],
      executiveName: json['executiveName'],
      requestDate: json['requestDate'],
      requestStatus: json['requestStatus'],
      lastApprovalBy: json['lastApprovalBy'],
      approvalDate: json['approvalDate'],
    );
  }
}