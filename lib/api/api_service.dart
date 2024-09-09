import 'dart:convert';

import 'package:avant/api/api_constants.dart';
import 'package:avant/common/constants.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/approval_details_model.dart';
import 'package:avant/model/approval_list_model.dart';
import 'package:avant/model/change_password_model.dart';
import 'package:avant/model/check_in_check_out_response.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/entry_model.dart';
import 'package:avant/model/fetch_titles_model.dart';
import 'package:avant/model/followup_action_model.dart';
import 'package:avant/model/forgot_password_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/search_bookseller_response.dart';
import 'package:avant/model/setup_values.dart';
import 'package:avant/model/ship_to_response.dart';
import 'package:avant/model/submit_approval_model.dart';
import 'package:avant/model/travel_plan_model.dart';
import 'package:avant/model/visit_details_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/sampling_details_response.dart';
import '../model/series_and_class_level_list_response.dart';

class TokenService {
  Future<void> token(String username, String password) async {
    final body = jsonEncode(
        <String, String>{'username': username, 'password': password});
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    if (kDebugMode) {
      print("body:$body");
    }
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (kDebugMode) {
        print('Get token successful! responseData: $responseData');
      }
      // Store data in SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['Token']);
    } else {
      if (kDebugMode) {
        print('Get token failure! responseData: ${response.statusCode}');
      }
      throw Exception('Failed to getting token : ${response.reasonPhrase}');
    }
  }
}

class LoginService {
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      String ipAddress,
      String deviceId,
      String deviceInfo,
      String token) async {
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'EmailId': email,
        'Password': password,
        'IPAddress': ipAddress,
        'BrowserInformation': deviceInfo,
        'SessionId': deviceId,
        'Api': 'Yes',
      }),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (kDebugMode) {
        print('login successful! responseData: $responseData');
      }
      if (responseData['Status'] == 'Success') {
        return responseData;
      } else {
        if (kDebugMode) {
          print('login failure! responseData: ${response.statusCode}');
        }
        throw Exception('Failed to log in: ${responseData['Status']}');
      }
    } else {
      if (kDebugMode) {
        print('login failure!! responseData: ${response.statusCode}');
      }
      throw Exception('Failed to log in: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> logout(int userId, String token) async {
    final response = await http.post(
      Uri.parse(logoutUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, int>{
        'Id': userId,
      }),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (kDebugMode) {
        print('logout successful! responseData: $responseData');
      }
      if (responseData['Status'] == 'Success') {
        return responseData;
      } else {
        if (kDebugMode) {
          print('logout failure! responseData: ${response.statusCode}');
        }
        throw Exception('Failed to log out: ${responseData['Status']}');
      }
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryLogin(userId);
    } else {
      if (kDebugMode) {
        print('logout failure!! responseData: ${response.statusCode}');
      }
      throw Exception('Failed to log out: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> refreshAndRetryLogin(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await logout(userId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(
      String emailId, String token) async {
    final body = jsonEncode(<String, dynamic>{
      'EmailId': emailId,
    });
    final response = await http.post(
      Uri.parse(forgotPasswordUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ForgotPasswordResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryForgotPassword(emailId);
    } else {
      throw Exception('Failed to forgot password');
    }
  }

  Future<ForgotPasswordResponse> refreshAndRetryForgotPassword(
      String emailId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = tokenUsername;
    String password = tokenPassword;

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await forgotPassword(emailId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<ChangePasswordResponse> changePassword(
      int userId,
      String password,
      String newPassword,
      String ipAddress,
      String browserInformation,
      int enteredBy,
      String token) async {
    final body = jsonEncode(<String, dynamic>{
      'UserId': userId,
      'Password': password,
      'NewPassword': newPassword,
      'IPAddress': ipAddress,
      'BrowserInformation': browserInformation,
      'EnteredBy': enteredBy,
    });
    final response = await http.post(
      Uri.parse(changePasswordUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ChangePasswordResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryChangePassword(userId, password, newPassword,
          ipAddress, browserInformation, enteredBy);
    } else {
      throw Exception('Failed to change password');
    }
  }

  Future<ChangePasswordResponse> refreshAndRetryChangePassword(
      int userId,
      String password,
      String newPassword,
      String ipAddress,
      String browserInformation,
      int enteredBy) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await TokenService().token(tokenUsername, tokenPassword);
    String? newToken = prefs.getString('token');

    if (newToken != null && newToken.isNotEmpty) {
      return await changePassword(userId, password, newPassword, ipAddress,
          browserInformation, enteredBy, newToken);
    } else {
      throw Exception('Failed to retrieve new token');
    }
  }
}

class MenuService {
  Future<List<MenuData>> getMenus(int profileId, String token) async {
    final response = await http.post(
      Uri.parse(menuUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'Profileid': profileId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (kDebugMode) {
        print('Get menu successful! responseData: $responseData');
      }
      if (responseData['Status'] == 'Success') {
        if (responseData['Success'] != null &&
            responseData['Success'] is List) {
          final List<dynamic> menuList = responseData['Success'];
          final menus =
              menuList.map((data) => MenuData.fromJson(data)).toList();

          await DatabaseHelper().clearMenuDataDatabase();

          // Save the fetched menu data to the database
          for (var menu in menus) {
            await DatabaseHelper().insertMenuData(menu);
          }

          return menus;
        } else {
          if (kDebugMode) {
            print('Menu data is null or not a list');
          }
          return await getMenuDataFromDB();
        }
      } else {
        if (kDebugMode) {
          print('Status is not Success');
        }
        return await getMenuDataFromDB();
      }
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(profileId);
    } else {
      return await getMenuDataFromDB();
    }
  }

  Future<List<MenuData>> refreshAndRetry(int profileId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await getMenus(profileId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<List<MenuData>> getMenuDataFromDB() async {
    return await DatabaseHelper().getMenuDataFromDB();
  }
}

class SetupValuesService {
  Future<List<SetupValues>> setupValues(String token) async {
    final response = await http.post(
      Uri.parse(setupValuesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'setupKey': 'False',
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (kDebugMode) {
        print('Get setup values successful! responseData: $responseData');
      }
      if (responseData['Status'] == 'Success') {
        if (responseData['SetupValue'] != null &&
            responseData['SetupValue'] is List) {
          final List<dynamic> setupList = responseData['SetupValue'];
          final setupData =
              setupList.map((data) => SetupValues.fromJson(data)).toList();

          // Save the fetched menu data to the database
          for (var setup in setupData) {
            await DatabaseHelper().insertSetupValueData(setup);
          }

          return setupData;
        } else {
          if (kDebugMode) {
            print('SetupValue data is null or not a list');
          }
          return await getSetupValuesDataFromDB();
        }
      } else {
        if (kDebugMode) {
          print('SetupValue Status is not Success');
        }
        return await getSetupValuesDataFromDB();
      }
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry();
    } else {
      return await getSetupValuesDataFromDB();
    }
  }

  Future<List<SetupValues>> refreshAndRetry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await setupValues(newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<List<SetupValues>> getSetupValuesDataFromDB() async {
    return await DatabaseHelper().getSetupValuesDataFromDB();
  }
}

class TravelPlanService {
  Future<PlanResponse> fetchTravelPlans(int executiveId, String token) async {
    final response = await http.post(
      Uri.parse(travelPlanUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'ExecutiveId': executiveId,
      }),
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return PlanResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(executiveId);
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<PlanResponse> refreshAndRetry(int executiveId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchTravelPlans(executiveId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class VisitDetailsService {
  Future<VisitDetailsResponse> visitDetails(
      int customerId, int visitId, String token) async {
    final body = jsonEncode(<String, dynamic>{
      'CustomerId': customerId,
      'VisitId': visitId,
    });
    final response = await http.post(
      Uri.parse(visitDetailsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
      print('Request body: ${response.request?.url}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return VisitDetailsResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(customerId, visitId);
    } else {
      throw Exception('Failed to load visit details');
    }
  }

  Future<VisitDetailsResponse> refreshAndRetry(
      int customerId, int visitId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await visitDetails(customerId, visitId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class GetVisitDsrService {
  Future<GetVisitDsrResponse> getVisitDsr(
      int executiveId,
      int customerId,
      String customerType,
      String upHierarchy,
      String downHierarchy,
      String token) async {
    final response = await http.post(
      Uri.parse(getDsrEntryUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'downhierarchy': downHierarchy,
        'CustomerType': customerType,
        'Uphierarchy': upHierarchy,
        'Executiveid': executiveId,
        'Customerid': customerId,
      }),
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return GetVisitDsrResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryVisitDsr(
          executiveId, customerId, customerType, upHierarchy, downHierarchy);
    } else {
      throw Exception('Failed to load visit dsr');
    }
  }

  Future<GetVisitDsrResponse> refreshAndRetryVisitDsr(
      int executiveId,
      int customerId,
      String customerType,
      String upHierarchy,
      String downHierarchy) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await getVisitDsr(executiveId, customerId, customerType,
            upHierarchy, downHierarchy, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<FetchTitlesResponse> fetchTitles(int selectedIndex, int executiveId,
      int seriesId, int classLevel, String isbn, String token) async {
    final String body;
    if (selectedIndex == 1) {
      body = jsonEncode(<String, dynamic>{
        'BookISBN': isbn,
        'ExecutiveId': executiveId,
      });
    } else {
      body = jsonEncode(<String, dynamic>{
        'ClassLevel': classLevel,
        'SeriesId': seriesId,
        'ExecutiveId': executiveId,
      });
    }
    final response = await http.post(
      Uri.parse(fetchTitlesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return FetchTitlesResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryFetchTitles(
          selectedIndex, executiveId, seriesId, classLevel, isbn);
    } else {
      throw Exception('Failed to load fetch titles');
    }
  }

  Future<FetchTitlesResponse> refreshAndRetryFetchTitles(int selectedIndex,
      int executiveId, int seriesId, int classLevel, String isbn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchTitles(
            selectedIndex, executiveId, seriesId, classLevel, isbn, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<SamplingDetailsResponse> samplingDetails(
      int customerId,
      String requestType,
      int profileId,
      String customerType,
      int executiveId,
      int seriesId,
      int classLevelId,
      int titleId,
      String token) async {
    final String body = jsonEncode(<String, dynamic>{
      'CustomerId': customerId,
      'RequestType': requestType,
      'ProfileId': profileId,
      'CustomerType': customerType,
      'ExecutiveId': executiveId,
      'SeriesId': seriesId,
      'ClassLavelId': classLevelId,
      'TitleId': titleId,
    });
    final response = await http.post(
      Uri.parse(samplingDetailsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return SamplingDetailsResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetrySamplingDetails(
        customerId,
        requestType,
        profileId,
        customerType,
        executiveId,
        seriesId,
        classLevelId,
        titleId,
      );
    } else {
      throw Exception('Failed to load fetch titles');
    }
  }

  Future<SamplingDetailsResponse> refreshAndRetrySamplingDetails(
      int customerId,
      String requestType,
      int profileId,
      String customerType,
      int executiveId,
      int seriesId,
      int classLevelId,
      int titleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await samplingDetails(
            customerId,
            requestType,
            profileId,
            customerType,
            executiveId,
            seriesId,
            classLevelId,
            titleId,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<ShipToResponse> getShipTo(int customerId, int customerContactId,
      String sampleGiven, int executiveId, String token) async {
    final String body = jsonEncode(<String, dynamic>{
      'CustomerId': customerId,
      'CustomerContactId': customerContactId,
      'SampleGiven': sampleGiven,
      'ExecutiveId': executiveId,
    });
    final response = await http.post(
      Uri.parse(shipToUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ShipToResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryShipTo(
          customerId, customerContactId, sampleGiven, executiveId);
    } else {
      throw Exception('Failed to load fetch titles');
    }
  }

  Future<ShipToResponse> refreshAndRetryShipTo(int customerId,
      int customerContactId, String sampleGiven, int executiveId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await getShipTo(
            customerId, customerContactId, sampleGiven, executiveId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class FollowupActionExecutiveService {
  Future<FollowupActionExecutiveResponse> getFollowupActionExecutives(
      int executiveDepartmentId, String token) async {
    final response = await http.post(
      Uri.parse(followupActionExecutiveUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'ExecutiveDepartmentId': executiveDepartmentId,
      }),
    );

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return FollowupActionExecutiveResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(executiveDepartmentId);
    } else {
      throw Exception('Failed to load followup action executives');
    }
  }

  Future<FollowupActionExecutiveResponse> refreshAndRetry(
      int executiveDepartmentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await getFollowupActionExecutives(
            executiveDepartmentId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class VisitEntryService {
  Future<EntryResponse> visitEntry(
      int executiveId,
      String customerType,
      int customerId,
      int loggedInExecutiveId,
      String addressEntry,
      String loggedInExecutiveProfileCode,
      double longEntry,
      double latEntry,
      int academicSessionId,
      String visitFeedBack,
      String visitDate,
      int visitPurpose,
      int customerContact,
      String jointVisitWith,
      String uploadedDocumentXML,
      String otherVisitPurpose,
      String requestRemarks,
      String shippingInstructions,
      String shipmentMode,
      double totalPrice,
      int totalQty,
      int enteredBy,
      String followUpActionXML,
      String visitDetailsXMLForSampleGiven,
      String webEntry,
      String mailBody,
      String mailContentType,
      bool sendThankYouMail,
      String competingDataXML,
      String visitDetailsXMLForToBeDispatched,
      String token) async {
    final String body = jsonEncode(<String, dynamic>{
      'ExecutiveId': executiveId,
      'CustomerType': customerType,
      'Customerid': customerId,
      'LoggedInExecutiveid': loggedInExecutiveId,
      'addressEntry': addressEntry,
      'LoggedInExecutiveProfileCode': loggedInExecutiveProfileCode,
      if (longEntry > 0) 'LongEntry': longEntry,
      if (latEntry > 0) 'LatEntry': latEntry,
      'AcademicSessionId': academicSessionId,
      'VisitFeedBack': visitFeedBack,
      'VisitDate': visitDate,
      'VisitPurpose': visitPurpose,
      'CustomerContact': customerContact,
      'JointVisitWith': jointVisitWith,
      if (uploadedDocumentXML.isNotEmpty)
        'UploadedDocumentXML': uploadedDocumentXML,
      if (otherVisitPurpose.isNotEmpty) 'OtherVisitPurpose': otherVisitPurpose,
      if (requestRemarks.isNotEmpty) 'RequestRemarks': requestRemarks,
      if (shippingInstructions.isNotEmpty)
        'ShippingInstructions': shippingInstructions,
      if (shipmentMode.isNotEmpty) 'ShipmentMode': shipmentMode,
      if (totalPrice > 0) 'TotalPrice': totalPrice,
      if (totalQty > 0) 'TotalQty': totalQty,
      if (enteredBy > 0) 'EnteredBy': enteredBy,
      if (followUpActionXML.isNotEmpty) 'FollowUpActionXML': followUpActionXML,
      if (visitDetailsXMLForSampleGiven.isNotEmpty)
        'VisitDetailsXMLforSampleGiven': visitDetailsXMLForSampleGiven,
      'WebEntry': webEntry,
      if (mailBody.isNotEmpty) 'MailBody': mailBody,
      if (mailContentType.isNotEmpty) 'MailContentType': mailContentType,
      'SendThankyouMail': sendThankYouMail,
      if (competingDataXML.isNotEmpty) 'CompetingDataXML': competingDataXML,
      if (visitDetailsXMLForToBeDispatched.isNotEmpty)
        'VisitDetailsXMLforToBeDispatched': visitDetailsXMLForToBeDispatched,
    });
    if (kDebugMode) {
      print("Request body : $body");
    }
    final response = await http.post(
      Uri.parse(visitEntryUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Request URL: ${response.request?.url}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return EntryResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(
          executiveId,
          customerType,
          customerId,
          loggedInExecutiveId,
          addressEntry,
          loggedInExecutiveProfileCode,
          longEntry,
          latEntry,
          academicSessionId,
          visitFeedBack,
          visitDate,
          visitPurpose,
          customerContact,
          jointVisitWith,
          uploadedDocumentXML,
          otherVisitPurpose,
          requestRemarks,
          shippingInstructions,
          shipmentMode,
          totalPrice,
          totalQty,
          enteredBy,
          followUpActionXML,
          visitDetailsXMLForSampleGiven,
          webEntry,
          mailBody,
          mailContentType,
          sendThankYouMail,
          competingDataXML,
          visitDetailsXMLForToBeDispatched);
    } else {
      throw Exception('Failed to load followup action executives');
    }
  }

  Future<EntryResponse> refreshAndRetry(
      int executiveId,
      String customerType,
      int customerId,
      int loggedInExecutiveId,
      String addressEntry,
      String loggedInExecutiveProfileCode,
      double longEntry,
      double latEntry,
      int academicSessionId,
      String visitFeedBack,
      String visitDate,
      int visitPurpose,
      int customerContact,
      String jointVisitWith,
      String uploadedDocumentXML,
      String otherVisitPurpose,
      String requestRemarks,
      String shippingInstructions,
      String shipmentMode,
      double totalPrice,
      int totalQty,
      int enteredBy,
      String followUpActionXML,
      String visitDetailsXMLForSampleGiven,
      String webEntry,
      String mailBody,
      String mailContentType,
      bool sendThankYouMail,
      String competingDataXML,
      String visitDetailsXMLForToBeDispatched) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await visitEntry(
            executiveId,
            customerType,
            customerId,
            loggedInExecutiveId,
            addressEntry,
            loggedInExecutiveProfileCode,
            longEntry,
            latEntry,
            academicSessionId,
            visitFeedBack,
            visitDate,
            visitPurpose,
            customerContact,
            jointVisitWith,
            uploadedDocumentXML,
            otherVisitPurpose,
            requestRemarks,
            shippingInstructions,
            shipmentMode,
            totalPrice,
            totalQty,
            enteredBy,
            followUpActionXML,
            visitDetailsXMLForSampleGiven,
            webEntry,
            mailBody,
            mailContentType,
            sendThankYouMail,
            competingDataXML,
            visitDetailsXMLForToBeDispatched,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class GeographyService {
  Future<GeographyResponse> fetchGeographyData(
      String cityAccess, int executiveId, String token) async {
    final response = await http.post(
      Uri.parse(geographyUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'CityAccess': cityAccess,
        'ExecutiveId': executiveId,
      }),
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final geographyResponse = GeographyResponse.fromJson(jsonResponse);
      // Create an instance of DatabaseHelper
      DatabaseHelper dbHelper = DatabaseHelper();

      // Insert each Geography data into the database
      for (var data in geographyResponse.geographyList) {
        await dbHelper.insertGeographyData(data);
      }

      return geographyResponse;
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(cityAccess, executiveId);
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<GeographyResponse> refreshAndRetry(
      String cityAccess, int executiveId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchGeographyData(cityAccess, executiveId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class CustomerEntryMasterService {
  Future<CustomerEntryMasterResponse> fetchCustomerEntryMaster(
      String downHierarchy, String token) async {
    final body = jsonEncode(<String, dynamic>{
      'DownHierarchy': downHierarchy,
    });
    final response = await http.post(
      Uri.parse(customerEntryMasterUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('URL: ${response.request?.url}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return CustomerEntryMasterResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(downHierarchy);
    } else {
      // Print the status code and response body for debugging
      if (kDebugMode) {
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
      throw Exception('Failed to load plans');
    }
  }

  Future<CustomerEntryMasterResponse> refreshAndRetry(
      String downHierarchy) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchCustomerEntryMaster(downHierarchy, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class CustomerSamplingApprovalListService {
  Future<ApprovalListResponse> fetchCustomerSamplingApprovalList(
      String type, int executiveId, String listFor, String token) async {
    final body = jsonEncode(<String, dynamic>{
      'ExecutiveId': executiveId,
      'ListFor': listFor,
    });

    final response = await http.post(
      Uri.parse(type == customerSampleApproval
          ? customerSamplingApprovalListUrl
          : selfStockApprovalListUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('type: $type');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request: ${response.request?.url}');
      print('Request body: $body');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ApprovalListResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(type, executiveId, listFor);
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<ApprovalListResponse> refreshAndRetry(
      String type, int executiveId, String listFor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchCustomerSamplingApprovalList(
            type, executiveId, listFor, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class ApprovalDetailsService {
  Future<ApprovalDetailsResponse> fetchApprovalDetails(
      String type,
      int customerId,
      String customerType,
      int requestId,
      String module,
      String token) async {
    final bodyCustomerSampleApproval = jsonEncode(<String, dynamic>{
      'CustomerId': customerId,
      'CustomerType': customerType,
      'RequestId': requestId,
      'Module': module,
    });
    final bodySelfStockRequest = jsonEncode(<String, dynamic>{
      'RequestId': requestId,
      'Module': module,
    });
    final body = (type == customerSampleApproval)
        ? bodyCustomerSampleApproval
        : bodySelfStockRequest;
    final response = await http.post(
      Uri.parse(type == customerSampleApproval
          ? customerSamplingApprovalDetailsUrl
          : selfStockApprovalDetailsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Request body: $body');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ApprovalDetailsResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(
          type, customerId, customerType, requestId, module);
    } else {
      throw Exception('Failed to get fetchCustomerSamplingApprovalDetails');
    }
  }

  Future<ApprovalDetailsResponse> refreshAndRetry(String type, int customerId,
      String customerType, int requestId, String module) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchApprovalDetails(
            type, customerId, customerType, requestId, module, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class SubmitRequestApprovalService {
  Future<SubmitRequestApprovalResponse> submitCustomerSamplingRequestApproved(
      String type,
      bool isBulkApproval,
      String approvalFor,
      String executiveProfile,
      String loggedInExecutiveId,
      String enteredBy,
      String requestId,
      String approvedBooksAndQtyXML,
      String approvalRemarks,
      String token) async {
    final body = isBulkApproval
        ? jsonEncode(<String, dynamic>{
            'ApprovalFor': approvalFor,
            'ExecutiveProfile': executiveProfile,
            'LoggedInExecutiveId': loggedInExecutiveId,
            'EnteredBy': enteredBy,
            'RequestIds': requestId,
            'ApporvalRemarks': approvalRemarks,
          })
        : jsonEncode(<String, dynamic>{
            'ApprovalFor': approvalFor,
            'ExecutiveProfile': executiveProfile,
            'LoggedInExecutiveId': loggedInExecutiveId,
            'EnteredBy': enteredBy,
            'RequestIds': requestId,
            'ApprovedBooksAndQtyXML': approvedBooksAndQtyXML,
            'ApporvalRemarks': approvalRemarks,
          });

    final url = isBulkApproval
        ? customerSamplingRequestBulkApprovalSubmitUrl
        : customerSamplingRequestApprovalSubmitUrl;
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print(' url: $url');
      print(' body: $body');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Request: success');
      }
      final jsonResponse = json.decode(response.body);
      return SubmitRequestApprovalResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      if (kDebugMode) {
        print('Request: 401 going to take new token');
      }
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetrySamplingRequestApprove(
          type,
          isBulkApproval,
          approvalFor,
          executiveProfile,
          loggedInExecutiveId,
          enteredBy,
          requestId,
          approvedBooksAndQtyXML,
          approvalRemarks);
    } else {
      throw Exception('Failed to submitCustomerSamplingRequestApproved');
    }
  }

  Future<SubmitRequestApprovalResponse> refreshAndRetrySamplingRequestApprove(
      String type,
      bool isBulkApproval,
      String approvalFor,
      String executiveProfile,
      String loggedInExecutiveId,
      String enteredBy,
      String requestId,
      String approvedBooksAndQtyXML,
      String approvalRemarks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');
      if (kDebugMode) {
        print('re request newToken : $newToken');
      }
      if (newToken != null && newToken.isNotEmpty) {
        if (kDebugMode) {
          print('re request again with new token');
        }
        return await submitCustomerSamplingRequestApproved(
            type,
            isBulkApproval,
            approvalFor,
            executiveProfile,
            loggedInExecutiveId,
            enteredBy,
            requestId,
            approvedBooksAndQtyXML,
            approvalRemarks,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  submitSelfStockRequestApproved(
      String type,
      bool isBulkApproval,
      String requestFor,
      String profileCode,
      String loggedInExecutiveId,
      String enteredBy,
      String requestId,
      String selfStockDetailsXml,
      String remarks,
      String token) async {
    final body = (isBulkApproval)
        ? jsonEncode(<String, dynamic>{
            'RequestFor': requestFor,
            'ProfileCode': profileCode,
            'LoggedInExecutiveId': loggedInExecutiveId,
            'EnteredBy': enteredBy,
            'SelfStockRequestIds': requestId,
            'Remarks': remarks,
          })
        : jsonEncode(<String, dynamic>{
            'RequestFor': requestFor,
            'ProfileCode': profileCode,
            'LoggedInExecutiveId': loggedInExecutiveId,
            'EnteredBy': enteredBy,
            'SelfStockRequestIds': requestId,
            'SelfStockDetailsxml': selfStockDetailsXml,
            'Remarks': remarks,
          });

    final url = isBulkApproval
        ? selfStockBulkApprovalSubmitUrl
        : selfStockApprovalSubmitUrl;
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print(' url: $url');
      print(' body: $body');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Request: success');
      }
      final jsonResponse = json.decode(response.body);
      return SubmitRequestApprovalResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      if (kDebugMode) {
        print('Request: 401 going to take new token');
      }
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetrySelfStockApprove(
          type,
          isBulkApproval,
          requestFor,
          profileCode,
          loggedInExecutiveId,
          enteredBy,
          requestId,
          selfStockDetailsXml,
          remarks);
    } else {
      throw Exception('Failed to submitCustomerSamplingRequestApproved');
    }
  }

  Future<SubmitRequestApprovalResponse> refreshAndRetrySelfStockApprove(
      String type,
      bool isBulkApproval,
      String requestFor,
      String profileCode,
      String loggedInExecutiveId,
      String enteredBy,
      String requestId,
      String selfStockDetailsXml,
      String remarks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');
      if (kDebugMode) {
        print('re request newToken : $newToken');
      }
      if (newToken != null && newToken.isNotEmpty) {
        if (kDebugMode) {
          print('re request again with new token');
        }
        return await submitSelfStockRequestApproved(
            type,
            isBulkApproval,
            requestFor,
            profileCode,
            loggedInExecutiveId,
            enteredBy,
            requestId,
            selfStockDetailsXml,
            remarks,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class CreateNewCustomerService {
  Future<EntryResponse> createNewCustomer(
      String customerType,
      String customerName,
      String refCode,
      String emailId,
      String mobile,
      String address,
      int cityId,
      int pinCode,
      String keyCustomer,
      String customerStatus,
      String xmlCustomerCategoryId,
      String xmlAccountTableExecutiveId,
      String comment,
      int enteredBy,
      String firstName,
      String lastName,
      String contactEmailId,
      String contactMobile,
      String contactStatus,
      String primaryContact,
      String resAddress,
      int resCity,
      int resPinCode,
      int salutationId,
      int contactDesignationId,
      double latEntry,
      double longEntry,
      String token) async {
    final body = jsonEncode(<String, dynamic>{
      'CustomerType': customerType,
      'CustomerName': customerName,
      'RefCode': refCode,
      'EmailId': emailId,
      'Mobile': mobile,
      'Address': address,
      'CityId': cityId,
      'Pincode': pinCode,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'xmlCustomerCategoryId': xmlCustomerCategoryId,
      'xmlAccountTableExecutiveId': xmlAccountTableExecutiveId,
      'Comment': comment,
      'EnteredBy': enteredBy,
      'FirstName': firstName,
      'LastName': lastName,
      'ContactEmailId': contactEmailId,
      'ContactMobile': contactMobile,
      'ContactStatus': contactStatus,
      'PrimaryContact': primaryContact,
      'resAddress': resAddress,
      'resCity': resCity,
      'resPincode': resPinCode,
      'SalutationId': salutationId,
      'ContactDesignationId': contactDesignationId,
      'latEntry': latEntry,
      'longEntry': longEntry,
    });

    final response = await http.post(
      Uri.parse(customerCreationUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print("Request Body: $body");

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return EntryResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(
        customerType,
        customerName,
        refCode,
        emailId,
        mobile,
        address,
        cityId,
        pinCode,
        keyCustomer,
        customerStatus,
        xmlCustomerCategoryId,
        xmlAccountTableExecutiveId,
        comment,
        enteredBy,
        firstName,
        lastName,
        contactEmailId,
        contactMobile,
        contactStatus,
        primaryContact,
        resAddress,
        resCity,
        resPinCode,
        salutationId,
        contactDesignationId,
        latEntry,
        longEntry,
      );
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<EntryResponse> refreshAndRetry(
      String customerType,
      String customerName,
      String refCode,
      String emailId,
      String mobile,
      String address,
      int cityId,
      int pinCode,
      String keyCustomer,
      String customerStatus,
      String xmlCustomerCategoryId,
      String xmlAccountTableExecutiveId,
      String comment,
      int enteredBy,
      String firstName,
      String lastName,
      String contactEmailId,
      String contactMobile,
      String contactStatus,
      String primaryContact,
      String resAddress,
      int resCity,
      int resPinCode,
      int salutationId,
      int contactDesignationId,
      double latEntry,
      double longEntry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await createNewCustomer(
            customerType,
            customerName,
            refCode,
            emailId,
            mobile,
            address,
            cityId,
            pinCode,
            keyCustomer,
            customerStatus,
            xmlCustomerCategoryId,
            xmlAccountTableExecutiveId,
            comment,
            enteredBy,
            firstName,
            lastName,
            contactEmailId,
            contactMobile,
            contactStatus,
            primaryContact,
            resAddress,
            resCity,
            resPinCode,
            salutationId,
            contactDesignationId,
            latEntry,
            longEntry,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }

  Future<EntryResponse> createNewCustomerSchool(
      String customerType,
      String customerName,
      String refCode,
      String emailId,
      String mobile,
      String address,
      int cityId,
      int pinCode,
      String keyCustomer,
      String customerStatus,
      String xmlCustomerCategoryId,
      String xmlAccountTableExecutiveId,
      String comment,
      int enteredBy,
      String firstName,
      String lastName,
      String contactEmailId,
      String contactMobile,
      String contactStatus,
      String primaryContact,
      String resAddress,
      int resCity,
      int resPinCode,
      int salutationId,
      int contactDesignationId,
      double latEntry,
      double longEntry,
      String ranking,
      int boardId,
      int chainSchoolId,
      int endClassId,
      int startClassId,
      String mediumInstruction,
      int samplingMonth,
      int decisionMonth,
      String purchaseMode,
      String xmlSubjectClassDM,
      String xmlClassName,
      int dataSourceId,
      String token) async {
    final body = jsonEncode(<String, dynamic>{
      'CustomerType': customerType,
      'CustomerName': customerName,
      'RefCode': refCode,
      'EmailId': emailId,
      'Mobile': mobile,
      'Address': address,
      'CityId': cityId,
      'Pincode': pinCode,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'xmlCustomerCategoryId': xmlCustomerCategoryId,
      'xmlAccountTableExecutiveId': xmlAccountTableExecutiveId,
      'Comment': comment,
      'EnteredBy': enteredBy,
      'FirstName': firstName,
      'LastName': lastName,
      'ContactEmailId': contactEmailId,
      'ContactMobile': contactMobile,
      'ContactStatus': contactStatus,
      'PrimaryContact': primaryContact,
      'resAddress': resAddress,
      'resCity': resCity,
      'resPincode': resPinCode,
      'SalutationId': salutationId,
      'ContactDesignationId': contactDesignationId,
      'latEntry': latEntry,
      'longEntry': longEntry,
      'Ranking': ranking,
      'BoardId': boardId,
      'ChainSchoolId': chainSchoolId,
      'EndClassId': endClassId,
      'StartClassId': startClassId,
      'MediumInstruction': mediumInstruction,
      'SamplingMonth': samplingMonth,
      'DecisionMonth': decisionMonth,
      'PurchaseMode': purchaseMode,
      'xmlSubjectClassDM': xmlSubjectClassDM,
      'xmlClassName': xmlClassName,
      'DataSourceId': dataSourceId,
    });

    final response = await http.post(
      Uri.parse(customerCreationUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print("Request Body: $body");

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Request URL body: ${response.request?.url}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return EntryResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetrySchool(
        customerType,
        customerName,
        refCode,
        emailId,
        mobile,
        address,
        cityId,
        pinCode,
        keyCustomer,
        customerStatus,
        xmlCustomerCategoryId,
        xmlAccountTableExecutiveId,
        comment,
        enteredBy,
        firstName,
        lastName,
        contactEmailId,
        contactMobile,
        contactStatus,
        primaryContact,
        resAddress,
        resCity,
        resPinCode,
        salutationId,
        contactDesignationId,
        latEntry,
        longEntry,
        ranking,
        boardId,
        chainSchoolId,
        endClassId,
        startClassId,
        mediumInstruction,
        samplingMonth,
        decisionMonth,
        purchaseMode,
        xmlSubjectClassDM,
        xmlClassName,
        dataSourceId,
      );
    } else {
      throw Exception('Failed to load refreshAndRetrySchool');
    }
  }

  Future<EntryResponse> refreshAndRetrySchool(
    String customerType,
    String customerName,
    String refCode,
    String emailId,
    String mobile,
    String address,
    int cityId,
    int pinCode,
    String keyCustomer,
    String customerStatus,
    String xmlCustomerCategoryId,
    String xmlAccountTableExecutiveId,
    String comment,
    int enteredBy,
    String firstName,
    String lastName,
    String contactEmailId,
    String contactMobile,
    String contactStatus,
    String primaryContact,
    String resAddress,
    int resCity,
    int resPinCode,
    int salutationId,
    int contactDesignationId,
    double latEntry,
    double longEntry,
    String ranking,
    int boardId,
    int chainSchoolId,
    int endClassId,
    int startClassId,
    String mediumInstruction,
    int samplingMonth,
    int decisionMonth,
    String purchaseMode,
    String xmlSubjectClassDM,
    String xmlClassName,
    int dataSourceId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await createNewCustomerSchool(
            customerType,
            customerName,
            refCode,
            emailId,
            mobile,
            address,
            cityId,
            pinCode,
            keyCustomer,
            customerStatus,
            xmlCustomerCategoryId,
            xmlAccountTableExecutiveId,
            comment,
            enteredBy,
            firstName,
            lastName,
            contactEmailId,
            contactMobile,
            contactStatus,
            primaryContact,
            resAddress,
            resCity,
            resPinCode,
            salutationId,
            contactDesignationId,
            latEntry,
            longEntry,
            ranking,
            boardId,
            chainSchoolId,
            endClassId,
            startClassId,
            mediumInstruction,
            samplingMonth,
            decisionMonth,
            purchaseMode,
            xmlSubjectClassDM,
            xmlClassName,
            dataSourceId,
            newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class CheckInCheckOutService {
  Future<CheckInCheckOutResponse> checkInCheckOut(
      int executiveId,
      int enteredBy,
      String date,
      String type,
      String dateTime,
      String longEntry,
      String latEntry,
      String token) async {
    String body = jsonEncode(<String, dynamic>{
      'ExecutiveId': executiveId,
      'Date': date,
      'Type': type,
      'DateTime': dateTime,
      'LongEntry': longEntry,
      'LatEntry': latEntry,
      'EnteredBy': enteredBy,
    });
    if (kDebugMode) {
      print('Request body: $body');
    }
    final response = await http.post(Uri.parse(checkInCheckOutUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body);
    if (kDebugMode) {
      print('Request URL: ${response.request?.url}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return CheckInCheckOutResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(
          executiveId, enteredBy, date, type, dateTime, longEntry, latEntry);
    } else {
      throw Exception('Failed to check in check out');
    }
  }

  Future<CheckInCheckOutResponse> refreshAndRetry(
      int executiveId,
      int enteredBy,
      String date,
      String type,
      String dateTime,
      String longEntry,
      String latEntry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await checkInCheckOut(executiveId, enteredBy, date, type,
            dateTime, longEntry, latEntry, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class SeriesAndClassLevelListService {
  Future<SeriesAndClassLevelListResponse> getSeriesAndClassLevelList(
      int executiveId, int profileId, String token) async {
    final String body = jsonEncode(<String, dynamic>{
      'ProfileId': profileId,
      'ExecutiveId': executiveId,
    });
    if (kDebugMode) {
      print("Request body : $body");
    }
    final response = await http.post(
      Uri.parse(getSeriesAndClassLevelListUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Request URL: ${response.request?.url}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return SeriesAndClassLevelListResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(executiveId, profileId);
    } else {
      throw Exception('Failed to load visit dsr');
    }
  }

  Future<SeriesAndClassLevelListResponse> refreshAndRetry(
      int executiveId, int profileId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await getSeriesAndClassLevelList(
            executiveId, profileId, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}

class BooksellerService {
  Future<SearchBooksellerResponse> fetchBooksellerData(int cityId,
      String bookSellerCode, String bookSellerName, String token) async {
    String body = jsonEncode(<String, dynamic>{
      'CityId': cityId,
      'BookSellerCode': bookSellerCode,
      'BookSellerName': bookSellerName,
    });
    if (kDebugMode) {
      print(body);
    }
    if (kDebugMode) {
      print(Uri.parse(booksellerSearchUrl));
    }
    final response = await http.post(
      Uri.parse(booksellerSearchUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return SearchBooksellerResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(cityId, bookSellerCode, bookSellerName);
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<SearchBooksellerResponse> refreshAndRetry(
      int cityId, String bookSellerCode, String bookSellerName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchBooksellerData(
            cityId, bookSellerCode, bookSellerName, newToken);
      } else {
        throw Exception('Failed to retrieve new token');
      }
    } else {
      throw Exception(
          'Username or password is not stored in SharedPreferences');
    }
  }
}
