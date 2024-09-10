class SearchCustomerResultResponse {
  final String status;
  final List<Result> result;

  SearchCustomerResultResponse({
    required this.status,
    required this.result,
  });

  factory SearchCustomerResultResponse.fromJson(Map<String, dynamic> json) {
    var listApproval = json["Result"] as List;
    List<Result> resultList =
        listApproval.map((i) => Result.fromJson(i)).toList();

    return SearchCustomerResultResponse(
      status: json['Status'] ?? '',
      result: resultList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'Result': result,
    };
  }
}

class Result {
  final int customerId;
  final String customerName;
  final String customerType;
  final String address;
  final String emailId;
  final String mobile;
  final String refCode;

  Result({
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.address,
    required this.emailId,
    required this.mobile,
    required this.refCode,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      customerId: json['CustomerId'] ?? 0,
      customerName: json['CustomerName'] ?? '',
      customerType: json['CustomerType'] ?? '',
      address: json['Address'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
      refCode: json['RefCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'CustomerName': customerName,
      'CustomerType': customerType,
      'Address': address,
      'EmailId': emailId,
      'Mobile': mobile,
      'RefCode': refCode,
    };
  }
}
