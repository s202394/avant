class SelfStockRequestResponse {
  final String status;
  final List<ShipmentMode> shipmentMode;
  final List<ShipTo> shipTo;

  SelfStockRequestResponse({
    required this.status,
    required this.shipmentMode,
    required this.shipTo,
  });

  factory SelfStockRequestResponse.fromJson(Map<String, dynamic> json) {
    var shipmentModeList = json["ShipmentMode"] as List;
    var shipToList = json["ShipTo"] as List;
    List<ShipmentMode> shipmentMode =
        shipmentModeList.map((i) => ShipmentMode.fromJson(i)).toList();
    List<ShipTo> shipTo = shipToList.map((i) => ShipTo.fromJson(i)).toList();

    return SelfStockRequestResponse(
      status: json['Status'] ?? '',
      shipmentMode: shipmentMode,
      shipTo: shipTo,
    );
  }
}

class ShipmentMode {
  final int shipmentModeId;
  final String shipmentMode;

  ShipmentMode({
    required this.shipmentModeId,
    required this.shipmentMode,
  });

  factory ShipmentMode.fromJson(Map<String, dynamic> json) {
    return ShipmentMode(
      shipmentModeId: json['ShipmentModeId'] ?? 0,
      shipmentMode: json['ShipmentMode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ShipmentModeId': shipmentModeId,
      'ShipmentMode': shipmentMode,
    };
  }
}

class ShipTo {
  final String shipTo;
  final String id;

  ShipTo({
    required this.shipTo,
    required this.id,
  });

  factory ShipTo.fromJson(Map<String, dynamic> json) {
    return ShipTo(
      shipTo: json['ShipTo'] ?? '',
      id: json['ID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ShipTo': shipTo,
      'ID': id,
    };
  }
}
