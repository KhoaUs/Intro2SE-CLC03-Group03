import 'package:flutter/material.dart';
import '../../backend/db/message.dart';
// import '../../backend/db/thread.dart';
// import './message_widget.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController _scrollController = ScrollController();
  MessageList({required this.messages, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUserMessage = message.sender == 'user';

        return Align(
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isUserMessage ? Colors.purple[600] : Colors.purpleAccent[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: isUserMessage ? Radius.circular(12) : Radius.zero,
                bottomRight: isUserMessage ? Radius.zero : Radius.circular(12),
              ),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUserMessage ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
