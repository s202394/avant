class SponsorshipFeedbackRequestDetailsResponse {
  final String status;
  final SponsorshipDetails? sponsorshipDetails;
  final SchoolBasicDetails? schoolBasicDetails;
  final List<SchoolEnrollment> schoolEnrollment;
  final List<ApprovalMetrix> approvalMatrix;

  SponsorshipFeedbackRequestDetailsResponse({
    required this.status,
    required this.sponsorshipDetails,
    required this.schoolBasicDetails,
    required this.schoolEnrollment,
    required this.approvalMatrix,
  });

  factory SponsorshipFeedbackRequestDetailsResponse.fromJson(
      Map<String, dynamic> json) {
    var sponsorshipDetailsData = json["SponsorshipDetails"] as List?;
    SponsorshipDetails? sponsorshipDetail;
    if (sponsorshipDetailsData != null && sponsorshipDetailsData.isNotEmpty) {
      sponsorshipDetail = SponsorshipDetails.fromJson(sponsorshipDetailsData[0]);
    }
    var schoolBasicDetailsData = json["SchoolBasicDetails"] as List?;
    SchoolBasicDetails? schoolBasicDetail;
    if (schoolBasicDetailsData != null && schoolBasicDetailsData.isNotEmpty) {
      schoolBasicDetail = SchoolBasicDetails.fromJson(schoolBasicDetailsData[0]);
    }

    var listSchoolEnrollment= json["SchoolEnrollment"] as List;
    List<SchoolEnrollment> resultSchoolEnrollment=
    listSchoolEnrollment.map((i) => SchoolEnrollment.fromJson(i)).toList();

    var listApprovalMatrix= json["ApprovalMetrix"] as List;
    List<ApprovalMetrix> resultApprovalMetrix=
    listApprovalMatrix.map((i) => ApprovalMetrix.fromJson(i)).toList();

    return SponsorshipFeedbackRequestDetailsResponse(
      status: json['Status'] ?? '',
      sponsorshipDetails: sponsorshipDetail,
      schoolBasicDetails: schoolBasicDetail,
      schoolEnrollment: resultSchoolEnrollment,
      approvalMatrix: resultApprovalMetrix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'SponsorshipDetails': sponsorshipDetails?.toJson(),
      'SchoolBasicDetails': schoolBasicDetails?.toJson(),
      'SchoolEnrollment': schoolEnrollment.map((e) => e.toJson()).toList(),
      'ApprovalMetrix': approvalMatrix.map((e) => e.toJson()).toList(),
    };
  }
}

class SponsorshipDetails {
  final int sponsorshipId;
  final String requestNumber;
  final String remarks;
  final String requestDate;
  final String executiveName;
  final String school;
  final String schoolCode;
  final String address;
  final String executiveCode;
  final String sponsorshipType;
  final String paymentMode;
  final String eventDate;
  final String lastDate;
  final int sponsorshipAmount;
  final int schoolId;
  final String beneficiary;
  final String requestDocument;
  final String sponsorshipStatus;
  final String action;

  SponsorshipDetails({
    required this.sponsorshipId,
    required this.requestNumber,
    required this.remarks,
    required this.requestDate,
    required this.executiveName,
    required this.school,
    required this.schoolCode,
    required this.address,
    required this.executiveCode,
    required this.sponsorshipType,
    required this.paymentMode,
    required this.eventDate,
    required this.lastDate,
    required this.sponsorshipAmount,
    required this.schoolId,
    required this.beneficiary,
    required this.requestDocument,
    required this.sponsorshipStatus,
    required this.action,
  });

  factory SponsorshipDetails.fromJson(Map<String, dynamic> json) {
    return SponsorshipDetails(
      sponsorshipId: json['SponsorshipId'] ?? 0,
      requestNumber: json['RequestNumber'] ?? '',
      remarks: json['Remarks'] ?? '',
      requestDate: json['RequestDate'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      school: json['School'] ?? '',
      schoolCode: json['SchoolCode'] ?? '',
      address: json['Address'] ?? '',
      executiveCode: json['ExecutiveCode'] ?? '',
      sponsorshipType: json['SponsorshipType'] ?? '',
      paymentMode: json['PaymentMode'] ?? '',
      eventDate: json['Eventdate'] ?? '',
      lastDate: json['LastDate'] ?? '',
      sponsorshipAmount: json['SponsorshipAmount'] ?? 0,
      schoolId: json['SchoolId'] ?? 0,
      beneficiary: json['Benificiary'] ?? '',
      requestDocument: json['RequestDocument'] ?? '',
      sponsorshipStatus: json['SponsorshipStatus'] ?? '',
      action: json['Action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SponsorshipId': sponsorshipId,
      'RequestNumber': requestNumber,
      'Remarks': remarks,
      'RequestDate': requestDate,
      'ExecutiveName': executiveName,
      'School': school,
      'SchoolCode': schoolCode,
      'Address': address,
      'ExecutiveCode': executiveCode,
      'SponsorshipType': sponsorshipType,
      'PaymentMode': paymentMode,
      'Eventdate': eventDate,
      'LastDate': lastDate,
      'SponsorshipAmount': sponsorshipAmount,
      'SchoolId': schoolId,
      'Benificiary': beneficiary,
      'RequestDocument': requestDocument,
      'SponsorshipStatus': sponsorshipStatus,
      'Action': action,
    };
  }
}

class SchoolBasicDetails {
  final String schoolName;
  final String refCode;
  final String customerCode;
  final String address;
  final String principal;
  final String emailId;
  final String mobile;
  final String contactDesignationName;
  final int endClassId;
  final int action;

  SchoolBasicDetails({
    required this.schoolName,
    required this.refCode,
    required this.customerCode,
    required this.address,
    required this.principal,
    required this.emailId,
    required this.mobile,
    required this.contactDesignationName,
    required this.endClassId,
    required this.action,
  });

  factory SchoolBasicDetails.fromJson(Map<String, dynamic> json) {
    return SchoolBasicDetails(
      schoolName: json['SchoolName'] ?? 0,
      refCode: json['RefCode'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      address: json['Address'] ?? '',
      principal: json['Principal'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      contactDesignationName: json['ContactDesignationName'] ?? '',
      endClassId: json['EndClassId'] ?? 0,
      action: json['Action'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SchoolName': schoolName,
      'RefCode': refCode,
      'CustomerCode': customerCode,
      'Address': address,
      'Principal': principal,
      'EmailId': emailId,
      'Mobile': mobile,
      'ContactDesignationName': contactDesignationName,
      'EndClassId': endClassId,
      'Action': action,
    };
  }
}

class SchoolEnrollment {
  final int sNo;
  final String classData;
  final int year2024_25;
  final int year2023_24;
  final int year2022_23;
  final String lastUpdated;

  SchoolEnrollment({
    required this.sNo,
    required this.classData,
    required this.year2024_25,
    required this.year2023_24,
    required this.year2022_23,
    required this.lastUpdated,
  });

  factory SchoolEnrollment.fromJson(Map<String, dynamic> json) {
    return SchoolEnrollment(
      sNo: json['SNo'] ?? 0,
      classData: json['Class'] ?? '',
      year2024_25: json['2024-25'] ?? 0,
      year2023_24: json['2023-24'] ?? 0,
      year2022_23: json['2022-23'] ?? 0,
      lastUpdated: json['LastUpdated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'Class': classData,
      '2024-25': year2024_25,
      '2023-24': year2023_24,
      '2022-23': year2022_23,
      'LastUpdated': lastUpdated,
    };
  }
}

class ApprovalMetrix {
  final int sequenceNo;
  final String entryDate;
  final String executiveName;
  final String profileCode;
  final String approvalLevel;
  final String remarks;
  final String requestId;

  ApprovalMetrix({
    required this.sequenceNo,
    required this.entryDate,
    required this.executiveName,
    required this.profileCode,
    required this.approvalLevel,
    required this.remarks,
    required this.requestId,
  });

  factory ApprovalMetrix.fromJson(Map<String, dynamic> json) {
    return ApprovalMetrix(
      sequenceNo: json['SequenceNo'] ?? 0,
      entryDate: json['EntryDate'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      profileCode: json['ProfileCode'] ?? '',
      approvalLevel: json['ApprovalLevel'] ?? '',
      remarks: json['Remarks'] ?? '',
      requestId: json['RequestId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SequenceNo': sequenceNo,
      'EntryDate': entryDate,
      'ExecutiveName': executiveName,
      'ProfileCode': profileCode,
      'ApprovalLevel': approvalLevel,
      'Remarks': remarks,
      'RequestId': requestId,
    };
  }
}
