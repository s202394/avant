class SubmitCustomerSamplingRequestApprovalResponse{
  final String status;
  final ReturnMessage returnMessage;

  SubmitCustomerSamplingRequestApprovalResponse({
    required this.status,
    required this.returnMessage,
  });

  factory SubmitCustomerSamplingRequestApprovalResponse.fromJson(Map<String, dynamic> json) {
    var returnMessageData = json["ReturnMessage"][0];
    final ReturnMessageData = ReturnMessage.fromJson(returnMessageData);

    return SubmitCustomerSamplingRequestApprovalResponse(
      status: json['Status'] ?? '',
      returnMessage: ReturnMessageData,
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