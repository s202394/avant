import 'package:animate_do/animate_do.dart';
import 'package:avant/api/api_service.dart';
import 'package:avant/change_password.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/model/forgot_password_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late SharedPreferences prefs;

  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  final ToastMessage _toastMessage = ToastMessage();

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
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _forgotPasswordLoad() async {
    final String email = _emailController.text.trim();

    if (!_validateInput(email)) return;

    if (!await _checkInternetConnection()) return;

    setState(() => _isLoading = true);

    try {
      await _forgotPassword(email);
      print('GOING TO Change Password Page');
    } catch (e) {
      print('Forgot Password Error $e');
      _toastMessage
          .showToastMessage("An error occurred while forgot password.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInput(String email) {
    if (email.isEmpty) {
      _showErrorMessage("Please enter your email ", _emailFocusNode);
      return false;
    }
    if (!Validator.isValidEmail(email)) {
      _showErrorMessage("Please enter a valid email id.", _emailFocusNode);
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

  Future<void> _forgotPassword(String email) async {
    print('Forgot Password');

    final responseData =
        await LoginService().forgotPassword(email, token ?? "");
    if (responseData.password != null &&
        responseData.password!.userName.isNotEmpty) {
      print(
          'Forgot password successful! Username: ${responseData.password?.userName}');
      if (responseData.password != null) {
        _navigateToChangePasswordPage(responseData.password!);
      }
    } else {
      print('Forgot password error! User ID: ${responseData.password}');
      _toastMessage
          .showToastMessage("There are any issue while forgot your password.");
    }
  }

  void _navigateToChangePasswordPage(Password model) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(password: model)));
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
                      _buildForgotPasswordButton(),
                      const SizedBox(height: 70),
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
                    child: Image(image: AssetImage('images/logo.png'))),
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
        child: _buildTextField(_emailController, _emailFocusNode, "Email Id"),
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

  Widget _buildForgotPasswordButton() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _forgotPasswordLoad();
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
            child: Text(
              "Forgot Password",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
