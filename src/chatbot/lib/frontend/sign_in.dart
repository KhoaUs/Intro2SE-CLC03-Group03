import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../backend/services/auth_service.dart';
import '../backend/config/logger.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Track the visibility of the password
  bool _isPasswordVisible = false;

  // Track the loading state to prevent multiple requests
  bool _isLoading = false;

  // Sign-in method
  void _signIn() async {
    // Prevent multiple button presses
    if (_isLoading) return;

    setState(() {
      _isLoading = true; // Set loading state
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Check for specific errors
    if (email.isEmpty && password.isEmpty) {
      _showErrorMessage("Email and password cannot be empty.");
      MyLogger.d("Email and password cannot be empty.");
      setState(() => _isLoading = false); // Reset loading state
      return;
    }

    if (email.isEmpty) {
      _showErrorMessage("Email cannot be empty.");
      MyLogger.d("Email cannot be empty.");
      setState(() => _isLoading = false);
      return;
    }

    if (password.isEmpty) {
      _showErrorMessage("Password cannot be empty.");
      MyLogger.d("Password cannot be empty.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authService.signInWithEmail(email, password);
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      _showErrorMessage(e.toString());
      MyLogger.d("Error during sign-in: $e");
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state after request
      });
    }
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(15),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight > 600 ? screenHeight : 600, // Set a minimum height
          ),
          child: Container(
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
                  width: screenWidth * 0.3,  // Adjust this width to be dynamic
                  constraints: const BoxConstraints(
                    minWidth: 300, // Minimum width for the login box
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Sign In',
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
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? FontAwesomeIcons.eye
                                  : FontAwesomeIcons.eyeSlash,
                              size: 17,
                              color: Colors.grey,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          hintText: 'Password',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        onSubmitted: (value) {
                          _signIn(); // Gọi hàm đăng nhập khi nhấn Enter
                        },
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () async {
                          String email = _emailController.text.trim();
                          if (email.isEmpty) {
                            _showErrorMessage("Email cannot be empty.");
                            return;
                          }
                          await _authService.sendPasswordResetEmail(email);
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signIn, // Disable button when loading
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0, // No shadow
                          backgroundColor: Colors.transparent, // Allows the gradient to show
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.pinkAccent.withAlpha(50); // Ripple effect when pressed
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.pinkAccent.withAlpha(25); // Hover effect
                              }
                              return null; // Default
                            },
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.pink, Colors.red],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Padding( // Thêm padding để tạo khoảng cách hợp lý
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 34),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text("Don't have an account? Sign up."),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
