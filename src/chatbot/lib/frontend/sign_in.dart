import 'package:flutter/material.dart';
import '../backend/services/auth_service.dart';
import '../backend/config/logger.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;

  // Hàm đăng nhập
  void _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Email và mật khẩu không thể để trống.";
        MyLogger.d("Email và mật khẩu không thể để trống.");
      });
      return;
    }

    try {
      // Authenticate user
      await _authService.signInWithEmail(email, password);

      // Navigate to ChatPage
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Convert error to a string for display
      });
      MyLogger.d("Error during sign-in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập tài khoản")),
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
              onPressed: _signIn,
              
              child: const Text("Đăng nhập"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay."),
            ),
            TextButton(
              onPressed: () async {
                // Gửi email khôi phục mật khẩu
                String email = _emailController.text.trim();
                if (email.isEmpty) {
                  setState(() {
                    _errorMessage = "Email không thể để trống.";
                  });
                  return;
                }
                await _authService.sendPasswordResetEmail(email);
              },
              child: const Text("Quên mật khẩu?"),
            ),
          ],
        ),
      ),
    );
  }
}
