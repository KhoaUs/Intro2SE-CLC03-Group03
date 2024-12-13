import 'package:chatbot/backend/config/string.dart';
import 'package:chatbot/backend/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/db/thread.dart';
import '../../backend/db/message.dart';
import '../frontend/widget/message_list.dart';

class ChatPage extends StatefulWidget {
  final FirebaseAuth auth;

  const ChatPage({super.key, required this.auth});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Thread? selectedThread;
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late final ChatService _chatService;
  String? userId;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(API_KEY_GEMINI); // Initialize ChatService with your API Key
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final user = widget.auth.currentUser;
    if (user == null) {
      // Handle unauthenticated user, e.g., navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      setState(() {
        userId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedThread?.title ?? 'Threads'),
      ),
      drawer: _buildDrawer(),
      body: selectedThread == null
          ? Center(child: Text('Select a thread to chat'))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('threads')
                        .doc(selectedThread!.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final threadData = snapshot.data?.data() as Map<String, dynamic>?;
                      if (threadData == null) {
                        return Center(child: Text('No messages'));
                      }

                      final messages = (threadData['messages'] as List<dynamic>)
                          .map((msg) => Message.fromMap(msg))
                          .toList();

                      return MessageList(messages: messages);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('threads')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final threads = snapshot.data!.docs
              .map((doc) => Thread.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('User'),
                accountEmail: Text(widget.auth.currentUser?.email ?? 'No email'),
              ),
              ListTile(
                title: const Text('New Thread'),
                onTap: () async {
                  await _addThread();
                  Navigator.pop(context);
                },
              ),
              ...threads.map((thread) {
                return ListTile(
                  title: Text(thread.title),
                  onTap: () {
                    setState(() {
                      selectedThread = thread;
                    });
                    Navigator.pop(context);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showRenameDialog(thread),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteThread(thread.id),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _addThread() async {
    if (userId == null) return;

    final thread = Thread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Thread',
      messages: [],
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads')
        .doc(thread.id)
        .set(thread.toMap());

    setState(() {
      selectedThread = thread;
    });
  }

  Future<void> _deleteThread(String threadId) async {
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads')
        .doc(threadId)
        .delete();

    if (selectedThread?.id == threadId) {
      setState(() {
        selectedThread = null;
      });
    }
  }

  void _showRenameDialog(Thread thread) {
    _renameController.text = thread.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Thread'),
        content: TextField(
          controller: _renameController,
          decoration: InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _renameThread(thread.id);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameThread(String threadId) async {
    if (_renameController.text.isEmpty || userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads')
        .doc(threadId)
        .update({'title': _renameController.text.trim()});
  }

  Future<void> _sendMessage() async {
    if (selectedThread == null || userId == null) return;

    String tmpMessage = _messageController.text.trim();
    _messageController.clear();
    if (tmpMessage.isEmpty) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      content: tmpMessage,
      timestamp: DateTime.now(),
    );

    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('threads')
        .doc(selectedThread!.id);

    await threadRef.update({
      'messages': FieldValue.arrayUnion([message.toMap()])
    });

    setState(() {});

    String aiResponse = await _chatService.sendMessage(tmpMessage);

    final aiMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'AI',
      content: aiResponse,
      timestamp: DateTime.now(),
    );

    await threadRef.update({
      'messages': FieldValue.arrayUnion([aiMessage.toMap()])
    });
  }
}
