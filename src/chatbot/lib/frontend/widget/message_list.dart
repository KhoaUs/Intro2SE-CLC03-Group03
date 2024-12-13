import 'package:flutter/material.dart';
import '../../backend/db/message.dart';
// import '../../backend/db/thread.dart';
// import './message_widget.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages; // Danh sách tin nhắn
  final ScrollController _scrollController = ScrollController();
  MessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Tự động cuộn tới cuối khi xây dựng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length, // Số lượng tin nhắn
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Align(
            alignment: message.sender == 'user'
                ? Alignment.centerRight // Tin nhắn của người dùng
                : Alignment.centerLeft, // Tin nhắn từ AI
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: message.sender == 'user'
                    ? Colors.blueAccent // Tin nhắn người dùng có màu xanh
                    : Colors.grey[300], // Tin nhắn AI có màu xám
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.content, // Nội dung tin nhắn
                style: TextStyle(
                  color: message.sender == 'user'
                      ? Colors.white // Màu chữ tin nhắn người dùng
                      : Colors.black, // Màu chữ tin nhắn AI
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
