class CheckInCheckOutResponse {
  final String status;
  final String s;
  final String e;
  final Success success;

  CheckInCheckOutResponse({
    required this.status,
    required this.s,
    required this.e,
    required this.success,
  });

  factory CheckInCheckOutResponse.fromJson(Map<String, dynamic> json) {
    var successData = json["success"][0];
    final success = Success.fromJson(successData);

    return CheckInCheckOutResponse(
      status: json['Status'] ?? '',
      s: json['s'] ?? '',
      e: json['e'] ?? '',
      success: success,
    );
  }
}

class Success {
  final String msgType;
  final String msgText;

  Success({
    required this.msgType,
    required this.msgText,
  });

  factory Success.fromJson(Map<String, dynamic> json) {
    return Success(
      msgType: json['MsgType'] ?? '',
      msgText: json['MsgText'] ?? '',
    );
  }
}
