class CustomerContactDetailsResponse {
  final String status;
  final CustomerContactDetails? contactDetails;

  CustomerContactDetailsResponse({
    required this.status,
    required this.contactDetails,
  });

  factory CustomerContactDetailsResponse.fromJson(Map<String, dynamic> json) {
    var customerContactDetails = json["CustomerContactDetails"] as List?;
    CustomerContactDetails? detail;
    if (customerContactDetails != null && customerContactDetails.isNotEmpty) {
      detail = CustomerContactDetails.fromJson(customerContactDetails[0]);
    }

    return CustomerContactDetailsResponse(
      status: json['Status'] ?? '',
      contactDetails: detail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerContactDetails': contactDetails?.toJson(),
    };
  }
}

class CustomerContactDetails {
  final String primaryContact;
  final String contactStatus;
  final String firstName;
  final String lastName;
  final int salutationId;
  final int contactDesignationId;
  final String contactEmailId;
  final String contactMobile;
  final String customerContactId;
  final String resAddress;
  final int resCountry;
  final int resState;
  final int resDistrict;
  final int resCity;
  final String resPincode;
  final String birthDay;
  final String anniversary;

  CustomerContactDetails({
    required this.primaryContact,
    required this.contactStatus,
    required this.firstName,
    required this.lastName,
    required this.salutationId,
    required this.contactDesignationId,
    required this.contactEmailId,
    required this.contactMobile,
    required this.customerContactId,
    required this.resAddress,
    required this.resCountry,
    required this.resState,
    required this.resDistrict,
    required this.resCity,
    required this.resPincode,
    required this.birthDay,
    required this.anniversary,
  });

  factory CustomerContactDetails.fromJson(Map<String, dynamic> json) {
    return CustomerContactDetails(
      primaryContact: json['PrimaryContact'] ?? '',
      contactStatus: json['ContactStatus'] ?? '',
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      salutationId: json['SalutationId'] ?? 0,
      contactDesignationId: json['ContactDesignationId'] ?? 0,
      contactEmailId: json['ContactEmailId'] ?? '',
      contactMobile: json['ContactMobile'] ?? '',
      customerContactId: json['CustomerContactId'] ?? '',
      resAddress: json['resAddress'] ?? '',
      resCountry: json['resCountry'] ?? 0,
      resState: json['resState'] ?? 0,
      resDistrict: json['resDistrict'] ?? 0,
      resCity: json['resCity'] ?? 0,
      resPincode: json['resPincode'] ?? '',
      birthDay: json['BirthDay'] ?? '',
      anniversary: json['Anniversary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PrimaryContact': primaryContact,
      'ContactStatus': contactStatus,
      'FirstName': firstName,
      'LastName': lastName,
      'SalutationId': salutationId,
      'ContactDesignationId': contactDesignationId,
      'ContactEmailId': contactEmailId,
      'ContactMobile': contactMobile,
      'CustomerContactId': customerContactId,
      'resAddress': resAddress,
      'resCountry': resCountry,
      'resState': resState,
      'resDistrict': resDistrict,
      'resCity': resCity,
      'resPincode': resPincode,
      'BirthDay': birthDay,
      'Anniversary': anniversary,
    };
  }
}

class CustomerContactDetailsSchoolResponse {
  final String status;
  final SchoolContactDetails? contactDetails;

  CustomerContactDetailsSchoolResponse({
    required this.status,
    required this.contactDetails,
  });

  factory CustomerContactDetailsSchoolResponse.fromJson(Map<String, dynamic> json) {
    var customerContactDetails = json["SchoolContactDetails"] as List?;
    SchoolContactDetails? detail;
    if (customerContactDetails != null && customerContactDetails.isNotEmpty) {
      detail = SchoolContactDetails.fromJson(customerContactDetails[0]);
    }

    return CustomerContactDetailsSchoolResponse(
      status: json['Status'] ?? '',
      contactDetails: detail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'SchoolContactDetails': contactDetails?.toJson(),
    };
  }
}

class SchoolContactDetails {
  final String primaryContact;
  final String contactStatus;
  final String firstName;
  final String lastName;
  final int salutationId;
  final int dataSourceId;
  final int contactDesignationId;
  final String contactEmailId;
  final String contactMobile;
  final String resAddress;
  final int resCountry;
  final int resState;
  final int resDistrict;
  final int resCity;
  final String resPincode;
  final String schoolContactId;
  final String classNumId;
  final String decisionId;
  final String subjectId;
  final String birthDay;
  final String anniversary;

  SchoolContactDetails({
    required this.primaryContact,
    required this.contactStatus,
    required this.firstName,
    required this.lastName,
    required this.salutationId,
    required this.dataSourceId,
    required this.contactDesignationId,
    required this.contactEmailId,
    required this.contactMobile,
    required this.resAddress,
    required this.resCountry,
    required this.resState,
    required this.resDistrict,
    required this.resCity,
    required this.resPincode,
    required this.schoolContactId,
    required this.classNumId,
    required this.decisionId,
    required this.subjectId,
    required this.birthDay,
    required this.anniversary,
  });

  factory SchoolContactDetails.fromJson(Map<String, dynamic> json) {
    return SchoolContactDetails(
      primaryContact: json['PrimaryContact'] ?? '',
      contactStatus: json['ContactStatus'] ?? '',
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      salutationId: json['SalutationId'] ?? 0,
      dataSourceId: json['DataSourceId'] ?? 0,
      contactDesignationId: json['ContactDesignationId'] ?? 0,
      contactEmailId: json['ContactEmailId'] ?? '',
      contactMobile: json['ContactMobile'] ?? '',
      resAddress: json['resAddress'] ?? '',
      resCountry: json['resCountry'] ?? 0,
      resState: json['resState'] ?? 0,
      resDistrict: json['resDistrict'] ?? 0,
      resCity: json['resCity'] ?? 0,
      resPincode: json['resPincode'] ?? '',
      schoolContactId: json['SchoolContactId'] ?? '',
      classNumId: json['ClassNumId'] ?? '',
      decisionId: json['DecisionId'] ?? '',
      subjectId: json['SubjectId'] ?? '',
      birthDay: json['BirthDay'] ?? '',
      anniversary: json['Anniversary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PrimaryContact': primaryContact,
      'ContactStatus': contactStatus,
      'FirstName': firstName,
      'LastName': lastName,
      'SalutationId': salutationId,
      'ContactDesignationId': contactDesignationId,
      'ContactEmailId': contactEmailId,
      'ContactMobile': contactMobile,
      'resAddress': resAddress,
      'resCountry': resCountry,
      'resState': resState,
      'resDistrict': resDistrict,
      'resCity': resCity,
      'resPincode': resPincode,
      'SchoolContactId': schoolContactId,
      'ClassNumId': classNumId,
      'DecisionId': decisionId,
      'SubjectId': subjectId,
      'BirthDay': birthDay,
      'Anniversary': anniversary,
    };
  }
}