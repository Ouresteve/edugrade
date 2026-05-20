import 'package:edugrade/screens/classes_screen.dart';
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


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.checkTeacherProfile();
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduGrade.KE',
      theme: AppTheme.lightTheme,
      home: const EntryPoint(),
       routes: {
        '/home': (context) => const HomeScreen(),
        '/setup': (context) => const TeacherSetupScreen(),
        '/cbc_config': (context) => const CbcConfigScreen(),
        '/student_config': (context) => const StudentConfigScreen(),
        '/class': (context) => const ClassesScreen(),
        '/subjects' : (context) => const SubjectsScreen(),
        
      },
    );
  }
}      