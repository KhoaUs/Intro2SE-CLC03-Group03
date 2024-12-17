import 'package:chatbot/backend/config/string.dart';
import 'package:chatbot/backend/db/prompt.dart';
import 'package:chatbot/backend/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/db/thread.dart';
import '../../backend/db/message.dart';
import '../frontend/widget/message_list.dart';
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

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  Thread? selectedThread;
  MyUser? curUser;
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late ChatService _chatService;
  String? userId;
  String _selectedModel = GEMINI_MODEL_1_0_PRO; // Default AI model
  bool _showPrompt = false;
  List<Prompt> prompts = []; // List of fetched prompts
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(API_KEY_GEMINI, _selectedModel); // Initialize ChatService with your API Key
    _initializeUserId();
    _loadUserData();
    _loadUserInfo();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Load current user info
  Future<void> _loadUserInfo() async {
    final user = widget.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pop(); // Close the settings dialog
      return;
    }
    try {
      MyUser? userData = await MyUser.getUserFromFirestore(user.uid);
      if (userData != null) {
        setState(() {
          curUser = userData;
        });
        MyLogger.i('User info loaded');
      }
    } catch (e) {
      MyLogger.e('Error loading user info: $e');
      _showErrorMessage('Failed to load user information. Please try again.');
    }
  }

  // Open Settings Dialog
  void _openSettings() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 500,
            child: Column(
              children: [
                // Dialog Header
                _buildDialogHeader(),
                const Divider(height: 1),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'General'),
                    Tab(text: 'Upgrade Plan'),
                  ],
                ),

                // Tab Contents
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // General Settings Tab
                      _buildGeneralSettingsContent(),

                      // Upgrade Plan Tab
                      _buildUpgradePlanContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog Header
  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // General Settings Tab
  Widget _buildGeneralSettingsContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: curUser == null
          ? const Center(child: CircularProgressIndicator())
          : Center( // Center the content
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make the column size as small as possible
                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
                children: [
                  const Text(
                    'General Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Name: ${curUser!.name}',
                    style: const TextStyle(fontSize: 18), // Increased font size
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan: ${curUser!.plan}',
                    style: const TextStyle(fontSize: 18), // Increased font size
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Token: ${curUser!.token}',
                    style: const TextStyle(fontSize: 18), // Increased font size
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _loadUserInfo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User data refreshed')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16), // Increased font size for button
                    ),
                    child: const Text('Refresh User Data'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _logOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16), // Increased font size for button
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Upgrade Plan Tab
  Widget _buildUpgradePlanContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column size as small as possible
        mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
        children: [
          const Text(
            'Upgrade Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your plan to access premium features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16), // Increased font size
          ),
          const SizedBox(height: 20),
          // Plan Boxes with Expanded for equal distribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), // Add some space between the boxes
                  child: _buildPlanBox('Free Plan', [
                    'Access to basic features',
                    'Limited usage of premium features',
                    'Community support only',
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Add some space between the boxes
                  child: _buildPlanBox('Pro Plan', [
                    'All basic features',
                    'Unlimited premium feature usage',
                    'Priority customer support',
                    'Exclusive access to new features',
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(  // Center the "Upgrade to Pro" button
            child: ElevatedButton(
              onPressed: _upgradePlan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Upgrade to Pro'),
            ),
          ),
        ],
      ),
    );
  }

  // Plan Box Widget
  Widget _buildPlanBox(String planName, List<String> benefits) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2, // Calculate width for both boxes
      decoration: BoxDecoration(
        color: planName == 'Pro Plan' ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: planName == 'Pro Plan' ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (var benefit in benefits)
            Text('• $benefit', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Upgrade Plan Logic
  Future<void> _upgradePlan() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.auth.currentUser!.uid)
          .update({'plan': 'Pro'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan upgraded successfully!')),
      );
      MyLogger.i('User upgraded to Pro plan');
    } catch (e) {
      MyLogger.e('Error upgrading plan: $e');
      _showErrorMessage('Failed to upgrade plan. Please try again later.');
    }
  }

  // Logout
  Future<void> _logOut() async {
    try {
      await widget.auth.signOut();  // Firebase sign-out operation
      
      // If route '/signin' exists in your app, use this method:
      Navigator.pushReplacementNamed(context, '/signin');  // Push sign-in route and remove current page from stack

      MyLogger.i('User signed out');
    } catch (e) {
      MyLogger.e('Error signing out: $e');
      _showErrorMessage('Sign-out failed. Please try again.');
    }
  }

  // Error Message Dialog
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(15),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
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
          ? const Center(child: Text('Select a thread to chat'))
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      final threadData = snapshot.data?.data() as Map<String, dynamic>?;
                      if (threadData == null) {
                        return const Center(child: Text('No messages'));
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
                    margin: const EdgeInsets.only(top: 8.0),
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
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      _openSettings();
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
                        icon: const Icon(Icons.edit),
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
              decoration: const InputDecoration(
                hintText: "Type '/' to see prompts",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () async {
              try {
                await _sendMessage();
              } catch (e) {
                if (e == 'Not enough token') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You do not have enough tokens!')),
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
        title: const Text('Select AI Model'),
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
            child: const Text('Cancel'),
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
        title: const Text('Rename Thread'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _renameThread(thread.id);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
