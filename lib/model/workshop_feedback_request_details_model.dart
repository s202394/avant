class WorkshopFeedbackRequestDetailsResponse {
  final String status;
  final WorkshopDetails? workshopDetails;
  final List<ApprovalMetrix> approvalMatrix;
  final List<ParticipantsDetails> participantsDetails;
  final List<ExpensesList> expensesList;

  WorkshopFeedbackRequestDetailsResponse({
    required this.status,
    required this.workshopDetails,
    required this.approvalMatrix,
    required this.participantsDetails,
    required this.expensesList,
  });

  factory WorkshopFeedbackRequestDetailsResponse.fromJson(
      Map<String, dynamic> json) {

    var workshopDetailsData = json["WorkshopDetails"] as List?;
    WorkshopDetails? workshopDetail;
    if (workshopDetailsData != null && workshopDetailsData.isNotEmpty) {
      workshopDetail = WorkshopDetails.fromJson(workshopDetailsData[0]);
    }

    var listApprovalMatrix= json["ApprovalMetrix"] as List;
    List<ApprovalMetrix> resultApprovalMetrix=
    listApprovalMatrix.map((i) => ApprovalMetrix.fromJson(i)).toList();

    var listParticipantsDetails= json["ParticipantsDetails"] as List;
    List<ParticipantsDetails> resultParticipantsDetails=
    listParticipantsDetails.map((i) => ParticipantsDetails.fromJson(i)).toList();

    var listExpensesList= json["ExpensesList"] as List;
    List<ExpensesList> resultExpensesList=
    listExpensesList.map((i) => ExpensesList.fromJson(i)).toList();

    return WorkshopFeedbackRequestDetailsResponse(
      status: json['Status'] ?? '',
      workshopDetails: workshopDetail,
      approvalMatrix: resultApprovalMetrix,
      participantsDetails: resultParticipantsDetails,
      expensesList: resultExpensesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'WorkshopDetails': workshopDetails?.toJson(),
      'ApprovalMetrix': approvalMatrix.map((e) => e.toJson()).toList(),
      'ParticipantsDetails': participantsDetails.map((e) => e.toJson()).toList(),
      'ExpensesList': expensesList.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkshopDetails {
  final int workshopId;
  final String requestNumber;
  final String remarks;
  final String requestDate;
  final String executiveName;
  final String proposedDateTime;
  final String venueType;
  final String venue;
  final String workshopRequirment;
  final String workshopType;
  final String workshopTopic;
  final String subjectName;
  final String seriesName;
  final String participantType;
  final String keyResourcePerson;
  final String additionResourcePerson;
  final String keyResourceId;
  final String addResourceId;
  final String workshopStatus;

  WorkshopDetails({
    required this.workshopId,
    required this.requestNumber,
    required this.remarks,
    required this.requestDate,
    required this.executiveName,
    required this.proposedDateTime,
    required this.venueType,
    required this.venue,
    required this.workshopRequirment,
    required this.workshopType,
    required this.workshopTopic,
    required this.subjectName,
    required this.seriesName,
    required this.participantType,
    required this.keyResourcePerson,
    required this.additionResourcePerson,
    required this.keyResourceId,
    required this.addResourceId,
    required this.workshopStatus,
  });

  factory WorkshopDetails.fromJson(Map<String, dynamic> json) {
    return WorkshopDetails(
      workshopId: json['WorkshopId'] ?? 0,
      requestNumber: json['RequestNumber'] ?? '',
      remarks: json['Remarks'] ?? '',
      requestDate: json['RequestDate'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      proposedDateTime: json['ProposedDateTime'] ?? '',
      venueType: json['VenueType'] ?? '',
      venue: json['Venue'] ?? '',
      workshopRequirment: json['WorkshopRequirment'] ?? '',
      workshopType: json['WorkshopType'] ?? '',
      workshopTopic: json['WorkshopTopic'] ?? '',
      subjectName: json['SubjectName'] ?? '',
      seriesName: json['SeriesName'] ?? '',
      participantType: json['ParticipantType'] ?? '',
      keyResourcePerson: json['KeyResourcePerson'] ?? '',
      additionResourcePerson: json['AdditionResourcePerson'] ?? '',
      keyResourceId: json['KeyResourceId'] ?? 0,
      addResourceId: json['AddResourceId'] ?? '',
      workshopStatus: json['WorkshopStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'WorkshopId': workshopId,
      'RequestNumber': requestNumber,
      'Remarks': remarks,
      'RequestDate': requestDate,
      'ExecutiveName': executiveName,
      'ProposedDateTime': proposedDateTime,
      'VenueType': venueType,
      'Venue': venue,
      'WorkshopRequirment': workshopRequirment,
      'WorkshopType': workshopType,
      'WorkshopTopic': workshopTopic,
      'SubjectName': subjectName,
      'SeriesName': seriesName,
      'ParticipantType': participantType,
      'KeyResourcePerson': keyResourcePerson,
      'AdditionResourcePerson': additionResourcePerson,
      'KeyResourceId': keyResourceId,
      'AddResourceId': addResourceId,
      'WorkshopStatus': workshopStatus,
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

class ParticipantsDetails {
  final String sNo;
  final String schoolCode;
  final String schoolName;
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String country;
  final double data_2024_25;
  final double data_2023_24;
  final int action;

  ParticipantsDetails({
    required this.sNo,
    required this.schoolCode,
    required this.schoolName,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.data_2024_25,
    required this.data_2023_24,
    required this.action,
  });

  factory ParticipantsDetails.fromJson(Map<String, dynamic> json) {
    return ParticipantsDetails(
      sNo: json['SNo'] ?? 0,
      schoolName: json['SchoolName'] ?? '',
      schoolCode: json['SchoolCode'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      country: json['Country'] ?? '',
      data_2024_25: json['2024-25'] ?? 0,
      data_2023_24: json['2023-24'] ?? 0,
      action: json['Action'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'SchoolCode': schoolCode,
      'SchoolName': schoolName,
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'Country': country,
      '2024-25': data_2024_25,
      '2023-24': data_2023_24,
      'Action': action,
    };
  }
}

class ExpensesList {
  final String expenseHead;
  final double requestedAmount;
  final int workshopId;
  final double expenseApproval;
  final int expenseHeadId;

  ExpensesList({
    required this.expenseHead,
    required this.requestedAmount,
    required this.workshopId,
    required this.expenseApproval,
    required this.expenseHeadId,
  });

  factory ExpensesList.fromJson(Map<String, dynamic> json) {
    return ExpensesList(
      expenseHead: json['ExpenseHead'] ?? '',
      requestedAmount: json['RequestedAmount'] ?? 0,
      workshopId: json['WorkshopId'] ?? 0,
      expenseApproval: json['ExpenseApproval'] ?? 0,
      expenseHeadId: json['ExpenseHeadId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ExpenseHead': expenseHead,
      'RequestedAmount': requestedAmount,
      'WorkshopId': workshopId,
      'ExpenseApproval': expenseApproval,
      'ExpenseHeadId': expenseHeadId,
    };
  }
}
