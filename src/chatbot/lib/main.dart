import 'package:chatbot/frontend/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
import 'backend/config/firebase_config.dart';
// import 'backend/db/user.dart';
// import 'backend/services/auth_service.dart';
// import 'frontend/testUser.dart';
// import 'frontend/testFetch.dart';
import 'frontend/sign_in.dart';
import 'frontend/sign_up.dart';
import 'frontend/home.dart';
import 'frontend/setting.dart';
import '../backend/config/logger.dart';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Example',
      initialRoute: '/signup',  // Khởi động ứng dụng ở trang đăng nhập
      routes: {
        '/signin': (context) => const SignInPage(),  // Đăng nhập
        '/signup': (context) => const SignUpPage(),  // Đăng ký
        '/home': (context) => const HomePage(),
        '/chat': (context) => ChatPage(auth: FirebaseAuth.instance),
        '/chat/setting': (context) => SettingsPage(auth: FirebaseAuth.instance),
      },
    );
  }
}