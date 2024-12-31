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
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Prompt>>(
        stream: Prompt.fetchPrompts(widget.auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy danh sách prompts và sắp xếp theo thứ tự A-Z
          final prompts = snapshot.data!..sort((a, b) => a.title.compareTo(b.title));

          // Lọc prompts theo từ khóa tìm kiếm
          _filteredPrompts = prompts.where((prompt) {
            return prompt.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Search bar và Add button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search prompts...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 175, 35, 200), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1),
                          ),
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
              // Danh sách Prompts
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _filteredPrompts[index];
                    return Card(
                      color: Colors.purple[200],
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(prompt.title),
                        subtitle: Text(
                          prompt.text.length > 100
                              ? '${prompt.text.substring(0, 100)}...'
                              : prompt.text,
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
                        onTap: () => _showPromptDetails(prompt),
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
              else{
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please fill in both fields',
                      style: TextStyle(
                        color: Colors.white, // Màu chữ
                        fontWeight: FontWeight.bold, // Chữ đậm
                        fontSize: 16, // Kích thước chữ
                      ),
                    ),
                    backgroundColor: Colors.red, // Màu nền nổi bật
                    behavior: SnackBarBehavior.floating, // Kiểu hiển thị nổi
                    margin: const EdgeInsets.all(16), // Khoảng cách đến các cạnh
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), // Bo góc
                    ),
                  ),
                );
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
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Enter new title',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
              }else{
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please fill in both fields',
                      style: TextStyle(
                        color: Colors.white, // Màu chữ
                        fontWeight: FontWeight.bold, // Chữ đậm
                        fontSize: 16, // Kích thước chữ
                      ),
                    ),
                    backgroundColor: Colors.red, // Màu nền nổi bật
                    behavior: SnackBarBehavior.floating, // Kiểu hiển thị nổi
                    margin: const EdgeInsets.all(16), // Khoảng cách đến các cạnh
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), // Bo góc
                    ),
                  ),
                );
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