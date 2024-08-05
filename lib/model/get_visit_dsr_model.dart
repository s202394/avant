class GetVisitDsrResponse {
  final String status;
  final CustomerSummery customerSummery;
  final List<VisitPurpose> visitPurposeList;
  final List<JoinVisit> joinVisitList;
  final List<PersonMet> personMetList;
  final List<Department> departmentList;

  GetVisitDsrResponse({
    required this.status,
    required this.customerSummery,
    required this.visitPurposeList,
    required this.joinVisitList,
    required this.personMetList,
    required this.departmentList,
  });

  factory GetVisitDsrResponse.fromJson(Map<String, dynamic> json) {
    var customerSummeryData = json["CustomerSummery"][0];
    final customerSummery = CustomerSummery.fromJson(customerSummeryData);

    var visitPurposeList = json["VisitPurpose"] as List;
    var joinVisitList = json["JoinVisit"] as List;
    var personMetList = json["PersonMet"] as List;
    var departmentList = json["Department"] as List;
    List<VisitPurpose> visitPurpose =
        visitPurposeList.map((i) => VisitPurpose.fromJson(i)).toList();
    List<JoinVisit> joinVisit =
        joinVisitList.map((i) => JoinVisit.fromJson(i)).toList();
    List<PersonMet> personMet =
        personMetList.map((i) => PersonMet.fromJson(i)).toList();
    List<Department> department =
        departmentList.map((i) => Department.fromJson(i)).toList();

    return GetVisitDsrResponse(
      status: json['Status'] ?? '',
      customerSummery: customerSummery,
      visitPurposeList: visitPurpose,
      joinVisitList: joinVisit,
      personMetList: personMet,
      departmentList: department,
    );
  }
}

class CustomerSummery {
  final int customerId;
  final String customerName;
  final String customerType;
  final String address;
  final String emailId;
  final String mobile;
  final String refCode;

  CustomerSummery({
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.address,
    required this.emailId,
    required this.mobile,
    required this.refCode,
  });

  factory CustomerSummery.fromJson(Map<String, dynamic> json) {
    return CustomerSummery(
      customerId: json['CustomerId'] ?? 0,
      customerName: json['CustomerName'] ?? '',
      customerType: json['CustomerType'] ?? '',
      address: json['Address'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      refCode: json['RefCode'] ?? '',
    );
  }
}

class VisitPurpose {
  final String visitPurpose;
  final int id;

  VisitPurpose({
    required this.visitPurpose,
    required this.id,
  });

  factory VisitPurpose.fromJson(Map<String, dynamic> json) {
    return VisitPurpose(
      visitPurpose: json['VisitPurpose'] ?? '',
      id: json['Id'] ?? 0,
    );
  }
}

class JoinVisit {
  final String executiveName;
  final int executiveId;

  JoinVisit({
    required this.executiveName,
    required this.executiveId,
  });

  factory JoinVisit.fromJson(Map<String, dynamic> json) {
    return JoinVisit(
      executiveName: json['ExecutiveName'] ?? '',
      executiveId: json['ExecutiveId'] ?? 0,
    );
  }
}

class PersonMet {
  final String customerContactName;
  final int customerContactId;

  PersonMet({
    required this.customerContactName,
    required this.customerContactId,
  });

  factory PersonMet.fromJson(Map<String, dynamic> json) {
    return PersonMet(
      customerContactName: json['CustomerContactName'] ?? '',
      customerContactId: json['CustomerContactId'] ?? 0,
    );
  }
}

class Department {
  final String executiveDepartmentName;
  final int id;

  Department({
    required this.executiveDepartmentName,
    required this.id,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      executiveDepartmentName: json['ExecutiveDepartmentName'] ?? '',
      id: json['Id'] ?? 0,
    );
  }
}