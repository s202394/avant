class EntryResponse {
  final String status;
  final String s;

  EntryResponse({
    required this.status,
    required this.s,
  });

  factory EntryResponse.fromJson(Map<String, dynamic> json) {
    return EntryResponse(
      status: json['Status'] ?? '',
      s: json['s'] ?? '',
    );
  }
}