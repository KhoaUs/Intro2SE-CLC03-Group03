import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/db/thread.dart';
import '../backend/db/message.dart';
import '../frontend/testUser.dart';

class ThreadChatPage extends StatefulWidget {
  final User user;
  final Thread thread;

  const ThreadChatPage({Key? key, required this.user, required this.thread})
      : super(key: key);

  @override
  _ThreadChatPageState createState() => _ThreadChatPageState();
}

class _ThreadChatPageState extends State<ThreadChatPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: widget.user.email!,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('threads')
        .doc(widget.thread.id);

    widget.thread.messages.add(message);

    await threadRef.update({'messages': widget.thread.messages.map((m) => m.toMap()).toList()});

    setState(() {
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.thread.messages.length,
              itemBuilder: (context, index) {
                final message = widget.thread.messages[index];
                return ListTile(
                  title: Text(message.sender),
                  subtitle: Text(message.content),
                  trailing: Text(
                    '${message.timestamp.hour}:${message.timestamp.minute}',
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComprehensiveTestPage extends StatefulWidget {
  const ComprehensiveTestPage({Key? key}) : super(key: key);

  @override
  _ComprehensiveTestPageState createState() => _ComprehensiveTestPageState();
}

class _ComprehensiveTestPageState extends State<ComprehensiveTestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();
  User? _user;
  List<Thread> threads = [];
  String? _selectedThreadId;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final user = _auth.currentUser;
    setState(() {
      _user = user;
    });
    if (user != null) {
      _fetchThreads();
    }
  }

  Future<void> _login() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _user = userCredential.user;
      });
      _fetchThreads();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> _fetchThreads() async {
    if (_user == null) return;

    final threadsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('threads');

    final snapshot = await threadsCollection.get();
    final loadedThreads = snapshot.docs.map((doc) {
      return Thread.fromMap(doc.data());
    }).toList();

    setState(() {
      threads = loadedThreads;
    });
  }

  Future<void> _addThread() async {
    if (_user == null) return;

    final thread = Thread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Thread',
      messages: [],
    );

    await thread.saveToFirestore(_user!.uid);
    _fetchThreads();
  }

  Future<void> _renameThread(String threadId) async {
    if (_renameController.text.isEmpty || _user == null) return;

    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('threads')
        .doc(threadId);

    await threadRef.update({'title': _renameController.text.trim()});
    _renameController.clear();
    _fetchThreads();
  }

  Future<void> _deleteThread(String threadId) async {
    if (_user == null) return;

    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('threads')
        .doc(threadId);

    await threadRef.delete();
    _fetchThreads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user == null ? 'Login Required' : 'Welcome ${_user!.email}'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                setState(() {
                  _user = null;
                  threads = [];
                });
              },
            ),
        ],
      ),
      body: _user == null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                ElevatedButton(
                  onPressed: _addThread,
                  child: const Text('Add New Thread'),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return ListTile(
                        title: Text(thread.title),
                        subtitle: Text('Messages: ${thread.messages.length}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _renameController.text = thread.title;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Rename Thread'),
                                    content: TextField(
                                      controller: _renameController,
                                      decoration: const InputDecoration(
                                        labelText: 'New Title',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _renameThread(thread.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteThread(thread.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThreadChatPage(user: _user!, thread: thread),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
