import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CheckLogsScreen extends StatefulWidget {
  @override
  _CheckLogsScreenState createState() => _CheckLogsScreenState();
}

class _CheckLogsScreenState extends State<CheckLogsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String selectedActionType = 'all';

  // List of action types for filtering
  final List<String> actionTypes = [
    'all',
    'account_creation',
    'profile_update',
    'account_deletion',
    // Add other action types as needed
  ];

  @override
  Widget build(BuildContext context) {
    // Build the query based on the selected filters
    Query activityLogsQuery = firestore.collection('activity_logs');

    if (selectedActionType != 'all') {
      activityLogsQuery =
          activityLogsQuery.where('actionType', isEqualTo: selectedActionType);
    }

    // Order the logs by timestamp, most recent first
    activityLogsQuery = activityLogsQuery.orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Activity Logs',
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
          // Filters Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedActionType,
              items: actionTypes.map((String actionType) {
                return DropdownMenuItem<String>(
                  value: actionType,
                  child: Text(actionType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedActionType = newValue!;
                });
              },
              decoration: InputDecoration(
                labelText: '',
                labelStyle: TextStyle(
                  color: Colors.white60,
                  letterSpacing: 4,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white60,
              ),
            ),
          ),
          // Logs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: activityLogsQuery.snapshots(),
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

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'No activity logs found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var log = logs[index];
                    var data = log.data() as Map<String, dynamic>;

                    String actionType = data['actionType'] ?? 'Unknown Action';
                    String userId = data['userId'] ?? 'Unknown User';
                    String details = data['details'] ?? '';
                    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
                    String adminId = data['adminId'] ?? '';

                    DateTime dateTime = timestamp.toDate();
                    String formattedDate =
                    DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

                    return Card(
                      color: Colors.grey[900],
                      margin:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: ListTile(
                        title: Text(
                          actionType,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID: $userId',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (adminId.isNotEmpty)
                              Text(
                                'Admin ID: $adminId',
                                style: TextStyle(color: Colors.white70),
                              ),
                            if (details.isNotEmpty)
                              Text(
                                'Details: $details',
                                style: TextStyle(color: Colors.white70),
                              ),
                            Text(
                              'Timestamp: $formattedDate',
                              style: TextStyle(color: Colors.white70),
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
