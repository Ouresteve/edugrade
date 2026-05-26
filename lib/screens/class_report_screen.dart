import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class ClassReportScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final String initialTerm;
  final String initialYear;
  final String initialExam;
  final double Function(double) getPointsFromScore;
   final String Function(double) getGrade;
  final List<Map<String, dynamic>> rankedStudents;
  final List<Map<String, dynamic>> topSubjects;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> assessments;

  const ClassReportScreen({
    super.key,
    required this.classData,
    required this.initialTerm,
    required this.initialYear,
    required this.initialExam,
    required this.rankedStudents,
    required this.topSubjects,
    required this.subjects,
    required this.assessments,
    required this.getPointsFromScore,
    required this.getGrade,
  });

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {

  bool usePoints = false;        // Toggle between Raw Marks vs Points
  bool isGenerating = false;
  List<Map<String, dynamic>> assessments = [];
  List<Map<String, dynamic>> subjects = [];
  
  String selectedTerm = "Term 1";
  String  schoolName="School Name";
  String selectedYear = DateTime.now().year.toString();
  String selectedExam = "EXAM 1";

  @override
  void initState() {
    super.initState();
    selectedTerm = widget.initialTerm;
    selectedYear = widget.initialYear;
    selectedExam = widget.initialExam;
    assessments = widget.assessments;
    subjects = widget.subjects;
    _loadSchoolName();
  }

Future<void> _loadSchoolName() async {
    try {
        final db = await DatabaseHelper.instance.database;
        final result = await db.query('teacher', limit: 1);
        if (result.isNotEmpty) {
            setState((){
                schoolName = result.first['school_name'] as String ?? "Your School";
            });
        }
    } catch (e) {
        print("Could not load school name: $e");
    }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report - ${widget.classData['class_name']}"),
        backgroundColor: AppTheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Toggle
            const Text("Report Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text("Raw Marks")),
                ButtonSegment(value: true, label: Text("Points & Grades")),
              ],
              selected: {usePoints},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => usePoints = selection.first);
              },
            ),

            const SizedBox(height: 24),

            // Filters (Term, Year, Exam) - can be pre-filled
            const Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // You can improve this later with better selectors

            const SizedBox(height: 32),

            // Preview Area (Simple for now)
            const Text("Report Preview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  usePoints ? "Points & CBC Grades Preview" : "Raw Marks Preview",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Generate Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : () => _generateReport(isPdf: true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : () => _generateReport(isPdf: false),
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Export Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport({required bool isPdf}) async {
    setState(() => isGenerating = true);

    try {
      if (isPdf) {
        await _generatePdfReport();
      } else {
        await _generateExcelReport();
    
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isGenerating = false);
    }
  }


Future<void> _generateExcelReport() async {
  setState(() => isGenerating = true);

  try {
    final excel = Excel.createExcel();
    final sheet = excel['${widget.classData['class_name']}_Report'];
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('teacher', limit: 1);
        if (result.isNotEmpty) {
            setState((){
                schoolName = result.first['school_name'] as String ?? "Your School";
            });
        }
    // Title
    sheet.appendRow([schoolName]);
    sheet.appendRow(["${widget.classData['class_name']} | $selectedTerm | $selectedYear | $selectedExam"]);
    sheet.appendRow(["Generated: ${DateTime.now().toString().substring(0, 16)}"]);
    sheet.appendRow([]);

    // Headers
    List<String> headers = ["Rank", "Student Name", "Admission Number"];

    for (var sub in widget.subjects) {
      headers.add(sub['subject_code'] as String);
    }

    headers.add(usePoints ? "Total Points" : "Average %");
    headers.add("Grade");

    sheet.appendRow(headers);

    // Fill Student Data
    for (int i = 0; i < widget.rankedStudents.length; i++) {
      final student = widget.rankedStudents[i];
      final studentId = student['id'] as int;
      final avgPoint = student['totalPoints'] as double? ?? 0.0;
      double point = 0.0;
      List<dynamic> row = [
        "#${i + 1}",
        student['full_name'] ?? 'N/A',
        student['admission_number'] ?? 'N/A',
      ];

      // Subject columns
      for (var sub in widget.subjects) {
        final subjectCode = sub['subject_code'] as String;

        final markEntry = widget.assessments.firstWhere(
          (a) => a['student_id'] == studentId && a['subject_code'] == subjectCode && a['assessment_type'] == selectedExam && a['term']  == selectedTerm && a['academic_year'] == selectedYear,
          orElse: () => <String, dynamic>{},
        );

        final rawScore = markEntry['raw_score'] as double?;
     
         point =  rawScore != null
          ?widget.getPointsFromScore(rawScore)
          : 0.0;
      
        final display = usePoints 
            ? (point?.toString() ?? "-")
            : (rawScore?.toStringAsFixed(0) ?? "-");

        row.add(display);
      }
      final result =  widget.getGrade(avgPoint);
      final parts = result.split("|");
      String grade = parts[0];
      row.add(usePoints ? avgPoint.toStringAsFixed(1) : "-");
      row.add(grade);  

      sheet.appendRow(row);
    }

    // Save to Downloads folder
     final timestamp = DateTime.now().toString()
        .substring(0, 19)
        .replaceAll(' ', '_')
        .replaceAll(':', '')
        .replaceAll('-', '');
    final directory = await getExternalStorageDirectory();
    final fileName = "EduGrade_${widget.classData['class_name']}_${selectedTerm}_${selectedYear}_$timestamp.xlsx";
    final reportsDir = Directory('${directory!.path}/EduGrade_Reports');
    if (!await reportsDir.exists() ) {
      await reportsDir.create(recursive: true);
    }
    final filePath ='${reportsDir.path}/$fileName';
    final fileBytes = excel.encode()!;
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Excel saved successfully!\n$filePath"),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel failed: $e"),
        backgroundColor: AppTheme.error,),
      );
    }
  } finally {
    setState(() => isGenerating = false);
  }
}


 Future<void> _generatePdfReport() async {
  setState(() => isGenerating = true);

  try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(context),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => _buildPdfContent(),
      ),
    );

    // Generate PDF bytes
    final pdfBytes = await pdf.save();

    // Show preview first
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );

    // Save to visible Downloads folder
     final timestamp = DateTime.now().toString()
        .substring(0, 19)
        .replaceAll(' ', '_')
        .replaceAll(':', '')
        .replaceAll('-', '');
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final reportsDir = Directory('${directory.path}/EduGrade_Reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final fileName = "EduGrade_${widget.classData['class_name']}_${selectedTerm}_${selectedYear}_$timestamp.pdf";
      final filePath = '${reportsDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved: $fileName"),
          backgroundColor: AppTheme.success,),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate PDF: $e"),
        backgroundColor: AppTheme.error,),
      );
    }
  } finally {
    setState(() => isGenerating = false);
  }
}

pw.Widget _buildPdfHeader(pw.Context context) {
  return pw.Column(
    children: [
      pw.Text(
        schoolName,
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        "${widget.classData['class_name']} |  $selectedTerm | $selectedYear | $selectedExam",
        style:  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
      pw.Divider(),
      pw.SizedBox(height: 10),
    ],
  );
}

pw.Widget _buildPdfFooter(pw.Context context) {
  return pw.Column(
    children: [
      pw.Divider(),
      pw.SizedBox(height: 5),
      pw.Text(
        "Powered by EduGrade - Offline CBC Grading System",
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
      pw.Text(
        "Page ${context.pageNumber} of ${context.pagesCount}",
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    ],
  );
}

List<pw.Widget> _buildPdfContent() {
  final subjectList = widget.subjects;

  return [
    pw.Text(
      usePoints ? "Final Results - Points & CBC Grades" : "Raw Marks Report",
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 15),

    pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),      // Rank
        1: const pw.FlexColumnWidth(2.6),      // Student Name
        2: const pw.FixedColumnWidth(70),      // Adm No
      },
      
      children: [
        // Header
        pw.TableRow(
          decoration:  pw.BoxDecoration(color: PdfColors.blueGrey200),
          repeat: true,
        
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rank", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Student Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Adm No", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

            // Subject Columns
            ...subjectList.map((sub) => 
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  sub['subject_code'] as String,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              )
            ),

            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(usePoints ? "Total Points" : " ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Grade", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),

        // Student Rows
        ...List.generate(widget.rankedStudents.length, (index) {
          final student = widget.rankedStudents[index];
          final studentId = student['id'] as int;
          final avgPoint = student['totalPoints'] as double? ?? 0.0;
          final gradeParts = widget.getGrade(avgPoint);
          final parts = gradeParts.split("|");
          String Grade = parts[0];
           PdfColor rangi = PdfColor.fromHex(parts[1].replaceFirst("#", '')); 

          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("#${index+1}")),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student['full_name'] ?? 'N/A')),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student['admission_number'] ?? 'N/A')),

              // Subject Cells → Raw Marks or Points only
              ...subjectList.map((sub) {
                final subjectCode = sub['subject_code'] as String;

                final markEntry = widget.assessments.firstWhere(
                  (a) => a['student_id'] == studentId && a['subject_code'] == subjectCode,
                  orElse: () => <String, dynamic>{},
                );

                final rawScore = markEntry['raw_score'] as double?;
                final point =  rawScore != null
                ? widget.getPointsFromScore(rawScore)
                : 0.0;

                final display = usePoints 
                    ? (point?.toString() ?? "-")
                    : (rawScore?.toStringAsFixed(0) ?? "-");

                return pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(display, textAlign: pw.TextAlign.center),
                );
              }).toList(),

              // Total Points / Avg
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  usePoints ? avgPoint.toStringAsFixed(1) : "-",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              
              // Final Overall Grade with Color
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  "$Grade", 
                  style:  pw.TextStyle(color: rangi, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        }),
      ],
    ),

    pw.SizedBox(height: 30),

    // Top 3 Subjects
    pw.Text("Top 3 Subjects", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 10),
    pw.Text(
      widget.topSubjects.isNotEmpty 
        ? widget.topSubjects.map((s) => "${s['subject']} (${(s['average'] as double).toStringAsFixed(1)})").join(" \n ") 
        : "No data available",
    ),
  ];
}
}