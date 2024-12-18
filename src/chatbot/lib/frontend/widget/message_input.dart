import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final Function(String) onSend;

  const MessageInput({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(hintText: 'Enter a message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                onSend(messageController.text.trim());
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
