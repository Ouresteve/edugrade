import 'package:flutter/material.dart';
import 'theme.dart';
import 'entry_point.dart';
import 'home_screen.dart';
import 'setup.dart';
import 'loading_dialog.dart';
import '../globals.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "title": "Welcome to EduGrade",
      //"desc": "Assessment under CBC has come with a lot more work for teachers. Most teachers assess and keep records by hand, these processes are burdensome and repetitive. It is also very difficult to analyze manual records. The EdugradeApp reduces the time teachers take to assess from hours to minutes, provides highly accurate records, and automatically generates learners' reports - all with a click of a button!",
      "desc" : "Assessment under CBC has come with a lot more work for teachers. Most teachers asses records by hand, these processes are burdensome.",
      "icon": Icons.school,
      "color": AppTheme.primary,
    },
    {
      "title": "Auto CBC Grading",
      "desc": "Enter percentage → Get Exceeding, Meeting, Approaching or Below Expectations instantly",
      "icon": Icons.auto_awesome,
      "color": AppTheme.accent,
    },
    {
      "title": "Works Offline",
      "desc": "No internet needed For Perfect Grading. Perfect for rural and urban schools across Kenya",
      "icon": Icons.offline_bolt,
      "color": Colors.orange,
    },
    {
      "title": "Collaborate & Share",
      "desc": "Easily share student performance reports with parents and colleagues, Let Subject Teachers enter marks on their phone and sync when connected to the internet  ",
      "icon": Icons.group,
      "color": AppTheme.accent,
    },
    {
      "title": "Get Started Now",
      "desc": "Set up your Classes and start grading in minutes. Welcome to the future of grading with EduGrade!",
      "icon": Icons.rocket_launch,
      "color": Colors.orange,  
    }

    
  ];

  void nextPage() {
    if (currentIndex < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    //Edit: For now, we will just set hasTeacher to true when onboarding is done. Later we will navigate to Teacher Setup or Home
    if (currentIndex == pages.length - 1) {
      
      hasTeacher = true; 
      EntryPoint();
    }
  }

  void skip()  async {
    // Later we will navigate to Teacher Setup or Home
 // Simulate teacher presence
    
    hasTeacher = true;
    LoadingDialog.show(context, message: "Setting things up for you...");
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) LoadingDialog.hide(context);
    if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TeacherSetupScreen(),
        ),
    );
    
      
    }
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       backgroundColor: const Color(0xFF1A73E8),
        title: const Text(
          "EduGrade",
         style:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        actions: [
          TextButton(
            onPressed: skip,
            child: const Text("Skip", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
  itemBuilder: (context, index) {
  final page = pages[index];
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.background,
      image: const DecorationImage(
        image: AssetImage('assets/images/doodle.jpg'),
        fit: BoxFit.cover,
        opacity: 0.15,           // Very subtle - important!
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page["icon"] as IconData,
            size: 130,
            color: page["color"] as Color,
          ),
          const SizedBox(height: 50),
          Text(
            page["title"] as String,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page["desc"] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
},
            ),
          ),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: currentIndex == index ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? AppTheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),

          const SizedBox(height: 40),

          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: SizedBox(
    width: double.infinity, // Makes button fill the width, or use a fixed number like 200
    height: 50, // Optional: Sets the button height
    child: ElevatedButton(
      onPressed: () {
        if (currentIndex == pages.length - 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TeacherSetupScreen(),
            ),
          );
        } else {
          nextPage();
        }
      },
      child: Text(
        currentIndex == pages.length - 1 ? "Get Started" : "Next",
      ),
    ),
  ),
),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}