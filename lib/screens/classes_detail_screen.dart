import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'add_student_screen.dart';  
import '../globals.dart'; 
import 'classes_screen.dart';
import 'enter_marks.dart';
class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final bool triggerAddStudent;

  const ClassDetailScreen({
    super.key,
   required this.classData,
   this.triggerAddStudent = false,
   
   });


  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  String selectedTerm = "Term 1";
  List<Map<String, dynamic>> students = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    if (widget.triggerAddStudent){
    WidgetsBinding.instance.addPostFrameCallback((_){
      _addStudent();
    });
  }
  }
  


  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'students',
        where: 'class_id = ?',
        whereArgs: [widget.classData['id']],
      );
      setState(() {
        students = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addStudent() async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddStudentBottomSheet(classId: widget.classData['id'], className: widget.classData['class_name']),
    );

    if (success == true) {
      _loadStudents(); // Refresh student list
    }
  }
  
  // ===EDIT CLASS===
  Future<void>_editClass() async {
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),
      builder: (context) => EditClassBottomSheet(currentName: widget.classData['class_name']),

    );
    if(newName !=null && newName.trim().isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'classes',
        {'class_name': newName.trim()},
        where: 'id = ?',
        whereArgs: [widget.classData['id']],
      );
      Navigator.pushReplacementNamed(context, '/home');
      setState((){
        updatedName = newName.trim();
        widget.classData['class_name'] = newName.trim();
      });
      if (mounted) {
         Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class name updated")),
      );
      }

      
    }

  }

  // Enter Marks
  Future<void> _enterMarks() async {
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EnterMarksScreen(classData: widget.classData),
    ),
  );
  }

  //===DELETE STUDENT===
  Future<void>_deleteStudent(int studentId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student?"),
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
      await db.delete('students', where: 'id = ?', whereArgs:[studentId]);
      _loadStudents();
    }
  }


  @override
  Widget build(BuildContext context) {
    final cls = widget.classData;

    return Scaffold(
      appBar: AppBar(
        title: Text(cls['class_name'] ?? "Class"),
        elevation: 0,
        actions: [ 
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editClass,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.school, size: 45, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls['class_name'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          Text("${cls['level']} • ${cls['academic_year'] ?? '2026'}",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Term Selector
            const Text("Term", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Term 1", label: Text("Term 1")),
                ButtonSegment(value: "Term 2", label: Text("Term 2")),
                ButtonSegment(value: "Term 3", label: Text("Term 3")),
              ],
              selected: {selectedTerm},
              onSelectionChanged: (Set<String> selection) {
                setState(() => selectedTerm = selection.first);
              },
            ), 

            const SizedBox(height: 28),

            // Analytics Cards
            const Text("Performance Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAnalyticCard("Total Students", "${students.length}", "", Colors.blue),
                const SizedBox(width: 12),
                _buildAnalyticCard("Avg Score", "0%", "↑ 3%", Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAnalyticCard("Top 3 Subjects", "MAT, ENG, KISW", "", Colors.orange),
                const SizedBox(width: 12),
                _buildAnalyticCard("Below Expectations", "7", "Students", Colors.red),
              ],
            ),

            const SizedBox(height: 32),
            // Quick Actions Updated 
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
               _buildActionCard(Icons.person_add, "Add Student", Colors.blue, onTap: _addStudent),
                _buildActionCard(Icons.edit_note, "Enter Marks", Colors.green, onTap: _enterMarks),
                _buildActionCard(Icons.people, "View All Students", Colors.indigo),
                _buildActionCard(Icons.picture_as_pdf, "Generate Report", Colors.red),
              ],
              
            ),
            //=====Updated fr====
            // Quick Actions
           /* const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.3,
              children: [
                _buildActionButton(Icons.person_add, "Add Student", Colors.blue, onTap: _addStudent),
                _buildActionButton(Icons.edit_note, "Enter Marks", Colors.green, onTap: _enterMarks),
                _buildActionButton(Icons.people, "View All Students", Colors.indigo),
                _buildActionButton(Icons.picture_as_pdf, "Generate Report", Colors.red),
              ],
            ),
*/
            const SizedBox(height: 32),

            // Students List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Students", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),
            const SizedBox(height: 8),

            if (students.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text("No students added yet")),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text("${student['class_id']}" ), // to modify later to read position
                      ),
                      title: Text(student['full_name']),
                      subtitle: Text("Adm No: ${student['admission_number'] ?? 'N/A'}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,color: Colors.red),
                        onPressed: () => _deleteStudent(student['id'], student['full_name']),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticCard(String title, String value, String change, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              if (change.isNotEmpty) Text(change, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildActionCard(
    IconData icon,
    String label, 
    Color color,
    {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      // FIX: Add padding around the card container edges
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20, // Slightly reduced radius from 24 to save vertical space
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24), // Scale down icon slightly
          ),
          const SizedBox(height: 6), // Tightened spacer height from 8 to 6
          
          // FIX: Wrap inside a Flexible widget to handle text cleanly
          Flexible(
            child: Text(
              label, 
              textAlign: TextAlign.center, 
              maxLines: 2, // Limits lines to prevent endless pushing down
              overflow: TextOverflow.ellipsis, // Safely cuts off text if too long
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );
}

}


//Edit Class Bottom Sheet
class EditClassBottomSheet extends StatefulWidget {
  final String currentName;
  const EditClassBottomSheet({super.key, required this.currentName});

  @override
  State<EditClassBottomSheet> createState() => _EditClassBottomSheetState();
}
class _EditClassBottomSheetState extends State<EditClassBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Class Name", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText:"Class Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              
              onPressed: () => Navigator.pop(context, _controller.text.trim()),            
          
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }
}