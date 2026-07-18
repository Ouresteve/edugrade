
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'cbc_config.dart';
import '../globals.dart';
import '../services/app_state.dart';
// This is a temporary entry point for testing the onboarding screen.
class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState()=> _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  Future<void> _refreshState() async {
    try {
      await AppState.checkTeacherProfile();
    } catch (e) {
      debugPrint('Entry point state refresh failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasTeacher) {
      return const OnboardingScreen();
    } else if (hasTeacher && !continuingOnboarding) {
      return const HomeScreen();
    } else if (hasTeacher && continuingOnboarding) {
      return const CbcConfigScreen();
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
