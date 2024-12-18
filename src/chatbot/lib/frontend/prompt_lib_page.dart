import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/db/prompt.dart';

class PromptLibrary extends StatefulWidget {
  final FirebaseAuth auth;

  const PromptLibrary({super.key, required this.auth});

  @override
  _PromptLibraryState createState() => _PromptLibraryState();
}

class _PromptLibraryState extends State<PromptLibrary> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Prompt> _filteredPrompts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Library'),
      ),
      body: StreamBuilder<List<Prompt>>(
        stream: Prompt.fetchPrompts(widget.auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prompts = snapshot.data!;
          _filteredPrompts = prompts.where((prompt) {
            return prompt.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Search bar and Add button in a row
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search prompts...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 36),
                      onPressed: _showAddPromptDialog,
                    ),
                  ],
                ),
              ),
              // List of Prompts
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _filteredPrompts[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(prompt.title),
                        subtitle: Text(
                          prompt.text.length > 100
                              ? '${prompt.text.substring(0, 100)}...' // Hiển thị tóm tắt 100 ký tự
                              : prompt.text, // Hiển thị nội dung đầy đủ nếu ngắn
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editPrompt(prompt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePrompt(prompt.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info, color: Colors.green),
                              onPressed: () => _showPromptDetails(prompt),
                            ),
                          ],
                        ),
                        onTap: () => _showPromptDetails(prompt), // Nhấn vào mục sẽ hiển thị chi tiết
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show Add Prompt Dialog
  void _showAddPromptDialog() {
    _titleController.clear();
    _promptController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Prompt Title'),
            ),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(hintText: 'Prompt Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final text = _promptController.text.trim();
              if (title.isNotEmpty && text.isNotEmpty) {
                await Prompt.addPrompt(widget.auth.currentUser!.uid, title, text);
              }
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

  // Edit Prompt Dialog
  Future<void> _editPrompt(Prompt prompt) async {
    _titleController.text = prompt.title;
    _promptController.text = prompt.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Enter new title'),
            ),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(hintText: 'Enter new content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newTitle = _titleController.text.trim();
              final newText = _promptController.text.trim();
              if (newTitle.isNotEmpty && newText.isNotEmpty) {
                await Prompt.editPrompt(widget.auth.currentUser!.uid, prompt.id, newTitle, newText);
              }
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

  // Delete Prompt with confirmation
  Future<void> _deletePrompt(String promptId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this prompt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Trả về "false" khi hủy
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Trả về "true" khi đồng ý
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    // Nếu người dùng chọn "Yes", thực hiện xóa
    if (shouldDelete == true) {
      await Prompt.deletePrompt(widget.auth.currentUser!.uid, promptId);
    }
  }


  // Show Prompt Details Dialog
  // Show Prompt Details Dialog
  Future<void> _showPromptDetails(Prompt prompt) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Details: ${prompt.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(prompt.text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Đóng dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}