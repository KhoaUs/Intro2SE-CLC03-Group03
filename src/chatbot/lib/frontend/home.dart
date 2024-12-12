import 'package:flutter/material.dart';
import '../backend/services/auth_service.dart'; // Thay bằng đường dẫn thực tế
import 'package:logger/logger.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

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
    Navigator.pushReplacementNamed(context, '/signin'); // Chuyển về trang đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trang Chủ")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chào mừng, $_userName!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              child: Text("Đăng xuất"),
            ),
          ],
        ),
      ),
    );
  }
}


class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}