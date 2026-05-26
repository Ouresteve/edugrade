import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'classes_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../globals.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> student = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('classes', orderBy: 'created_at DESC');
      setState(() {
        classes = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading classes: $e")),
        );
      }
    }
  }

  Future<void> _addNewClass() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddClassBottomSheet(),
    );

    if (result != null) {
      await FirebaseAnalytics.instance.logEvent(
  name: 'class_created',
  parameters: {
    'class_name': result['class_name'],
    'level': result ['level'],
  },
);
      final db = await DatabaseHelper.instance.database;
      await db.insert('classes', result);
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Classes", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewClass,
        icon: const Icon(Icons.add),
        label: const Text("New Class"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: classes.length,
                    itemBuilder: (context, index) => _buildClassCard(classes[index]),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Classes is selected
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(context, '/class', (route) => false);
            } else if (index== 3) {
              Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
            } else if (index==0) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false,);
            }  else if (index==1) {
                Navigator.pushNamedAndRemoveUntil(context, '/group', (route) => false,);
            } else if (index==4) {
                Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false,);
            }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Classes"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 120, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            "No Classes Yet",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Create classes to start managing students and marks",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _addNewClass,
            icon: const Icon(Icons.add),
            label: const Text("Add Your First Class"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls) {
    updatedName =cls['class_name'];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(classData: cls),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opened ${cls['class_name']}")),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: const Icon(Icons.school, color: AppTheme.primary, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls['class_name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${cls['level']} • ${cls['academic_year'] ?? '2026'}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${cls['student_count']} students",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Add New Class Bottom Sheet ==================
class AddClassBottomSheet extends StatefulWidget {
  const AddClassBottomSheet({super.key});

  @override
  State<AddClassBottomSheet> createState() => _AddClassBottomSheetState();
}

class _AddClassBottomSheetState extends State<AddClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  String selectedLevel = "jss";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create New Class", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: "Class Name",
                hintText: "Form 2A, Grade 7B, 8C...",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.trim().isEmpty ? "Class name is required" : null,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(
                labelText: "School Level",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "primary", child: Text("Primary")),
                DropdownMenuItem(value: "jss", child: Text("Junior Secondary (JSS)")),
              ],
              onChanged: (value) => setState(() => selectedLevel = value!),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'class_name': _classNameController.text.trim(),
                      'level': selectedLevel,
                      'academic_year': DateTime.now().year.toString(),
                      'term': 1,
                      'student_count': 0,
                    });
                  }

                  
                },
                child: const Text("Create Class", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}