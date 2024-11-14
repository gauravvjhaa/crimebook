import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart'; // Use the appropriate SMTP server

class DeletionRequestsScreen extends StatefulWidget {
  @override
  _DeletionRequestsScreenState createState() => _DeletionRequestsScreenState();
}

class _DeletionRequestsScreenState extends State<DeletionRequestsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // SMTP server configuration (replace with your own credentials securely)
  final String smtpUsername = 'jhakumargaurav786@gmail.com';
  final String smtpPassword = 'poaapfboidurkgni';


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Deletion Requests',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 4,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .where('deletionScheduledOn', isNotEqualTo: null)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Text(
                'No deletion requests found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              DocumentSnapshot userDoc = users[index];
              Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
              String userId = userDoc.id;
              String name = userData['firstName'] ?? 'No Name';
              String email = userData['email'] ?? 'No Email';
              Timestamp? deletionScheduledOn = userData['deletionScheduledOn'];

              // Check if 'deletionScheduledOn' exists and is a Timestamp
              if (deletionScheduledOn != null) {
                DateTime deletionDate = deletionScheduledOn.toDate();

                DateTime currentDate = DateTime.now();
                bool canDelete = currentDate.isAfter(deletionDate);

                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Scheduled deletion on: ${DateFormat('dd MMM yyyy, hh:mm a').format(deletionDate)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: canDelete
                        ? IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Confirm deletion
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: Text(
                              'Confirm Deletion',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'Are you sure you want to delete this user?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                child: Text('Delete'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _deleteUserAndData(userId, email, name);
                        }
                      },
                    )
                        : null,
                  ),
                );
              } else {
                // Skip users without 'deletionScheduledOn' field
                return SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteUserAndData(
      String userId, String email, String userName) async {
    try {
      // Delete user data from Firestore
      await firestore.collection('users').doc(userId).delete();

      // Send email notification
      await sendEmail(email, userName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $userName deleted successfully')),
      );

      // To delete the user from Firebase Auth, you would need to use Firebase Admin SDK or Cloud Functions
      await _deleteAuthUser(userId);
    } catch (e) {
      print('Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  Future<void> sendEmail(String recipientEmail, String userName) async {
    final smtpServer = gmail(smtpUsername, smtpPassword);

    final message = Message()
      ..from = Address(smtpUsername, 'CrimeBook')
      ..recipients.add(recipientEmail)
      ..subject = 'Account Deletion Confirmation'
      ..text = '''
Hello $userName,

Your account has been deleted as per your request.

Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}

Regards,
Team CrimeBook
''';

    try {
      await send(message, smtpServer);
      print('Email sent to $recipientEmail');
    } on MailerException catch (e) {
      print('Email not sent. Error: $e');
      // Handle email sending error
    } catch (e) {
      print('An unexpected error occurred: $e');
      // Handle other errors
    }
  }

  Future<void> _deleteAuthUser(String userId) async {
    // This method is a placeholder. You would use Firebase Admin SDK or Cloud Functions for deleting users
    try {
      // Placeholder for deleting the Firebase Auth user via Firebase Admin SDK or Functions
      print('Request to delete user $userId from Firebase Authentication');
    } catch (e) {
      print('Error deleting user from Firebase Auth: $e');
    }
  }
}
