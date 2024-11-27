import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/github_sign_in_provider.dart';
import '../auth/google_sign_in_provider.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  // Handle login logic
  handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9), // Red background for error
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Logged in successfully');

      Get.offAllNamed('/wrapper', arguments: null);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Error',
        e.code,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9), // Red background for error
        colorText: Colors.white,
      );
    } catch (e) {
      print('Login Error: $e');
      Get.snackbar(
        'Login Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.9), // Red background for error
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
            // Login Form content
            Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 35 : 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Title Text with shadow
                          Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CrimeBook',
                                  style: TextStyle(
                                    letterSpacing: 3,
                                    fontSize: screenWidth * 0.095, // Responsive text size
                                    fontWeight: FontWeight.bold, // Bold for the title
                                    color: Colors.white, // White text color
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(2.0, 4.0), // Horizontal and vertical offset
                                        blurRadius: 30.0, // How blurry the shadow is
                                        color: Colors.black.withOpacity(0.8), // Shadow color and opacity
                                      ),
                                    ],
                                  ),
                                ),
                                // "Stay Informed" text with shadow
                                RichText(
                                  text: TextSpan(
                                    text: 'Stay Informed',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.07, // Responsive text size
                                      color: Colors.white, // Lighter white color for the subtitle
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1.5, 1.5), // Slightly smaller offset for subtitle
                                          blurRadius: 30.0, // Slightly less blur
                                          color: Colors.black.withOpacity(0.8), // Shadow color and opacity
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // "Stay Safer" with shadow
                                RichText(
                                  text: TextSpan(
                                    text: 'Stay ', // Normal "Stay"
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.07, // Responsive text size
                                      color: Colors.white, // Lighter white for the normal text
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1.5, 1.5),
                                          blurRadius: 30.0,
                                          color: Colors.black.withOpacity(0.8),
                                        ),
                                      ],
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'Safer.', // "Safer" is bold
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, // Bold for emphasis
                                          color: Colors.white, // White color for "Safer"
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(1.5, 1.5),
                                              blurRadius: 3.0,
                                              color: Colors.black.withOpacity(0.4), // Shadow for "Safer."
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          // Email input
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12.0, right: 18.0),
                                child: Icon(Icons.person, color: Colors.black54),
                              ),
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.black54), // Black54 color for hint
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Password input
                          TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible, // Toggle password visibility
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12.0, right: 18.0),
                                child: Icon(Icons.lock, color: Colors.black54),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                                child: Icon(
                                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.black54,
                                ),
                              ),
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.black54), // Black54 color for hint
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Get.toNamed('/forgotPassword');
                              },
                              child: const Text(
                                'Forgot Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 35 : 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Login Button
                          SizedBox(
                            width: screenWidth * 0.7,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                handleLogin();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF276EF1), // Blue color
                                padding: const EdgeInsets.symmetric(vertical: 15,),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                                backgroundColor: Color(0xFF276EF1),
                              )
                                  : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // OR divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Or',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  GoogleAuthService().loginWithGoogle(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                ),
                                icon: Image.asset('assets/images/google_icon.png', height: 20),
                                label: const Text('Google'),
                              ),
                              const SizedBox(width: 10),
                              // Facebook Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  GitHubAuthService().loginWithGitHub(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4267B2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: Image.asset('assets/images/github_icon.png', height: 20),
                                label: const Text('Github'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Signup text
                          GestureDetector(
                            onTap: () {
                              Get.offNamed('/signup', arguments: null);
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.white70, fontSize: 15),
                                children: [
                                  TextSpan(
                                    text: 'SignUp',
                                    style: TextStyle(
                                      letterSpacing: 1.5,
                                      color: Colors.blue[900],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
