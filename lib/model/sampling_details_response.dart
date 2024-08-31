class SamplingDetailsResponse {
  final String status;
  final List<SamplingType>? samplingType;
  final List<SampleGiven>? sampleGiven;
  final List<SamplingTitleList>? titleList;
  final List<SampleTo>? sampleTo;

  SamplingDetailsResponse({
    required this.status,
    required this.samplingType,
    required this.sampleGiven,
    required this.titleList,
    required this.sampleTo,
  });

  factory SamplingDetailsResponse.fromJson(Map<String, dynamic> json) {
    var samplingTypeData = json["SamplingType"] as List?;
    List<SamplingType>? samplingType;
    if (samplingTypeData != null && samplingTypeData.isNotEmpty) {
      samplingType =
          samplingTypeData.map((i) => SamplingType.fromJson(i)).toList();
    }
    var sampleGivenData = json["SampleGiven"] as List?;
    List<SampleGiven>? sampleGiven;
    if (sampleGivenData != null && sampleGivenData.isNotEmpty) {
      sampleGiven =
          sampleGivenData.map((i) => SampleGiven.fromJson(i)).toList();
    }
    var titleListData = json["TitleList"] as List?;
    List<SamplingTitleList>? titleList;
    if (titleListData != null && titleListData.isNotEmpty) {
      titleList =
          titleListData.map((i) => SamplingTitleList.fromJson(i)).toList();
    }
    var sampleToData = json["SampleTo"] as List?;
    List<SampleTo>? sampleTo;
    if (sampleToData != null && sampleToData.isNotEmpty) {
      sampleTo = sampleToData.map((i) => SampleTo.fromJson(i)).toList();
    }

    return SamplingDetailsResponse(
      status: json['Status'] ?? '',
      samplingType: samplingType,
      sampleGiven: sampleGiven,
      titleList: titleList,
      sampleTo: sampleTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'SamplingType': samplingType?.map((e) => e.toJson()).toList(),
      'SampleGiven': sampleGiven?.map((e) => e.toJson()).toList(),
      'TitleList': titleList?.map((e) => e.toJson()).toList(),
      'SampleTo': sampleTo?.map((e) => e.toJson()).toList(),
    };
  }
}

class SamplingType {
  final String samplingType;
  final String samplingTypeValue;

  SamplingType({
    required this.samplingType,
    required this.samplingTypeValue,
  });

  factory SamplingType.fromJson(Map<String, dynamic> json) {
    return SamplingType(
      samplingType: json['SamplingType'] ?? '',
      samplingTypeValue: json['SamplingTypeValue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SamplingType': samplingType,
      'SamplingTypeValue': samplingTypeValue,
    };
  }
}

class SampleGiven {
  final String sampleGiven;
  final String sampleGivenValue;

  SampleGiven({
    required this.sampleGiven,
    required this.sampleGivenValue,
  });

  factory SampleGiven.fromJson(Map<String, dynamic> json) {
    return SampleGiven(
      sampleGiven: json['SampleGiven'] ?? '',
      sampleGivenValue: json['SampleGivenValue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SampleGiven': sampleGiven,
      'SampleGivenValue': sampleGivenValue,
    };
  }
}

class SamplingTitleList {
  final int bookId;
  final String title;
  final String isbn;
  final String author;
  final double price;
  final int physicalQty;
  final String bookType;
  final int maxSamplingQty;

  SamplingTitleList({
    required this.bookId,
    required this.title,
    required this.isbn,
    required this.author,
    required this.price,
    required this.physicalQty,
    required this.bookType,
    required this.maxSamplingQty,
  });

  factory SamplingTitleList.fromJson(Map<String, dynamic> json) {
    return SamplingTitleList(
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      isbn: json['ISBN'] ?? '',
      author: json['Author'] ?? '',
      price: json['Price'] ?? '',
      physicalQty: json['PhysicalQty'] ?? 0,
      bookType: json['BookType'] ?? '',
      maxSamplingQty: json['MaxSamplingQty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BookId': bookId,
      'Title': title,
      'ISBN': isbn,
      'Author': author,
      'Price': price,
      'PhysicalQty': physicalQty,
      'BookType': bookType,
      'MaxSamplingQty': maxSamplingQty,
    };
  }
}

class SampleTo {
  final String customerName;
  final int customerContactId;

  SampleTo({
    required this.customerName,
    required this.customerContactId,
  });

  factory SampleTo.fromJson(Map<String, dynamic> json) {
    return SampleTo(
      customerName: json['CustomerName'] ?? '',
      customerContactId: json['CustomerContactId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CustomerName': customerName,
      'CustomerContactId': customerContactId,
    };
  }
}
