import 'package:flutter/material.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế
import 'package:logger/logger.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  String? _errorMessage;

  // Hàm đăng nhập
  void _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Email và mật khẩu không thể để trống.";
      });
      return;
    }

    await _authService.signInWithEmail(email, password);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng nhập tài khoản")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              
              child: Text("Đăng nhập"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              child: Text("Chưa có tài khoản? Đăng ký ngay."),
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
              child: Text("Quên mật khẩu?"),
            ),
          ],
        ),
      ),
    );
  }
}
