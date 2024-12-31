import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế
import '../backend/config/logger.dart';
import '../backend/db/user.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Controller for confirm password
  final AuthService _authService = AuthService();

  // Add a boolean to toggle password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSigningUp = false;

  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.purple[400],
      end: Colors.purple[800],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Sign-up method
  void _signUp() async {
    // Prevent multiple button presses
    if (_isSigningUp) return;

    setState(() {
      _isSigningUp = true; // Set signing up state
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Check for specific errors
    if (email.isEmpty && password.isEmpty && confirmPassword.isEmpty) {
      _showErrorMessage("Email, password, and confirm password cannot be empty.");
      MyLogger.d("Email, password, and confirm password cannot be empty.");
      setState(() => _isSigningUp = false); // Reset signing up state
      return;
    }

    if (email.isEmpty) {
      _showErrorMessage("Email cannot be empty.");
      MyLogger.d("Email cannot be empty.");
      setState(() => _isSigningUp = false);
      return;
    }

    if (password.isEmpty) {
      _showErrorMessage("Password cannot be empty.");
      MyLogger.d("Password cannot be empty.");
      setState(() => _isSigningUp = false);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showErrorMessage("Confirm password cannot be empty.");
      MyLogger.d("Confirm password cannot be empty.");
      setState(() => _isSigningUp = false);
      return;
    }

    if (password != confirmPassword) {
      _showErrorMessage("Passwords do not match.");
      MyLogger.d("Passwords do not match.");
      setState(() => _isSigningUp = false);
      return;
    }

try {
      User? curUser = await _authService.signUpWithEmail(email, password);
      String username = email.split('@')[0];

      final newUser = MyUser(
        id: curUser?.uid,
        name: username,
        plan: 'free',
        token: 100,
      );

      await newUser.saveToFirestore();

      if (curUser != null && !curUser.emailVerified) {
        await curUser.sendEmailVerification();

        _showSuccessMessage(
          "A verification email has been sent to $email. Please check your email to verify your account.",
        );
      }

      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      MyLogger.d("Error during sign-up: $e");
      _showErrorMessage(e.toString());
    } finally {
      setState(() {
        _isSigningUp = false; // Unlock the button after request finishes
      });
    }
  }

  void _showSuccessMessage(String message) {
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
                    "Success",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: screenWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorAnimation.value!,
                      Colors.purple[800]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: child,
              );
            },
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // SizedBox(
                  //   child: Image.asset('images/logo.png', fit: BoxFit.contain),
                  // ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to AI Copilot',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: screenWidth * 0.3,  // Adjust this width to be dynamic
                    constraints: const BoxConstraints(
                      minWidth: 300, // Minimum width for the sign-up box
                    ),
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
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                size: 17,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            hintText: 'Confirm Password',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _isSigningUp ? null : _signUp, // Disable button when signing up
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
                                colors: [Colors.purpleAccent, Colors.purple],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Padding( // Thêm padding để tạo khoảng cách hợp lý
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 34),
                              child: Center(
                                child: _isSigningUp
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Sign Up',
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
                            Navigator.pushReplacementNamed(context, '/signin');
                          },
                          child: const Text(
                            "Already have an account? Sign in.",
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}