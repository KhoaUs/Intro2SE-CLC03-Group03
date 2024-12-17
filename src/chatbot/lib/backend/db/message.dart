class Message {
  String id;
  String sender; // 'user' hoặc 'ai'
  String content;
  DateTime timestamp;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  // Chuyển Message thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Khởi tạo Message từ Map đọc từ Firestore
  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      id: data['id'] ?? '',
      sender: data['sender'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
