import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crimebook/admin/log_impl.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers for input fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController adminCodeController = TextEditingController(); // Controller for admin code

  DateTime? dob; // Optional
  String? selectedGender; // Optional
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Gender dropdown options
  final List<String> genderOptions = ['Male', 'Female', 'Others'];

  // Role dropdown options
  String selectedRole = 'User'; // Default role
  final List<String> roleOptions = ['User', 'Admin'];

  // Function to handle form submission
  handleSignup() async {
    // Extract trimmed values from text fields
    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String state = stateController.text.trim();
    final String adminCode = adminCodeController.text.trim();

    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      // Additional checks for Admin role
      if (selectedRole == 'Admin' && adminCode != 'crimebook') {
        Get.snackbar(
          'Error',
          'Invalid admin secret code',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.5),
          colorText: Colors.white,
        );
        return; // Stop execution if admin code is incorrect
      }

      try {
        setState(() {
          _isLoading = true;
        });

        // Create a new user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the user's UID
        final uid = userCredential.user?.uid;

        // Prepare user data
        Map<String, dynamic> userData = {
          'email': email,
          'createdAt': Timestamp.now(),
          'profileImageUrl': null,
          'role': selectedRole,
          'firstName': '$firstName $lastName',
          'dob':'Not Provided',
          'gender': selectedGender ?? 'Not Provided',
          'state': state.isNotEmpty,
          'status': 'unbanned',
          'preferences': {
            'categories': ['india', 'crime'],
            'sources': ['bbc-news',],
            'keywords': ['crime', 'india']
          }
        };

        // Add optional fields for User role
        if (selectedRole == 'User') {
          userData.addAll({
            'dob': dob?.toIso8601String() ?? 'Not provided',
            'gender': selectedGender ?? 'Not provided',
            'state': state.isNotEmpty ? state : 'Not provided',
          });
        }

        // Add user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        await logActivity(
          userId: userCredential.user!.uid,
          actionType: 'account_creation',
          details: 'User account created with email $email',
        );

        setState(() {
          _isLoading = false;
        });

        print('User Created and Database Initialized successfully');
        Get.offNamed('/wrapper', arguments: null);

        // Show success snackbar
        Get.snackbar(
          'Success',
          'User has been signed up and data saved!',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error snackbar
        Get.snackbar(
          'SignUp Error',
          e.code,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.5),
          colorText: Colors.white,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Handle any errors and show error snackbar
        Get.snackbar(
          'Error',
          'Failed to sign up: $e',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.5),
          colorText: Colors.white,
        );
      }
    } else {
      // Show error snackbar for missing fields
      Get.snackbar(
        'Error',
        'Please fill in all compulsory fields',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red.withOpacity(0.5),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background image and overlay (same as before)
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/delhi-blast.jpeg'),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
              ),
            ),
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
            // Signup Form Content
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * .05),
                      // Title and subtitle (same as before)
                      Text(
                        'CrimeBook',
                        style: TextStyle(
                          letterSpacing: 3,
                          fontSize: screenWidth * 0.095,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(2.0, 4.0),
                              blurRadius: 30.0,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Stay Informed',
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(1.5, 1.5),
                                blurRadius: 30.0,
                                color: Colors.black.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Stay ',
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            color: Colors.white,
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
                              text: 'Safer.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1.5, 1.5),
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // First Name and Last Name fields (same as before)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                hintText: 'First Name',
                                hintStyle: const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18.0, horizontal: 20.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                hintText: 'Last Name',
                                hintStyle: const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18.0, horizontal: 20.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Email field (same as before)
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 18.0),
                            child: Icon(Icons.email, color: Colors.black54),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password field with visibility toggle (same as before)
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 18.0),
                            child: Icon(Icons.lock, color: Colors.black54),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Role selection dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                        ),
                        value: selectedRole,
                        items: roleOptions.map((String role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedRole = newValue!;
                            // Clear admin code and optional fields when role changes
                            adminCodeController.clear();
                            dob = null;
                            selectedGender = null;
                            stateController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Conditional fields based on selected role
                      if (selectedRole == 'User') ...[
                        // Date of Birth
                        GestureDetector(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                dob = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 13.0, horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dob != null
                                      ? '${dob!.toLocal()}'.split(' ')[0]
                                      : 'Date of Birth (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: dob != null
                                        ? Colors.black87
                                        : Colors.black54,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 13.0, horizontal: 20.0),
                          ),
                          hint: const Text('Gender (Optional)',
                              style: TextStyle(color: Colors.black54)),
                          value: selectedGender,
                          items: genderOptions.map((String gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedGender = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        // State field
                        TextField(
                          controller: stateController,
                          decoration: InputDecoration(
                            hintText: 'State/UT (Optional)',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18.0, horizontal: 20.0),
                          ),
                        ),
                      ] else if (selectedRole == 'Admin') ...[
                        // Admin Secret Code field
                        TextField(
                          controller: adminCodeController,
                          decoration: InputDecoration(
                            hintText: 'Enter Admin Secret Code',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18.0, horizontal: 20.0),
                          ),
                        ),
                      ],
                      const SizedBox(height: 35),
                      // Signup Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.7,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                handleSignup();
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                backgroundColor: const Color(0xFF276EF1),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                                backgroundColor: Color(0xFF276EF1),
                              )
                                  : const Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // OR divider (same as before)
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
                      // Already have an account? Login (same as before)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.toNamed('/login');
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login',
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
                      const SizedBox(height: 40),
                    ],
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
