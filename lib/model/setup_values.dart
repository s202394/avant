class SetupValues {
  final int id;
  final String keyName;
  final String keyValue;
  final bool keyStatus;
  final String keyDescription;

  SetupValues({
    required this.id,
    required this.keyName,
    required this.keyValue,
    required this.keyStatus,
    required this.keyDescription,
  });

  factory SetupValues.fromJson(Map<String, dynamic> json) {
    return SetupValues(
      id: json['Id'] ?? '',
      keyName: json['KeyName'] ?? '',
      keyValue: json['KeyValue'] ?? '',
      keyStatus: json['KeyStatus'] ?? '',
      keyDescription: json['KeyDescription'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'KeyName': keyName,
      'KeyValue': keyValue,
      'KeyStatus': keyStatus,
      'KeyDescription': keyDescription,
    };
  }
}
