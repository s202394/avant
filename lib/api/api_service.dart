import 'dart:convert';

import 'package:avant/api/api_constants.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/common/constants.dart';
import 'package:avant/model/approval_details_model.dart';
import 'package:avant/model/visit_details_model.dart';
import 'package:avant/model/approval_list_model.dart';
import 'package:avant/model/change_password_model.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/entry_model.dart';
import 'package:avant/model/followup_action_model.dart';
import 'package:avant/model/forgot_password_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/setup_values.dart';
import 'package:avant/model/submit_approval_model.dart';
import 'package:avant/model/travel_plan_model.dart';
import 'package:avant/model/fetch_titles_model.dart';
import 'package:avant/common/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  Future<void> token(String username, String password) async {
    final body = jsonEncode(
        <String, String>{'username': username, 'password': password});
    final response = await http.post(
      Uri.parse(TOKEN_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    print("body:$body");
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Get token successful! responseData: $responseData');
      // Store data in SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['Token']);
    } else {
      print('Get token failure! responseData: ${response.statusCode}');
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
      Uri.parse(LOGIN_URL),
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
      print('login successful! responseData: $responseData');
      if (responseData['Status'] == 'Success') {
        return responseData;
      } else {
        print('login failure! responseData: ${response.statusCode}');
        throw Exception('Failed to log in: ${responseData['Status']}');
      }
    } else {
      print('login failure!! responseData: ${response.statusCode}');
      throw Exception('Failed to log in: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> logout(int userId, String token) async {
    final response = await http.post(
      Uri.parse(LOGOUT_URL),
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
      print('logout successful! responseData: $responseData');
      if (responseData['Status'] == 'Success') {
        return responseData;
      } else {
        print('logout failure! responseData: ${response.statusCode}');
        throw Exception('Failed to log out: ${responseData['Status']}');
      }
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryLogin(userId);
    } else {
      print('logout failure!! responseData: ${response.statusCode}');
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
      Uri.parse(FORGOT_PASSWORD_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request body: ${body}');

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
    String username = TOKEN_USERNAME;
    String password = TOKEN_PASSWORD;

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
      Uri.parse(CHANGE_PASSWORD_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request body: ${body}');

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
    await TokenService().token(TOKEN_USERNAME, TOKEN_PASSWORD);
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
      Uri.parse(MENU_URL),
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
      print('Get menu successful! responseData: $responseData');
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
          print('Menu data is null or not a list');
          return await getMenuDataFromDB();
        }
      } else {
        print('Status is not Success');
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
      Uri.parse(SETUP_VALUES_URL),
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
      print('Get setup values successful! responseData: $responseData');
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
          print('SetupValue data is null or not a list');
          return await getSetupValuesDataFromDB();
        }
      } else {
        print('SetupValue Status is not Success');
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
      Uri.parse(TRAVEL_PLAN_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'ExecutiveId': executiveId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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
      Uri.parse(VISIT_DETAILS_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request body: ${body}');
    print('Request body: ${response.request?.url}');

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
      Uri.parse(GET_DSR_ENTRY_URL),
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

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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

  Future<GetVisitDsrResponse> refreshAndRetryVisitDsr(int executiveId, int customerId,
      String customerType, String upHierarchy, String downHierarchy) async {
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

  Future<FetchTitlesResponse> fetchTitles(
      int seriesId, String classLevel, String isbn, String token) async {
    final body;
    if (isbn.isNotEmpty)
      body = jsonEncode(<String, dynamic>{
        'BookISBN': isbn,
      });
    else if (classLevel.isNotEmpty)
      body = jsonEncode(<String, dynamic>{
        'ClassLevel': classLevel,
      });
    else
      body = jsonEncode(<String, dynamic>{
        'SeriesId': seriesId,
      });

    final response = await http.post(
      Uri.parse(FETCH_TITLES_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request body: ${body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return FetchTitlesResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetryFetchTitles(seriesId, classLevel, isbn);
    } else {
      throw Exception('Failed to load fetch titles');
    }
  }

  Future<FetchTitlesResponse> refreshAndRetryFetchTitles(
      int seriesId, String classLevel, String isbn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await fetchTitles(seriesId, classLevel, isbn, newToken);
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
      Uri.parse(FOLLOWUP_ACTION_EXECUTIVE_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'ExecutiveDepartmentId': executiveDepartmentId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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
      String longEntry,
      String latEntry,
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
      String sendThankYouMail,
      String competingDataXML,
      String visitDetailsXMLForToBeDispatched,
      String token) async {
    final response = await http.post(
      Uri.parse(VISIT_ENTRY_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'ExecutiveId': executiveId,
        'LoggedInExecutiveid': loggedInExecutiveId,
        'CustomerId': customerId,
        'EnteredBy': enteredBy,
        'CustomerContact': customerContact,
        'AcademicSessionId': academicSessionId,
        'LoggedInExecutiveProfileCode': loggedInExecutiveProfileCode,
        'JointVisitWith': jointVisitWith,
        'VisitPurpose': visitPurpose,
        'VisitFeedBack': visitFeedBack,
        'VisitDate': visitDate,
        'addressEntry': addressEntry,
        'LongEntry': longitude,
        'LatEntry': latitude,
        'CustomerType': customerType,
        'TotalQty': totalQty,
        'TotalPrice': totalPrice,
        'Shipping instruct': shippingInstruct,
        'ShipmentMode': shipmentMode,
        'UploadedDocumentXML': uploadedDocumentXML,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return EntryResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(
          executiveId,
          loggedInExecutiveId,
          customerId,
          enteredBy,
          customerContact,
          academicSessionId,
          loggedInExecutiveProfileCode,
          jointVisitWith,
          visitPurpose,
          visitFeedBack,
          visitDate,
          addressEntry,
          longitude,
          latitude,
          customerType,
          totalQty,
          totalPrice,
          shippingInstruct,
          shipmentMode,
          uploadedDocumentXML);
    } else {
      throw Exception('Failed to load followup action executives');
    }
  }

  Future<EntryResponse> refreshAndRetry(
      int executiveId,
      int loggedInExecutiveId,
      int customerId,
      int enteredBy,
      int customerContact,
      int academicSessionId,
      String loggedInExecutiveProfileCode,
      String jointVisitWith,
      int visitPurpose,
      String visitFeedBack,
      String visitDate,
      String addressEntry,
      String longitude,
      String latitude,
      String customerType,
      int totalQty,
      double totalPrice,
      String shippingInstruct,
      String shipmentMode,
      String uploadedDocumentXML) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('token_username') ?? '';
    String password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await TokenService().token(username, password);
      String? newToken = prefs.getString('token');

      if (newToken != null && newToken.isNotEmpty) {
        return await visitEntry(
            executiveId,
            loggedInExecutiveId,
            customerId,
            enteredBy,
            customerContact,
            academicSessionId,
            loggedInExecutiveProfileCode,
            jointVisitWith,
            visitPurpose,
            visitFeedBack,
            visitDate,
            addressEntry,
            longitude,
            latitude,
            customerType,
            totalQty,
            totalPrice,
            shippingInstruct,
            shipmentMode,
            uploadedDocumentXML,
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
      Uri.parse(GEOGRAPHY_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'CityAccess': cityAccess,
        'ExecutiveId': executiveId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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
    final body=jsonEncode(<String, dynamic>{
      'DownHierarchy': downHierarchy,
    });
    final response = await http.post(
      Uri.parse(CUSTOMER_ENTRY_MASTER_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('URL: ${response.request?.url}');
    print('Request body: ${body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return CustomerEntryMasterResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      // Token is invalid or expired, refresh the token and retry
      return await refreshAndRetry(downHierarchy);
    } else {
      // Print the status code and response body for debugging
      print('Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
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
      Uri.parse(type == CUSTOMER_SAMPLE_APPROVAL
          ? CUSTOMER_SAMPLING_APPROVAL_LIST_URL
          : SELF_STOCK_APPROVAL_LIST_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('type: $type');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request: ${response.request?.url}');
    print('Request body: ${body}');

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
    final body = (type == CUSTOMER_SAMPLE_APPROVAL)
        ? bodyCustomerSampleApproval
        : bodySelfStockRequest;
    final response = await http.post(
      Uri.parse(type == CUSTOMER_SAMPLE_APPROVAL
          ? CUSTOMER_SAMPLING_APPROVAL_DETAILS_URL
          : SELF_STOCK_APPROVAL_DETAILS_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Request body: $body');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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
        ? CUSTOMER_SAMPLING_REQUEST_BULK_APPROVAL_SUBMIT_URL
        : CUSTOMER_SAMPLING_REQUEST_APPROVAL_SUBMIT_URL;
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print(' url: ${url}');
    print(' body: ${body}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Request: success');
      final jsonResponse = json.decode(response.body);
      return SubmitRequestApprovalResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      print('Request: 401 going to take new token');
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
      print('re request newToken : $newToken');
      if (newToken != null && newToken.isNotEmpty) {
        print('re request again with new token');
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
        ? SELF_STOCK_BULK_APPROVAL_SUBMIT_URL
        : SELF_STOCK_APPROVAL_SUBMIT_URL;
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print(' url: ${url}');
    print(' body: ${body}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Request: success');
      final jsonResponse = json.decode(response.body);
      return SubmitRequestApprovalResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      print('Request: 401 going to take new token');
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
      print('re request newToken : $newToken');
      if (newToken != null && newToken.isNotEmpty) {
        print('re request again with new token');
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
      String latEntry,
      String longEntry,
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
      Uri.parse(CUSTOMER_CREATION_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print("Request Body: $body");

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

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
      String latEntry,
      String longEntry) async {
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
      String latEntry,
      String longEntry,
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
      Uri.parse(CUSTOMER_CREATION_URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print("Request Body: $body");

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Request URL body: ${response.request?.url}');

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
    String latEntry,
    String longEntry,
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
