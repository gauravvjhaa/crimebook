import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DeleteAccountButton extends StatefulWidget {
  const DeleteAccountButton({Key? key}) : super(key: key);

  @override
  _DeleteAccountButtonState createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _showDeleteAccountDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[800],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: const Text(
        'Delete Account',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background for the dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              '⚠️ Delete Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade300, Colors.red.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView( // To prevent overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'We are sorry to see you go.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Could you please tell us why you want to delete your account?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Your reason',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Grey color for cancel button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black, // Black text
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // Red accent for delete
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: _confirmDeletion,
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white, // White text
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeletion() async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      Get.snackbar(
        'Reason Required',
        'Please provide a reason for deleting your account.',
        backgroundColor: Colors.red[100],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Get the current user (assuming user is logged in)
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userId = user.uid;
        final email = user.email ?? '';
        final scheduledDeletionDate = DateTime.now().add(const Duration(days: 30));
        final formattedDate = DateFormat('dd MMM yyyy').format(scheduledDeletionDate);

        // Add deletion request to 'deletions' collection
        await firestore.collection('deletions').doc(userId).set({
          'userId': userId,
          'email': email,
          'deletionScheduledOn': Timestamp.fromDate(scheduledDeletionDate), // Changed here
          'deletionReason': reason,
          'requestedAt': Timestamp.now(), // Changed here
        });

        // Update user's document in 'users' collection
        await firestore.collection('users').doc(userId).update({
          'deletionScheduledOn': Timestamp.fromDate(scheduledDeletionDate), // Changed here
        });

        Navigator.of(context).pop(); // Close the delete account dialog

        // Show confirmation dialog with the same theme and block user interaction
        _showBlockingConfirmationDialog(formattedDate);
      }
    } catch (e) {
      print('Error scheduling account deletion: $e');
      Get.snackbar(
        'Error',
        'Failed to schedule account deletion. Please try again.',
        backgroundColor: Colors.red[100],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showBlockingConfirmationDialog(String formattedDate) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      barrierColor: Colors.black.withOpacity(0.5), // Dimmed background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: Center(
            child: AlertDialog(
              backgroundColor: Colors.white, // White background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Center(
                child: Text(
                  'Account Deletion Scheduled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.red.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your account has been scheduled for deletion.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Scheduled Deletion Date: $formattedDate',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'You will be logged out shortly.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Delay for 5 seconds before logging out
    Future.delayed(const Duration(seconds: 4), () async {
      // Close the dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Sign the user out and navigate to login
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/login');
    });
  }
}
