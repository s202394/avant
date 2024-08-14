import 'package:animate_do/animate_do.dart';
import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/dialog/custom_alert_dialog.dart';
import 'package:avant/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late SharedPreferences prefs;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailMobileFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final ToastMessage _toastMessage = ToastMessage();

  LoginResponse? loginResponse;

  bool _isLoading = false;
  String? token = "";

  String tokenUsername = "imi@gmail.com";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    prefs = await SharedPreferences.getInstance();
    _emailController.text = 'Gaurav@gmail.com';
    _passwordController.text = 'admin@123';
  }

  Future<void> _saveData(
      String emailOrPhone, String password, bool value) async {
    prefs.setString('token_username', tokenUsername);
    prefs.setString('username', emailOrPhone);
    prefs.setString('password', password);
    prefs.setBool('is_already_login', value);

    _navigateToHomePage();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailMobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String emailOrPhone = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (!_validateInput(emailOrPhone, password)) return;

    if (!await _checkInternetConnection()) return;

    setState(() => _isLoading = true);

    try {
      await _getToken(tokenUsername, password);
      print('Get token successful! token: $token');
      if ((token ?? "").isNotEmpty) {
        print('GOING TO LOGIN');
        await _loginUser(emailOrPhone, password);
        print('GOING TO Home Page');
      } else {
        print('Token Error');
        _toastMessage.showToastMessage("An error occurred while logging in.");
      }
    } catch (e) {
      print('Token Error $e');
      _toastMessage.showToastMessage("An error occurred while logging in.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInput(String emailOrPhone, String password) {
    if (emailOrPhone.isEmpty) {
      _showErrorMessage(
          "Please enter your email/phone number", _emailMobileFocusNode);
      return false;
    }

    if (!Validator.isValidEmail(emailOrPhone) &&
        !Validator.isValidMobile(emailOrPhone)) {
      _showErrorMessage(
          "Please enter a valid email or phone number.", _emailMobileFocusNode);
      return false;
    }

    if (password.isEmpty) {
      _showErrorMessage("Please enter your password", _passwordFocusNode);
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

  Future<void> _getToken(String emailOrPhone, String password) async {
    print('Getting Token $emailOrPhone $password');
    await TokenService().token(emailOrPhone, password);
    token = prefs.getString('token');
    print('Get token successful! Token: $token');
  }

  Future<void> _loginUser(String emailOrPhone, String password) async {
    final String ipAddress = await getIpAddress();
    final String deviceInfo = await getDeviceInfo();
    final String deviceId = await getDeviceId();

    print(
        'Login details ipAddress : $ipAddress , deviceInfo : $deviceInfo , deviceId : $deviceId');

    final responseData = await LoginService().login(
        emailOrPhone, password, ipAddress, deviceId, deviceInfo, token ?? "");
    final loginResponse = await LoginResponse.fromJson(responseData);
    if (loginResponse!.executiveData.loginBlocked == 'N') {
      final String? userId = prefs.getString('userId');

      print('Login successful! User ID: $userId');
      _saveData(emailOrPhone, password, true);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SingleAlertDialog(
            title: "Alert",
            content: "You are not allowed to login. Please contact to admin.",
            onOk: () {
              // Handle ok action
              Navigator.of(context).pop();
            },
          );
        },
      );
    }
  }

  void _navigateToHomePage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
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
                      _buildLoginButton(),
                      const SizedBox(height: 70),
                      _buildForgotPasswordText(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                child:
                    Center(child: Image(image: AssetImage('images/logo.png'))),
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
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(244, 155, 32, 1)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(244, 155, 32, .2),
              blurRadius: 20.0,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: <Widget>[
            _buildTextField(_emailController, _emailMobileFocusNode,
                "Email or Phone number",
                applyDecoration: true),
            _buildTextField(_passwordController, _passwordFocusNode, "Password",
                obscureText: true),
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
          ? BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: const Color.fromRGBO(244, 155, 32, 1))),
            )
          : null,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _login();
      },
      child: FadeInUp(
        duration: const Duration(milliseconds: 1900),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                const Color.fromRGBO(244, 155, 32, 1),
                const Color.fromRGBO(244, 155, 32, .6)
              ],
            ),
          ),
          child: Center(
            child: const Text(
              "Login",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordText() {
    return FadeInUp(
      duration: const Duration(milliseconds: 2000),
      child: const Text(
        "Forgot Password?",
        style: TextStyle(color: Color.fromRGBO(244, 155, 32, 1)),
      ),
    );
  }
}
