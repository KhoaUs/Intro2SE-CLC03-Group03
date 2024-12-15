import 'package:chatbot/backend/config/string.dart';
import 'package:chatbot/backend/db/prompt.dart';
import 'package:chatbot/backend/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/db/thread.dart';
import '../../backend/db/message.dart';
import '../frontend/widget/message_list.dart';
import '../frontend/setting.dart';
import '../backend/config/logger.dart';
import '../backend/db/user.dart';
import '../frontend/prompt_lib_page.dart';

const List<String> availableModels = [GEMINI_MODEL_1_0_PRO, GEMINI_MODEL_1_5_FLASH];

class ChatPage extends StatefulWidget {
  final FirebaseAuth auth;

  const ChatPage({super.key, required this.auth});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Thread? selectedThread;
  MyUser? curUser;
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late ChatService _chatService;
  String? userId;
  String _selectedModel = GEMINI_MODEL_1_0_PRO; // Default AI model
  bool _showPrompt = false;
  List<Prompt> prompts = []; // List of fetched prompts

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(API_KEY_GEMINI, _selectedModel); // Initialize ChatService with your API Key
    _initializeUserId();
    _loadUserData();
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
        title: Row(
          children: [
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedModel,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeModel(newValue);
                }
              },
              items: availableModels.map<DropdownMenuItem<String>>((String model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              icon: const Icon(Icons.arrow_drop_down),
              underline: Container(height: 0), // Removes underline
            ),
          ],
        ),
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
                if (_showPrompt)
                  Container(
                    margin: EdgeInsets.only(top: 8.0),
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      itemCount: prompts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(prompts[index].title), // Display prompt title
                          onTap: () {
                            // Replace '/' with selected prompt's text
                            String currentText = _messageController.text;
                            _messageController.text = currentText.replaceAll('/', prompts[index].text);
                            _messageController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _messageController.text.length),
                            );
                            setState(() {
                              _showPrompt = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
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
                accountName: Text(curUser!.name),
                accountEmail: Text(widget.auth.currentUser?.email ?? 'No email'),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/chat/setting');
                      _loadUserData();
                    }
                  ),
                ],
              ),
              // New option to change prompt
              ListTile(
                title: const Text('Prompt Library'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PromptLibrary(auth: widget.auth),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Add Thread'),
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
              onChanged: (text) {
                _handleSlashInput(text);
              },
              decoration: InputDecoration(
                hintText: "Type '/' to see prompts",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              try {
                await _sendMessage();
              } catch (e) {
                if (e == 'Not enough token') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You do not have enough tokens!')),
                  );
                }
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              }
            }
          ),
        ],
      ),
    );
  }

  void _handleSlashInput(String text) {
    // Handle '/' input and show prompts accordingly
    if (text.endsWith('/')) {
      setState(() {
        _showPrompt = true;
      });
    } else {
      setState(() {
        _showPrompt = false;
      });
    }
  }


  void _showModelSelectionDialog() {
    MyLogger.i(_selectedModel);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select AI Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableModels.map((model) {
            return RadioListTile<String>(
              title: Text(model),
              value: model,
              groupValue: _selectedModel,
              onChanged: (value) {
                if (value != null) {
                  _changeModel(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
    MyLogger.d('Added thread');
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
    MyLogger.d('Deleted thread');
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

    MyLogger.d('Renamed');
  }

  Future<void> _sendMessage() async {
    if (selectedThread == null || userId == null) return;
    String tmpMessage = _messageController.text.trim();
    _messageController.clear();
    if (tmpMessage.isEmpty) return;

    int tokenCost = _countToken(tmpMessage);
    if (curUser?.plan == 'Pro') {
      tokenCost = 0;
    }
    MyLogger.i('tokencost:$tokenCost');
    MyLogger.i('token:${curUser!.token}');

    if (curUser!.token < tokenCost) {
      throw 'Not enough token';
    }

    curUser!.token = curUser!.token - tokenCost;
    // update to firebase
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'token': curUser!.token});

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

    MyLogger.d('Message sent to firestore');

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

    MyLogger.d('AI response sent to firebase');
  }

  int _countToken(String message) {
    return (message.length / 4).toInt();
  }

  Future<void> _changeModel(String newModel) async {
    setState(() {
      _selectedModel = newModel;
      _chatService = ChatService(API_KEY_GEMINI, _selectedModel); // Update ChatService with new model
    });
    MyLogger.i('AI model changed to $_selectedModel');
  }

  Future<void> _initializeUserId() async {
    final user = widget.auth.currentUser;
    if (user == null) {
      // Handle unauthenticated user, e.g., navigate to login screen
      Navigator.of(context).pushReplacementNamed('/signin');
      MyLogger.d('Ask the user to login');
    } else {
      setState(() {
        userId = user.uid;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        curUser = MyUser.fromMap(userData); // Chuyển dữ liệu thành đối tượng User
        MyLogger.i('Retrieve user info successful');
      } else {
        MyLogger.e('User not found');
      }
    } catch (e) {
      MyLogger.e('Error loading user data: $e');
    }

    // Fetch prompts from Firestore
    if (userId != null) {
      Prompt.fetchPrompts(userId!).listen((fetchedPrompts) {
        setState(() {
          prompts = fetchedPrompts;
        });
      });
    }
  }
}
