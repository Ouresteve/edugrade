import 'package:edugrade/globals.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'loading_dialog.dart';
import '../globals.dart';
import'../services/app_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


class StudentConfigScreen extends StatefulWidget {
  const StudentConfigScreen({super.key});

  @override
  State<StudentConfigScreen> createState() => _StudentConfigScreenState();
}

class _StudentConfigScreenState extends State<StudentConfigScreen> {
  bool _isLoading = false;

  
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    //LoadingDialog.show(context, message: "Saving preferences...");

    try {
      final db = await DatabaseHelper.instance.database;

      // Save each setting
      final settings = [
        {'key': 'use_admission_number', 'value': useAdmissionNumber.toString()},
        
      ];

      for (var setting in settings) {
        await db.insert('settings', setting, 
          conflictAlgorithm: ConflictAlgorithm.replace);
      }

      if (mounted) {
        await FirebaseAnalytics.instance.logEvent(
  name: 'setup_completed',
  parameters: {'school_name': schoolName},
);
        
        if (continuingOnboarding)  {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Setup completed! ")),
        );
          continuingOnboarding = false;

        await db.insert('tracker', {
          'key': 'continuingOnboarding',
          'value': '$continuingOnboarding',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        
        await AppState.checkTeacherProfile();
         } // Refresh teacher profile to update onboarding status
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      //LoadingDialog.hide(context);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Student Information Setup", 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("These settings can be changed later in Settings"),
            
            const SizedBox(height: 32),

            const Text("ID System", style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<bool>(
              title: const Text("Use Admission Number (Recommended)"),
              value: true,
              groupValue: useAdmissionNumber,
              onChanged: (val) => setState(() => useAdmissionNumber = val!),
            ),
            RadioListTile<bool>(
              title: const Text("Use Auto-generated ID"),
              value: false,
              groupValue: useAdmissionNumber,
              onChanged: (val) => setState(() => useAdmissionNumber = val!),
            ),

            const Divider(height: 40),
            const Divider(height: 40),

// Add this block:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            "About ID System",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        
        "The above option helps in identifying each student uniquely,"
         "use of auto-generated Id means the app will provide unique identification for each student, use of Admission Number means  You will enter unique addmission Numbers manually, schools with consistent use of admission number are therefore recommended  to use addmission numbers.",
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
      ),
    ],
  ),
),

//const Text("Additional Fields", style: TextStyle(fontWeight: FontWeight.bold)),
// ... your CheckboxListTiles

            
            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                child: const Text("Finish Setup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}