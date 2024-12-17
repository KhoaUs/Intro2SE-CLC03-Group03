import 'package:flutter/material.dart';
import '../../backend/db/thread.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Sidebar extends StatefulWidget {
  final List<Thread> initialThreads;
  final Function(String) onThreadSelected;
  final VoidCallback onCreateThread;  // Hàm callback để tạo thread mới

  const Sidebar({
    Key? key,
    required this.initialThreads,
    required this.onThreadSelected,
    required this.onCreateThread,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late List<Thread> threads;

  @override
  void initState() {
    super.initState();
    threads = widget.initialThreads;
  }

  // Hàm hiển thị hộp thoại đổi tên thread
  void _showRenameDialog(BuildContext context, String threadId) {
    final TextEditingController _renameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên Thread'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(labelText: 'Tên mới'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (_renameController.text.isNotEmpty) {
                _renameThread(threadId, _renameController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Hàm xác nhận xóa thread
  void _showDeleteDialog(BuildContext context, String threadId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Thread'),
        content: const Text('Bạn có chắc muốn xóa thread này không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _deleteThread(threadId);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Hàm để đổi tên thread
  Future<void> _renameThread(String threadId, String newTitle) async {
    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc('user-id')  // Thay 'user-id' bằng ID người dùng thực tế
        .collection('threads')
        .doc(threadId);

    await threadRef.update({'title': newTitle});
    setState(() {
      threads = threads.map((thread) {
        if (thread.id == threadId) {
          thread.title = newTitle;
        }
        return thread;
      }).toList();
    });
  }

  // Hàm để xóa thread
  Future<void> _deleteThread(String threadId) async {
    final threadRef = FirebaseFirestore.instance
        .collection('users')
        .doc('user-id')  // Thay 'user-id' bằng ID người dùng thực tế
        .collection('threads')
        .doc(threadId);

    await threadRef.delete();
    setState(() {
      threads.removeWhere((thread) => thread.id == threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: Column(
        children: [
          // Nút tạo thread mới
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: widget.onCreateThread,
              child: const Text("Tạo Thread Mới"),
            ),
          ),
          // Danh sách các thread
          Expanded(
            child: ListView.builder(
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return ListTile(
                  title: Text(thread.title),
                  onTap: () {
                    widget.onThreadSelected(thread.id);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút đổi tên
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showRenameDialog(context, thread.id);
                        },
                      ),
                      // Nút xóa
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteDialog(context, thread.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
