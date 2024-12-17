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
import 'widget/text_gradient.dart';

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
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  String? userId;
  String? hoveredThreadId;
  String _selectedModel = GEMINI_MODEL_1_0_PRO; // Default AI model
  String _searchPromptQuery = '';
  String _selectedFilter = "All"; // Default filter 
  bool _showPrompt = false;
  bool _isAscending = true; // Default sorting order: ascending
  final Map<int,bool> _hoverStates = {}; // Map to track hover state for each prompt
  List<Prompt> prompts = []; // List of fetched prompts
  Prompt? _selectedPrompt; // Track the currently selected prompt

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
      backgroundColor: Colors.white, // GPT Dark background
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              dropdownColor: Colors.grey[300], // Darken the dropdown background
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black, // Use a contrasting icon color
              ),
              iconSize: 30.0, // Increase the icon size for better visibility
              elevation: 5, // Add elevation to give it a raised effect
              style: const TextStyle(
                color: Colors.white, // Ensure text is clearly visible
                fontSize: 16,
                fontWeight: FontWeight.w600, // Make the text bold for emphasis
              ),
              underline: Container(
                height: 0, // Remove the underline
              ),
              items: availableModels.map<DropdownMenuItem<String>>((String model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Space out the items
                    // child: Text(
                    //   model,
                    //   style: const TextStyle(color: Colors.white),
                    // ),
                    child: GradientText(
                      text: model, 
                      gradient: LinearGradient(colors: [
                        Colors.black,
                        Colors.deepPurple.shade400
                      ]),
                      style: const TextStyle(
                        fontSize: 50,
                        fontFamily: 'Roboto Flex',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.6
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: selectedThread == null
          ? const Center(child: Text(
                'Select a thread to chat',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25
                ),
              )
            )
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
                        return const Center(child: Text(
                          'No messages',
                          style: TextStyle(color: Colors.white),));
                      }

                      final messages = (threadData['messages'] as List<dynamic>)
                          .map((msg) => Message.fromMap(msg))
                          .toList();

                      // Scroll to the bottom after building the messages
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return MessageList(messages: messages);
                    },
                  ),
                ),
                _buildMessageInput(),
                if (_showPrompt)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Prompts List",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search prompts...",
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.white,
                          hoverColor: Colors.blueGrey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setState(() {
                            _searchPromptQuery = query;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", isSelected: _selectedFilter == "All"),
                            _buildFilterChip("Asc", isSelected: _selectedFilter == "Asc"),
                            _buildFilterChip("Des", isSelected: _selectedFilter == "Des"),
                            // Call the popup function
                            _buildPopupChip(context, FirebaseAuth.instance)
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredAndSortedPrompts.length,
                        itemBuilder: (context, index) {
                          return MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                _hoverStates[index] = true; // Track hover for specific prompt
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                _hoverStates[index] = false; // Reset hover for specific prompt
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPrompt = filteredAndSortedPrompts[index];
                                });
                                String currentText = _messageController.text;
                                _messageController.text = currentText.replaceAll('/', filteredAndSortedPrompts[index].text);
                                _messageController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _messageController.text.length),
                                );
                                setState(() {
                                  _showPrompt = false;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: //_selectedPrompt == filteredAndSortedPrompts[index]
                                      //? Colors.blueGrey.shade100 : // Selected state color
                                      _hoverStates[index] == true
                                          ? Colors.blueGrey.shade200 // Hovered state color for specific prompt
                                          : Colors.white, // Default color
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      filteredAndSortedPrompts[index].title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4), // Space between title and text
                                    Text(
                                      filteredAndSortedPrompts[index].text, // Display the prompt text
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

        ],
      ),
    ))]));
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
        backgroundColor: Colors.grey.shade300,
        selectedColor: Colors.blueGrey.shade600,
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            if (label == "All") {
              _selectedFilter = "All";
            } else if (label == "Asc") {
              _selectedFilter = "Asc";
              _isAscending = true;
              _sortPrompts();
            } else if (label == "Des") {
              _selectedFilter = "Des";
              _isAscending = false;
              _sortPrompts();
            }
          });
        },
      ),
    );
  }

  void _sortPrompts() {
    setState(() {
      prompts.sort((a, b) {
        if (_isAscending) {
          return a.title.compareTo(b.title); // Ascending order
        } else {
          return b.title.compareTo(a.title); // Descending order
        }
      });
    });
  }

  // Filter prompts based on search query and selected filter
  List<Prompt> get filteredAndSortedPrompts {
    List<Prompt> filteredList = prompts;

    // Apply search filter
    if (_searchPromptQuery.isNotEmpty) {
      filteredList = filteredList
          .where((prompt) =>
              prompt.title.toLowerCase().contains(_searchPromptQuery.toLowerCase()))
          .toList();
    }

    // Apply sort filter
    if (_selectedFilter == "Asc") {
      filteredList.sort((a, b) => a.title.compareTo(b.title)); // Ascending order
    } else if (_selectedFilter == "Des") {
      filteredList.sort((a, b) => b.title.compareTo(a.title)); // Descending order
    }

    return filteredList;
  }

  // Helper method to scroll to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: Column(
        children: [
          Expanded(
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
                    // "Begin a New Chat" section with icon
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.chat, color: Colors.white),
                        title: const Text(
                          'Begin a New Chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        hoverColor: Colors.blueGrey.shade500.withOpacity(0.3),
                        onTap: () async {
                          await _addThread();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Threads list
                    ...threads.map((thread) {
                    // ..._getFilteredThreads().map((thread) {
                      final isSelected = selectedThread?.id == thread.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                        child: MouseRegion(
                          onEnter: (event) => setState(() {
                            hoveredThreadId = thread.id;
                          }),
                          onExit: (event) => setState(() {
                            hoveredThreadId = null;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueGrey.shade700
                                  : (hoveredThreadId == thread.id
                                      ? Colors.blueGrey.shade800
                                      : Colors.blueGrey.shade900),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              title: Text(
                                thread.title,
                                style: const TextStyle(color: Colors.white),
                              ),
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
                                    icon: const Icon(Icons.edit, color: Colors.white60),
                                    hoverColor: Colors.blue.shade200.withOpacity(0.3),
                                    onPressed: () => _showRenameDialog(thread),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    hoverColor: Colors.red.shade300.withOpacity(0.3),
                                    onPressed: () => _deleteThread(thread.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          // User Profile Section at the Bottom
          Column(
            children: [
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'User Profile',
                  style: TextStyle(color: Colors.white),
                ),
                hoverColor: Colors.blueGrey.shade500.withOpacity(0.3),
                onTap: () {
                  Navigator.pushNamed(context, '/chat/setting');
                  _loadUserData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  void openPromptLibrary(BuildContext context, FirebaseAuth auth) {
    showDialog(
      context: context,
      builder: (context) => PromptLibrary(auth: auth),
    );
  }

  Widget _buildPopupChip(BuildContext context, FirebaseAuth auth) {
    return ActionChip(
      label: const Text(
        'Add Prompt',
        style: TextStyle(
          color: Colors.white, // White text color for contrast
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.red, // Red chip background
      onPressed: () {     // Call the pop-up function
        showDialog(
          context: context,
          builder: (context) => PromptLibrary(auth: auth),
        ); // Call the pop-up function
      },
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
              cursorColor: Colors.blueGrey[400],
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintStyle: TextStyle(color: Colors.grey),
                hintText: "Type '/' to see prompts",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Modify focus border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1), // Modify non-focus border color
                ),
              ),
              onSubmitted: (value) async {
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
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(backgroundColor: Colors.purple),
            color: Colors.white,
            hoverColor: Colors.blue.shade200.withOpacity(0.3),
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
        title: const Text(
            'Select AI Model',
            style: TextStyle(color: Colors.white),
          ),
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
