class ChangePasswordModel {
  final String msgType;
  final String msgText;

  ChangePasswordModel({
    required this.msgType,
    required this.msgText,
  });

  factory ChangePasswordModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordModel(
      msgType: json['MsgType'] ?? '',
      msgText: json['MsgText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MsgType': msgType,
      'MsgText': msgText,
    };
  }
}
