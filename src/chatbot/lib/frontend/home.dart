import 'package:flutter/material.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Hàm lấy thông tin người dùng
  void _loadUserInfo() {
    // Lấy thông tin người dùng từ Firebase
    var user = _authService.getCurrentUser();
    setState(() {
      _userName = user?.displayName ?? "Người dùng";
    });
  }

  // Hàm đăng xuất
  void _signOut() async {
    await _authService.signOut();
    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/signin'); // Chuyển về trang đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trang Chủ")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chào mừng, $_userName!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              child: const Text("Đăng xuất"),
            ),
          ],
        ),
      ),
    );
  }
}


class Home extends StatefulWidget {
  const Home({ super.key });

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}