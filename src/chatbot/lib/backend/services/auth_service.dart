import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: non_constant_identifier_names
  final Logger MyLogger = Logger();

  // Register account with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      // Create a new account with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user information of the newly created account
      User? user = userCredential.user;

      // Check if user exists, perform any necessary actions
      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();
        MyLogger.i("Registration successful! Please check your email to verify your account.");
        return user;
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors during registration
      if (e.code == 'weak-password') {
        MyLogger.e("Password is too weak.");
        throw "Password is too weak.";
      } else if (e.code == 'email-already-in-use') {
        MyLogger.e("Email is already used by another account.");
        throw "Email is already used by another account.";
      } else if (e.code == 'invalid-email') {
        MyLogger.e("Invalid email.");
        throw "Invalid email.";
      } else {
        MyLogger.e("Undefined error: ${e.message}");
        throw "Undefined error: ${e.message}";
      }
    }
    return null;
  }

 // Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Get user information after signing in
      User? user = userCredential.user;

      // Check if the user exists and if email is verified
      if (user != null) {
        if (user.emailVerified) {
          MyLogger.i("Login successful!");
        } else {
          MyLogger.w("Account is not verified. Please check your email.");
          throw "Account is not verified. Please check your email.";
        }
      }
    } on FirebaseAuthException {
      // Handle errors during sign in
      MyLogger.e("Incorrect email or password.");
      throw "Incorrect email or password.";
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    MyLogger.i("Signed out");
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    MyLogger.i("Password reset email sent. Please check your email.");
  }

  // Get current user status
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
