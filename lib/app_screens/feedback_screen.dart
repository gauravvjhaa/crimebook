import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  // Function to submit feedback
  Future<void> submitUserFeedback() async {
    setState(() {
      _isLoading = true;
    });

    String feedbackText = _feedbackController.text.trim();

    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your feedback.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String userId = _isAnonymous ? 'anonymous' : user?.uid ?? 'anonymous';
      String userEmail = '';
      String userName = '';

      if (!_isAnonymous && user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc =
        await firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic>? userData =
        userDoc.data() as Map<String, dynamic>?;

        userEmail = userData?['email'] ?? '';
        userName = userData?['firstName'] ?? '';
      }

      // Prepare feedback data
      Map<String, dynamic> feedbackData = {
        'userId': userId,
        'feedbackText': feedbackText,
        'submittedAt': Timestamp.now(),
      };

      if (!_isAnonymous) {
        feedbackData['userEmail'] = userEmail;
        feedbackData['userName'] = userName;
      }

      // Save feedback to Firestore
      await firestore.collection('feedback').add(feedbackData);

      // Optionally, log the feedback submission in the activity logs
      if (!_isAnonymous) {
        await logActivity(
          userId: userId,
          actionType: 'feedback_submission',
          details: 'User submitted feedback',
        );
      }

      // Clear the feedback form
      _feedbackController.clear();
      setState(() {
        _isAnonymous = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to log activity (assuming you have this function)
  Future<void> logActivity({
    required String userId,
    required String actionType,
    String? details,
  }) async {
    try {
      await firestore.collection('activity_logs').add({
        'userId': userId,
        'actionType': actionType,
        'timestamp': Timestamp.now(),
        'details': details ?? '',
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modern UI for the feedback screen
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Hey there!',style: TextStyle(
          color: Colors.white60,
          letterSpacing: 4,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'We value your feedback!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your feedback here...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  activeColor: Colors.blue.shade900,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAnonymous = value ?? false;
                    });
                  },
                ),
                Text(
                  'Submit anonymously',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : submitUserFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Text(
                  'Submit Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
