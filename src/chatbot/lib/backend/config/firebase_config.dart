import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Hàm khởi tạo Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBQ-s6DasKililmPBHNkzvaeg5kPCiQ-yE",
        authDomain: "chatbot-db-43fad.firebaseapp.com",
        projectId: "chatbot-db-43fad",
        storageBucket: "chatbot-db-43fad.firebasestorage.app",
        messagingSenderId: "864814362862",
        appId: "1:864814362862:web:038dbfdaaa3431ff9103ff",
        measurementId: "G-VEBNDTJB7S"
      ),
    );
  }
}
