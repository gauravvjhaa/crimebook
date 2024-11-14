import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimebook/app_screens/safety_alert_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:crimebook/components/colors_file.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:crimebook/components/custom_appbar.dart';
import 'package:crimebook/components/colors_file.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  // final NewsScreen newsScreen = NewsScreen();
  // final HomeScreen homeScreen = HomeScreen();
  // final AlertScreen safetyAlertsScreen = AlertScreen();

  // bool isDarkMode = true;

  int _selectedIndex = 0;
  String apiKey =
      dotenv.env['NEWS_API_KEY'] ?? '';
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    // Restore the system UI when the widget is disposed
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            profileImageUrl = userData['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Load the appropriate screen based on index
  Widget _getScreenByIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return NewsScreen();
      case 2:
        return AlertScreen();

      default:
        return const Center(child: Text('Invalid screen index'));
    }
  }


  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode? darkModeBody : lightModeBody,
      appBar: CustomAppBar(profileImageUrl: profileImageUrl,),
      body: _getScreenByIndex(_selectedIndex),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        height: 60,
        animationCurve: Curves.linear,
        animationDuration: const Duration(milliseconds: 300),
        color: isDarkMode? Color(0xFF0C0D10) : Colors.blue,
        onTap: (index){
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          Icon(Icons.home, color: Colors.white,),
          Icon(Icons.favorite, color: Colors.white,),
          Icon(Icons.notifications, color: Colors.white,),
        ],
      ),
    );
  }

}
