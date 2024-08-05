class FollowupActionExecutiveResponse {
  final String status;
  final List<Executive> executiveList;

  FollowupActionExecutiveResponse({
    required this.status,
    required this.executiveList,
  });

  factory FollowupActionExecutiveResponse.fromJson(Map<String, dynamic> json) {
    var listExecutive = json["Executive"] as List;
    List<Executive> list =
    listExecutive.map((i) => Executive.fromJson(i)).toList();

    return FollowupActionExecutiveResponse(
      status: json['Status'] ?? '',
      executiveList: list,
    );
  }
}

class Executive {
  final int executiveId;
  final String executiveName;

  Executive({
    required this.executiveId,
    required this.executiveName,
  });

  factory Executive.fromJson(Map<String, dynamic> json) {
    return Executive(
      executiveId: json['ExecutiveId'] ?? 0,
      executiveName: json['ExecutiveName'] ?? '',
    );
  }
}
