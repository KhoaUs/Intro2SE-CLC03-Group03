// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../backend/services/prompt_service.dart';
import '../frontend/widget/message.dart'; // Import the MessageWidget

/// The API key to use when accessing the Gemini API.
/// 
/// To learn how to generate and specify this key,
/// check out the README file of this sample.
const String _apiKey = 'AIzaSyAqkrM-DQDwpAcKbiro-fNYLZJJ61dGWO4';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key}); // Removed the 'title' parameter

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({String? text, bool fromUser})> _generatedContent =
      <({String? text, bool fromUser})>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(_apiKey);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
      _generatedContent.add((text: message, fromUser: true));
    });

    try {
      final response = await _chatService.sendMessage(message);
      if (response != null) {
        setState(() {
          _generatedContent.add((text: response, fromUser: false));
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _scrollDown();
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('CHAT PAGE'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _apiKey.isNotEmpty
                  ? ListView.builder(
                      controller: _scrollController,
                      itemBuilder: (context, idx) {
                        final content = _generatedContent[idx];
                        return MessageWidget(
                          text: content.text,
                          isFromUser: content.fromUser,
                        );
                      },
                      itemCount: _generatedContent.length,
                    )
                  : ListView(
                      children: const [
                        Text(
                          'No API key found. Please provide an API Key using '
                          "'--dart-define' to set the 'API_KEY' declaration.",
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 25,
                horizontal: 15,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      focusNode: _textFieldFocus,
                      decoration: textFieldDecoration,
                      controller: _textController,
                      onSubmitted: _sendChatMessage,
                    ),
                  ),
                  const SizedBox.square(dimension: 15),
                  if (!_loading)
                    IconButton(
                      onPressed: () => _sendChatMessage(_textController.text),
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
