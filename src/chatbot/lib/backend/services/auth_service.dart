import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../config/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger MyLogger = Logger();

  // Đăng Ký tài khoản bằng Email và mật khẩu
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      // Tạo tài khoản mới với email và mật khẩu
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Lấy thông tin người dùng vừa được tạo
      User? user = userCredential.user;

      // Kiểm tra nếu user tồn tại, thực hiện các hành động tiếp theo (nếu cần)
      if (user != null) {
        // Gửi email xác thực
        await user.sendEmailVerification();
        MyLogger.i("Đăng ký thành công! Vui lòng kiểm tra email để kích hoạt tài khoản.");
        return user;
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi khi đăng ký
      if (e.code == 'weak-password') {
        MyLogger.e("Mật khẩu quá yếu.");
        throw "Mật khẩu quá yếu.";
      } else if (e.code == 'email-already-in-use') {
        MyLogger.e("Email đã được sử dụng cho tài khoản khác.");
        throw "Email đã được sử dụng cho tài khoản khác.";
      } else if (e.code == 'invalid-email') {
        MyLogger.e("Email không hợp lệ.");
        throw "Email không hợp lệ.";
      } else {
        MyLogger.e("Lỗi không xác định: ${e.message}");
        throw "Lỗi không xác định: ${e.message}";
      }
    }
  }

  // Đăng nhập với email và mật khẩu
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Đăng nhập với email và mật khẩu
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Lấy thông tin người dùng sau khi đăng nhập
      User? user = userCredential.user;

      // Kiểm tra nếu user tồn tại và đã xác thực email
      if (user != null) {
        if (user.emailVerified) {
          MyLogger.i("Đăng nhập thành công!");
        } else {
          MyLogger.w("Tài khoản chưa được xác thực. Vui lòng kiểm tra email.");
          throw "Tài khoản chưa được xác thực. Vui lòng kiểm tra email.";
        }
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi khi đăng nhập
      MyLogger.e("Tài khoản hoặc mật khẩu không đúng");
      throw "Tài khoản hoặc mật khẩu không đúng";
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    MyLogger.i("Đã đăng xuất");
  }

  // Gửi email khôi phục mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    MyLogger.i("Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra email của bạn.");
  }

  // Lấy trạng thái người dùng hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }

}
