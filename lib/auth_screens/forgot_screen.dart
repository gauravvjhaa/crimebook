import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLinkSent = false; // Track if the link has been sent
  bool isEmailAUser = true; // Track if the email is a registered user
  bool isProcessing = false; // Track if the process is ongoing

  // Method to check if email exists in Firestore users collection
  Future<bool> checkIfEmailExists(String email) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return result.docs.isNotEmpty; // Return true if email exists, false otherwise
  }

  // Handle Forgot Password process
  handleForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        print('Password reset link sent to $email');
        setState(() {
          isLinkSent = true; // Update the button text and color
        });
        Get.snackbar(
          'Success',
          'Password reset link sent to $email',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else {
          errorMessage = 'An error occurred. Please try again later.';
        }

        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'An unknown error occurred. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  // Method to validate email and send link if valid
  validateAndSendLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isProcessing = true; // Show a loading state
    });

    // Check if email exists in Firestore users collection
    bool emailExists = await checkIfEmailExists(email);
    setState(() {
      isProcessing = false; // Stop loading
      isEmailAUser = emailExists;
      isLinkSent = emailExists; // If email exists, mark link sent
    });

    if (isEmailAUser) {
      // If email exists, send reset link and update UI
      handleForgotPassword();
    } else {
      // If email does not exist, show error and update button
      setState(() {
        isLinkSent = false;
      });
      Get.snackbar(
        'Error',
        'Entered email is not a user',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/delhi-blast.jpeg'),
                opacity: 0.6,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.85),
                  Colors.blue.withOpacity(0.1),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // Forgot Password Form content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Lock icon at the top
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 60,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Instruction text
                    const Text(
                      'Enter e-mail to receive reset link',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    // Email input field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your e-mail',
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        prefixIcon: const Icon(Icons.email, color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Send Link button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : validateAndSendLink, // Disable button if processing
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isProcessing
                              ? Colors.grey
                              : isLinkSent
                              ? Colors.lightGreenAccent
                              : isEmailAUser
                              ? const Color(0xFF276EF1)
                              : Colors.redAccent, // Change color based on state
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          isLinkSent
                              ? 'Link Sent'
                              : isEmailAUser
                              ? 'Send Link'
                              : 'Try Again',
                          style: TextStyle(
                            fontSize: 18,
                            color: isLinkSent || isEmailAUser ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed('/login');
                      },
                      child: const Text(
                        'Click here to go back to Login',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
