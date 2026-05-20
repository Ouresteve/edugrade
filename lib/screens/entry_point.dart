
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'theme.dart';
import 'cbc_config.dart';
import '../services/database_helper.dart';
import '../globals.dart';
// This is a temporary entry point for testing the onboarding screen.
class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState()=> _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  
 // hasTeacher = true; // Simulate teacher presence
   
   
   // Simulate onboarding completion status
   @override
  
  Widget build(BuildContext context) {
      if (!hasTeacher) {
        return const OnboardingScreen();
      } else if (hasTeacher && !continuingOnboarding) {
        return const HomeScreen();
      } else if (hasTeacher && continuingOnboarding) {
        // return const OnboardingScreen()
        return const CbcConfigScreen();
  
      }
  
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}
