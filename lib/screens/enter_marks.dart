import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'classes_detail_screen.dart';



class EnterMarksScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Future<void> Function() reload;
  
  const EnterMarksScreen({super.key, required this.classData, required this.reload}); 
  
  
   @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}


class _EnterMarksScreenState extends State<EnterMarksScreen> {

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> gradingConfig = [];
  final List<FocusNode> _focusNodes = [];
  bool isLoading = true;
  bool isSaving = false;  
  String? selectedSubjectCode;
  String _searchQuery = '';
  String selectedExam = "EXAM 1";
  String selectedTerm = "Term 1"; 

  String currentLevel = "primary";
  String selectedYear = DateTime.now().year.toString(); // Track marks data: {studentId: mark}
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  
  final Map<int, TextEditingController> _markControllers = {};// Track active cell for visual feedback
  int? _activeCellStudentId;
  final FocusNode _tableFocusNode = FocusNode(); 
  
 @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(_scrollListener);
  } 

   Future<void> _loadData() async {
    setState(() => isLoading = true);
    currentLevel = widget.classData['level']?.toString().toLowerCase() ?? "jss";
    try {
      final db = await DatabaseHelper.instance.database;  // Load Students
  final stuRes = await db.query(
    'students',
    where: 'class_id = ?',
    whereArgs: [widget.classData['id']],
    orderBy: 'full_name ASC',
  );
  students = stuRes;

  final gradeRes = await db.query(
    'grading_config',
    where: 'level = ?',
    whereArgs: [currentLevel],
  );
  gradingConfig = gradeRes;
  // Load Subjects
  final subRes = await db.query('subjects', orderBy: 'subject_code ASC');
  subjects = subRes;

  // Initialize marks data
  for (var s in students) {
    _markControllers[s['id']] = TextEditingController();
    _focusNodes.add(FocusNode());
  }
  
  // Set first subject as default
  if (subjects.isNotEmpty && selectedSubjectCode == null) {
    selectedSubjectCode = subjects[0]['subject_code'].toString();
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error loading data: $e"),
        backgroundColor: AppTheme.error,
      ),
    );
  }
} finally {
  setState(() => isLoading = false);
  // Load marks after data is loaded
  if (selectedSubjectCode != null) {
    _loadMarksForSelection(selectedSubjectCode!);
  }
}  }

Future<void> _loadMarksForSelection(String subjectCode) async {
  try {
    final db = await DatabaseHelper.instance.database;
    
    // Clear existing marks
    for (var s in students) {
      _markControllers[s['id']]!.text = '';
    }

    // Fetch marks for the selected subject, term, and exam
    final results = await db.query(
      'assessments',
      where: 'class_id = ? AND subject_code = ? AND term = ? AND assessment_type = ? AND academic_year = ?',
      whereArgs: [
        widget.classData['id'],
        subjectCode,
        selectedTerm,
        selectedExam,
        selectedYear,
      ],
    );

    // Populate marks data with fetched results
    for (var result in results) {
      final studentId = result['student_id'] as int;
      final score = (result['raw_score'] as double).toString();
      if (_markControllers.containsKey(studentId)) {
      _markControllers[studentId]!.text = score;
      }
    }

    setState(() {});
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading marks: $e"),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
Map<String, dynamic> _getGradeFromMark(double? mark) {
  if(mark==null) return {'grade':'-','color':'#9E9E9E'};
  
  for(var g in gradingConfig) {
    final min=g['min_mark'] as int;
    final max = g['max_mark'] as int? ?? 100;
    if (mark >=min && mark <=max) {
      return {
        'grade': g['grade'],
        'color': g['color'] ?? '#9E9E9E',
      };
    }
  }
  return {'grade': 'N/A', 'color': '#9E9E9E'};
}
Future<void> _saveMarks() async {
    if (selectedSubjectCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a subject"),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }// Count entries with values
int enteredCount = _markControllers.values.where((v) => v.text.trim().isNotEmpty).length;
if (enteredCount == 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please enter at least one mark"),
      backgroundColor: AppTheme.warning,
    ),
  );
  return;
}

setState(() => isSaving = true);

try {
  final db = await DatabaseHelper.instance.database;
  int savedCount = 0;
  int errorCount = 0;

  for (var student in students) {
    final markText = _markControllers[student['id']]!.text.trim();
    if (markText.isNotEmpty) {
      try {
        double score = double.parse(markText);
        
        // Validate mark range
        if (score < 0 || score > 100) {
          errorCount++;
          continue;
        }

        await db.insert(
          'assessments',
          {
            'student_id': student['id'],
            'class_id': widget.classData['id'],
            'subject_code': selectedSubjectCode,
            'academic_year': selectedYear,
            'term': selectedTerm,
            'assessment_type': selectedExam,
            'raw_score': score,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        savedCount++;
      } catch (_) {
        errorCount++;
      }
    }
  }

  if (mounted) {
    widget.reload();

    String message = '$savedCount marks saved successfully!';
    if (errorCount > 0) {
      message += ' ($errorCount errors)';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorCount > 0 ? AppTheme.warning : AppTheme.success,
      ),
    );

    // Reset form after successful save
    if (errorCount == 0 ) {
      setState(() {
        for (var s in students) {
         // _marksData[s['id']] = '';
        }
      });
    }
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error saving marks: $e"),
        backgroundColor: AppTheme.error,
      ),
    );
  }
} finally {
  setState(() => isSaving = false);
}  }  
   int _getCompletionPercentage() {
    if (students.isEmpty) return 0;
    int filled = _markControllers.values.where((v) => v.text.trim().isNotEmpty).length;
    return ((filled / students.length) * 100).toInt();
  } 
   @override
  void dispose() {
    _tableFocusNode.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    _tableFocusNode.dispose();
    super.dispose();
  }  

  void _scrollListener() {
    if(_scrollController.offset  > _lastScrollOffset + 1) {
      //Scrolling down
      if(_isHeaderVisible) {
        setState(() => _isHeaderVisible = false);
      }
    } else if (_scrollController.offset < _lastScrollOffset -20) {
      //Up
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible= false);
      }
    }
    _lastScrollOffset = _scrollController.offset;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marks Entry - ${widget.classData['class_name']}"),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with selections
                AnimatedContainer(
                  duration: const Duration(milliseconds: 3000),
                  height: _isHeaderVisible ? 250: 0,
                  curve: Curves.easeInOut,
                  child: _buildHeaderSection(),
                ),
                const Divider(height: 1),
                _buildProgressSection(),

            // Frozen Table
            Expanded(
              child: students.isEmpty
                  ? const Center(
                      child: Text(
                        "Oops! Student Roster is Empty, Add Students First ",
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                      
                      ),
                    )
                  : _buildFrozenTable(),
            ),
          ],
        ),
  bottomNavigationBar: _buildBottomBar(),
);  }  




Widget _buildHeaderSection() {
  return Container(
    
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primaryLight,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ), 
    ),
  child: SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    clipBehavior: Clip.hardEdge,
    child: Column(
      children: [
        //Year Selected
                const SizedBox(height: 12),

        // Year Selector
        /*DropdownButtonFormField<String>(
          value: selectedYear,
          decoration: InputDecoration(
            labelText: "Academic Year",
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: List.generate(6, (i) => (DateTime.now().year - 3 + i).toString())
              .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedYear = value);
              if (selectedSubjectCode != null) {
                _loadMarksForSelection(selectedSubjectCode!);
              }
            }
          },
        ),*/
        
        // Subject Dropdown - Safer
        DropdownButtonFormField<String>(
          value: selectedSubjectCode,
          dropdownColor: AppTheme.primaryLight,
          decoration: InputDecoration(
            labelText: "Subject",
            labelStyle : const TextStyle(color: Colors.black),
            prefixIcon: const Icon(Icons.book, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          hint: const Text("Select Subject",
          style:  TextStyle(color: Colors.white),
          ),
          items: subjects.isEmpty 
              ? null 
              : subjects.map<DropdownMenuItem<String>>((sub) {
                  return DropdownMenuItem<String>(
                    value: sub['subject_code'] as String?,
                    child: Text(
                      "${sub['subject_code']} - ${sub['subject_name']}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (BuildContext context) {
    return subjects.map<Widget>((sub) {
      return Text(
        "${sub['subject_code']} - ${sub['subject_name']}",
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.black87), // Closed field text color
      );
    }).toList();
  },
          onChanged: (String? value) {
            if (value != null) {
              setState(() => selectedSubjectCode = value);
              _loadMarksForSelection(value);
            }
          },
        ),

        const SizedBox(height: 12),

        // Term + Assessment in one row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedTerm,
                dropdownColor: AppTheme.primaryLight,
                
                decoration: InputDecoration(
                  labelText: "Term",
                  labelStyle : const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.timelapse, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:const EdgeInsets.symmetric(vertical:6),
                ),
                items: const [
                  DropdownMenuItem(value: "Term 1", child: Text("Term 1",style: TextStyle(color: Colors.white),)),
                  DropdownMenuItem(value: "Term 2", child: Text("Term 2",style: TextStyle(color: Colors.white),)),
                  DropdownMenuItem(value: "Term 3", child: Text("Term 3",style: TextStyle(color: Colors.white),)),
                  
                ],

                 selectedItemBuilder: (BuildContext context) {
                    return const [
                    Text("Term 1", style: TextStyle(color: Colors.black87)),
                    Text("Term 2", style: TextStyle(color: Colors.black87)),
                    Text("Term 3", style: TextStyle(color: Colors.black87)),
                  ];
                 },
                
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedTerm = value);
                    if (selectedSubjectCode != null) {
                      _loadMarksForSelection(selectedSubjectCode!);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedExam,
                dropdownColor: AppTheme.primaryLight,
                decoration: InputDecoration(
                  labelText: "Assessment",
                  labelStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.assignment, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:const EdgeInsets.symmetric(vertical:6),
                ),
                items: const [
                  DropdownMenuItem(value: "EXAM 1", child: Text("EXAM 1",style: TextStyle(color: Colors.white),)),
                  DropdownMenuItem(value: "EXAM 2", child: Text("EXAM 2",style: TextStyle(color: Colors.white),)),
                  DropdownMenuItem(value: "EXAM 3", child: Text("EXAM 3",style: TextStyle(color: Colors.white),)),
                ],
                selectedItemBuilder: (BuildContext context) {
                  return const [
                     DropdownMenuItem(value: "EXAM 1", child: Text("EXAM 1",style: TextStyle(color: Colors.black87),)),
                  DropdownMenuItem(value: "EXAM 2", child: Text("EXAM 2",style: TextStyle(color: Colors.black87),)),
                  DropdownMenuItem(value: "EXAM 3", child: Text("EXAM 3",style: TextStyle(color: Colors.black87),)),
                  ];
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedExam = value);
                    if (selectedSubjectCode != null) {
                      _loadMarksForSelection(selectedSubjectCode!);
                    }
                  }
                },
              ),
            ),
            
          ],
        ),
        const SizedBox(height: 12),
        TextField(
            decoration: InputDecoration(
              labelText: "Search Student",
              hintText: "Type name or admission number...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical: 6),

            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
        ),
        const SizedBox(height: 12),
      ],
      
    ),
  ),
  );
}
 Widget _buildProgressSection() {
    int percentage = _getCompletionPercentage();
    int filled = _markControllers.values.where((v) => v.text.trim().isNotEmpty).length;return Container(
  color: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Progress: $filled/${students.length}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            "$percentage%",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: percentage == 100 ? AppTheme.success : AppTheme.accent,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 6,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage == 100 ? AppTheme.success : AppTheme.accent,
          ),
        ),
      ),
    ],
  ),
);  }

 Widget _buildFrozenTable() {
    final filteredStudents = students.where((student) {
    final name = (student['full_name'] ?? '').toString().toLowerCase();
    final adm = (student['admission_number'] ?? '').toString().toLowerCase();
    return name.contains(_searchQuery) || adm.contains(_searchQuery) ;
  }).toList();
  // Inside your widget build() section:
if (filteredStudents.isEmpty) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Oops! Student not found...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
        ],
      ),
    ),
  );
}

// Otherwise, show your normal table list if matches exist:

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Frozen header row
          _buildHeaderRow(),
          
          // Scrollable content - both student names and marks scroll together
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
              
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // Student names column - scrolls with marks
                      Column(

                        children: List.generate(
                          filteredStudents.length,
                          (index) {
                            final student = filteredStudents[index];
                            final isActive = _activeCellStudentId == student['id'];
                           
                            return Container(
                              height: 56,
                              width: 140,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryLight.withOpacity(0.1) : Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                  right: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                
                                children: [
                                  Text(
                                    student['full_name'] ?? 'N/A',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "Adm: ${student['admission_number'] ?? 'N/A'}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Marks columns - scrolls with student names
                      Column(
                        children: List.generate(
                          filteredStudents.length,
                          (index) => _buildDataRow(filteredStudents[index], index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 Widget _buildHeaderRow() {
  return Container(
    height: 40, 
    width: double.infinity,                   // Slightly taller for better labels
    decoration: BoxDecoration(
      color: AppTheme.primary,
      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
    ),
    child: Row(
      children: [
        // Student Name Column Header
        Container(
          width: 150,                  // Match the width of student column
          alignment: Alignment.center,
          child:  Text(
            selectedSubjectCode ?? '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Assessment Type (EXAM 1, etc.)
        Container(
          width: 100,
          alignment: Alignment.center,
          child:    Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            Text(
              selectedExam ,
            style:  TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
                '$selectedYear-$selectedTerm',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
               ],
          ),
      ),

        // Mark Column
        Container(
          width: 100,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Mark",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                "(0 - 100)",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDataRow(Map<String, dynamic> student, int index) {
    final StudentName = student['full_name'] as String ;
    final studentId = student['id'] as int;
    final isActive = _activeCellStudentId == studentId;

     final markText = _markControllers[student['id']]?.text.trim();
    final mark = markText != null && markText.isNotEmpty
                              ? double.tryParse(markText)
                              : null;

                            final gradeInfo = _getGradeFromMark(mark);
    //final displayValue = _markControllers[studentId]!.text.isEmpty ? "-" : _markControllers[studentId]!.text;
    return Container(
  height: 56,
  decoration: BoxDecoration(
    color: isActive ? AppTheme.primaryLight.withOpacity(0.08) : Colors.white,
    border: Border(
      bottom: BorderSide(color: Colors.grey[200]!),
    ),
  ),
  
  child: Row(
    children: [
      // Name column
      //if(mark != null)
      Container(
        width: 100,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accent.withOpacity(0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          
          child: Text(
            gradeInfo['grade'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(int.parse(gradeInfo['color'].replaceFirst('#','0xFF'))),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      
      // Mark input field
      SizedBox(
        width: 100,
        child: TextField(
          controller: _markControllers[studentId],
          focusNode: _focusNodes[index],
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _markControllers[studentId]!.text = value;
              _activeCellStudentId = studentId;
            });
          },
          onSubmitted: (value) {
            setState(() => _activeCellStudentId = studentId);
            if (index < students.length - 1) {
               final nextIndex = index + 1;
               FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
               setState(() => _activeCellStudentId = students[nextIndex]['id']);
            } else {
              FocusScope.of(context).unfocus();
            }
            
           
          },
          onTap: () {
            setState(() => _activeCellStudentId = studentId);
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: (_markControllers[studentId]?.text.isEmpty ?? true)
            ? AppTheme.textLight
            :AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: "-",
            hintStyle: const TextStyle(color: AppTheme.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isActive ? AppTheme.accent : Colors.grey[300]!,
                width: isActive ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isActive ? AppTheme.accent : (Colors.grey[300] ?? Colors.grey),
                width: isActive ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.accent,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isActive
                ? AppTheme.accent.withOpacity(0.08)
                : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixText: "%",
            suffixStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
        ),
      ),
    ],
  ),
); 
 } 
  Widget _buildBottomBar() {
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _saveMarks,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? "Saving..." : "Save Marks"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppTheme.success,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Toggle Header Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isHeaderVisible = !_isHeaderVisible;
              });
            },
            icon: Icon(_isHeaderVisible ? Icons.arrow_upward : Icons.arrow_downward),
            label: Text(_isHeaderVisible ? "Hide Header" : "Show Header"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
} 

