class SubmitRequestApprovalResponse{
  final String status;
  final ReturnMessage returnMessage;

  SubmitRequestApprovalResponse({
    required this.status,
    required this.returnMessage,
  });

  factory SubmitRequestApprovalResponse.fromJson(Map<String, dynamic> json) {
    var returnMessageData = json["ReturnMessage"][0];
    final returnMessage = ReturnMessage.fromJson(returnMessageData);

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