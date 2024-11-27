import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false; // To track the loading state
  int currentStep = 0;
  late Timer _timer;

  // Method to show the sign-in screen with progress indicator
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      // Start the loading process and show progress indicator
      _startLoadingIndicator(context);

      String clientId;
      if (kIsWeb) {
        clientId = '512034669842-bh4du1cn6ktlphs838ekrso9qbbbdp7a.apps.googleusercontent.com';
      } else if (Platform.isAndroid) {
        clientId = '512034669842-ol5qgo378t1a6spor7m4uqa2ekf5t4p1.apps.googleusercontent.com';
      } else {
        clientId = 'YOUR_IOS_CLIENT_ID';
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn(clientId: clientId).signIn();

      if (googleUser == null) {
        Get.snackbar(
          'Error',
          'Sign-in aborted by user',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.9), // Red background for error
          colorText: Colors.white,
        );
        _stopLoadingIndicator(); // Stop progress indicator
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      _stopLoadingIndicator(); // Stop progress indicator after sign-in

      if (user != null) {
        // Check if the user already exists in Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If the user doesn't exist in Firestore, initialize with default values
          String firstName = googleUser.displayName?.split(' ')[0] ?? 'Not provided';
          String lastName = googleUser.displayName!.split(' ').length > 1
              ? googleUser.displayName!.split(' ')[1]
              : 'Not provided';
          String email = googleUser.email;
          DateTime? dob;

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            // 'firstName': firstName,
            // 'lastName': lastName,
            'firstName': firstName+lastName,
            'email': email,
            'dob':'Not Provided',
            'status': 'unbanned',
            'gender': 'Not Provided',
            'state': 'Not Provided',
            'createdAt': Timestamp.now(),
            'profileImageUrl': googleUser.photoUrl,
            'role': 'User',
            'preferences': {
              'categories': ['india', 'crime'],
              'sources': ['bbc-news',],
                'keywords': ['crime', 'india']
            }
          }
          );

          Get.snackbar(
            'Success',
            'User profile created successfully',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.green.withOpacity(0.9), // Green background for success
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Success',
            'Logged in successfully',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.green.withOpacity(0.9), // Green background for success
            colorText: Colors.white,
          );
        }

        // Navigate to wrapper or home screen after successful login
        Get.offAllNamed('/wrapper');
      }
    } on FirebaseAuthException catch (e) {
      _stopLoadingIndicator(); // Stop progress indicator in case of error
      String errorMessage;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Account exists with a different credential.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'This operation is not allowed.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with these credentials.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = 'An undefined Error happened.';
      }

      Get.snackbar(
        'Login Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.5), // Red background for error
        colorText: Colors.white,
      );
    } catch (e) {
      _stopLoadingIndicator(); // Stop progress indicator in case of a general error
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.5), // Red background for error
        colorText: Colors.white,
      );
    }
  }

  // Method to start the progress indicator
  void _startLoadingIndicator(BuildContext context) {
    isLoading = true;
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      currentStep = (currentStep % 10) + 1; // Loop steps between 1 and 10
      // Redraw the UI to show the updated step progress
      (context as Element).markNeedsBuild();
    });
  }

  // Method to stop the progress indicator
  void _stopLoadingIndicator() {
    _timer.cancel();
    isLoading = false;
  }
}
