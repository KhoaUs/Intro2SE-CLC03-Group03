import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PromptLibrary_2 extends StatelessWidget {
  final FirebaseAuth auth;
  // Constructor chính của Widget
  const PromptLibrary_2({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Library',
            style: TextStyle(
              fontSize: 24, // Kích thước chữ
              fontWeight: FontWeight.bold, // Chữ đậm
              letterSpacing: 1.5, // Khoảng cách giữa các ký tự
            )),
        centerTitle: true, // Canh giữa
        backgroundColor: Colors.blueAccent, // Màu AppBar
      ),
      body: Column(
        children: [
          // Subtitle
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Manage and access your prompts easily!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),

          // Row chứa nút "+" và thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // Nút "+"
                IconButton(
                  icon: const Icon(Icons.add, size: 30, color: Colors.blueAccent),
                  onPressed: () {
                    // TODO: Thêm chức năng thêm prompt
                    print('Add new prompt');
                  },
                ),
                // Thanh tìm kiếm
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search prompts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Danh sách hiển thị Prompt
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Giả lập có 10 prompt
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('Prompt ${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: const Text('This is a sample prompt description.'),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // TODO: Thêm chức năng tùy chỉnh
                        print('Options for prompt ${index + 1}');
                      },
                    ),
                    onTap: () {
                      // TODO: Thêm chức năng khi click prompt
                      print('Selected prompt ${index + 1}');
                    },
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
