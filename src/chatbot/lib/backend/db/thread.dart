import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart';

class Thread {
  String id;
  String title;
  List<Message> messages;

  Thread({
    required this.id,
    required this.title,
    required this.messages,
  });

  // Chuyển Thread thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }

  // Khởi tạo Thread từ Map đọc từ Firestore
  factory Thread.fromMap(Map<String, dynamic> data) {
    return Thread(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      messages: (data['messages'] as List<dynamic>?)
              ?.map((msg) => Message.fromMap(msg))
              .toList() ??
          [],
    );
  }

  // Lưu Thread vào subcollection của user trong Firestore
  Future<void> saveToFirestore(String userId) async {
    final threadsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads');
    await threadsCollection.doc(id).set(toMap());
  }

  // Cập nhật Thread trong subcollection của user
  Future<void> updateInFirestore(String userId) async {
    final threadsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads');
    await threadsCollection.doc(id).update(toMap());
  }

  // Xóa Thread khỏi subcollection của user
  Future<void> deleteFromFirestore(String userId) async {
    final threadsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads');
    await threadsCollection.doc(id).delete();
  }

  Future<List<Thread>> fetchThreadsFromFirestore(String userId) async {
    try {
      // Access the threads subcollection of the specified user
      final threadsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('threads');

      // Fetch all documents in the collection
      final snapshot = await threadsCollection.get();

      // Map each document to a Thread object
      final threads = snapshot.docs.map((doc) {
        return Thread.fromMap(doc.data());
      }).toList();

      return threads;
    } catch (e) {
      // Log or handle any errors
      print('Error fetching threads: $e');
      return [];
    }
  }
}
