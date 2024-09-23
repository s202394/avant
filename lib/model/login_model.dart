import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/db/db_helper.dart';

class LoginResponse {
  final String status;
  final ExecutiveData executiveBasicData;

  LoginResponse({
    required this.status,
    required this.executiveBasicData,
  });

  // Add a getter for executiveData
  ExecutiveData get executiveData => executiveBasicData;

  static Future<LoginResponse> fromJson(
      Map<String, dynamic> responseData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Store ExecutiveBasicdata data in SharedPreferences
    final executiveDataJson = responseData['ExecutiveBasicdata'][0];
    final executiveBasicData = ExecutiveData.fromJson(executiveDataJson);
    await prefs.setString(
        'executiveData', jsonEncode(executiveBasicData.toJson()));

    // Parse and store Application Setup Data
    if (responseData['ApplicationSetup'] != null &&
        responseData['ApplicationSetup'] is List) {
      final applicationSetupList = responseData['ApplicationSetup'] as List;
      List<ApplicationSetup> applicationSetups = applicationSetupList
          .map((data) => ApplicationSetup.fromJson(data))
          .toList();

      for (var setup in applicationSetups) {
        await DatabaseHelper().insertApplicationSetup(setup);
      }
    } else {
      if (kDebugMode) {
        print('ApplicationSetup data is null or not a list');
      }
    }

    // Store ProductDivision data in SharedPreferences
    final productDivisionJson = responseData['ProductDivision'][0];
    final productDivisionData = ProductDivision.fromJson(productDivisionJson);
    await prefs.setString(
        'ProductDivisionIds', productDivisionData.productDivisionIds);
    await prefs.setString(
        'ExecutiveDepartmentCode', productDivisionData.executiveDepartmentCode);

    // Store UpHierarchy data in SharedPreferences
    final upHierarchyJson = responseData['UpHierarchy'][0];
    final upHierarchyData = UpHierarchy.fromJson(upHierarchyJson);
    await prefs.setString('UpHierarchy', upHierarchyData.upHierarchy);

    // Store DownHierarchy data in SharedPreferences
    final downHierarchyJson = responseData['DownHierarchy'][0];
    final downHierarchyData = DownHierarchy.fromJson(downHierarchyJson);
    await prefs.setString('DownHierarchy', downHierarchyData.downHierarchy);

    // Store TerritoryAccess data in SharedPreferences
    final territoryAccessJson = responseData['TerritoryAccess'][0];
    final territoryAccessData = TerritoryAccess.fromJson(territoryAccessJson);
    await prefs.setString(
        'TerritoryAccess', territoryAccessData.territoryAccess);

    // Store CityAccess data in SharedPreferences
    final cityAccessJson = responseData['CityAccess'][0];
    final cityAccessData = CityAccess.fromJson(cityAccessJson);
    await prefs.setString('CityAccess', cityAccessData.cityAccess);

    // Store EntryAccess data in SharedPreferences
    final entryAccessJson = responseData['EntryAccess'][0];
    final entryAccessData = EntryAccess.fromJson(entryAccessJson);
    await prefs.setString('EntryAccess', entryAccessData.entryAccess);

    return LoginResponse(
      status: responseData['Status'] ?? '',
      executiveBasicData: executiveBasicData,
    );
  }
}

class ExecutiveData {
  final int userId;
  final int executiveId;
  final String executiveCode;
  final String executiveName;
  final String executiveEmail;
  final String executiveMobile;
  final String executiveCategoryName;
  final String executiveDesignationName;
  final int profileId;
  final String profileCode;
  final String profileName;
  final String loginBlocked;
  final String profileImage;

  ExecutiveData({
    required this.userId,
    required this.executiveId,
    required this.executiveCode,
    required this.executiveName,
    required this.executiveEmail,
    required this.executiveMobile,
    required this.executiveCategoryName,
    required this.executiveDesignationName,
    required this.profileId,
    required this.profileCode,
    required this.profileName,
    required this.loginBlocked,
    required this.profileImage,
  });

  factory ExecutiveData.fromJson(Map<String, dynamic> json) {
    return ExecutiveData(
      userId: json['UserId'] ?? 0,
      executiveId: json['ExecutiveId'] ?? 0,
      executiveCode: json['ExecutiveCode'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      executiveEmail: json['ExecutiveEmail'] ?? '',
      executiveMobile: json['ExecutiveMobile'] ?? '',
      executiveCategoryName: json['ExecutiveCategoryName'] ?? '',
      executiveDesignationName: json['ExecutiveDesignationName'] ?? '',
      profileId: json['ProfileId'] ?? 0,
      profileCode: json['ProfileCode'] ?? '',
      profileName: json['ProfileName'] ?? '',
      loginBlocked: json['LoginBlocked'] ?? '',
      profileImage: json['ProfileImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'ExecutiveId': executiveId,
      'ExecutiveCode': executiveCode,
      'ExecutiveName': executiveName,
      'ExecutiveEmail': executiveEmail,
      'ExecutiveMobile': executiveMobile,
      'ExecutiveCategoryName': executiveCategoryName,
      'ExecutiveDesignationName': executiveDesignationName,
      'ProfileId': profileId,
      'ProfileCode': profileCode,
      'ProfileName': profileName,
      'LoginBlocked': loginBlocked,
      'ProfileImage': profileImage,
    };
  }
}

class ApplicationSetup {
  final String key;
  final String keyValue;

  ApplicationSetup({
    required this.key,
    required this.keyValue,
  });

  factory ApplicationSetup.fromJson(Map<String, dynamic> json) {
    return ApplicationSetup(
      key: json['key'] ?? '',
      keyValue: json['KeyValue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'KeyValue': keyValue,
    };
  }
}

class ProductDivision {
  final int executiveId;
  final String productDivisionIds;
  final String executiveDepartmentCode;

  ProductDivision({
    required this.executiveId,
    required this.productDivisionIds,
    required this.executiveDepartmentCode,
  });

  factory ProductDivision.fromJson(Map<String, dynamic> json) {
    return ProductDivision(
      executiveId: json['ExecutiveId'] ?? 0,
      productDivisionIds: json['ProductDivisionIds'] ?? '',
      executiveDepartmentCode: json['ExecutiveDepartmentCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveId': executiveId,
      'ProductDivisionIds': productDivisionIds,
      'ExecutiveDepartmentCode': executiveDepartmentCode,
    };
  }
}

class UpHierarchy {
  final String upHierarchy;

  UpHierarchy({required this.upHierarchy});

  factory UpHierarchy.fromJson(Map<String, dynamic> json) {
    return UpHierarchy(
      upHierarchy: json['UpHierarchy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'UpHierarchy': upHierarchy};
  }
}

class DownHierarchy {
  final String downHierarchy;

  DownHierarchy({required this.downHierarchy});

  factory DownHierarchy.fromJson(Map<String, dynamic> json) {
    return DownHierarchy(
      downHierarchy: json['DownHierarchy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'DownHierarchy': downHierarchy};
  }
}

class TerritoryAccess {
  final String territoryAccess;

  TerritoryAccess({required this.territoryAccess});

  factory TerritoryAccess.fromJson(Map<String, dynamic> json) {
    return TerritoryAccess(
      territoryAccess: json['TerritoryAccess'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'TerritoryAccess': territoryAccess};
  }
}

class CityAccess {
  final String cityAccess;

  CityAccess({required this.cityAccess});

  factory CityAccess.fromJson(Map<String, dynamic> json) {
    return CityAccess(
      cityAccess: json['CityAccess'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'CityAccess': cityAccess};
  }
}

class EntryAccess {
  final String entryAccess;

  EntryAccess({required this.entryAccess});

  factory EntryAccess.fromJson(Map<String, dynamic> json) {
    return EntryAccess(
      entryAccess: json['EntryAccess'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EntryAccess': entryAccess,
    };
  }
}

// Function to retrieve profile id
Future<int?> getProfileId() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.profileId;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve profile id
Future<String?> getProfileCode() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.profileCode;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve user id
Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.userId;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve executive id
Future<int?> getExecutiveId() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.executiveId;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve executive name
Future<String?> getExecutiveName() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.executiveName;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve executive mobile
Future<String?> getExecutiveMobile() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.executiveMobile;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}
// Function to retrieve executive mobile
Future<String?> getExecutiveCode() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.executiveCode;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve executive designation name
Future<String?> getExecutiveDesignationName() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.executiveDesignationName;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve profile name
Future<String?> getProfileName() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.profileName;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}

// Function to retrieve login blocked
Future<String?> getLoginBlocked() async {
  final prefs = await SharedPreferences.getInstance();
  final String? executiveDataString = prefs.getString('executiveData');

  if (executiveDataString != null) {
    final Map<String, dynamic> executiveDataJson =
        jsonDecode(executiveDataString);
    final ExecutiveData executiveData =
        ExecutiveData.fromJson(executiveDataJson);
    return executiveData.loginBlocked;
  } else {
    return null; // Handle the case where the executiveData is not found
  }
}
