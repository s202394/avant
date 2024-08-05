class VisitEntryResponse {
  final String status;
  final String s;

  VisitEntryResponse({
    required this.status,
    required this.s,
  });

  factory VisitEntryResponse.fromJson(Map<String, dynamic> json) {
    return VisitEntryResponse(
      status: json['Status'] ?? '',
      s: json['s'] ?? '',
    );
  }
}