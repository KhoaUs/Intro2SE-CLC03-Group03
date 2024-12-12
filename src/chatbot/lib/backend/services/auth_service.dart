import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Đăng Ký tài khoản bằng Email và mật khẩu
  Future<void> signUpWithEmail(String email, String password) async {
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
        _logger.i("Đăng ký thành công! Vui lòng kiểm tra email để kích hoạt tài khoản.");
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi khi đăng ký
      if (e.code == 'weak-password') {
        _logger.e("Mật khẩu quá yếu.");
      } else if (e.code == 'email-already-in-use') {
        _logger.e("Email đã được sử dụng cho tài khoản khác.");
      } else if (e.code == 'invalid-email') {
        _logger.e("Email không hợp lệ.");
      } else {
        _logger.e("Lỗi không xác định: ${e.message}");
      }
      throw e;
    } catch (e) {
      // Xử lý các lỗi khác (nếu có)
      _logger.e("Có lỗi xảy ra: $e");
      throw Exception("Có lỗi xảy ra: $e");
    }
  }

  // Kiểm tra trạng thái xác thực email
  Future<void> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        _logger.i("Tài khoản đã được xác thực.");
      } else {
        _logger.w("Tài khoản chưa được xác thực. Vui lòng kiểm tra email.");
      }
      throw e;
    } else {
      _logger.e("Không tìm thấy người dùng đăng nhập.");
      throw Exception("Có lỗi xảy ra: $e");
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
          _logger.i("Đăng nhập thành công!");
        } else {
          _logger.w("Tài khoản chưa được xác thực. Vui lòng kiểm tra email.");
        }
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi khi đăng nhập
      if (e.code == 'user-not-found') {
        _logger.e("Không tìm thấy tài khoản với email này.");
      } else if (e.code == 'wrong-password') {
        _logger.e("Mật khẩu không đúng.");
      } else {
        _logger.e("Lỗi không xác định: ${e.message}");
      }
      throw e;
    } catch (e) {
      // Xử lý các lỗi khác (nếu có)
      _logger.e("Có lỗi xảy ra: $e");
      throw Exception("Có lỗi xảy ra: $e");
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    _logger.i("Đã đăng xuất");
  }

  // Gửi email khôi phục mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i("Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra email của bạn.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _logger.e("Không tìm thấy người dùng với email này.");
      } else if (e.code == 'invalid-email') {
        _logger.e("Email không hợp lệ.");
      } else {
        _logger.e("Lỗi không xác định: ${e.message}");
      }
      throw e;
    } catch (e) {
      _logger.e("Có lỗi xảy ra: $e");
      throw Exception("Có lỗi xảy ra: $e");
    }
  }

  // Xác nhận và thay đổi mật khẩu mới
  Future<void> confirmPasswordReset(String oobCode, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
      _logger.i("Mật khẩu đã được thay đổi thành công.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-action-code') {
        _logger.e("Mã xác thực không hợp lệ.");
      } else if (e.code == 'expired-action-code') {
        _logger.e("Mã xác thực đã hết hạn.");
      } else {
        _logger.e("Lỗi không xác định: ${e.message}");
      }
    } catch (e) {
      _logger.e("Có lỗi xảy ra: $e");
    }
  }

  // Lấy trạng thái người dùng hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Lấy uid của người dùng hiện tại
  String? getCurrentUserUID() {
    return _auth.currentUser?.uid;
  }

}
