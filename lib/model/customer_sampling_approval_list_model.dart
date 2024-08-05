class CustomerSamplingApprovalListResponse {
  final String status;
  final List<ApprovalList> approvalList;

  CustomerSamplingApprovalListResponse({
    required this.status,
    required this.approvalList,
  });

  factory CustomerSamplingApprovalListResponse.fromJson(
      Map<String, dynamic> json) {
    var listApproval = json["Geography"] as List;
    List<ApprovalList> approval =
        listApproval.map((i) => ApprovalList.fromJson(i)).toList();

    return CustomerSamplingApprovalListResponse(
      status: json['Status'] ?? '',
      approvalList: approval,
    );
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
    );
  }
}
