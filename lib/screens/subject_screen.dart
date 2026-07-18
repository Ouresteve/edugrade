import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../globals.dart';
import '../widgets/app_loading_view.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Map<String, dynamic>> subjects = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('subjects',
                                    where:'category=?',
                                    whereArgs: [selectedLevel],
                                    orderBy: 'subject_code ASC',
                                    );
      setState(() {
        subjects = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading subjects: $e")),
        );
      }
    }
  }

  Future<void> _addNewSubject() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddSubjectBottomSheet(),
    );

    if (result != null) {
      final db = await DatabaseHelper.instance.database;
      for(var subject in subjects) {
        if(subject['subject_code'] == result['subject_code'] && subject['category'] == result['category']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Subject code already exists for this level."),
            )
,
          );
          return;
        }
      }
      await db.insert('subjects', result, conflictAlgorithm: ConflictAlgorithm.replace);
      _loadSubjects();
    }
  }

  Future<void> _deleteSubject(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Subject?"),
        content: Text("Are you sure you want to delete $code?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
      _loadSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subjects", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewSubject,
        icon: const Icon(Icons.add),
        label: const Text("New Subject"),
      ),

      body: isLoading
          ? Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Center(
                child: AppLoadingView(
                  title: "Loading subjects",
                  subtitle: "We are preparing the subject list for this level.",
                  icon: Icons.school_rounded,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

              Padding(
                              padding: const EdgeInsets.all(16.0),
                              key: const ValueKey('header_padding'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("School Level", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: "LP", label: Text("Lower Primary")),
                                      ButtonSegment(value: "UP", label: Text("Upper Primary")),
                                      ButtonSegment(value: "Js", label: Text("Junior Secondary")),
                                    ],
                                    selected: {selectedLevel},
                                    onSelectionChanged: (Set<String> selection) {
                                      setState(() => selectedLevel = selection.first);
                                      _loadSubjects();
                                    },
                                  ),
                                ],
                              ),
                            ),
              Expanded(

              child: subjects.isEmpty ?  

                const Center(
                      child: Text(
                        "No subjects saved for this Level ",
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                      
                      ),
                    )
                :ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal:16),
                itemCount: subjects.length,
  
                itemBuilder:  (context, index) {
                    final sub = subjects[index];
                    final isDefault = sub['is_default'] == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        sub['subject_code'],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    title: Text(sub['subject_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sub['category'] ?? 'Core'),
                    trailing: //isDefault
                        //? const Icon(Icons.lock, color: Colors.grey) // Can't delete default subjects
                         IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteSubject(sub['id'], sub['subject_code']),
                          ),
                    onLongPress: isDefault ? null : () => _deleteSubject(sub['id'], sub['subject_code']),
                  ),
                );
              },
            ),
            ),
            ],
            ),


    );

}
}
// ================== Add New Subject Bottom Sheet ==================
class AddSubjectBottomSheet extends StatefulWidget {
  const AddSubjectBottomSheet({super.key});

  @override
  State<AddSubjectBottomSheet> createState() => _AddSubjectBottomSheetState();
}

class _AddSubjectBottomSheetState extends State<AddSubjectBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  String category = (selectedLevel == "Js") ? "Js" : (selectedLevel == "UP") ? "UP" : "LP";


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
            const Text("Add New Subject", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Subject Code",
                hintText: "e.g. PHY, HST",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.trim().isEmpty ? "Code required" : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Subject Name",
                hintText: "e.g. Physics, History",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.trim().isEmpty ? "Name required" : null,
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: "School Level",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "UP", child: Text("Upper Primary")),
                DropdownMenuItem(value: "LP", child: Text("Lower Primary")),
                DropdownMenuItem(value: "Js", child: Text("Junior Secondary (JSS)")),
              ],
              onChanged: (value) => setState(() => category = value!),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'subject_code': _codeController.text.trim().toUpperCase(),
                      'subject_name': _nameController.text.trim(),
                      'category': category,
                      'is_default': 0,
                    });
                  }
                },
                child: const Text("Add Subject"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}