import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';


class HomeScreenAdmin extends StatelessWidget {
  HomeScreenAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Admin Portal',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 6,
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            children: <Widget>[
              MenuCard(
                text: 'View All Users',
                icon: Icons.people,
                onTap: () {
                  Get.toNamed('/adminViewUsers');
                },
              ),
              MenuCard(
                text: 'Sync User Deletions',
                icon: Icons.sync,
                onTap: () {
                  Get.toNamed('/adminSyncDeletions');
                },
              ),
              MenuCard(
                text: 'Check Logs',
                icon: Icons.book,
                onTap: () {
                  Get.toNamed('/adminCheckLogs');
                },
              ),
              MenuCard(
                text: 'User Feedbacks',
                icon: Icons.feedback,
                onTap: () {
                  Get.toNamed('/adminUserReports');
                },
              ),
              MenuCard(
                text: 'Add Crime Data',
                icon: Icons.book,
                onTap: () {
                  Get.toNamed('/addCrimeData');
                },
              ),
              MenuCard(
                text: 'Log Out',
                icon: Icons.logout,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAllNamed('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are logged out')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const MenuCard({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.shade100, Colors.redAccent.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
