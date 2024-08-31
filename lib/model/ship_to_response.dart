class ShipToResponse {
  final String? status;
  final ShipTo? shipTo;

  ShipToResponse({
    this.status,
    this.shipTo,
  });

  factory ShipToResponse.fromJson(Map<String, dynamic> json) {
    var shipToData = json["ShipTo"] as List?;
    ShipTo? shipToDetail;
    if (shipToData != null && shipToData.isNotEmpty) {
      shipToDetail = ShipTo.fromJson(shipToData[0]);
    }
    return ShipToResponse(
      status: json['Status'] as String?,
      shipTo: shipToDetail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'ShipTo': shipTo?.toJson(),
    };
  }
}

class ShipTo {
  final String resAddress;
  final String officeAddress;

  ShipTo({
    required this.resAddress,
    required this.officeAddress,
  });

  factory ShipTo.fromJson(Map<String, dynamic> json) {
    return ShipTo(
      resAddress: json['ResAddress'] ?? '',
      officeAddress: json['OfficeAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ResAddress': resAddress,
      'OfficeAddress': officeAddress,
    };
  }
}
