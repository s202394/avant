class ApprovalDetailsResponse {
  final String? status;
  final RequestDetails? requestDetails;
  final List<TitleDetails>? titleDetails;
  final List<ApprovalMatrix>? approvalMatrix;
  final CustomerDetails? customerDetails;
  final List<ClarificationExecutivesList>? clarificationExecutivesList;
  final List<ClarificationList>? clarificationList;

  ApprovalDetailsResponse({
    this.status,
    this.requestDetails,
    this.titleDetails,
    this.approvalMatrix,
    this.customerDetails,
    this.clarificationExecutivesList,
    this.clarificationList,
  });

  factory ApprovalDetailsResponse.fromJson(Map<String, dynamic> json) {
    var requestDetailsData = json["RequestDetails"] as List?;
    RequestDetails? requestDetail;
    if (requestDetailsData != null && requestDetailsData.isNotEmpty) {
      requestDetail = RequestDetails.fromJson(requestDetailsData[0]);
    }

    var titleDetailsData = json["TitleDetails"] as List?;
    List<TitleDetails>? titleDetailsList;
    if (titleDetailsData != null && titleDetailsData.isNotEmpty) {
      titleDetailsList = titleDetailsData.map((i) => TitleDetails.fromJson(i)).toList();
    }

    var approvalMatrixData = json["ApprovalMatrix"] as List?;
    List<ApprovalMatrix>? approvalMatrixList;
    if (approvalMatrixData != null && approvalMatrixData.isNotEmpty) {
      approvalMatrixList = approvalMatrixData.map((i) => ApprovalMatrix.fromJson(i)).toList();
    }

    var customerDetailsList = json["CustomerDetails"] as List?;
    CustomerDetails? customerDetail;
    if (customerDetailsList != null && customerDetailsList.isNotEmpty) {
      customerDetail = CustomerDetails.fromJson(customerDetailsList[0]);
    }

    var clarificationExecutives = json["ClarificationExecutivesList"] as List?;
    List<ClarificationExecutivesList>? clarificationExecutivesLists;
    if (clarificationExecutives != null && clarificationExecutives.isNotEmpty) {
      clarificationExecutivesLists = clarificationExecutives.map((i) => ClarificationExecutivesList.fromJson(i)).toList();
    }

    var clarification = json["ClarificationList"] as List?;
    List<ClarificationList>? clarificationLists;
    if (clarification != null && clarification.isNotEmpty) {
      clarificationLists = clarification.map((i) => ClarificationList.fromJson(i)).toList();
    }

    return ApprovalDetailsResponse(
      status: json['Status'] as String?,
      requestDetails: requestDetail,
      titleDetails: titleDetailsList,
      approvalMatrix: approvalMatrixList,
      customerDetails: customerDetail,
      clarificationExecutivesList: clarificationExecutivesLists,
      clarificationList: clarificationLists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'RequestDetails': requestDetails?.toJson(),
      'TitleDetails': titleDetails?.map((e) => e.toJson()).toList(),
      'ApprovalMatrix': approvalMatrix?.map((e) => e.toJson()).toList(),
      'CustomerDetails': customerDetails?.toJson(),
      'ClarificationExecutivesList': clarificationExecutivesList?.map((e) => e.toJson()).toList(),
      'ClarificationList': clarificationList?.map((e) => e.toJson()).toList(),
    };
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
  final double requestedBudget;
  final int budget;
  final int executiveId;
  final String executiveCode;
  final int shipmentModeId;
  final String shipTo;
  final int booksellerId;
  final String booksellerName;
  final String booksellerCode;
  final int areaId;
  final String approvalStatus;

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
    required this.requestedBudget,
    required this.budget,
    required this.executiveId,
    required this.executiveCode,
    required this.shipTo,
    required this.shipmentModeId,
    required this.booksellerId,
    required this.booksellerName,
    required this.booksellerCode,
    required this.areaId,
    required this.approvalStatus,
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
      requestedBudget: json['RequestedBudget'] ?? 0,
      budget: json['Budget'] ?? 0,
      executiveId: json['ExecutiveId'] ?? 0,
      executiveCode: json['ExecutiveCode'] ?? '',
      shipmentModeId: json['ShipmentModeId'] ?? 0,
      shipTo: json['ShipTo'] ?? '',
      booksellerId: json['BooksellerId'] ?? 0,
      booksellerName: json['BooksellerName'] ?? '',
      booksellerCode: json['BooksellerCode'] ?? '',
      areaId: json['AreaId'] ?? 0,
      approvalStatus: json['ApprovalStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RequestId': requestId,
      'RequestDate': requestDate,
      'RequestNumber': requestNumber,
      'RequestStatus': requestStatus,
      'RequestRemarks': requestRemarks,
      'ShipmentStatus': shipmentStatus,
      'ShippingAddress': shippingAddress,
      'ShippingInstructions': shippingInstructions,
      'ShipmentMode': shipmentMode,
      'AreaName': areaName,
      'WareHouseName': wareHouseName,
      'CustomerName': customerName,
      'RefCode': refCode,
      'ExecutiveName': executiveName,
      'RequestedBudget': requestedBudget,
      'Budget': budget,
      'ExecutiveId': executiveId,
      'ExecutiveCode': executiveCode,
      'ShipmentModeId': shipmentModeId,
      'ShipTo': shipTo,
      'BooksellerId': booksellerId,
      'BooksellerName': booksellerName,
      'BooksellerCode': booksellerCode,
      'AreaId': areaId,
      'ApprovalStatus': approvalStatus,
    };
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
  int approvedQty;
  final int budget;
  final double requestedBudget;
  final double bookMRP;
  final int recId;
  final String requestNumber;
  final String bookTypeName;
  final String bookNum;
  final int subjectId;
  final String subjectName;
  final String bookTypeName1;
  final int seriesId;
  final String seriesName;

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
    required this.budget,
    required this.requestedBudget,
    required this.bookMRP,
    required this.recId,
    required this.requestNumber,
    required this.bookTypeName,
    required this.bookNum,
    required this.subjectId,
    required this.subjectName,
    required this.bookTypeName1,
    required this.seriesId,
    required this.seriesName,
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
      budget: json['Budget'] ?? 0,
      requestedBudget: json['RequestedBudget'] ?? 0,
      bookMRP: json['BookMRP'] ?? 0,
      recId: json['RecId'] ?? 0,
      requestNumber: json['RequestNumber'] ?? '',
      bookTypeName: json['BookTypeName'] ?? '',
      bookNum: json['BookNum'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      bookTypeName1: json['BookTypeName1'] ?? '',
      seriesId: json['SeriesId'] ?? 0,
      seriesName: json['SeriesName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RequestId': requestId,
      'RequestedQty': requestedQty,
      'ShippedQty': shippedQty,
      'ShipmentRejectQty': shipmentRejectQty,
      'ISBN': isbn,
      'BookId': bookId,
      'Title': title,
      'Price': price,
      'PreviousApprovedQty': previousApprovedQty,
      'Author': author,
      'Series': series,
      'ApprovedQty': approvedQty,
      'Budget': budget,
      'RequestedBudget': requestedBudget,
      'BookMRP': bookMRP,
      'RecId': recId,
      'RequestNumber': requestNumber,
      'BookTypeName': bookTypeName,
      'BookNum': bookNum,
      'subjectId': subjectId,
      'SubjectName': subjectName,
      'BookTypeName1': bookTypeName1,
      'SeriesId': seriesId,
      'SeriesName': seriesName,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'CustomerName': customerName,
      'Address': address,
      'Name': name,
      'EmailId': emailId,
      'Mobile': mobile,
    };
  }
}

class ClarificationExecutivesList {
  final int executiveId;
  final String executive;

  ClarificationExecutivesList({
    required this.executiveId,
    required this.executive,
  });

  factory ClarificationExecutivesList.fromJson(Map<String, dynamic> json) {
    return ClarificationExecutivesList(
      executiveId: json['ExecutiveId'] ?? 0,
      executive: json['Executive'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveId': executiveId,
      'Executive': executive,
    };
  }
}

class ClarificationList {
  final String queryBy;
  final String clarificationQuery;
  final String clarificationQueryTo;
  final String clarificationQueryDate;
  final String clarificationResponse;
  final String responseBy;
  final String clarificationResponseDate;
  final String clarificationResponseFileUpload;

  ClarificationList({
    required this.queryBy,
    required this.clarificationQuery,
    required this.clarificationQueryTo,
    required this.clarificationQueryDate,
    required this.clarificationResponse,
    required this.responseBy,
    required this.clarificationResponseDate,
    required this.clarificationResponseFileUpload,
  });

  factory ClarificationList.fromJson(Map<String, dynamic> json) {
    return ClarificationList(
      queryBy: json['QueryBy'] ?? '',
      clarificationQuery: json['ClarificationQuery'] ?? '',
      clarificationQueryTo: json['ClarificationQueryTo'] ?? '',
      clarificationQueryDate: json['ClarificationQueryDate'] ?? '',
      clarificationResponse: json['ClarificationResponse'] ?? '',
      responseBy: json['responseby'] ?? '',
      clarificationResponseDate: json['ClarificationResponseDate'] ?? '',
      clarificationResponseFileUpload:
          json['ClarificationResponseFileUpload'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QueryBy': queryBy,
      'ClarificationQuery': clarificationQuery,
      'ClarificationQueryTo': clarificationQueryTo,
      'ClarificationQueryDate': clarificationQueryDate,
      'ClarificationResponse': clarificationResponse,
      'responseby': responseBy,
      'ClarificationResponseDate': clarificationResponseDate,
      'ClarificationResponseFileUpload': clarificationResponseFileUpload,
    };
  }
}
