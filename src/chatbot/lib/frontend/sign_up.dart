import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế
import '../backend/config/logger.dart';
import '../backend/db/user.dart' as u;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Controller for confirm password
  final AuthService _authService = AuthService();

  String? _errorMessage;

  // Hàm đăng ký
  void _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = "Email, mật khẩu, và xác nhận mật khẩu không thể để trống.";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Mật khẩu và xác nhận mật khẩu không khớp.";
      });
      return;
    }

    try {
      User? curUser = await _authService.signUpWithEmail(email, password);
      // Extract the username from the email
      String username = email.split('@')[0];

      // Create a User instance
      final newUser = u.User(
        id: curUser?.uid,
        name: username,
        plan: 'free',
        token: 100,
      );

      // Save the user to Firestore using the saveToFirestore method
      await newUser.saveToFirestore();

      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Convert error to a string for display
      });
      MyLogger.d("Error during sign-up: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple,
                Colors.pink,
                Colors.red,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              SizedBox(
                child: Image.asset('images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to ChatGPT',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: screenWidth * 0.6,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          FontAwesomeIcons.envelope,
                          size: 17,
                        ),
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          FontAwesomeIcons.lock,
                          size: 17,
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          FontAwesomeIcons.lock,
                          size: 17,
                        ),
                        hintText: 'Confirm Password',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _signUp, // Sign Up method when button is pressed
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.purple,
                              Colors.pink,
                              Colors.red,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signin');
                      },
                      child: const Text("Already have an account? Sign in."),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
