import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions using MediaQuery (for responsiveness)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Navigate to the login page after 10 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed('/wrapper', arguments: null);
    });

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
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // Start the gradient at the top
                end: Alignment.bottomCenter, // End the gradient at the bottom
                colors: [
                  Colors.blue.withOpacity(0.85), // More blue at the top
                  Colors.blue.withOpacity(0.1), // Less blue at the bottom
                ],
                stops: const [0.0, 1.0], // The gradient covers the entire height
              ),
            ),
          ),
          // Centered text
          Center(
            child: Text(
              'CrimeBook',
              style: TextStyle(
                fontSize: screenWidth * 0.1, // Responsive font size
                fontWeight: FontWeight.bold, // Bold text
                color: Colors.white, // Text color is white
              ),
            ),
          ),
        ],
      ),
    );
  }
}
