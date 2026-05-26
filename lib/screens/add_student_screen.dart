import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import '../globals.dart';   // for useAdmissionNumber
import 'package:sqflite/sqflite.dart';

class AddStudentBottomSheet extends StatefulWidget {
  final int classId;
  final String className;   // We'll pass this from Class Detail

  const AddStudentBottomSheet({
    super.key, 
    required this.classId,
    required this.className,
  });

  @override
  State<AddStudentBottomSheet> createState() => _AddStudentBottomSheetState();
}

class _AddStudentBottomSheetState extends State<AddStudentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _admissionController = TextEditingController();

  bool isLoading = false;

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;

      final data = {
        'full_name': _nameController.text.trim(),
        'class_name': widget.className,
        'class_id': widget.classId,
      };

      // Handle Admission Number
      if (useAdmissionNumber) {
        final admNo = _admissionController.text.trim();
        if (admNo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Admission number is required")),
          );
          return;
        }
        data['admission_number'] = admNo;
      } else {
        // Auto generate simple sequential number
        final last = await db.query('students', orderBy: 'id DESC', limit: 1);
        int nextNum = 1;

        if (last.isNotEmpty && last.first['admission_number'] != null) {
          try {
            nextNum = int.parse(last.first['admission_number'].toString()) + 1;
          } catch (_) {}
        }
        data['admission_number'] = nextNum.toString().padLeft(4, '0');
      
      }

      await db.insert('students', data);
      await db.update(
        'classes',
        {'student_count': await _getStudentCount(db, widget.classId)},
        where: 'id = ?',
        whereArgs: [widget.classId],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student added successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('UNIQUE') 
              ? "Admission number already exists!" 
              : "Error adding student")),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
       
  }
  Future<int> _getStudentCount(Database db, int classId) async {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM students WHERE class_id = ?',
        [classId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Student", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name *",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.trim().isEmpty ? "Full name is required" : null,
            ),
            const SizedBox(height: 20),

            if (useAdmissionNumber)
              TextFormField(
                controller: _admissionController,
                decoration: const InputDecoration(
                  labelText: "Admission Number *",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty ? "Admission number required" : null,
              )
            else
              TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  labelText: "Admission Number",
                  border: OutlineInputBorder(),
                ),
                initialValue: "Auto-generated",
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveStudent,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Student"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}