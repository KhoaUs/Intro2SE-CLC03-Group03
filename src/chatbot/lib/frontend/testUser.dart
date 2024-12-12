import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/db/user.dart'; // Update with the correct path to your User model.

class UserInfoPage extends StatefulWidget {
  final String userId; // Add userId as a parameter.

  UserInfoPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  User? user; // Use a single user variable instead of a list.

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  // Fetch user data by UID.
  Future<void> _fetchUser() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId) // Fetch the user by UID
        .get();

    if (userDoc.exists) {
      setState(() {
        user = User.fromMap(userDoc.data()!); // Use the User.fromMap to convert the data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Loading...' : 'User Information'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  title: Text(user!.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${user!.id}'),
                      Text('Plan: ${user!.plan}'),
                      Text('Tokens: ${user!.token}'),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
