import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:crimebook/components/loader.dart';
import 'package:url_launcher/url_launcher.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // User is authenticated
            if (snapshot.hasData) {
              User user = snapshot.data!;
              if (user.emailVerified) {
                _checkForDeletionRequest(user);
              } else {
                Future.microtask(() => Get.offAllNamed('/emailVerification'));
              }
            } else {
              Future.microtask(() => Get.offAllNamed('/login'));
            }
          }

          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/delhi-blast.jpeg'),
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.withOpacity(0.85),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFadingCircle(
                      color: Colors.black,
                      size: 50,
                    ),
                    SizedBox(height: 20), // Spacing between progress indicator and text
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkForDeletionRequest(User user) async {
    try {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          // Check if user is banned
          String status = userData['status']?.toString().toLowerCase() ?? 'unbanned';
          if (status == 'banned') {
            _showBannedDialog();
            return;
          }

          // Check for account deletion request
          if (userData.containsKey('deletionScheduledOn')) {
            var deletionTimestamp = userData['deletionScheduledOn'];
            DateTime deletionDate;
            if (deletionTimestamp is Timestamp) {
              deletionDate = deletionTimestamp.toDate(); // Convert Timestamp to DateTime
            } else if (deletionTimestamp is String) {
              deletionDate = DateTime.parse(deletionTimestamp); // Parse if it's a string
            } else {
              throw Exception("Invalid deletionScheduledOn format.");
            }
            _showDeletionDialog(user, deletionDate);
          } else {
            // Proceed based on the user's role
            String role = userData['role']?.toString().toLowerCase() ?? 'user';
            if (role == 'admin') {
              // Navigate to admin panel
              Future.microtask(() => Get.offAllNamed('/adminPanel'));
            } else {
              // Navigate to main screen
              Future.microtask(() => Get.offAllNamed('/main'));
            }
          }
        }
      } else {
        // User document does not exist in Firestore
        // Default to user role and navigate accordingly
        Future.microtask(() => Get.offAllNamed('/main'));
      }
    } catch (e) {
      print('Error fetching user data: $e');
      Get.snackbar(
        'Error',
        'Failed to load user data. Please try again.',
        backgroundColor: Colors.red[100],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showBannedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from closing when tapped outside
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              '⚠️ Account Banned',
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
                colors: [Colors.redAccent, Colors.deepOrangeAccent],
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
                  'Your account has been banned.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Please contact support for further assistance or click below for help.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'gauravkumarjha306@gmail.com',
                      queryParameters: {
                        'subject': 'Support: Account Banned Assistance'
                      },
                    );
                    await launchUrl(emailLaunchUri);
                  },
                  child: const Text(
                    'Email Support: gauravkumarjha306@gmail.com',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      // Sign out the banned user and take them to the login screen
                      await FirebaseAuth.instance.signOut();
                      Get.offAllNamed('/login');
                    },
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      // Open WhatsApp with a pre-filled message to the specified phone number
                      final Uri whatsappUri = Uri.parse(
                          'https://wa.me/919354897359?text=Hello, I need assistance regarding my banned account.'
                      );
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(whatsappUri, mode: LaunchMode.inAppBrowserView);
                      } else {
                        Get.snackbar(
                          'Error',
                          'Could not open WhatsApp. Please contact support via email.',
                          backgroundColor: Colors.red[100],
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    child: const Text(
                      'WhatsApp Us',
                      style: TextStyle(
                        color: Colors.black,
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

  void _showDeletionDialog(User user, DateTime deletionDate) {
    String formattedDate = DateFormat('dd MMM yyyy').format(deletionDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              '⚠️ Account Deletion\n Pending!',
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
                colors: [Colors.orange, Colors.red],
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
                  'Your account is scheduled for deletion!',
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
                  'Would you like to cancel the deletion request and continue using your account?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      // User cancels, take them back to login
                      await FirebaseAuth.instance.signOut();
                      Get.offAllNamed('/login');
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      // User wishes to proceed, remove the deletionScheduledOn field and navigate accordingly
                      await firestore.collection('users').doc(user.uid).update({
                        'deletionScheduledOn': FieldValue.delete(),
                      });

                      // Query the 'deletions' collection to find the document with the userId equal to the current user's ID
                      QuerySnapshot deletionDocs = await firestore
                          .collection('deletions')
                          .where('userId', isEqualTo: user.uid)
                          .get();

                      // Iterate through the matching documents and delete them
                      for (QueryDocumentSnapshot doc in deletionDocs.docs) {
                        await firestore.collection('deletions').doc(doc.id).delete();
                      }

                      // Success Snack bar
                      Get.snackbar(
                        'Welcome Back',
                        'You are logged in',
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                        backgroundColor: Colors.green.withOpacity(0.9),
                        colorText: Colors.black,
                      );

                      // Navigate based on the user's role
                      DocumentSnapshot updatedUserDoc = await firestore.collection('users').doc(user.uid).get();
                      var userData = updatedUserDoc.data() as Map<String, dynamic>?;
                      String role = userData?['role']?.toString().toLowerCase() ?? 'user';

                      if (role == 'admin') {
                        showLoader(context, 2, () {
                          Get.offAllNamed('/adminPanel');  // Navigate after 2 seconds
                        });
                      } else {
                        showLoader(context, 2, () {
                          Get.offAllNamed('/main');  // Navigate after 2 seconds
                        });
                      }
                    },
                    child: const Text(
                      'Proceed to Login',
                      style: TextStyle(
                        color: Colors.black,
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


}
