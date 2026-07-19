import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'add_student_screen.dart';  
import '../globals.dart'; 
import 'classes_screen.dart';
import 'enter_marks.dart';
import 'class_report_screen.dart';
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
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
  double averageScore = 0.0;
  String dominantGrade = "-";
  int belowExpectationsCount= 0;
  String selectedYear = DateTime.now().year.toString();

  String selectedExam = previousSelectedExam;
  String selectedTerm = previousSelectedTerm;
  List<Map<String,dynamic>> topSubjects = [];
  List<Map<String,dynamic>> subjects = [];
  List<Map<String,dynamic>> rankedStudents = [];
  List<Map<String, dynamic>> grading_config = [];
  List<Map<String, dynamic>> gradingConfig = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String,dynamic>> assess = [];
  bool isLoadingPerformance = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    
    if (widget.triggerAddStudent){
    WidgetsBinding.instance.addPostFrameCallback((_){
      _addStudent();
    });
  }
  }

  Future<void> _initializeScreen() async {
    await _loadSavedParameters();   // Load saved params FIRST
    await _loadStudents();           // Then load students with correct params
  }
  


  Future<void> _loadStudents() async {
    setState((){
      isLoading = true;
      
      isLoadingPerformance = true;
    });
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'students',
        where: 'class_id = ?',
        whereArgs: [widget.classData['id']],
        orderBy: 'full_name ASC',
      );
      students = result;
      await _calculatePerformance();

    } catch (e) {
      print("Erro loading class data: $e");
      setState(() => isLoading = false);
    } finally {
      setState(() {
        isLoading = false;
        isLoadingPerformance = false;
      });
    }
  }

  Future<void> _loadSavedParameters() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final params = await db.query('selected_parameters');
      
      for (var param in params) {
        if (param['key'] == 'selectedExam') {
          previousSelectedExam = (param['value'] as String?) ?? "EXAM 1";
        }
        if (param['key'] == 'selectedTerm') {
          previousSelectedTerm = (param['value'] as String?) ?? "Term 1";
        }
      }
      
      setState(() {
        selectedExam = previousSelectedExam;
        selectedTerm = previousSelectedTerm;
      });
    } catch (e) {
      print("Error loading saved parameters: $e");
    }
  }

Future<void> _calculatePerformance() async {
   String levelClass=widget.classData['level'];
    if (students.isEmpty) {
    setState(() {
      averageScore = 0;
      belowExpectationsCount = 0;
      
      topSubjects = [];
      rankedStudents = [];
    });
    return;
  }
  setState(() {
    isLoadingPerformance = true;
    
    });
  belowExpectationsCount = 0;
if (levelClass=="Js"){
 

  try {
  
    final db = await DatabaseHelper.instance.database;
    final gradeRes = await db.query (
      'grading_config',
      where: 'level=?',
      whereArgs: [widget.classData['level']],
    );
    final assessments = await db.query(
      'assessments',
      where: 'class_id = ? AND term = ? AND academic_year = ? AND assessment_type = ?',
      whereArgs: [widget.classData['id'],
       selectedTerm,
       selectedYear,
       selectedExam,
       ],
       
    );
    assess = assessments;
    previousSelectedExam = selectedExam;
    previousSelectedTerm = selectedTerm;
    await db.update(
      'selected_parameters',
      {
        'value': selectedExam,
      },
      where: 'key = ?',
      whereArgs: ['selectedExam'],
    );
    await db.update(
      'selected_parameters',
      {
        'value': selectedTerm,
      },
      where: 'key = ?',
      whereArgs: ['selectedTerm'],
    );

       final gradesRe = await db.query(
      'grading_config',
       where: 'level = ?',
     whereArgs: ['agp'],
    
      );
  

    final sub = await db.query(
      'subjects',
      where: 'category=?',
      whereArgs: [levelClass],

    );
    subjects = sub;

     gradingConfig = gradeRes;
     grading_config = gradesRe;

    if (assessments.isEmpty) {
      setState(() {
        averageScore = 0;
        belowExpectationsCount = 0;
        isLoadingPerformance = false;
        topSubjects = [];
        rankedStudents = students.map((s) => {...s, 'average': 0.0}).toList();
      });
      return;
    }

    double totalPoints = 0;
    
    int totalEntries = 0;

    Map<String, List<double>> subjectPoints = {};
    
    Map<int, List<double>> studentPoints= {};

    for (var a in assessments) {
      final score = (a['raw_score']as num ?? 0.0).toDouble();
      final point = _getPointsFromScore(score);
      totalPoints += point;
      
      totalEntries++;

      // Subject averages
      String subject = a['subject_code'] as String;
      subjectPoints.putIfAbsent(subject, ()=> []).add(point);
           // Student total points
      int studentId = a['student_id'] as int;
      studentPoints.putIfAbsent(studentId, () => []).add(point);
    }

    // Overall Average
    averageScore = totalEntries > 0 ? totalPoints / totalEntries : 0;

    
     

    // Top 3 Subjects
    topSubjects = subjectPoints.entries.map((e) {
      double avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'subject': e.key, 'average': avg};
    }).toList()
      ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

    if (topSubjects.length > 3) topSubjects = topSubjects.sublist(0, 3);

    // Ranked Students
    rankedStudents = students.map((s) {
      int id = s['id'];
      List<double> points = studentPoints[id] ?? [];
      double total = points.isEmpty ? 0 : points.reduce((a, b) => a + b).toDouble();
      double avgPoint = points.isEmpty ? 0 : total / points.length;
      if(total<=26.0){
        belowExpectationsCount++;
      }
      return {
        ...s,
        'totalPoints': total,
        'averagePoint': avgPoint,
      };
      
    }).toList()
      ..sort((a, b) => (b['totalPoints'] as double).compareTo(a['totalPoints'] as double));


  } catch (e) {
    print("Performance calculation error: $e");
  } finally {
    setState(() {
      isLoadingPerformance = false;
    });
  }

} else {
  // for primary classes
  try {
  
    final db = await DatabaseHelper.instance.database;
    final gradeRes = await db.query (
      'grading_config',
      where: 'level=?',
      whereArgs: ['UP'],
    );
    final assessments = await db.query(
      'assessments',
      where: 'class_id = ? AND term = ? AND academic_year = ? AND assessment_type = ?',
      whereArgs: [widget.classData['id'],
       selectedTerm,
       selectedYear,
       selectedExam,
       ],
       
    );
    assess = assessments;
    previousSelectedExam = selectedExam;
    previousSelectedTerm = selectedTerm;
    //mmmh
    await db.update(
      'selected_parameters',
      {
        'value': selectedExam,
      },
      where: 'key = ?',
      whereArgs: ['selectedExam'],
    );
    await db.update(
      'selected_parameters',
      {
        'value': selectedTerm,
      },
      where: 'key = ?',
      whereArgs: ['selectedTerm'],
    );

  

    final sub = await db.query(
      'subjects',
      where: 'category=?',
      whereArgs: [levelClass],

    );
    subjects = sub;

     gradingConfig = gradeRes;
     

    if (assessments.isEmpty) {
      setState(() {
        averageScore = 0;
        belowExpectationsCount = 0;
        isLoadingPerformance = false;
        topSubjects = [];
        rankedStudents = students.map((s) => {...s, 'totalPoints': 0.0,
          'finalGrade': '-',
          'gradeColor': '#6B7280',}).toList();
      });
      return;
    }

    double totalPoints = 0;
    
    int totalEntries = 0;

    Map<String, List<String>> subjectGrades = {};
    Map<String, List<double>> subjectMarks = {};
    Map<int, List<String>> studentGrades= {};
    Map<int, List<double>> studentMarks= {};

    for (var a in assessments) {
      final score = (a['raw_score']as num ?? 0.0).toDouble();
      final gradeParts = getGradeFromScore(score);
      final parts = gradeParts.split("|");
      final grade = parts[0];
      
    //  studentGrades.putIfAbsent(a['student_id'] as int, () => []).add(grade);
      
      totalEntries++;

      // Subject averages
      String subject = a['subject_code'] as String;
      subjectGrades.putIfAbsent(subject, ()=> []).add(grade);
      subjectMarks.putIfAbsent(subject, ()=> []).add(score);
           // Student total points
      int studentId = a['student_id'] as int;
      studentGrades.putIfAbsent(studentId, () => []).add(grade);
      studentMarks.putIfAbsent(studentId, () => []).add(score);
    }

    // Overall Average
    dominantGrade= subjectGrades.values.expand((grades) => grades).fold<Map<String, int>>({}, (map, grade) {
      map[grade] = (map[grade] ?? 0) + 1;
      return map;
    }).entries.reduce((a, b) => a.value > b.value ? a : b).key;

    
     

    // Top 3 Subjects
    topSubjects = subjectMarks.entries.map((e) {
      double avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'subject': e.key, 'average': avg};
    }).toList()
      ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

    if (topSubjects.length > 3) topSubjects = topSubjects.sublist(0, 3);

    // Ranked Students
    rankedStudents = students.map((s) {
      int id = s['id'];
      List<String> grades = studentGrades[id] ?? [];
      List<double> marks = studentMarks[id] ?? [];
    
      double total = marks.isEmpty ? 0 : marks.reduce((a, b) => a + b).toDouble();
      double avgPoint = marks.isEmpty ? 0 : total / marks.length;
      String finalGrade = grades.isEmpty ? "-" : grades.fold<Map<String, int>>({}, (map, grade) {
        map[grade] = (map[grade] ?? 0) + 1;
        return map;
      }).entries.reduce((a, b) => a.value > b.value ? a : b).key;
      String gradeColor = getGradeColor(finalGrade);
      if(total<=40.0){
        belowExpectationsCount++;
      }
      return {
        ...s,
        'totalPoints': total,
        
        'finalGrade': finalGrade,
        'gradeColor': gradeColor,
      };
      
    }).toList()
      ..sort((a, b) => (b['totalPoints'] as double).compareTo(a['totalPoints'] as double));


  } catch (e) {
    print("Performance calculation error: $e");
  } finally {
    setState(() {
      isLoadingPerformance = false;
    });
  }


}
}
double _getPointsFromScore(double score) {
  
  for(var g in gradingConfig) {
    final min = (g['min_mark'] as int?) ?? 0;
    final max = (g['max_mark'] as int?) ?? 100;
    if (score >=min && score <= max) {
      return(g['point'] as num? ?? 0.0).toDouble();
    }
  }
  return 0.0;
}
String getGradeColor(String grade) {
    for (var g in grading_config) {
      if(grade==g["grade"]){
        return g['color'];
      }
    }
    return "#000000";
}
String getFinalGrade(double score)  {

   String grade = "-";
   String colors = "-";
  
  
  for (var g in grading_config) {
    int mark = g['min_mark'] as int;
   
    int maxMark = g['max_mark'] as int ;
    if( score>= mark && score <= maxMark){
      grade = g['grade'] as String;
      colors = g['color'];
      
    }
  }
  return "$grade|$colors";
  

}

String getGradeFromScore(double score) {
   String grade = "-";
   String colors = "-";
  
  
  for (var g in gradingConfig) {
    int mark = g['min_mark'] as int;
   
    int maxMark = g['max_mark'] as int ;
    if( score>= mark && score <= maxMark){
      grade = g['grade'] as String;
      colors = g['color'];
      
    }
  }
  return "$grade|$colors";
}

int _getMinMark() {
  for(var f in gradingConfig){
    final min =(f['min_mark'] as int ?) ?? 0;
    final max = (f['max_mark'] as int?) ?? 100;
    if (f['point'] == 2 ) {
      return min;
  }
  
}
return 0;
}

String _getGradefromPoint(int point) {

  for (var g in gradingConfig) {
    if( point == g['point']) {
      return g['grade'] as String ;
    }
  
  }
  return '-';
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
      _loadStudents(); 
      _addStudent();// Refresh student list
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
        {'class_name': newName.trim(), 'level': selectedLevel},
        where: 'id = ?',
        whereArgs: [widget.classData['id']],
      );


      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Class updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      

      
      if (mounted) {
  
        Navigator.pushReplacementNamed(context, '/home');
        
      }

      
    }

  }

  // Enter Marks
  Future<void> _enterMarks() async {
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EnterMarksScreen(
        classData: widget.classData,
        reload: _calculatePerformance,
      ),
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
      await db.update(
        'classes',
        {'student_count': students.length - 1},
        where: 'id = ?',
        whereArgs: [widget.classData['id']],
      );
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
           const Text("View Performance For", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                // Term
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: "Term 1", label: Text("Term 1")),
                      ButtonSegment(value: "Term 2", label: Text("Term 2")),
                      ButtonSegment(value: "Term 3", label: Text("Term 3")),
                    ],
                    selected: {selectedTerm},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() => selectedTerm = selection.first);
                      _calculatePerformance();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Year Selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: "Year",
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (i) => (DateTime.now().year - 2 + i).toString())
                        .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedYear = value);
                        _calculatePerformance();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Exam Selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedExam,
                    decoration: const InputDecoration(
                      labelText: "Exam",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "EXAM 1", child: Text("Opener")),
                      DropdownMenuItem(value: "EXAM 2", child: Text("Mid-Term")),
                      DropdownMenuItem(value: "EXAM 3", child: Text("End-Term")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedExam = value);
                        _calculatePerformance();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Analytics Cards
            const Text("Performance Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            isLoadingPerformance
              ? Row(
                children: [
                Expanded(child: _buildSkeletonCard()),
                const SizedBox(width:12),
                Expanded(child: _buildSkeletonCard()),
                ],
              )
              
              : Row(
              children: [
                _buildAnalyticCard("Total Students", "${students.length}", "", Colors.blue),
                const SizedBox(width: 12),
                _buildAnalyticCard("${widget.classData['level']=="Js" ? "Avg Points" : "Dominant Grade"}", "${widget.classData['level']=="Js" ? averageScore.toStringAsFixed(1) : dominantGrade}", "", Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            

            isLoadingPerformance 
            ? Row(
              children: [
                Expanded(child:_buildSkeletonCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildSkeletonCard()),
              ],
            )
            
            
            : Row(
              children: [
                _buildAnalyticCard("Top 3 Subjects", topSubjects.isNotEmpty ? 
                topSubjects.map((s)=> s['subject']).join(", ")
                : "No data", "", const Color.fromARGB(255, 72, 52, 21)),

                const SizedBox(width: 12),
                _buildAnalyticCard("Below Expectations", "$belowExpectationsCount", "Students", Colors.red),
              ],
            ),

            const SizedBox(height: 32),
            // Quick Actions Updated 
            const Text("Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                //_buildActionCard(Icons.people, "View All Students", Colors.indigo),
                _buildActionCard(Icons.picture_as_pdf, "Generate Report", Colors.red, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassReportScreen(
                        classData: widget.classData,
                        initialTerm: selectedTerm,
                        initialYear: selectedYear,
                        initialExam: selectedExam,
                        rankedStudents: rankedStudents,
                        topSubjects: topSubjects,
                        subjects: subjects,
                        assessments: assess,
                        getPointsFromScore: _getPointsFromScore,
                        getGrade: getFinalGrade,
                        getGradeFromScore: getGradeFromScore,
                      ),

                    ),
                  );
                }),
              ],
              
            ),

             const SizedBox(height: 32),

            // Ranked Students List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Students Ranking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                //TextButton(onPressed: () {}, child: const Text("View All")),
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
            else if (isLoadingPerformance)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) => _buildSkeletonCard(),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rankedStudents.length,
                itemBuilder: widget.classData['level']=="Js" ?(context, index) {
                  final student = rankedStudents[index];
                  final avg = student['totalPoints'] != null 
                          ? (student['totalPoints'] as num).toDouble() 
                           : 0.0;


                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text("#${index + 1}"),
                      ),
                      title: Text(student['full_name']),
                     subtitle: FutureBuilder<String>(
  // 1. Pass your async function here
  future: Future.value(getFinalGrade(avg)), 
  builder: (context, snapshot) {
    // 2. Show a small loading message or dash while waiting for the calculation
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Text("Adm: ${student['admission_number'] ?? 'N/A'} • ${avg.toStringAsFixed(1)}points • Checking...");
    }
    
    // 3. Fallback to 'N/A' if an error happens or data returns null
     final gradePartsMain = snapshot.data ?? 'N/A';
     final parts = gradePartsMain.split("|");
     String grade= parts[0];
     String rangi = parts[1];
    // 4. Render the clean CBC grade once the data arrives
    return Text("Adm: ${student['admission_number'] ?? 'N/A'} • ${avg.toStringAsFixed(1)}points • $grade",
                  style:  TextStyle( color: Color(int.parse(rangi.replaceFirst('#','').padLeft(8,'FF'), radix:16)),
                  ),
                  );
    
  },
),
                      
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () {
                              // TODO: Navigate to Student Detail Screen later
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Opening ${student['full_name']}'s profile")),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteStudent(student['id'], student['full_name']),
                          ),
                                            
                        ],
                    ),
                  ),
                  );
                } :
                (context,index) {
                     final student = rankedStudents[index];
                     String grade= student['finalGrade'];
                     String rangi = student['gradeColor'];

                     return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text("#${index + 1}"),
            ),
            title: Text(student['full_name'] ?? 'N/A'),
            subtitle: Text(
              "Adm: ${student['admission_number'] ?? 'N/A'} • $grade",
              style: TextStyle(
                color: Color(
                  int.parse(rangi.replaceFirst('#', '').padLeft(8, 'FF'), radix: 16),
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Opening ${student['full_name']}'s profile")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteStudent(student['id'], student['full_name']),
                ),
              ],
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
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
           const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value:selectedLevel,
              decoration: const InputDecoration(
                labelText: "School Level",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "UP", child: Text("Upper Primary")),
                DropdownMenuItem(value: "LP", child: Text("Lower Primary")),
                DropdownMenuItem(value: "Js", child: Text("Junior Secondary (JSS)")),
              ],
              onChanged: (value) => setState(() => selectedLevel = value!),
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





//Skeleton loader
  Widget _buildSkeletonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 12, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Container(width: 60, height: 28, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }