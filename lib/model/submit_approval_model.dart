class SubmitRequestApprovalResponse {
  final String status;
  final ReturnMessage? returnMessage;

  SubmitRequestApprovalResponse({
    required this.status,
    this.returnMessage,
  });

  factory SubmitRequestApprovalResponse.fromJson(Map<String, dynamic> json) {
    // Check if 'ReturnMessage' exists and is a list with at least one element
    ReturnMessage? returnMessage;
    if (json['ReturnMessage'] != null &&
        json['ReturnMessage'] is List &&
        json['ReturnMessage'].isNotEmpty) {
      final returnMessageData = json['ReturnMessage'][0];
      returnMessage = ReturnMessage.fromJson(returnMessageData);
    }

    return SubmitRequestApprovalResponse(
      status: json['Status'] ?? '',
      returnMessage: returnMessage,
    );
  }
}

class ReturnMessage {
  final String msgType;
  final String msgText;

  ReturnMessage({
    required this.msgType,
    required this.msgText,
  });

  factory ReturnMessage.fromJson(Map<String, dynamic> json) {
    return ReturnMessage(
      msgType: json['MsgType'] ?? '',
      msgText: json['MsgText'] ?? '',
    );
  }
}
