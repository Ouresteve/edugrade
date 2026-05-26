import 'package:firebase_core/firebase_core.dart';
import 'package:edugrade/screens/classes_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:edugrade/screens/subject_screen.dart';
import 'package:flutter/material.dart';
import 'screens/entry_point.dart';
import 'screens/theme.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';  
import 'screens/setup.dart';
import 'screens/cbc_config.dart';
import 'screens/student_config.dart';
import 'screens/classes_screen.dart';
import 'screens/reports_archive_screen.dart';
import 'screens/settings.dart';
import 'screens/collaboration.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppState.checkTeacherProfile();
  

  runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }


  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduGrade.KE',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const EntryPoint(),
       routes: {
        '/home': (context) => const HomeScreen(),
        '/setup': (context) => const TeacherSetupScreen(),
        '/cbc_config': (context) => const CbcConfigScreen(),
        '/student_config': (context) => const StudentConfigScreen(),
        '/class': (context) => const ClassesScreen(),
        '/subjects' : (context) => const SubjectsScreen(),
        '/reports' : (context) => const  ReportsArchiveScreen(),
        '/group': (context) => const CollaborationScreen(),
        
        '/settings': (context) =>  SettingsScreen(toggleTheme: toggleTheme),
      },

    );
  }
}
   

  