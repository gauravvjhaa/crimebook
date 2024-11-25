import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

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
    // Detect theme
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Stack(
      children: [
        // Background image
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/delhi-blast.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.blue.withOpacity(0.4),
          ),
        ),
        // Semi-transparent gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, // Start the gradient at the top
              end: Alignment.bottomCenter, // End the gradient at the bottom
              colors: [
                isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : Colors.blue.withOpacity(0.6),
                isDarkMode
                    ? Colors.black.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.01),
              ],
              stops: const [0.0, 1.0], // The gradient covers the entire height
            ),
          ),
        ),
        // Main content
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'CrimeBook',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 4,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Animated feedback icon
                    Icon(
                      Icons.feedback,
                      size: 100,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'We value your feedback!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 6,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Write your feedback here...',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Theme(
                          data: ThemeData(
                            unselectedWidgetColor: Colors.white,
                          ),
                          child: Checkbox(
                            value: _isAnonymous,
                            activeColor: Colors.red,
                            checkColor: Colors.white,
                            onChanged: (bool? value) {
                              setState(() {
                                _isAnonymous = value ?? false;
                              });
                            },
                          ),
                        ),
                        Text(
                          'Submit anonymously',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : submitUserFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? SpinKitFadingCircle(
                          color: Colors.black,
                          size: 24.0,
                        )
                            : Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: SpinKitFadingCircle(
                      color: Colors.white,
                      size: 60.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
