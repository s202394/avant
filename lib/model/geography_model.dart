class GeographyResponse {
  final String status;
  final List<Geography> geographyList;

  GeographyResponse({
    required this.status,
    required this.geographyList,
  });

  factory GeographyResponse.fromJson(Map<String, dynamic> json) {
    var listGeography = json["Geography"] as List;
    List<Geography> geography =
        listGeography.map((i) => Geography.fromJson(i)).toList();

    return GeographyResponse(
      status: json['Status'] ?? '',
      geographyList: geography,
    );
  }
}

class Geography {
  final int countryId;
  final String country;
  final int stateId;
  final String state;
  final int districtId;
  final String district;
  final int cityId;
  final String city;

  Geography({
    required this.countryId,
    required this.country,
    required this.stateId,
    required this.state,
    required this.districtId,
    required this.district,
    required this.cityId,
    required this.city,
  });

  factory Geography.fromJson(Map<String, dynamic> json) {
    return Geography(
      countryId: json['CountryId'] ?? 0,
      country: json['Country'] ?? '',
      stateId: json['StateId'] ?? 0,
      state: json['State'] ?? '',
      districtId: json['DistrictId'] ?? 0,
      district: json['District'] ?? '',
      cityId: json['CityId'] ?? 0,
      city: json['City'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CountryId': countryId,
      'Country': country,
      'StateId': stateId,
      'State': state,
      'DistrictId': districtId,
      'District': district,
      'CityId': cityId,
      'City': city,
    };
  }
}