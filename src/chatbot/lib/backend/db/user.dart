import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String name;
  String plan;
  int token;

  User({
    required this.id,
    this.name = 'User',
    this.plan = 'free',
    this.token = 100 // default
  });

  // Chuyển đối tượng User thành Map<String, dynamic> để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plan': plan,
      'token': token,
    };
  }

  // Khởi tạo User từ Map đọc từ Firestore
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'] ?? '',
      name: data['name'] ?? 'User',
      plan: data['plan'] ?? 'free',
      token: data['token'] ?? 100,
    );
  }

  // Hàm lưu dữ liệu User vào Firestore
  Future<void> saveToFirestore() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.doc(id).set(toMap());
  }

  // Hàm cập nhật dữ liệu User trong Firestore
  Future<void> updateInFirestore() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.doc(id).update(toMap());
  }

  // Hàm xóa User khỏi Firestore
  Future<void> deleteFromFirestore() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.doc(id).delete();
  }
}