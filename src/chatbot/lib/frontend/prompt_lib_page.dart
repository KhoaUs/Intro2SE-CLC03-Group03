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

          return ListView(
            children: [
              ListTile(
                title: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a title for the prompt...',
                  ),
                ),
              ),
              ListTile(
                title: TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a new prompt...',
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addPrompt,
                ),
              ),
              ...prompts.map((prompt) {
                return ListTile(
                  title: Text(prompt.title),
                  subtitle: Text(prompt.text),
                  onTap: () {
                    // Handle prompt selection here, perhaps using a callback or directly updating the parent
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editPrompt(prompt),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePrompt(prompt.id),
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

  Future<void> _addPrompt() async {
    final title = _titleController.text.trim();
    final text = _promptController.text.trim();
    if (title.isEmpty || text.isEmpty) return;

    await Prompt.addPrompt(widget.auth.currentUser!.uid, title, text);
    _titleController.clear();
    _promptController.clear();
  }

  Future<void> _editPrompt(Prompt prompt) async {
    _titleController.text = prompt.title;
    _promptController.text = prompt.text;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Prompt'),
        content: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Enter new title'),
            ),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(hintText: 'Enter new prompt text'),
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

  Future<void> _deletePrompt(String promptId) async {
    await Prompt.deletePrompt(widget.auth.currentUser!.uid, promptId);
  }
}
