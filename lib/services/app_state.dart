import 'database_helper.dart';
import '../globals.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AppState {
  static Future<void> checkTeacherProfile() async {
    
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> result = await db.query('teacher', limit: 1);
      final List<Map<String, dynamic>> settings = await db.query('settings');
      final List<Map<String, dynamic>> paramsCheck = await db.query('selected_parameters');
     final List<Map<String, dynamic>> maps = await db.query('tracker');
     for (var sets in settings) {
      if (sets['key'] == 'useAdmissionNumber') {
        useAdmissionNumber = sets['value'] == 'true' ;
        
      }
      if(sets['key']=='isjss'){
        isjss = sets['value'] == 'true';
      }

     }
    for (var map in maps) {
      if (map['key'] == 'continuingOnboarding') {
        continuingOnboarding = map['value'] == 'true';
      } 

   } 
      
    for (var params in paramsCheck) {
      if (params['key'] == 'selectedExam') {
        previousSelectedExam = params['value'] ?? "EXAM 1";
      }
      if (params['key'] == 'selectedTerm') {
        previousSelectedTerm = params['value'] ?? "Term 1";
      }
    }
      if (result.isNotEmpty) {
        hasTeacher = true;
        teacherName = result[0]['full_name'] ?? '';
        schoolName = result[0]['school_name'] ?? '';
        await FirebaseAnalytics.instance.logEvent(
    name: 'app_open',
    parameters: {'user_name': teacherName},
);
        await db.insert('tracker', {
          'key': 'hasTeacher',
          'value': '$hasTeacher', 
        }, conflictAlgorithm: ConflictAlgorithm.replace);   
      } else {
        hasTeacher = false;
        await db.insert('tracker', {
          'key': 'hasTeacher',
          'value': '$hasTeacher', 
        }, conflictAlgorithm: ConflictAlgorithm.replace); 
      }
    } catch (e) {
      print("Error checking teacher profile: $e");
      hasTeacher = false; // Default to false if there's an error
    }
  }

}