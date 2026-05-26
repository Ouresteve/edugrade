import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../main.dart';


class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme; 
  const SettingsScreen({super.key, required this.toggleTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false; // Will connect to real theme later

  // Teacher profile (loaded from DB)
  String teacherName = "";
  String schoolName = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();

  }

  Future<void> _loadTeacherProfile() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('teacher', limit: 1);

      if (result.isNotEmpty) {
        final data = result.first;
        setState(() {
          teacherName = (data['full_name'] as String) ?? "";
          schoolName = (data['school_name'] as String) ?? "";
          phone = (data['phone'] as String)  ?? "";
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppTheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          const Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(teacherName.isNotEmpty ? teacherName : "Teacher Name"),
              subtitle: Text(schoolName.isNotEmpty ? schoolName : "School Name"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editProfile,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App Preferences
          const Text("Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Dark Mode Toggle
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Switch between light and dark theme"),
            value: isDarkMode,
            onChanged: (value) {
              setState(() => isDarkMode = value);
              widget.toggleTheme(); // 
            },
          ),

          const Divider(),

          // CBC Configuration
          ListTile(
            leading: const Icon(Icons.grade, color: Colors.orange),
            title: const Text("CBC Grading Configuration"),
            subtitle: const Text("Edit grade boundaries"),
            onTap: () {
              Navigator.pushNamed(context, '/cbc_config');
            },
          ),

          // Student Settings
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.blue),
            title: const Text("Student Configuration"),
            subtitle: const Text("Admission number, fields, etc."),
            onTap: () {
              Navigator.pushNamed(context, '/student_config');
            },
          ),

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About EduGrade"),
            subtitle: const Text("Version 1.0.0"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "EduGrade",
                applicationVersion: "1.0.0",
                applicationLegalese: "Offline CBC Grading for Kenyan Teachers",
            
              );
            },
          ),
        ],
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
            } else if (index==1) {
                Navigator.pushNamedAndRemoveUntil(context, '/group', (route) => false,);
            }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 4,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Class"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "settings"),
        ],
      ),
    );
  }

   void _editProfile() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditProfileBottomSheet(
        currentName: teacherName,
        currentSchool: schoolName,
        currentPhone: phone,
        currentEmail: "", // Add email if you have it in DB
      ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'teacher',
          {
            'full_name': result['full_name'],
            'school_name': result['school_name'],
            'phone': result['phone'],
            'email': result['email'],
          },
          where: 'id = 1', // Assuming first teacher
        );

        setState(() {
          teacherName = result['full_name'] ?? teacherName;
          schoolName = result['school_name'] ?? schoolName;
          phone = result['phone'] ?? phone;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating profile: $e")),
          );
        }
      }
    }
  }
}


class EditProfileBottomSheet extends StatefulWidget {
  final String currentName;
  final String currentSchool;
  final String currentPhone;
  final String currentEmail;

  const EditProfileBottomSheet({
    super.key,
    required this.currentName,
    required this.currentSchool,
    required this.currentPhone,
    required this.currentEmail,
  });

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _schoolController = TextEditingController(text: widget.currentSchool);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  Widget build(BuildContext context) {

      // 1. Define this key at the top of your State class (outside the build method)
final _formKey = GlobalKey<FormState>();

// 2. Your updated layout code:
return Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    left: 24,
    right: 24,
    top: 24,
  ),
  child: Form(
    key: _formKey, // Attach the form key here
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Changed to TextFormField to use the validator
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Full Name is required"; // Error message
            }
            return null; // Valid
          },
        ),
        const SizedBox(height: 10),

        // Changed to TextFormField to match styling and future validation
        TextFormField(
          controller: _schoolController,
          decoration: const InputDecoration(labelText: "School Name", border: OutlineInputBorder()),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
                return "School name is required";
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Email (Optional)", border: OutlineInputBorder()),
        ),


          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'full_name': _nameController.text.trim(),
                  'school_name': _schoolController.text.trim(),
                  'phone': _phoneController.text.trim(),
                  'email': _emailController.text.trim(),
                });
              },
              child: const Text("Save Changes"),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
);
  }
}
