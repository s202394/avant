import 'package:animate_do/animate_do.dart';
import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/login.dart';
import 'package:avant/model/change_password_model.dart';
import 'package:avant/model/forgot_password_model.dart';
import 'package:avant/views/custom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Password password;

  const ChangePasswordScreen({super.key, required this.password});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late SharedPreferences prefs;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final ToastMessage _toastMessage = ToastMessage();

  ChangePasswordModel? changePasswordResponse;

  bool _isLoading = false;
  String? token = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadChangePassword() async {
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (!_validateInput(password, confirmPassword)) return;

    if (!await _checkInternetConnection()) return;

    setState(() => _isLoading = true);

    try {
      await _changePassword(password);
      if (kDebugMode) {
        print('GOING TO Login Page');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Change Password Error $e');
      }
      _toastMessage
          .showToastMessage("An error occurred while change password.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInput(String password, String confirmPassword) {
    if (password.isEmpty) {
      _showErrorMessage("Please enter password.", _passwordFocusNode);
      return false;
    }
    if (confirmPassword.isEmpty) {
      _showErrorMessage(
          "Please enter confirm password.", _confirmPasswordFocusNode);
      return false;
    }
    if (password != confirmPassword) {
      _showErrorMessage(
          "Password didn't matched with confirm password.", _passwordFocusNode);
      return false;
    }
    return true;
  }

  void _showErrorMessage(String message, FocusNode focusNode) {
    _toastMessage.showToastMessage(message);
    FocusScope.of(context).requestFocus(focusNode);
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      _toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  Future<void> _changePassword(String newPassword) async {
    if (kDebugMode) {
      print('Change Password ${widget.password.toJson()}');
    }

    final String ipAddress = await getIpAddress();
    final String deviceInfo = await getDeviceInfo();

    final responseData = await LoginService().changePassword(
        widget.password.id,
        widget.password.password,
        newPassword,
        ipAddress,
        deviceInfo,
        widget.password.id,
        token ?? "");
    if (responseData.changePasswordModel != null) {
      if (responseData.changePasswordModel?.msgText != null &&
          responseData.changePasswordModel?.msgType != null) {
        if (responseData.changePasswordModel?.msgType == 's') {
          if (kDebugMode) {
            print(
                'Forgot password successful! ${responseData.changePasswordModel?.msgText}');
          }
          _toastMessage.showToastMessage(
              responseData.changePasswordModel?.msgText ??
                  'Password changed successfully.');
          _navigateToHomePage();
        } else {
          if (kDebugMode) {
            print(
                'Forgot password unsuccessful! ${responseData.changePasswordModel?.msgText}');
          }
          _toastMessage.showToastMessage(
              responseData.changePasswordModel?.msgText ??
                  'There are any issue while forgot your password.');
        }
      } else {
        if (kDebugMode) {
          print(
              'Forgot password error! ${responseData.changePasswordModel?.msgType} ${responseData.changePasswordModel?.msgText}');
        }
        _toastMessage.showToastMessage(
            "There are any issue while forgot your password.");
      }
    } else {
      if (kDebugMode) {
        print(
            'Forgot password error! ${responseData.changePasswordModel?.msgText}');
      }
      _toastMessage
          .showToastMessage("There are any issue while forgot your password.");
    }
  }

  void _navigateToHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: <Widget>[
                      _buildInputFields(),
                      const SizedBox(height: 30),
                      _buildChangePasswordButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 400,
      child: Stack(
        children: <Widget>[
          _buildAnimatedPositioned('images/light-1.png', 80, 200, 1, left: 30),
          _buildAnimatedPositioned('images/light-2.png', 80, 150, 1.2,
              left: 140),
          _buildAnimatedPositioned('images/clock.png', 80, 150, 1.3,
              top: 40, right: 40),
          Positioned(
            child: FadeInUp(
              duration: const Duration(milliseconds: 1600),
              child: Container(
                margin: const EdgeInsets.only(top: 200),
                child: const Center(
                    child: Image(image: AssetImage('images/dart_logo.png'))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPositioned(
      String imagePath, double width, double height, double durationSeconds,
      {double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: FadeInUp(
        duration: Duration(seconds: durationSeconds.toInt()),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage(imagePath)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return FadeInUp(
      duration: const Duration(milliseconds: 1800),
      child: Container(
        padding: const EdgeInsets.only(left: 5, right: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(244, 155, 32, 1)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(244, 155, 32, .2),
              blurRadius: 20.0,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: <Widget>[
            _buildTextField(_passwordController, _passwordFocusNode, "Password",
                applyDecoration: true),
            _buildTextField(_confirmPasswordController,
                _confirmPasswordFocusNode, "Confirm Password"),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, FocusNode focusNode, String hintText,
      {bool obscureText = false, bool applyDecoration = false}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: applyDecoration
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(244, 155, 32, 1),
                ),
              ),
            )
          : null,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        focusNode: focusNode,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelStyle: const TextStyle(fontSize: 14),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _loadChangePassword();
      },
      child: FadeInUp(
        duration: const Duration(milliseconds: 1900),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(244, 155, 32, 1),
                Color.fromRGBO(244, 155, 32, .6)
              ],
            ),
          ),
          child: const Center(
            child: CustomText("Change Password",
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
