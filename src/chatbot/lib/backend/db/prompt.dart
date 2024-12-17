import 'package:cloud_firestore/cloud_firestore.dart';

class Prompt {
  final String id; // Unique ID for the prompt
  final String title; // Title of the prompt
  final String text; // Prompt text

  Prompt({required this.id, required this.title, required this.text});

  // Factory constructor to create a Prompt instance from Firestore data
  factory Prompt.fromMap(String id, Map<String, dynamic> data) {
    return Prompt(
      id: id,
      title: data['title'] as String,  // Add title field
      text: data['text'] as String,
    );
  }

  // Convert a Prompt instance into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,  // Include title in the map
      'text': text,
    };
  }

  // Fetch all prompts for a user
  static Stream<List<Prompt>> fetchPrompts(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('prompts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Prompt.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Add a new prompt to Firestore
  static Future<void> addPrompt(String userId, String title, String text) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('prompts')
        .add({
          'title': title,  // Save the title along with text
          'text': text
        });
  }

  // Edit an existing prompt in Firestore
  static Future<void> editPrompt(String userId, String promptId, String newTitle, String newText) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('prompts')
        .doc(promptId)
        .update({
          'title': newTitle,  // Update the title
          'text': newText,
        });
  }

  // Delete a prompt from Firestore
  static Future<void> deletePrompt(String userId, String promptId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('prompts')
        .doc(promptId)
        .delete();
  }
}
