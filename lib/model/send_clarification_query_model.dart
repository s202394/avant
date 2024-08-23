class SendClarificationQueryResponse{
  final String status;
  final ApprovalList approvalList;

  SendClarificationQueryResponse({
    required this.status,
    required this.approvalList,
  });

  factory SendClarificationQueryResponse.fromJson(Map<String, dynamic> json) {
    var approvalListData = json["ApprovalList"][0];
    final approvalList = ApprovalList.fromJson(approvalListData);

    return SendClarificationQueryResponse(
      status: json['Status'] ?? '',
      approvalList: approvalList,
    );
  }
}

class ApprovalList {
  final String msgType;
  final String msgText;

  ApprovalList({
    required this.msgType,
    required this.msgText,
  });

  factory ApprovalList.fromJson(Map<String, dynamic> json) {
    return ApprovalList(
      msgType: json['MsgType'] ?? '',
      msgText: json['MsgText'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'MsgType': status,
      'MsgText': bookId,
    };
  }
}