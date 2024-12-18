import 'package:chatbot/frontend/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'backend/config/firebase_config.dart';
import 'frontend/sign_in.dart';
import 'frontend/sign_up.dart';
// import 'frontend/home.dart';
import 'frontend/setting.dart';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Auth Example',
      initialRoute: '/signup',  // Khởi động ứng dụng ở trang đăng nhập
      routes: {
        '/signin': (context) => const SignInPage(),  // Đăng nhập
        '/signup': (context) => const SignUpPage(),  // Đăng ký
        // '/home': (context) => const HomePage(),
        '/chat': (context) => ChatPage(auth: FirebaseAuth.instance),
        '/chat/setting': (context) => SettingsPage(auth: FirebaseAuth.instance),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}