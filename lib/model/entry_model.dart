class EntryResponse {
  final String status;
  final String s;
  final String e;

  EntryResponse({
    required this.status,
    required this.s,
    required this.e,
  });

  factory EntryResponse.fromJson(Map<String, dynamic> json) {
    return EntryResponse(
      status: json['Status'] ?? '',
      s: json['s'] ?? '',
      e: json['e'] ?? '',
    );
  }
}