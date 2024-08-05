import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avant/api/api_constants.dart';
import 'package:avant/model/request.dart';

Future<List<Request>> fetchRequests() async {
  final response = await http.get(Uri.parse(SELF_STOCK_REQUEST_APPROVAL_URL));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((request) => Request.fromJson(request)).toList();
  } else {
    throw Exception('Failed to load requests');
  }
}