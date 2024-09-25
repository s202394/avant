class ForgotPasswordResponse {
  final String? status;
  final String? msgType;
  final String? msgText;
  final Password? password;

  ForgotPasswordResponse({
    this.status,
    this.password,
    this.msgType,
    this.msgText,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    var forgotPasswordModelData = json["Password"] as List?;
    Password? passwordData;
    if (forgotPasswordModelData != null && forgotPasswordModelData.isNotEmpty) {
      passwordData = Password.fromJson(forgotPasswordModelData[0]);
    }

    return ForgotPasswordResponse(
      status: json['Status'] as String?,
      msgType: json['MsgType'] as String?,
      msgText: json['MsgText'] as String?,
      password: passwordData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'MsgType': msgType,
      'MsgText': msgText,
      'RequestDetails': password?.toJson(),
    };
  }
}

class Password {
  final int id;
  final String userName;
  final String emailId;
  final String password;
  final int profileId;
  final int action;

  Password({
    required this.id,
    required this.userName,
    required this.emailId,
    required this.password,
    required this.profileId,
    required this.action,
  });

  factory Password.fromJson(Map<String, dynamic> json) {
    return Password(
      id: json['Id'] ?? 0,
      userName: json['UserName'] ?? '',
      emailId: json['EmailId'] ?? '',
      password: json['Password'] ?? '',
      profileId: json['ProfileId'] ?? 0,
      action: json['Action'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'UserName': userName,
      'EmailId': emailId,
      'Password': password,
      'ProfileId': profileId,
      'Action': action,
    };
  }
}
