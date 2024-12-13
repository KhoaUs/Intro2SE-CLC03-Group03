import 'package:flutter/material.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế
import '../backend/config/logger.dart';

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
      await _authService.signUpWithEmail(email, password);
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
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Xác nhận mật khẩu"),
              obscureText: true,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text("Đăng ký"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signin');
              },
              child: const Text("Đã có tài khoản? Đăng nhập ngay."),
            ),
          ],
        ),
      ),
    );
  }
}
