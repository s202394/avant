class SaveFileResponse {
  final String status;
  final String message;
  final ReturnDetails returnDetails;

  SaveFileResponse({
    required this.status,
    required this.message,
    required this.returnDetails,
  });

  factory SaveFileResponse.fromJson(Map<String, dynamic> json) {
    var returnMessageData = json["ReturnDetails"][0];
    final returnDetails = ReturnDetails.fromJson(returnMessageData);

    return SaveFileResponse(
      status: json['Status'] ?? '',
      message: json['Message'] ?? '',
      returnDetails: returnDetails,
    );
  }
}

class ReturnDetails {
  final String fileName;
  final String module;

  ReturnDetails({
    required this.fileName,
    required this.module,
  });

  factory ReturnDetails.fromJson(Map<String, dynamic> json) {
    return ReturnDetails(
      fileName: json['FileName'] ?? '',
      module: json['Module'] ?? '',
    );
  }
}
