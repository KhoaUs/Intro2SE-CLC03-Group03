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
  // Track the currently hovered prompt
  String? hoveredPromptId;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[350],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: MediaQuery.of(context).size.width * 0.8, // Set fixed width
        height: MediaQuery.of(context).size.height * 0.6, // Set fixed height
        child: Column(
          children: [
            const Text(
              'Prompt Library',
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Text Input Area (Fixed at the top)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Enter a title for the prompt...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Enter a new prompt...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey, width: 1),
                    ),
                  ),
                  // Add button on the right for adding new prompts
                  onSubmitted: (_) => _addPrompt(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: _addPrompt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Scrolling Area for Prompts
            Expanded(
              child: StreamBuilder<List<Prompt>>(
                stream: Prompt.fetchPrompts(widget.auth.currentUser!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final prompts = snapshot.data!;

                  return ListView.builder(
                    itemCount: prompts.length,
                    itemBuilder: (context, index) {
                      final prompt = prompts[index];
                      final isHovered = hoveredPromptId == prompt.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding between prompts
                        child: MouseRegion(
                          onEnter: (_) => setState(() {
                            hoveredPromptId = prompt.id; // Track hovered prompt
                          }),
                          onExit: (_) => setState(() {
                            hoveredPromptId = null; // Reset hovered prompt
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200), // Smooth transition
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Colors.blueGrey.shade100 // Light color on hover
                                  : Colors.white, // Default background
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                      ? Colors.blueGrey.shade300 // Highlight shadow on hover
                                      : Colors.black26,
                                  blurRadius: 4.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              title: Text(
                                prompt.title,
                                style: const TextStyle(color: Colors.black),
                              ),
                              subtitle: Text(
                                prompt.text,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              onTap: () {
                                // Handle prompt selection if necessary
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.black87,
                                    onPressed: () => _editPrompt(prompt),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deletePrompt(prompt.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
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
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Enter new prompt text',
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
