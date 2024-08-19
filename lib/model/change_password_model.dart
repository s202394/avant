class ChangePasswordResponse {
  final String? status;
  final ChangePasswordModel? changePasswordModel;

  ChangePasswordResponse({
    this.status,
    this.changePasswordModel,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    ChangePasswordModel? changePasswordData;
    var data = json["Success"] as List?;
    if (data != null && data.isNotEmpty) {
      changePasswordData = ChangePasswordModel.fromJson(data[0]);
    }

    return ChangePasswordResponse(
      status: json['Status'] as String?,
      changePasswordModel: changePasswordData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'Success': changePasswordModel?.toJson(),
    };
  }
}

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
