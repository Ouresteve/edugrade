import 'package:firebase_core/firebase_core.dart';
import 'package:edugrade/screens/classes_screen.dart';
import 'package:edugrade/screens/subject_screen.dart';
import 'package:flutter/material.dart';
import 'screens/entry_point.dart';
import 'screens/theme.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/setup.dart';
import 'screens/cbc_config.dart';
import 'screens/student_config.dart';
import 'screens/reports_archive_screen.dart';
import 'screens/settings.dart';
import 'screens/collaboration.dart';
import 'screens/app_launch_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showLaunch = true;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        Firebase.initializeApp(),
        AppState.checkTeacherProfile(),
        Future.delayed(const Duration(milliseconds: 1800)),
      ]);
    } catch (e) {
      debugPrint('App initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showLaunch = false;
        });
      }
    }
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }


  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduGrade',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _showLaunch || _isInitializing ? const AppLaunchScreen() : const EntryPoint(),
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
   

  