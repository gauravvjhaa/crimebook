import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:mailer/smtp_server/gmail.dart';

class ViewUsers extends StatefulWidget {
  const ViewUsers({Key? key}) : super(key: key);

  @override
  _ViewUsersState createState() => _ViewUsersState();
}

class _ViewUsersState extends State<ViewUsers> {
  final TextEditingController _searchController = TextEditingController();

  // SMTP server configuration (replace with your own credentials securely)
  final String smtpServerHost = 'smtp.gmail.com';
  final int smtpServerPort = 587;
  final String smtpUsername = 'jhakumargaurav786@gmail.com';
  final String smtpPassword = 'poaapfboidurkgni';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        // Rebuild UI when search text changes
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void toggleBanUser(
      String userId, String currentStatus, String email, String userName) async {
    String newStatus = currentStatus == 'banned' ? 'unbanned' : 'banned';
    String action = newStatus == 'banned' ? 'BAN' : 'UNBAN';

    // Show dialog to get reason
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String inputReason = '';
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Enter reason for $action',
              style: const TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              inputReason = value;
            },
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Reason',
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Return null if cancelled
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputReason.isNotEmpty) {
                  Navigator.of(context).pop(inputReason); // Return the reason
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason.'),
                    ),
                  );
                }
              },
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      // Update user status in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });

      // Send email using SMTP
      bool emailSent = await sendEmail(email, userName, action, reason);

      if (emailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${action.toLowerCase()}ned successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send email notification.'),
          ),
        );
      }
    }
  }

  Future<bool> sendEmail(
      String recipientEmail, String userName, String action, String reason) async {
    // Use the gmail() helper function
    final smtpServer = gmail(smtpUsername, smtpPassword);

    // Create the message
    final message = Message()
      ..from = Address(smtpUsername, 'CrimeBook')
      ..recipients.add(recipientEmail)
      ..subject = 'Account $action Notification'
      ..text = '''
Hello $userName,
Your account has been ${action}NED.

Reason: $reason
Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}

Regards,
Team CrimeBook
''';

    try {
      await send(message, smtpServer);
      print('Email sent to $recipientEmail');
      return true;
    } on MailerException catch (e) {
      print('Email not sent. Error: ${e.toString()}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true, // Center the title
        title: const Text(
          'View Users',
          style: TextStyle(
              color: Colors.white,
              letterSpacing: 6,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              style: TextStyle(
                color: Colors.white,
              ),
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(
                  color: Colors.white54
                ),
                hintText: 'Search by any parameter',
                hintStyle: TextStyle(
                  color: Colors.white54
                ),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'User')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter users based on search input
                String searchText = _searchController.text.toLowerCase();
                var displayedUsers = snapshot.data!.docs.where((userDoc) {
                  Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;

                  // Convert all user data values to strings and concatenate them
                  String combinedValues = userData.values
                      .map((value) => value.toString().toLowerCase())
                      .join(' ');

                  return combinedValues.contains(searchText);
                }).toList();

                if (displayedUsers.isEmpty) {
                  return const Center(child: Text('No users found', style: TextStyle(color: Colors.white54),));
                }

                return ListView.builder(
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot userDoc = displayedUsers[index];
                    Map<String, dynamic> userData =
                    userDoc.data() as Map<String, dynamic>;
                    String name = userData['firstName'] ?? 'No Name';
                    String email = userData['email'] ?? 'No Email';
                    String status = userData['status'] ?? 'unbanned';
                    String userId = userDoc.id;

                    return Card(
                      color: Colors.grey[900],
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        backgroundColor: Colors.grey[850],
                        collapsedBackgroundColor: Colors.grey[850],
                        leading: CircleAvatar(
                          backgroundColor: status == 'banned'
                              ? Colors.redAccent
                              : Colors.green,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(2),
                              },
                              children: userData.entries.map((entry) {
                                Widget keyWidget = Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                );

                                Widget valueWidget;

                                if (entry.key == 'createdAt') {
                                  DateTime? dateTime;
                                  if (entry.value is Timestamp) {
                                    dateTime =
                                        (entry.value as Timestamp).toDate();
                                  } else if (entry.value is DateTime) {
                                    dateTime = entry.value as DateTime;
                                  }

                                  String formattedDate = dateTime != null
                                      ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(dateTime)
                                      : 'Invalid date';

                                  valueWidget = Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  );
                                } else {
                                  valueWidget = Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  );
                                }

                                return TableRow(
                                  children: [keyWidget, valueWidget],
                                );
                              }).toList(),
                            ),
                          ),
                          ButtonBar(
                            alignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  toggleBanUser(
                                      userId, status, email, name);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'banned'
                                      ? Colors.green
                                      : Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  status == 'banned' ? 'UNBAN' : 'BAN',
                                  style:
                                  const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
