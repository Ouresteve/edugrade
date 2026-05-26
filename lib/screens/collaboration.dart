import 'package:flutter/material.dart';
import 'theme.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups & Collaboration"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
           if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(context, '/class', (route) => false);
            } else if (index== 3) {
              Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
            } else if (index==0) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false,);
            } else if (index == 4) {
              Navigator.pushNamedAndRemoveUntil(context, '/settings', (route)=> false);
            }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Class"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "settings"),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.groups, size: 120, color: Colors.blue),
            ),
            const SizedBox(height: 24),

            const Text(
              "Coming Soon",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Collaborate with other teachers",
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            const Text(
              "What’s Coming in Next Update:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildFeatureItem(
              Icons.share_outlined,
              "Share Class Data",
              "Allow subject teachers to submit marks directly to your class",
            ),
            _buildFeatureItem(
              Icons.school,
              "School Workspace",
              "Connect all teachers in your school under one account",
            ),
            _buildFeatureItem(
              Icons.sync,
              "Real-time Sync",
              "See updates instantly when colleagues enter marks (when online)",
            ),
            _buildFeatureItem(
              Icons.lock_outline,
              "Permission Control",
              "Decide who can view or edit your class data",
            ),
            _buildFeatureItem(
              Icons.notifications_active,
              "Smart Notifications",
              "Get notified when marks are submitted to your class",
            ),

            const SizedBox(height: 40),

            const Text(
              "This feature is currently under development.\n\n"
              "We are working hard to bring seamless collaboration to Kenyan teachers.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                child: const Text("Got it, Thanks!"),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}