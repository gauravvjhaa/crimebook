import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserController extends GetxController {
  var profileImageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfileImageUrl();
  }

  // Method to fetch the profileImageUrl from Firestore
  Future<void> fetchProfileImageUrl() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user's document from the 'users' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Set the profileImageUrl if it's available
      if (userDoc.exists && userDoc['profileImageUrl'] != null) {
        profileImageUrl.value = userDoc['profileImageUrl'];
      } else {
        // Set a default or empty value if not available
        profileImageUrl.value = '';
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
      profileImageUrl.value = '';
    }
  }
}
