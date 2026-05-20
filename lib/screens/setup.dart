import 'package:edugrade/globals.dart';
import 'package:edugrade/screens/cbc_config.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'loading_dialog.dart';
import 'package:sqflite/sqflite.dart';

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();

}


class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  Future<void>_saveTeacherProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    //LoadingDialog.show(context, message: "Saving your profile...");

    try {
      final db = await DatabaseHelper.instance.database;

      await db.insert('teacher', {
        'full_name': _nameController.text.trim(),
        'school_name':_schoolController.text.trim(),
        'email': _emailController.text.trim(),
        'phone':_phoneController.text.trim(),
      });
      
      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully!")),
        );
        continuingOnboarding = true; 
        await db.insert('tracker', {
          'key': 'continuingOnboarding',
          'value': '$continuingOnboarding',
        }, conflictAlgorithm: ConflictAlgorithm.replace); 
        // Set the flag to indicate we're continuing onboarding
        //Navigate to dashboard here!
        //Navigator.pushReplacementNamed(context, '/cbc_config');
        Navigator.pushReplacement(context, 
                  MaterialPageRoute(
                    builder: (_) => const CbcConfigScreen(),
                  ),
                  );
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
  Widget build(BuildContext  context) {
    return Scaffold (
    appBar: AppBar(
      title: const Text(
        "Teacher Setup",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          ),
        ),
      backgroundColor: AppTheme.primary,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key:_formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's get you started!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),

            ),
            const SizedBox(height: 8),
            const Text(
              "This information will help personalize EduGrade experience for you.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText:"Full Name *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? "Name is required": null,

              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: "School Name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) => value!.isEmpty ? "School name is required": null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType:  TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTeacherProfile,
                  child: const Text(
                    "Next",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
                  ],
        ),
      ),
    ),
    );
  
  }
}