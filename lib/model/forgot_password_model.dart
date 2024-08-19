class ForgotPasswordResponse {
  final String? status;
  final Password? password;

  ForgotPasswordResponse({
    this.status,
    this.password,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    var forgotPasswordModelData = json["Password"] as List?;
    Password? passwordData;
    if (forgotPasswordModelData != null && forgotPasswordModelData.isNotEmpty) {
      passwordData = Password.fromJson(forgotPasswordModelData[0]);
    }

    return ForgotPasswordResponse(
      status: json['Status'] as String?,
      password: passwordData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
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
      'MenuName': id,
      'UserName': userName,
      'EmailId': emailId,
      'Password': password,
      'ProfileId': profileId,
      'Action': action,
    };
  }
}
