import 'package:crimebook/auth_screens/emailverify_screen.dart';
import 'package:crimebook/auth_screens/forgot_screen.dart';
import 'package:crimebook/auth_screens/login_screen.dart';
import 'package:crimebook/auth_screens/signup_screen.dart';
import 'package:crimebook/auth_screens/splash_screen.dart';
import 'package:crimebook/auth/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'admin/add_data.dart';
import 'admin/admin_home.dart';
import 'admin/check_for_deletion.dart';
import 'admin/check_logs.dart';
import 'admin/user_feedback.dart';
import 'admin/view_users.dart';
import 'app_screens/feedback_screen.dart';
import 'app_screens/main_screen.dart';
import 'app_screens/news_detail_screen.dart';
import 'app_screens/profile_screen.dart';
import 'controllers/user_controller.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');
  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCETQ3NIwtI5C6IAFKKx-DvOmKuYsqYUE8',
        appId: '1:512034669842:android:500b9c741b985d6b519fcb',
        messagingSenderId: '512034669842',
        projectId: 'crimedataindia',
        storageBucket: 'crimedataindia.appspot.com',
      ),
    );
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.put(UserController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => SplashScreen()),
        GetPage(name: '/wrapper', page: () => const Wrapper()),
        GetPage(name: '/login', page: () => const LogInScreen()),
        GetPage(name: '/forgotPassword', page: () => ForgotPasswordScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/emailVerification', page: () => const EmailVerifyScreen()),
        GetPage(name: '/main', page: () => MainScreen()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(name: '/particularNews', page: () => NewsDetailScreen()),
        GetPage(name: '/adminPanel', page: () => HomeScreenAdmin()),
        GetPage(name: '/adminViewUsers', page: () => ViewUsers()),
        GetPage(name: '/adminSyncDeletions', page: () => DeletionRequestsScreen()),
        GetPage(name: '/adminCheckLogs', page: () => CheckLogsScreen()),
        GetPage(name: '/adminUserReports', page: () => AdminFeedbackScreen()),
        GetPage(name: '/feedback', page: () => FeedbackScreen()),
        GetPage(name: '/addCrimeData', page: () => AddDataPage()),
      ],
    );

  }
}
