class VisitDetailsResponse {
  final String? status;
  final CustomerDetails? customerDetails;
  final VisitDetails? visitDetails;
  final List<UploadedDocuments>? uploadedDocuments;
  final List<PromotionalDetails>? promotionalDetails;

  VisitDetailsResponse({
    required this.status,
    required this.customerDetails,
    required this.visitDetails,
    required this.uploadedDocuments,
    required this.promotionalDetails,
  });

  factory VisitDetailsResponse.fromJson(Map<String, dynamic> json) {
    // Handle CustomerDetails
    CustomerDetails? customerDetails;
    if (json["CustomerDetails"] != null && (json["CustomerDetails"] as List).isNotEmpty) {
      customerDetails = CustomerDetails.fromJson((json["CustomerDetails"] as List)[0]);
    }

    // Handle VisitDetails
    VisitDetails? visitDetails;
    if (json["VisitDetails"] != null && (json["VisitDetails"] as List).isNotEmpty) {
      visitDetails = VisitDetails.fromJson((json["VisitDetails"] as List)[0]);
    }

    // Handle UploadedDocuments
    List<UploadedDocuments> uploadedDocumentsList = [];
    if (json["UploadedDocuments"] != null) {
      uploadedDocumentsList = (json["UploadedDocuments"] as List)
          .map((item) => UploadedDocuments.fromJson(item))
          .toList();
    }

    // Handle PromotionalDetails
    List<PromotionalDetails>? promotionalDetailsList;
    if (json["PromotionalDetails"] != null && (json["PromotionalDetails"] as List).isNotEmpty) {
      promotionalDetailsList = (json["PromotionalDetails"] as List)
          .map((item) => PromotionalDetails.fromJson(item))
          .toList();
    }

    return VisitDetailsResponse(
      status: json['Status'] ?? '',
      customerDetails: customerDetails,
      visitDetails: visitDetails,
      uploadedDocuments: uploadedDocumentsList,
      promotionalDetails: promotionalDetailsList ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerDetails': customerDetails?.toJson(),
      'VisitDetails': visitDetails?.toJson(),
      'UploadedDocuments': uploadedDocuments?.map((e) => e.toJson()).toList(),
      'PromotionalDetails': promotionalDetails?.map((e) => e.toJson()).toList(),
    };
  }

  bool isEmpty() {
    return (customerDetails == null || visitDetails == null) &&
        (uploadedDocuments == null || uploadedDocuments!.isEmpty) &&
        (promotionalDetails == null || promotionalDetails!.isEmpty);
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
      name: json['Name'] ?? '',
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

class VisitDetails {
  final String executiveName;
  final String jointVisitWith;
  final String personMet;
  final String visitDate;
  final String visitPurpose;
  final String visitEntryDate;
  final String visitFeedback;
  final int customerId;
  final int customerContactId;
  final String customerType;
  final String webEntry;

  VisitDetails({
    required this.executiveName,
    required this.jointVisitWith,
    required this.personMet,
    required this.visitDate,
    required this.visitPurpose,
    required this.visitEntryDate,
    required this.visitFeedback,
    required this.customerId,
    required this.customerContactId,
    required this.customerType,
    required this.webEntry,
  });

  factory VisitDetails.fromJson(Map<String, dynamic> json) {
    return VisitDetails(
      executiveName: json['ExecutiveName'] ?? '',
      jointVisitWith: json['JointVisitWith'] ?? '',
      personMet: json['PersonMet'] ?? '',
      visitDate: json['VisitDate'] ?? '',
      visitPurpose: json['VisitPurpose'] ?? '',
      visitEntryDate: json['VisitEntryDate'] ?? '',
      visitFeedback: json['VisitFeedback'] ?? '',
      customerId: json['CustomerId'] ?? 0,
      customerContactId: json['CustomerContactId'] ?? 0,
      customerType: json['CustomerType'] ?? '',
      webEntry: json['WebEntry'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveName': executiveName,
      'JointVisitWith': jointVisitWith,
      'PersonMet': personMet,
      'VisitDate': visitDate,
      'VisitPurpose': visitPurpose,
      'VisitEntryDate': visitEntryDate,
      'VisitFeedback': visitFeedback,
      'CustomerId': customerId,
      'CustomerContactId': customerContactId,
      'CustomerType': customerType,
      'WebEntry': webEntry,
    };
  }
}

class UploadedDocuments {
  final int sNo;
  final String documentName;
  final String uploadedFile;
  final String action;

  UploadedDocuments({
    required this.sNo,
    required this.documentName,
    required this.uploadedFile,
    required this.action,
  });

  factory UploadedDocuments.fromJson(Map<String, dynamic> json) {
    return UploadedDocuments(
      sNo: json['SNO'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      uploadedFile: json['UploadedFile'] ?? '',
      action: json['Action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNO': sNo,
      'DocumentName': documentName,
      'UploadedFile': uploadedFile,
      'Action': action,
    };
  }
}

class PromotionalDetails {
  final int sNo;
  final String isbn;
  final int bookId;
  final String title;
  final double price;
  final String author;
  final String series;
  final int requestedQty;
  final String requestedNumber;
  final String requestedStatus;
  final String samplingType;
  final String samplingGiven;
  final String shipTo;
  final String shipmentAddress;

  PromotionalDetails({
    required this.sNo,
    required this.isbn,
    required this.bookId,
    required this.title,
    required this.price,
    required this.author,
    required this.series,
    required this.requestedQty,
    required this.requestedNumber,
    required this.requestedStatus,
    required this.samplingType,
    required this.samplingGiven,
    required this.shipTo,
    required this.shipmentAddress,
  });

  factory PromotionalDetails.fromJson(Map<String, dynamic> json) {
    return PromotionalDetails(
      sNo: json['SNO'] ?? 0,
      isbn: json['ISBN'] ?? '',
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      price: json['Price'] ?? 0,
      author: json['Author'] ?? '',
      series: json['Series'] ?? '',
      requestedQty: json['RequestedQty'] ?? 0,
      requestedNumber: json['RequestedNumber'] ?? '',
      requestedStatus: json['RequestedStatus'] ?? '',
      samplingType: json['SamplingType'] ?? '',
      samplingGiven: json['SamplingGiven'] ?? '',
      shipTo: json['ShipTo'] ?? '',
      shipmentAddress: json['ShipmentAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNO': sNo,
      'ISBN': isbn,
      'BookId': bookId,
      'Title': title,
      'Price': price,
      'Author': author,
      'Series': series,
      'RequestedQty': requestedQty,
      'RequestedNumber': requestedNumber,
      'RequestedStatus': requestedStatus,
      'SamplingType': samplingType,
      'SamplingGiven': samplingGiven,
      'ShipTo': shipTo,
      'ShipmentAddress': shipmentAddress,
    };
  }
}
