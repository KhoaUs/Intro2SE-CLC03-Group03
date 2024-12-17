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

  Future<void> _upgradePlan(BuildContext context) async {
    TextEditingController cardNumberController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    TextEditingController cvvController = TextEditingController();

    // Show a dialog to collect card information
    bool? success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upgrade to Pro Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your card details to proceed.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (MM/YY)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cvvController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Mock validation for now
                if (cardNumberController.text.isNotEmpty &&
                    expiryController.text.isNotEmpty &&
                    cvvController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: const Text('Pay \$20'),
            ),
          ],
        );
      },
    );

    if (success == true) {
      // Simulate payment and plan upgrade
      try {
        // Mock successful payment process and update plan in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.auth.currentUser!.uid)
            .update({'plan': 'Pro'});

        setState(() {
          MyUser tmpUser = MyUser(id: currentUser?.id, name: currentUser!.name, plan: 'Pro', token: currentUser!.token);

          currentUser = tmpUser;
        });

        MyLogger.i('User upgraded to Pro Plan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan upgraded successfully!')),
        );
      } catch (e) {
        MyLogger.e('Error upgrading plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upgrade plan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Name: ${currentUser!.name}'),
            Text('Plan: ${currentUser!.plan}'),
            Text('Token: ${currentUser?.plan == 'Pro' ? 'Unlimited' : currentUser?.token.toString()}'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _upgradePlan(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  currentUser!.plan == 'Pro' ? 'Already Pro' : 'Upgrade to Pro',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _logOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
