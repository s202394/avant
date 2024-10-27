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
      id: json['Id'] ?? 0,
      keyName: json['KeyName'] ?? '',
      keyValue: json['KeyValue'] ?? '',
      keyStatus: (json['KeyStatus'] ?? false) == true,
      keyDescription: json['KeyDescription'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'KeyName': keyName,
      'KeyValue': keyValue,
      'KeyStatus': keyStatus ? 1 : 0, // Convert to int for sqflite
      'KeyDescription': keyDescription,
    };
  }

  static SetupValues fromDatabase(Map<String, dynamic> json) {
    return SetupValues(
      id: json['Id'],
      keyName: json['KeyName'],
      keyValue: json['KeyValue'],
      keyStatus: json['KeyStatus'] == 1,
      keyDescription: json['KeyDescription'],
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    return {
      'Id': id,
      'KeyName': keyName,
      'KeyValue': keyValue,
      'KeyStatus': keyStatus ? 1 : 0,
      'KeyDescription': keyDescription,
    };
  }
}
