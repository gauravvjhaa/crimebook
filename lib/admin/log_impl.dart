import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> logActivity({
  required String userId,
  required String actionType,
  String? details,
  String? adminId,
}) async {
  try {
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'userId': userId,
      'actionType': actionType,
      'timestamp': Timestamp.now(),
      'details': details ?? '',
      'adminId': adminId ?? '',
    });
  } catch (e) {
    print('Error logging activity: $e');
    // Optionally handle errors, e.g., report to a logging service
  }
}
