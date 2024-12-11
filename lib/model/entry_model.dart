class EntryResponse {
  final String status;
  String s = '';
  String e = '';
  String w = '';

  EntryResponse({
    required this.status,
    this.s = '',
    this.e = '',
    this.w = '',
  });

  factory EntryResponse.fromJson(Map<String, dynamic> json) {
    return EntryResponse(
      status: json['Status'] ?? '',
      s: json['s'] ?? '',
      e: json['e'] ?? '',
      w: json['w'] ?? '',
    );
  }
}
