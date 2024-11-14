import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:crimebook/components/delete_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:crimebook/controllers/user_controller.dart';
import 'package:crimebook/components/colors_file.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final UserController userController = Get.find<UserController>();

  // Text controllers for the profile fields
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  String? selectedGender = 'Male';
  DateTime? createdAt;
  File? selectedImage;
  String? profileImageUrl;

  bool isProfileUpdated = false;
  bool isLoading = false; // For loading indicator
  bool hasChanged = false; // To track if any changes were made

  // List of valid Indian states
  final List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Puducherry'
  ];

  // Variables to hold original data for comparison
  String originalName = '';
  String originalPhone = '';
  String originalState = '';
  String originalDob = '';
  String originalGender = '';
  String? originalProfileImageUrl;

  @override
  void initState() {
    super.initState();

    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      DocumentSnapshot userDoc =
      await firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = userData['firstName'] ?? '';
          emailController.text = userData['email'] ?? '';
          phoneController.text = userData['phone'] ?? '';
          stateController.text = userData['state'] ?? '';
          dobController.text = userData['dob'] != null &&
              userData['dob'] != 'Not provided'
              ? DateFormat('dd/MMM/yyyy').format(DateTime.parse(userData['dob']))
              : '';

          profileImageUrl = userData['profileImageUrl'];

          if (userData['gender'] == 'Male' ||
              userData['gender'] == 'Female' ||
              userData['gender'] == 'Others') {
            selectedGender = userData['gender'];
          } else {
            selectedGender = 'Male';
          }

          createdAt = (userData['createdAt'] as Timestamp?)?.toDate();

          originalName = nameController.text;
          originalPhone = phoneController.text;
          originalState = stateController.text;
          originalDob = dobController.text;
          originalGender = selectedGender!;
          originalProfileImageUrl = profileImageUrl;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> saveUserProfile() async {
    if (!hasChanged) {
      Get.snackbar(
        'No Changes Detected',
        'No changes were made to your profile.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange[300],
        colorText: Colors.black,
        icon: const Icon(Icons.info, color: Colors.black),
        duration: const Duration(milliseconds: 100),
      );
      Get.offNamed('/main');
      return;
    }

    if (phoneController.text.isNotEmpty &&
        phoneController.text != 'Not provided') {
      // Validate phone number format
      final phoneRegExp = RegExp(r'^\+91\d{10}$');
      if (!phoneRegExp.hasMatch(phoneController.text)) {
        Get.snackbar(
          'Error',
          'Phone number must be in the format +91XXXXXXXXXX.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
        return;
      }
    }

    // if (stateController.text.isNotEmpty &&
    //     stateController.text != 'Not provided') {
    //   // Make validation case-insensitive
    //   String inputState = stateController.text.toLowerCase();
    //   List<String> lowerCaseStates =
    //   indianStates.map((state) => state.toLowerCase()).toList();
    //   if (!lowerCaseStates.contains(inputState)) {
    //     Get.snackbar(
    //       'Error',
    //       'Please enter a valid Indian state.',
    //       snackPosition: SnackPosition.BOTTOM,
    //       backgroundColor: Colors.red[100],
    //     );
    //     return;
    //   } else {
    //     int index = lowerCaseStates.indexOf(inputState);
    //     stateController.text = indianStates[index];
    //   }
    // }

    setState(() {
      isLoading = true;
    });

    String? uploadedImageUrl;
    if (selectedImage != null) {
      try {
        final ref = storage.ref().child('profile_pictures/${user!.uid}');
        UploadTask uploadTask = ref.putFile(selectedImage!);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print('Task state: ${snapshot.state}');
          print('Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
        }, onError: (e) {
          print('Error during upload: $e');
          Get.snackbar(
            'Image Upload Failed',
            'There was a problem uploading your profile picture. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
          );
        });

        TaskSnapshot taskSnapshot = await uploadTask;
        uploadedImageUrl = await taskSnapshot.ref.getDownloadURL(); // Get image URL
      } catch (e) {
        print('Error uploading image: $e');
        Get.snackbar(
          'Image Upload Failed',
          'There was a problem uploading your profile picture. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
      }
    }




    // Proceed with saving the profile if validation passes
    try {
      await firestore.collection('users').doc(user!.uid).set({
        'firstName': nameController.text,
        'phone': phoneController.text.isNotEmpty
            ? phoneController.text
            : 'Not provided',
        'state': stateController.text.isNotEmpty
            ? stateController.text
            : 'Not provided',
        'dob': dobController.text.isNotEmpty
            ? DateFormat('dd/MMM/yyyy')
            .parse(dobController.text)
            .toIso8601String()
            : 'Not provided',
        'gender': selectedGender ?? 'Male',
        'email': emailController.text,
        'profileImageUrl': uploadedImageUrl ?? originalProfileImageUrl,
      }, SetOptions(merge: true));

      setState(() {
        isProfileUpdated = true;
      });

      Get.snackbar(
        'Profile Updated',
        'Your profile has been updated successfully!',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: true,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        duration: const Duration(seconds: 3),
        forwardAnimationCurve: Curves.easeOutBack,
        overlayBlur: 1.5,
        borderRadius: 20,
      );

      // Simulate a delay to show the loading indicator
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        isLoading = false; // Stop loading indicator
        hasChanged = false; // Reset hasChanged after saving
        // Update original values to current values
        originalName = nameController.text;
        originalPhone = phoneController.text;
        originalState = stateController.text;
        originalDob = dobController.text;
        originalGender = selectedGender!;
        originalProfileImageUrl = uploadedImageUrl ?? profileImageUrl;
      });

      Get.offNamed('/main');
    } catch (e) {
      print('Error saving user data: $e');
      setState(() {
        isLoading = false; // Stop loading indicator
      });
    }
  }

  // Method to pick profile picture from system
  Future<void> pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
        hasChanged = true; // Mark as changed
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dobController.text.isNotEmpty
          ? DateFormat('dd/MMM/yyyy').parse(dobController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('dd/MMM/yyyy').format(pickedDate);
        if (dobController.text != originalDob) {
          hasChanged = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {


    Color? blue = Colors.transparent;
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
                isDarkMode? Colors.black.withOpacity(0.6) : Colors.blue.withOpacity(0.6),
                isDarkMode? Colors.black.withOpacity(0.1) : Colors.blue.withOpacity(0.01),
              ],
              stops: const [0.0, 1.0], // The gradient covers the entire height
            ),
          ),
        ),
        // Login Form content
        Scaffold(
          // backgroundColor: blue,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: blue,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: saveUserProfile,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
          body: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          color: blue,
                        ),
                        Positioned(
                          top: 60,
                          left: MediaQuery.of(context).size.width / 2 - 69,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!)
                                : profileImageUrl != null
                                ? NetworkImage(profileImageUrl!) as ImageProvider
                                : const AssetImage('assets/images/profile_icon.png'),
                          ),
                        ),
                        Positioned(
                          top: 130,
                          right: MediaQuery.of(context).size.width / 2 - 90,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.red),
                              onPressed:
                              pickProfilePicture, // Pick profile picture from the system
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildProfileField('Name', 'Enter your name', nameController),
                          buildProfileField('Email', 'Enter your email',
                              emailController,
                              isEnabled: false),
                          buildProfileField(
                              'Phone', 'Enter your phone number', phoneController),
                          buildProfileField('State', 'Enter your state', stateController),
                          buildDOBField(
                              'D.O.B', 'Enter your date of birth', dobController),
                          buildGenderDropdown(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Member Since ${createdAt != null ? DateFormat('yyyy').format(createdAt!) : 'N/A'}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const DeleteAccountButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Loading indicator
              if (isLoading)
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

  Widget buildProfileField(String label, String placeholder,
      TextEditingController controller,
      {bool isEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label :',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: TextFormField(
              controller: controller,
              enabled: isEnabled, // Disable email field
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                if (label == 'Name' && value != originalName) {
                  setState(() {
                    hasChanged = true;
                  });
                } else if (label == 'Phone' && value != originalPhone) {
                  setState(() {
                    hasChanged = true;
                  });
                } else if (label == 'State' && value != originalState) {
                  setState(() {
                    hasChanged = true;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Gender :',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: DropdownButtonFormField<String>(
              value: selectedGender,
              items: ['Male', 'Female', 'Others'].map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedGender = newValue;
                  if (selectedGender != originalGender) {
                    hasChanged = true;
                  }
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDOBField(String label, String placeholder,
      TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label :',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: pickDate,
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
