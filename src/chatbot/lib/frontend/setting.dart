import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/db/user.dart'; // Replace with your correct path
import '../backend/config/logger.dart';

class SettingsPage extends StatefulWidget {
  final FirebaseAuth auth;

  const SettingsPage({super.key, required this.auth});

  // Expose the settings dialog as a static method for reuse
  static void openSettingsDialog(BuildContext context, FirebaseAuth auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SettingsPage(auth: auth),
    );
  }

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  MyUser? currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Load current user info
  Future<void> _loadUserInfo() async {
    final user = widget.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pop(); // Close the settings dialog
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
      _showErrorMessage('Failed to load user information. Please try again.');
    }
  }

  // Dialog Header
  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // General Settings Tab
  Widget _buildGeneralSettingsContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Center( // Center the content
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make the column size as small as possible
                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
                children: [
                  const Text(
                    'General Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Name: ${currentUser!.name}',
                    style: const TextStyle(fontSize: 18), // Increased font size
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan: ${currentUser!.plan}',
                    style: const TextStyle(fontSize: 18), // Increased font size
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Token: ',
                          style: TextStyle(fontSize: 18), // Phần "Token:" giữ nguyên định dạng
                        ),
                        TextSpan(
                          text: currentUser!.plan == 'Pro' ? 'Unlimited' : currentUser!.token.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: currentUser!.plan == 'Pro' ? FontWeight.bold : FontWeight.normal,
                            color: currentUser!.plan == 'Pro' ? const Color.fromARGB(255, 56, 25, 109) : Colors.black,
                            fontStyle: currentUser!.plan == 'Pro' ? FontStyle.normal : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _loadUserInfo();
                      _showSuccessMessage('User data refreshed');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16), // Increased font size for button
                    ),
                    child: const Text('Refresh User Data'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _logOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16), // Increased font size for button
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Upgrade Plan Tab
  Widget _buildUpgradePlanContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column size as small as possible
        mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
        children: [
          const Text(
            'Upgrade Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your plan to access premium features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16), // Increased font size
          ),
          const SizedBox(height: 20),
          // Plan Boxes with Expanded for equal distribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), // Add some space between the boxes
                  child: _buildPlanBox('Free Plan', [
                    'Access to basic features',
                    'Limited usage of premium features',
                    'Community support only',
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Add some space between the boxes
                  child: _buildPlanBox('Pro Plan  -  \$20', [
                    'All basic features',
                    'Unlimited premium feature usage',
                    'Priority customer support',
                    'Exclusive access to new features',
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(  // Center the "Upgrade to Pro" button
            child: ElevatedButton(
              onPressed: _showBankCredentialsDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Upgrade to Pro'),
            ),
          ),
        ],
      ),
    );
  }

  // Plan Box Widget
  Widget _buildPlanBox(String planName, List<String> benefits) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2, // Calculate width for both boxes
      decoration: BoxDecoration(
        color: planName == 'Pro Plan  -  \$20' ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: planName == 'Pro Plan  -  \$20' ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (var benefit in benefits)
            Text('• $benefit', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Upgrade Plan Logic
  Future<void> _upgradePlan() async {
    try {
      // Get the current user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.auth.currentUser!.uid)
          .get();

      // Check if the current user already has the 'Pro' plan
      if (userDoc.exists && userDoc['plan'] == 'Pro') {
        // If the user is already on the 'Pro' plan, show a message and do nothing
        _showErrorMessage('You are already on the Pro plan!');
        return;
      }

      // Update the plan to 'Pro' and token to a large value in the Firestore database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.auth.currentUser!.uid)
          .update({'plan': 'Pro', 'token': 999999999});

      // Update the current user plan and token in local state
      setState(() {
        if (currentUser != null) {
          currentUser!.plan = 'Pro'; // Update plan to Pro
          currentUser!.token = 999999999; // Update token to 'Unlimited' (large value)
        }
      });

      MyLogger.i('User upgraded to Pro plan');
      _showSuccessMessage('Plan upgraded successfully!');
    } catch (e) {
      MyLogger.e('Error upgrading plan: $e');
      _showErrorMessage('Failed to upgrade plan. Please try again later.');
    }
  }


  // Logout
  Future<void> _logOut() async {
    try {
      await widget.auth.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
      MyLogger.i('User signed out');
    } catch (e) {
      MyLogger.e('Error signing out: $e');
      _showErrorMessage('Sign-out failed. Please try again.');
    }
  }

  // Error Message Dialog
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(15),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

    // Error Message Dialog
  void _showSuccessMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(15),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Success",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBankCredentialsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController bankNameController = TextEditingController();
        final TextEditingController accountNumberController = TextEditingController();
        final TextEditingController cvvController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text(
            'Enter Bank Credentials',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cvvController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Validate inputs
                    final bankName = bankNameController.text.trim();
                    final accountNumber = accountNumberController.text.trim();
                    final cvv = cvvController.text.trim();

                    if (bankName.isEmpty || accountNumber.isEmpty || cvv.isEmpty) {
                      _showErrorMessage('Please fill in all fields.');
                      return;
                    }

                    // Simulate bank credentials processing
                    _processBankCredentials(bankName, accountNumber, cvv);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate Credentials'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the credentials dialog
                    _upgradePlan(); // Call the upgrade plan process
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Complete Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Process Bank Credentials (Simulated)
  void _processBankCredentials(String bankName, String accountNumber, String cvv) {
    try {
      // Simulate payment processing
      MyLogger.i('Processing payment with bank: $bankName');
      _showSuccessMessage('Bank credentials validated. Your Pro plan is activated!');
    } catch (e) {
      MyLogger.e('Error processing payment: $e');
      _showErrorMessage('Failed to process payment. Please try again later.');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Set fixed dialog dimensions
    const dialogWidth = 600.0; // Fixed width for the dialog
    const dialogHeight = 500.0; // Fixed height for the dialog

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                maxHeight: dialogHeight,
                minWidth: 300, // Minimum width for small screens
                minHeight: 300, // Minimum height for small screens
              ),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensure it takes only necessary space
                  children: [
                    // Dialog Header
                    _buildDialogHeader(),
                    const Divider(height: 1),
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'General'),
                        Tab(text: 'Upgrade Plan'),
                      ],
                    ),
                    // TabBarView wrapped with Expanded
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            child: _buildGeneralSettingsContent(),
                          ),
                          SingleChildScrollView(
                            child: _buildUpgradePlanContent(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}