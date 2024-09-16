class ShipmentResponse {
  String status;
  List<ShipmentAddress>   shipmentAddress;

  ShipmentResponse({
    required this.status,
    required this.shipmentAddress,
  });

  factory ShipmentResponse.fromJson(Map<String, dynamic> json, String shipTo) {
    if (shipTo == "Trade") {
      return ShipmentResponse(
        status: json['Status'],
        shipmentAddress: List<ShipmentAddress>.from(
          json['ShipmentAddress'].map((x) => TradeShipmentAddress.fromJson(x)),
        ),
      );
    } else {
      return ShipmentResponse(
        status: json['Status'],
        shipmentAddress: List<ShipmentAddress>.from(
          json['ShipmentAddress'].map((x) => Address.fromJson(x)),
        ),
      );
    }
  }
}

class ShipmentAddress {}

class Address extends ShipmentAddress {
  String shippingAddress;
  String shippingAddress1;

  Address({
    required this.shippingAddress,
    required this.shippingAddress1,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      shippingAddress: json['ShippingAddress'],
      shippingAddress1: json['ShippingAddress1'],
    );
  }
}

  class TradeShipmentAddress extends ShipmentAddress {
  int customerId;
  String customerName;
  String customerType;
  String customerCity;
  String shippingAddress;
  String customerAddress;

  TradeShipmentAddress({
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.customerCity,
    required this.shippingAddress,
    required this.customerAddress,
  });

  factory TradeShipmentAddress.fromJson(Map<String, dynamic> json) {
    return TradeShipmentAddress(
      customerId: json['CustomerId'],
      customerName: json['CustomerName'],
      customerType: json['CustomerType'],
      customerCity: json['CustomerCity'],
      shippingAddress: json['ShippingAddress'],
      customerAddress: json['CustomerAddress'],
    );
  }
}
