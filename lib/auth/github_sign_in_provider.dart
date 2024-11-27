import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:github_oauth/github_oauth.dart';
import 'package:flutter/material.dart';

class GitHubAuthService {
  final GitHubSignIn gitHubSignIn;

  GitHubAuthService()
      : gitHubSignIn = GitHubSignIn(
    clientId: dotenv.env['GITHUB_CLIENT_ID'] ?? '',
    clientSecret: dotenv.env['GITHUB_CLIENT_SECRET'] ?? '',
    redirectUrl: dotenv.env['GITHUB_REDIRECT_URL'] ?? '',
  );

  Future<void> loginWithGitHub(BuildContext context) async {
    try {
      // Trigger the GitHub OAuth login process
      final result = await gitHubSignIn.signIn(context);

      print('GitHubSignInResult: $result');


      if (result.status == GitHubSignInResultStatus.ok) {
        // Successfully logged in
        final String? token = result.token;
        final Map<String, dynamic>? userProfile = result.userProfile;

        final String username = userProfile?['login'] ?? 'Unknown';
        final String? profileUrl = userProfile?['avatar_url'];

        // Save user details to Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(username)
            .set({
          'username': username,
          'token': token ?? 'No Token',
          'profile_url': profileUrl ?? 'No Profile URL',
          'createdAt': Timestamp.now(),
          'role': 'User',
          'preferences': {
            'categories': ['india', 'crime'],
            'sources': ['bbc-news'],
            'keywords': ['crime', 'india']
          }
        });

        Get.snackbar(
          'Success',
          'Logged in successfully as $username',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.green.withOpacity(0.6),
          colorText: Colors.white,
        );

        // Navigate to home or wrapper
        Get.offAllNamed('/wrapper');
      } else {
        // Handle login errors
        Get.snackbar(
          'Error',
          result.errorMessage ?? 'Unknown error occurred',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.5),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }
}
