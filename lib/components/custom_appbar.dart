import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crimebook/components/colors_file.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? profileImageUrl;
  bool isDarkMode = true;

  CustomAppBar({this.profileImageUrl}); // Constructor to accept profile image URL

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 55, // Shorter height for the AppBar
      backgroundColor: isDarkMode? darkModeHead : lightModeHead,
      title: Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 12), // Adjusted padding for shorter height
        child: Text(
          'CrimeBook',
          style: GoogleFonts.poppins(
              letterSpacing: 1.2,
              fontSize: 22,  // Adjust font size to fit with shorter height
              color: Colors.white,
              fontWeight: FontWeight.w500
          ),
        ),
      ),
      actions: [
        // Translate Icon with Styling
        // Padding(
        //   padding: const EdgeInsets.only(top: 12.0, right: 17),
        //   child: GestureDetector(
        //     onTap: () {
        //       // Language button functionality
        //     },
        //     child: const Icon(
        //       Icons.translate,
        //       color: Colors.white,
        //     ),
        //   ),
        // ),

        // Profile Avatar with Dynamic Image URL
        GestureDetector(
          onTap: (){
            _showProfileMenu(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 12),
            child: Container(
              height: 35,  // Adjust height for the avatar container
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode? Color(0xFF0C0D10) : Colors.blue,
                borderRadius: BorderRadius.circular(30), // Rounded container
                border: Border.all(
                  color: Colors.white, // Border color
                  width: 1.5, // Border width
                ),
              ),
              child: Row(
                children: [
                  // Profile Image inside a Circle with dynamic URL
                  Padding(
                    padding: const EdgeInsets.only(right: 1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), // Match the corners to the container
                      child: Image(
                        image: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!) as ImageProvider
                            : const AssetImage('assets/images/profile_icon.png'),
                        width: 28, // Set width for the profile image
                        height: 28, // Set height for the profile image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Dropdown Icon with rounded background
                  GestureDetector(
                    onTap: () {
                      _showProfileMenu(context); // Profile menu action
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 1.0), // Add padding for the icon
                      decoration: BoxDecoration(
                        color: isDarkMode? Color(0xFF0C0D10) : Colors.blue,
                        shape: BoxShape.circle, // Make the icon container rounded
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down, // Dropdown arrow icon
                        color: Colors.white, // Icon color (same as background)
                        size: 22, // Adjust the icon size
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ],
    );
  }

  // Override the preferredSize method to ensure the AppBar height is correct
  @override
  Size get preferredSize => const Size.fromHeight(65); // Shorter preferred height

  // Profile menu with logout and profile options
  void _showProfileMenu(BuildContext context) {
    String clientId;
    if (kIsWeb) {
      clientId = '512034669842-bh4du1cn6ktlphs838ekrso9qbbbdp7a.apps.googleusercontent.com';
    } else if (Platform.isAndroid) {
      clientId = '512034669842-ol5qgo378t1a6spor7m4uqa2ekf5t4p1.apps.googleusercontent.com';
    } else {
      clientId = 'YOUR_IOS_CLIENT_ID';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: 80.0,  // Adjust this based on the shorter AppBar height
              right: 20.0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('My Profile'),
                        onTap: () {
                          Get.toNamed('/profile');  // Navigating to profile screen using GetX
                        },
                      ),
                      // const Divider(height: 1, color: Colors.black),
                      // ListTile(
                      //   leading: const Icon(Icons.person),
                      //   title: const Text('Theme'),
                      //   onTap: () {
                      //     Get.toNamed('/profile');  // Navigating to profile screen using GetX
                      //   },
                      // ),
                      const Divider(height: 1, color: Colors.black),
                      ListTile(
                        leading: const Icon(Icons.feedback),
                        title: const Text('Feedback'),
                        onTap: () {
                          Get.toNamed('/feedback');  // Navigating to profile screen using GetX
                        },
                      ),
                      const Divider(height: 1, color: Colors.black),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Log out'),
                        onTap: () async {
                          GoogleSignIn googleSignIn = GoogleSignIn(clientId: clientId);
                          if (await googleSignIn.isSignedIn()) {
                            await googleSignIn.signOut();
                            await googleSignIn.disconnect();
                          }
                          await FirebaseAuth.instance.signOut();
                          Get.offAllNamed('/login'); // Navigate to login screen after logout
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
