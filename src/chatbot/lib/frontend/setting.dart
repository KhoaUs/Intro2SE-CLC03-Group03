import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/db/user.dart'; // Replace with your correct path
import '../backend/config/logger.dart';

class SettingsPage extends StatefulWidget {
  final FirebaseAuth auth;

  const SettingsPage({Key? key, required this.auth}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  MyUser? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = widget.auth.currentUser;
    if (user == null) {
      // If no user is signed in, navigate to login
      Navigator.of(context).pushReplacementNamed('/signin');
      return;
    }

    try {
      MyUser? userData = await MyUser.getUserFromFirestore(user.uid);
      if (userData != null) {
        setState(() {
          currentUser = userData;
        });
        MyLogger.i('User info loaded');
      }
    } catch (e) {
      MyLogger.e('Error loading user info: $e');
    }
  }

  Future<void> _logOut() async {
    try {
      await widget.auth.signOut();
      Navigator.of(context).pushReplacementNamed('/signin');
      MyLogger.i('User logged out');
    } catch (e) {
      MyLogger.e('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Name: ${currentUser!.name}'),
            Text('Plan: ${currentUser!.plan}'),
            Text('Token: ${currentUser!.token}'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _logOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}