import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final Function(String) onSend;

  const MessageInput({Key? key, required this.onSend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Enter a message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                onSend(_messageController.text.trim());
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
