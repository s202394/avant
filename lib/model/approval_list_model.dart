class ApprovalListResponse {
  final String status;
  final List<ApprovalList> approvalList;

  ApprovalListResponse({
    required this.status,
    required this.approvalList,
  });

  factory ApprovalListResponse.fromJson(
      Map<String, dynamic> json) {
    var listApproval = json["ApprovalList"] as List;
    List<ApprovalList> approval =
        listApproval.map((i) => ApprovalList.fromJson(i)).toList();

    return ApprovalListResponse(
      status: json['Status'] ?? '',
      approvalList: approval,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'ApprovalList': approvalList,
    };
  }
}

class ApprovalList {
  final int sNo;
  final int requestId;
  final String requestDate;
  final String requestNumber;
  final String executiveName;
  final String customerName;
  final int customerId;
  final String customerType;
  final String customerCode;
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String requestStatus;
  final String executiveCode;
  final String mobile;
  final String emailId;
  final String column1;

  ApprovalList({
    required this.sNo,
    required this.requestId,
    required this.requestDate,
    required this.requestNumber,
    required this.executiveName,
    required this.customerName,
    required this.customerId,
    required this.customerType,
    required this.customerCode,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.requestStatus,
    required this.executiveCode,
    required this.mobile,
    required this.emailId,
    required this.column1,
  });

  factory ApprovalList.fromJson(Map<String, dynamic> json) {
    return ApprovalList(
      sNo: json['SNo'] ?? 0,
      requestId: json['RequestId'] ?? 0,
      requestDate: json['RequestDate'] ?? '',
      requestNumber: json['RequestNumber'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      customerName: json['CustomerName'] ?? '',
      customerId: json['CustomerId'] ?? 0,
      customerType: json['CustomerType'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      requestStatus: json['RequestStatus'] ?? '',
      executiveCode: json['ExecutiveCode'] ?? '',
      mobile: json['Mobile'] ?? '',
      emailId: json['EmailId'] ?? '',
      column1: json['Column1'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'RequestId': requestId,
      'RequestDate': requestDate,
      'RequestNumber': requestNumber,
      'ExecutiveName': executiveName,
      'CustomerName': customerName,
      'CustomerId': customerId,
      'CustomerType': customerType,
      'CustomerCode': customerCode,
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'RequestStatus': requestStatus,
      'ExecutiveCode': executiveCode,
      'Mobile': mobile,
      'EmailId': emailId,
      'Column1': column1,
    };
  }
}
