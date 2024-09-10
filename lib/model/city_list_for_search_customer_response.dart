class CityListForSearchCustomerResponse {
  final String status;
  final List<CityList> cityList;

  CityListForSearchCustomerResponse({
    required this.status,
    required this.cityList,
  });

  factory CityListForSearchCustomerResponse.fromJson(
      Map<String, dynamic> json) {
    var cityList = json["CityList"] as List;
    List<CityList> cityListData =
        cityList.map((i) => CityList.fromJson(i)).toList();

    return CityListForSearchCustomerResponse(
      status: json['Status'] ?? '',
      cityList: cityListData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'ApprovalList': cityList,
    };
  }
}

class CityList {
  final double cityId;
  final String cityName;

  CityList({
    required this.cityId,
    required this.cityName,
  });

  factory CityList.fromJson(Map<String, dynamic> json) {
    return CityList(
      cityId: json['CityId'] ?? 0,
      cityName: json['CityName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CityId': cityId,
      'CityName': cityName,
    };
  }
}
