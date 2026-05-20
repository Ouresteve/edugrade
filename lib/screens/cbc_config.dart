import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../globals.dart';

class CbcConfigScreen extends StatefulWidget {
  const CbcConfigScreen({super.key});

  @override
  State<CbcConfigScreen> createState() => _CbcConfigScreenState();
}

class _CbcConfigScreenState extends State<CbcConfigScreen> {
  bool _isLoading = true;
  String selectedLevel = "primary";
  // "primary" or "jss"

  // Controllers for editing
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _pointControllers = {};

  @override
  void initState() {
    super.initState();
    // Respect global isJSS from tracker
    selectedLevel = isjss ? "jss" : "primary";
    _loadGradingConfig();
  }

  Future<void> _loadGradingConfig() async {
    setState(() => _isLoading = true);
    _minControllers.clear();
    _pointControllers.clear();

    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'grading_config',
        where: 'level = ?',
        whereArgs: [selectedLevel],
        orderBy: 'min_mark DESC',
      );

      for (var row in results) {
        String key = row['grade'] as String;
        _minControllers[key] = TextEditingController(
          text: (row['min_mark'] ?? 0).toString(),
        );
        if(selectedLevel == "jss" && row['point'] != null) {
            _pointControllers[key] = TextEditingController(
          text:(row['point'] ?? 0).toString(),
        );
        }
        
      }
    } catch (e) {
      print("Error loading grades: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;

    
      for (var entry in _minControllers.entries) {
        String grade = entry.key;
        int minMark = int.tryParse(entry.value.text.trim()) ?? 0;
        int? point = selectedLevel == "jss"
              ? int.tryParse(_pointControllers[grade]?.text.trim() ?? '0')
              : null;
        await db.update(
          'grading_config',
          {'min_mark': minMark,
          if(point != null ) 'point': point, },
          where: 'level = ? AND grade = ?',
          whereArgs: [selectedLevel, grade],
        );
      }

      // Update global tracker
      isjss = (selectedLevel == "jss");
      await db.update(
        'tracker',{
          'key':'isjss',
          'value':'$isjss'
        },conflictAlgorithm: ConflictAlgorithm.replace
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grading configuration saved successfully!")),
        );
        Navigator.pushReplacementNamed(context, '/student_config');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

                  isjss = selectedLevel == "jss";

    return Scaffold(
      appBar: AppBar(
        title: const Text("CBC Grading Setup"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("School Level", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "primary", label: Text("Primary")),
                ButtonSegment(value: "jss", label: Text("Junior Secondary")),
              ],
              selected: {selectedLevel},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  selectedLevel = selection.first;
                });
                _loadGradingConfig(); // Reload when level changes
              },
            ),

            const SizedBox(height: 32),
            Text(
              isjss ? "Junior Secondary (8 Levels)" : "Primary (4 Bands)",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: isjss ? _buildJSSRows() : _buildPrimaryRows(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveConfig,
                child: const Text("Save Grading Configuration"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrimaryRows() {
    return [
     _buildPrimaryRow("Exceeding Expectations (EE)", "EE"),
      _buildPrimaryRow("Meeting Expectations (ME)", "ME"),
      _buildPrimaryRow("Approaching Expectations (AE)", "AE"),
      _buildPrimaryRow("Below Expectations (BE)", "BE"),
    ];
  }

  List<Widget> _buildJSSRows() {
    return [
      _buildJSSRow("EE1 - Exceeding Expectations 1", "EE1"),
      _buildJSSRow("EE2 - Exceeding Expectations 2", "EE2"),
      _buildJSSRow("ME1 - Meeting Expectations 1", "ME1"),
      _buildJSSRow("ME2 - Meeting Expectations 2", "ME2"),
      _buildJSSRow("AE1 - Approaching Expectations 1", "AE1"),
      _buildJSSRow("AE2 - Approaching Expectations 2", "AE2"),
      _buildJSSRow("BE1 - Below Expectations 1", "BE1"),
      _buildJSSRow("BE2 - Below Expectations 2", "BE2"),
    ];
  }

   Widget _buildPrimaryRow(String label, String gradeKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _minControllers[gradeKey],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: "% ↑",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJSSRow(String label, String gradeKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _minControllers[gradeKey],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: "% ↑",
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _pointControllers[gradeKey],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Pts",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
