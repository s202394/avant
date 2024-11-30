class FetchCustomerDetailsSchoolResponse {
  final String status;
  final SchoolDetails? schoolDetails;
  final List<EnrolmentList> enrolmentList;
  final List<SchoolComments> comments;

  FetchCustomerDetailsSchoolResponse({
    required this.status,
    required this.schoolDetails,
    required this.enrolmentList,
    required this.comments,
  });

  factory FetchCustomerDetailsSchoolResponse.fromJson(
      Map<String, dynamic> json) {
    var schoolDetailsData = json["SchoolDetails"] as List?;
    SchoolDetails? schoolDetail;
    if (schoolDetailsData != null && schoolDetailsData.isNotEmpty) {
      schoolDetail = SchoolDetails.fromJson(schoolDetailsData[0]);
    }

    var enrolmentList = json["EnrolmentList"] as List;
    List<EnrolmentList> listEnrolment =
        enrolmentList.map((i) => EnrolmentList.fromJson(i)).toList();

    var listComments = json["Comments"] as List;
    List<SchoolComments> commentList =
        listComments.map((i) => SchoolComments.fromJson(i)).toList();

    return FetchCustomerDetailsSchoolResponse(
      status: json['Status'] ?? '',
      schoolDetails: schoolDetail,
      enrolmentList: listEnrolment,
      comments: commentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'SchoolDetails': schoolDetails?.toJson(),
      'EnrolmentList': enrolmentList.map((e) => e.toJson()).toList(),
      'Comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}

class SchoolDetails {
  final int schoolId;
  final String schoolCode;
  final String schoolName;
  final String refCode;
  final String address;
  final int cityId;
  final int stateId;
  final int districtId;
  final int countryId;
  final String validationStatus;
  final String emailId;
  final String mobile;
  final String keyCustomer;
  final String customerStatus;
  final String pinCode;
  final int startClassId;
  final int endClassId;
  final int boardId;
  final int chainSchoolId;
  final String mediumInstruction;
  final String ranking;
  final int samplingMonth;
  final int decisionMonth;
  final String purchaseMode;
  final int bookSeller1;
  final int bookSeller2;
  final String xmlAccountTableExecutiveId;
  final String msgWarning;
  final int existence;
  final String panNumber;
  final String gstNumber;

  SchoolDetails({
    required this.schoolId,
    required this.schoolCode,
    required this.schoolName,
    required this.refCode,
    required this.address,
    required this.cityId,
    required this.stateId,
    required this.districtId,
    required this.countryId,
    required this.validationStatus,
    required this.emailId,
    required this.mobile,
    required this.keyCustomer,
    required this.customerStatus,
    required this.pinCode,
    required this.startClassId,
    required this.endClassId,
    required this.boardId,
    required this.chainSchoolId,
    required this.mediumInstruction,
    required this.ranking,
    required this.samplingMonth,
    required this.decisionMonth,
    required this.purchaseMode,
    required this.bookSeller1,
    required this.bookSeller2,
    required this.xmlAccountTableExecutiveId,
    required this.msgWarning,
    required this.existence,
    required this.panNumber,
    required this.gstNumber,
  });

  factory SchoolDetails.fromJson(Map<String, dynamic> json) {
    return SchoolDetails(
      schoolId: json['SchoolId'] ?? 0,
      schoolCode: json['SchoolCode'] ?? '',
      schoolName: json['SchoolName'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      cityId: json['CityId'] ?? 0,
      stateId: json['StateId'] ?? 0,
      districtId: json['DistrictId'] ?? 0,
      countryId: json['CountryId'] ?? 0,
      validationStatus: json['ValidationStatus'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      keyCustomer: json['KeyCustomer'] ?? '',
      customerStatus: json['CustomerStatus'] ?? '',
      pinCode: json['Pincode'] ?? '',
      startClassId: json['StartClassId'] ?? 0,
      endClassId: json['EndClassId'] ?? 0,
      boardId: json['BoardId'] ?? 0,
      chainSchoolId: json['ChainSchoolId'] ?? 0,
      mediumInstruction: json['MediumInstruction'] ?? '',
      ranking: json['Ranking'] ?? '',
      samplingMonth: json['SamplingMonth'] ?? 0,
      decisionMonth: json['DecisionMonth'] ?? 0,
      purchaseMode: json['PurchaseMode'] ?? '',
      bookSeller1: json['BookSeller1'] ?? 0,
      bookSeller2: json['BookSeller2'] ?? 0,
      xmlAccountTableExecutiveId: json['xmlAccountTableExecutiveId'] ?? '',
      msgWarning: json['MsgWarning'] ?? '',
      existence: json['Existence'] ?? 0,
      panNumber: json['PanNumber'] ?? '',
      gstNumber: json['GstNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SchoolId': schoolId,
      'SchoolCode': schoolCode,
      'SchoolName': schoolName,
      'RefCode': refCode,
      'Address': address,
      'CityId': cityId,
      'StateId': stateId,
      'DistrictId': districtId,
      'CountryId': countryId,
      'ValidationStatus': validationStatus,
      'EmailId': emailId,
      'Mobile': mobile,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'Pincode': pinCode,
      'StartClassId': startClassId,
      'BoardId': boardId,
      'ChainSchoolId': chainSchoolId,
      'MediumInstruction': mediumInstruction,
      'Ranking': ranking,
      'SamplingMonth': samplingMonth,
      'DecisionMonth': decisionMonth,
      'PurchaseMode': purchaseMode,
      'BookSeller1': bookSeller1,
      'BookSeller2': bookSeller2,
      'xmlAccountTableExecutiveId': xmlAccountTableExecutiveId,
      'MsgWarning': msgWarning,
      'Existence': existence,
      'PanNumber': panNumber,
      'GstNumber': gstNumber,
    };
  }
}

class EnrolmentList {
  final int classNumId;
  final String className;
  final int enrolValue;

  EnrolmentList({
    required this.classNumId,
    required this.className,
    required this.enrolValue,
  });

  factory EnrolmentList.fromJson(Map<String, dynamic> json) {
    return EnrolmentList(
      classNumId: json['ClassNumId'] ?? 0,
      className: json['ClassName'] ?? '',
      enrolValue: json['EnrolValue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ClassNumId': classNumId,
      'ClassName': className,
      'EnrolValue': enrolValue,
    };
  }
}

class SchoolComments {
  final int sNo;
  final String commentDate;
  final String enteredBy;
  final String comment;
  final int enrolValue;

  SchoolComments({
    required this.sNo,
    required this.commentDate,
    required this.enteredBy,
    required this.comment,
    required this.enrolValue,
  });

  factory SchoolComments.fromJson(Map<String, dynamic> json) {
    return SchoolComments(
      sNo: json['SNo'] ?? 0,
      commentDate: json['CommentDate'] ?? '',
      enteredBy: json['EnteredBy'] ?? '',
      comment: json['Comment'] ?? '',
      enrolValue: json['EnrolValue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'CommentDate': commentDate,
      'EnteredBy': enteredBy,
      'Comment': comment,
      'EnrolValue': enrolValue,
    };
  }
}

class FetchCustomerDetailsInstituteResponse {
  final String status;
  final InstituteDetails? instituteDetails;
  final List<Comments> comments;

  FetchCustomerDetailsInstituteResponse({
    required this.status,
    required this.instituteDetails,
    required this.comments,
  });

  factory FetchCustomerDetailsInstituteResponse.fromJson(
      Map<String, dynamic> json) {
    var instituteDetailsData = json["InstituteDetails"] as List?;
    InstituteDetails? instituteDetail;
    if (instituteDetailsData != null && instituteDetailsData.isNotEmpty) {
      instituteDetail = InstituteDetails.fromJson(instituteDetailsData[0]);
    }

    var listComments = json["Comments"] as List;
    List<Comments> commentList =
        listComments.map((i) => Comments.fromJson(i)).toList();

    return FetchCustomerDetailsInstituteResponse(
      status: json['Status'] ?? '',
      instituteDetails: instituteDetail,
      comments: commentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'InstituteDetails': instituteDetails?.toJson(),
      'Comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}

class InstituteDetails {
  final int instituteId;
  final String instituteName;
  final String instituteCode;
  final String refCode;
  final String address;
  final int cityId;
  final int stateId;
  final int districtId;
  final int countryId;
  final String validationStatus;
  final String emailId;
  final String mobile;
  final String keyCustomer;
  final String customerStatus;
  final String pinCode;
  final String comment;
  final int enteredBy;
  final String commentDate;
  final String xmlAccountTableExecutiveId;
  final String ranking;
  final String instituteType;
  final String instituteLevel;
  final String affiliationType;
  final int universityId;
  final String msgWarning;
  final int existence;
  final String panNumber;
  final String gstNumber;

  InstituteDetails({
    required this.instituteId,
    required this.instituteName,
    required this.instituteCode,
    required this.refCode,
    required this.address,
    required this.cityId,
    required this.stateId,
    required this.districtId,
    required this.countryId,
    required this.validationStatus,
    required this.emailId,
    required this.mobile,
    required this.keyCustomer,
    required this.customerStatus,
    required this.pinCode,
    required this.comment,
    required this.enteredBy,
    required this.commentDate,
    required this.xmlAccountTableExecutiveId,
    required this.ranking,
    required this.instituteType,
    required this.instituteLevel,
    required this.affiliationType,
    required this.universityId,
    required this.msgWarning,
    required this.existence,
    required this.panNumber,
    required this.gstNumber,
  });

  factory InstituteDetails.fromJson(Map<String, dynamic> json) {
    return InstituteDetails(
      instituteId: json['InstituteId'] ?? 0,
      instituteName: json['InstituteName'] ?? '',
      instituteCode: json['InstituteCode'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      cityId: json['CityId'] ?? 0,
      stateId: json['StateId'] ?? 0,
      districtId: json['DistrictId'] ?? 0,
      countryId: json['CountryId'] ?? 0,
      validationStatus: json['ValidationStatus'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      keyCustomer: json['KeyCustomer'] ?? '',
      customerStatus: json['CustomerStatus'] ?? '',
      pinCode: json['Pincode'] ?? '',
      comment: json['Comment'] ?? '',
      enteredBy: json['EnteredBy'] ?? 0,
      commentDate: json['CommentDate'] ?? '',
      xmlAccountTableExecutiveId: json['xmlAccountTableExecutiveId'] ?? '',
      ranking: json['Ranking'] ?? '',
      instituteType: json['InstituteType'] ?? '',
      instituteLevel: json['InstituteLevel'] ?? '',
      affiliationType: json['AffiliationType'] ?? '',
      universityId: json['UniversityId'] ?? 0,
      msgWarning: json['MsgWarning'] ?? '',
      existence: json['Existence'] ?? 0,
      panNumber: json['PanNumber'] ?? '',
      gstNumber: json['GstNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'InstituteId': instituteId,
      'InstituteName': instituteName,
      'InstituteCode': instituteCode,
      'RefCode': refCode,
      'Address': address,
      'CityId': cityId,
      'StateId': stateId,
      'DistrictId': districtId,
      'CountryId': countryId,
      'ValidationStatus': validationStatus,
      'EmailId': emailId,
      'Mobile': mobile,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'Pincode': pinCode,
      'Comment': comment,
      'EnteredBy': enteredBy,
      'CommentDate': commentDate,
      'xmlAccountTableExecutiveId': xmlAccountTableExecutiveId,
      'Ranking': ranking,
      'InstituteType': instituteType,
      'InstituteLevel': instituteLevel,
      'AffiliationType': affiliationType,
      'UniversityId': universityId,
      'MsgWarning': msgWarning,
      'Existence': existence,
      'PanNumber': panNumber,
      'GstNumber': gstNumber,
    };
  }
}

class Comments {
  final int sNo;
  final String commentDate;
  final String enteredBy;
  final String comment;
  final int existence;

 Comments({
    required this.sNo,
    required this.commentDate,
    required this.enteredBy,
    required this.comment,
    required this.existence,
  });

  factory Comments.fromJson(Map<String, dynamic> json) {
    return Comments(
      sNo: json['SNo'] ?? 0,
      commentDate: json['CommentDate'] ?? '',
      enteredBy: json['EnteredBy'] ?? '',
      comment: json['Comment'] ?? '',
      existence: json['Existence'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'CommentDate': commentDate,
      'EnteredBy': enteredBy,
      'Comment': comment,
      'Existence': existence,
    };
  }
}

class FetchCustomerDetailsLibraryResponse {
  final String status;
  final CustomerDetails? customerDetails;
  final List<Comments> comments;

  FetchCustomerDetailsLibraryResponse({
    required this.status,
    required this.customerDetails,
    required this.comments,
  });

  factory FetchCustomerDetailsLibraryResponse.fromJson(
      Map<String, dynamic> json) {
    var customerDetailsData = json["CustomerDetails"] as List?;
    CustomerDetails? customerDetail;
    if (customerDetailsData != null && customerDetailsData.isNotEmpty) {
      customerDetail = CustomerDetails.fromJson(customerDetailsData[0]);
    }

    var listComments = json["Comments"] as List;
    List<Comments> commentList =
        listComments.map((i) => Comments.fromJson(i)).toList();

    return FetchCustomerDetailsLibraryResponse(
      status: json['Status'] ?? '',
      customerDetails: customerDetail,
      comments: commentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerDetails': customerDetails?.toJson(),
      'Comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerDetails {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String refCode;
  final String address;
  final int cityId;
  final int stateId;
  final int districtId;
  final int countryId;
  final String validationStatus;
  final String emailId;
  final String mobile;
  final String keyCustomer;
  final String customerStatus;
  final String pinCode;
  final String xmlCustomerCategoryId;
  final String xmlAccountTableExecutiveId;
  final String msgWarning;
  final int existence;
  final String panNumber;
  final String gstNumber;

  CustomerDetails({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.refCode,
    required this.address,
    required this.cityId,
    required this.stateId,
    required this.districtId,
    required this.countryId,
    required this.validationStatus,
    required this.emailId,
    required this.mobile,
    required this.keyCustomer,
    required this.customerStatus,
    required this.pinCode,
    required this.xmlCustomerCategoryId,
    required this.xmlAccountTableExecutiveId,
    required this.msgWarning,
    required this.existence,
    required this.panNumber,
    required this.gstNumber,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      customerId: json['CustomerId'] ?? 0,
      customerName: json['CustomerName'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      cityId: json['CityId'] ?? 0,
      stateId: json['StateId'] ?? 0,
      districtId: json['DistrictId'] ?? 0,
      countryId: json['CountryId'] ?? 0,
      validationStatus: json['ValidationStatus'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      keyCustomer: json['KeyCustomer'] ?? '',
      customerStatus: json['CustomerStatus'] ?? '',
      pinCode: json['Pincode'] ?? '',
      xmlCustomerCategoryId: json['xmlCustomerCategoryId'] ?? '',
      xmlAccountTableExecutiveId: json['xmlAccountTableExecutiveId'] ?? '',
      msgWarning: json['MsgWarning'] ?? '',
      existence: json['Existence'] ?? 0,
      panNumber: json['PanNumber'] ?? '',
      gstNumber: json['GstNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'CustomerName': customerName,
      'CustomerCode': customerCode,
      'RefCode': refCode,
      'Address': address,
      'CityId': cityId,
      'StateId': stateId,
      'DistrictId': districtId,
      'CountryId': countryId,
      'ValidationStatus': validationStatus,
      'EmailId': emailId,
      'Mobile': mobile,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'Pincode': pinCode,
      'xmlCustomerCategoryId': xmlCustomerCategoryId,
      'xmlAccountTableExecutiveId': xmlAccountTableExecutiveId,
      'MsgWarning': msgWarning,
      'Existence': existence,
      'PanNumber': panNumber,
      'GstNumber': gstNumber,
    };
  }
}