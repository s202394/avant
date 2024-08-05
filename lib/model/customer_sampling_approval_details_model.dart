class CustomerSamplingApprovalDetailsResponse {
  final String status;
  final RequestDetails requestDetails;
  final TitleDetails titleDetails;
  final ApprovalMatrix approvalMatrix;
  final CustomerDetails customerDetails;

  CustomerSamplingApprovalDetailsResponse({
    required this.status,
    required this.requestDetails,
    required this.titleDetails,
    required this.approvalMatrix,
    required this.customerDetails,
  });

  factory CustomerSamplingApprovalDetailsResponse.fromJson(
      Map<String, dynamic> json) {
    var requestDetailsData = json["RequestDetails"][0];
    final RequestDetails = RequestDetails.fromJson(requestDetailsData);
    var titleDetailsData = json["TitleDetails"][0];
    final TitleDetails = RequestDetails.fromJson(titleDetailsData);
    var approvalMatrixData = json["TitleDetails"][0];
    final ApprovalMatrix = ApprovalMatrix.fromJson(approvalMatrixData);
    var customerDetailsData = json["CustomerDetails"][0];
    final CustomerDetails = ApprovalMatrix.fromJson(customerDetailsData);

    return CustomerSamplingApprovalDetailsResponse(
      status: json['Status'] ?? '',
      requestDetails: RequestDetails,
      titleDetails: TitleDetails,
      approvalMatrix: ApprovalMatrix,
      customerDetails: CustomerDetails,
    );
  }
}

class RequestDetails {
  final int requestId;
  final String requestDate;
  final String requestNumber;
  final String requestStatus;
  final String requestRemarks;
  final String shipmentStatus;
  final String shippingAddress;
  final String shippingInstructions;
  final String shipmentMode;
  final String areaName;
  final String wareHouseName;
  final String customerName;
  final String refCode;
  final String executiveName;

  RequestDetails({
    required this.requestId,
    required this.requestDate,
    required this.requestNumber,
    required this.requestStatus,
    required this.requestRemarks,
    required this.shipmentStatus,
    required this.shippingAddress,
    required this.shippingInstructions,
    required this.shipmentMode,
    required this.areaName,
    required this.wareHouseName,
    required this.customerName,
    required this.refCode,
    required this.executiveName,
  });

  factory RequestDetails.fromJson(Map<String, dynamic> json) {
    return RequestDetails(
      requestId: json['RequestId'] ?? 0,
      requestDate: json['RequestDate'] ?? '',
      requestNumber: json['RequestNumber'] ?? '',
      requestStatus: json['RequestStatus'] ?? '',
      requestRemarks: json['RequestRemarks'] ?? '',
      shipmentStatus: json['ShipmentStatus'] ?? '',
      shippingAddress: json['ShippingAddress'] ?? '',
      shippingInstructions: json['ShippingInstructions'] ?? '',
      shipmentMode: json['ShipmentMode'] ?? '',
      areaName: json['AreaName'] ?? '',
      wareHouseName: json['WareHouseName'] ?? '',
      customerName: json['CustomerName'] ?? '',
      refCode: json['RefCode'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
    );
  }
}

class TitleDetails {
  final int requestId;
  final int requestedQty;
  final int shippedQty;
  final int shipmentRejectQty;
  final String isbn;
  final int bookId;
  final String title;
  final double price;
  final String previousApprovedQty;
  final String author;
  final String series;
  final int approvedQty;

  TitleDetails({
    required this.requestId,
    required this.requestedQty,
    required this.shippedQty,
    required this.shipmentRejectQty,
    required this.isbn,
    required this.bookId,
    required this.title,
    required this.price,
    required this.previousApprovedQty,
    required this.author,
    required this.series,
    required this.approvedQty,
  });

  factory TitleDetails.fromJson(Map<String, dynamic> json) {
    return TitleDetails(
      requestId: json['RequestId'] ?? 0,
      requestedQty: json['RequestedQty'] ?? 0,
      shippedQty: json['ShippedQty'] ?? 0,
      shipmentRejectQty: json['ShipmentRejectQty'] ?? 0,
      isbn: json['ISBN'] ?? '',
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      price: json['Price'] ?? 0,
      previousApprovedQty: json['PreviousApprovedQty'] ?? '',
      author: json['Author'] ?? '',
      series: json['Series'] ?? '',
      approvedQty: json['ApprovedQty'] ?? 0,
    );
  }
}

class ApprovalMatrix {
  final int sequenceNo;
  final String entryDate;
  final String executiveName;
  final String profileCode;
  final String approvalLevel;
  final String remarks;
  final int requestId;

  ApprovalMatrix({
    required this.sequenceNo,
    required this.entryDate,
    required this.executiveName,
    required this.profileCode,
    required this.approvalLevel,
    required this.remarks,
    required this.requestId,
  });

  factory ApprovalMatrix.fromJson(Map<String, dynamic> json) {
    return ApprovalMatrix(
      sequenceNo: json['SequenceNo'] ?? 0,
      entryDate: json['EntryDate'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      profileCode: json['ProfileCode'] ?? 0,
      approvalLevel: json['ApprovalLevel'] ?? '',
      remarks: json['Remarks'] ?? '',
      requestId: json['RequestId'] ?? 0,
    );
  }
}

class CustomerDetails {
  final int customerId;
  final String customerName;
  final String address;
  final String name;
  final String emailId;
  final String mobile;

  CustomerDetails({
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.name,
    required this.emailId,
    required this.mobile,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      customerId: json['CustomerId'] ?? 0,
      customerName: json['CustomerName'] ?? '',
      address: json['Address'] ?? '',
      name: json['Name'] ?? 0,
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
    );
  }
}