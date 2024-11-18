import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatefulWidget {
  @override
  _AdminFeedbackScreenState createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String feedbackSearch = '';

  @override
  Widget build(BuildContext context) {
    // Build the query based on the search filters
    Query feedbackQuery = firestore.collection('feedback');

    // Order the feedback by submission date, most recent first
    feedbackQuery = feedbackQuery.orderBy('submittedAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'User Feedback',
          style: TextStyle(
            color: Colors.white60,
            letterSpacing: 4,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Search Feedback Text Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  feedbackSearch = value.trim();
                });
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search Feedback Text',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white24,
              ),
            ),
          ),
          // Feedback List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: feedbackQuery.snapshots(),
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

                List<DocumentSnapshot> feedbackDocs = snapshot.data?.docs ?? [];

                // Client-side filtering for feedback text search (inefficient)
                if (feedbackSearch.isNotEmpty) {
                  feedbackDocs = feedbackDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String feedbackText = data['feedbackText'] ?? '';
                    return feedbackText
                        .toLowerCase()
                        .contains(feedbackSearch.toLowerCase());
                  }).toList();
                }

                if (feedbackDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No feedback found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: feedbackDocs.length,
                  itemBuilder: (context, index) {
                    var feedbackDoc = feedbackDocs[index];
                    var data = feedbackDoc.data() as Map<String, dynamic>;

                    String userId = data['userId'] ?? 'Unknown User';
                    String feedbackText = data['feedbackText'] ?? '';
                    Timestamp submittedAt = data['submittedAt'] ?? Timestamp.now();
                    String userEmail = data['userEmail'] ?? '';
                    String userName = data['userName'] ?? '';

                    DateTime dateTime = submittedAt.toDate();
                    String formattedDate =
                    DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

                    return Card(
                      color: Colors.grey[900],
                      margin:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: ListTile(
                        title: Text(
                          userName.isNotEmpty ? userName : 'User ID: $userId',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userEmail.isNotEmpty)
                              Text(
                                'Email: $userEmail',
                                style: TextStyle(color: Colors.white70),
                              ),
                            Text(
                              'Submitted At: $formattedDate',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 8),
                            Text(
                              feedbackText,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
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
