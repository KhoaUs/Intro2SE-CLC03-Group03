import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http;

class FirebaseService {
  final String baseUrl;

  FirebaseService(this.baseUrl);

  // Create a new chat thread
  Future<String> createThread() async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat_threads.json'),
      body: json.encode({'messages': {}}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['name']; // Returns the thread ID
    } else {
      throw Exception('Failed to create thread: ${response.body}');
    }
  }

  // Add a message to a thread
  Future<void> addMessage(String threadId, String text, bool fromUser) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final messageData = {
      'text': text,
      'fromUser': fromUser,
      'timestamp': timestamp,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/chat_threads/$threadId/messages.json'),
      body: json.encode(messageData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add message: ${response.body}');
    }
  }

  // Fetch all messages for a thread
  Future<List<Map<String, dynamic>>> fetchMessages(String threadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat_threads/$threadId/messages.json'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> messagesData = json.decode(response.body);
      return messagesData.entries.map((e) {
        final Map<String, dynamic> message = e.value;
        message['id'] = e.key; // Add the message ID
        return message;
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }
}
