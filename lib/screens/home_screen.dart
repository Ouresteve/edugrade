import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'classes_detail_screen.dart';
import 'theme.dart';
import '../services/database_helper.dart';
import '../services/update_checker.dart';
import 'package:sqflite/sqflite.dart';

/*import 'entry_point.dart';
import 'onBoarding_screen.dart';*/
import '../globals.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String greeting = "";
  String classPlural = "Classes";
  late Map<String, dynamic>  cls ;
  
  //String classPlural = "Classes";
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = []; 
  List<Map<String, dynamic>> sbj = [];
  bool isLoading = true;  
  @override
  void initState() {
    super.initState();
    Initializedatainclass();
    _setGreeting();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateChecker.checkForUpdate(context);
      }
    });
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }
  }

   Future<void> Initializedatainclass() async  {
     setState(() => isLoading = true, );
     //List<Map<String, dynamic>> classes = [];
      final db = await  DatabaseHelper.instance.database;
      try {
        setState(() => isLoading = true);
        final subjects= await db.query ('subjects');
        final student= await db.query('students');  
        final results= await db.query('classes', orderBy: 'created_at DESC');
        setState((){
        classes = results;
        sbj = subjects;
        students = student;

        
        if (classes.length == 1) {
            classPlural = "Class";
        } else {
          classPlural = "Classes";
        } 
        });
      } catch (e) {
        setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading classes: $e")),
        );
      }
    }
  

  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EduGrade"),
        automaticallyImplyLeading: false, 
        actions: [
          
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            //offset: const Offset(0,0),
            padding:  EdgeInsets.zero,
            constraints: const BoxConstraints(),
            position: PopupMenuPosition.under,
            color: AppTheme.primary,
             shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if(value == "Settings"){
                Navigator.pushNamed(context, '/cbc_config');
              
              //Menu Actions
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Selected: Settings")),
              );
            } 
             if (value== "Subjects") {
              Navigator.pushNamed(context, '/subjects');
             }
            },
            itemBuilder: (context) => [
             const PopupMenuItem(value: "Subjects", child: Text("Subjects",style: TextStyle(color: AppTheme.background))),
              const PopupMenuItem(value: "Settings", child: Text("Settings",style: TextStyle(color: AppTheme.background))),
              const PopupMenuItem(value: "Help", child: Text("Help & Support",style: TextStyle(color: AppTheme.background))),
              const PopupMenuItem(value: "about", child: Text("About", style: TextStyle(color: AppTheme.background)))
            ],
          ),
          //const SizedBox(width: 8),
          
        ],
      ),
          
      body: SingleChildScrollView(
        
        padding: const EdgeInsets.all(16),
        child: Column(      
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
             Text(
              "$greeting, Mwalimu $teacherName 👋",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
           Text(
              "$schoolName",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Overview Stats
            Row(
              children: [
                _buildStatCard("Students", "${students.length}", "All classes", Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard("$classPlural", "${classes.length}", "Active", Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard("Subjects", "${sbj.length}", "This term", Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard("Reports"," Infinite", "Generation", Colors.purple),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(Icons.settings, "Settings", Colors.blueGrey, onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/settings',(route)=>false);
                }),
              
                _buildActionCard(Icons.schedule, "TimeTable", Colors.orange, onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text("Coming Soon...!"),
                    backgroundColor: AppTheme.success,
      ),
    );              
                          },
                ),
                _buildActionCard(Icons.class_,
                 classPlural,
                  Colors.indigo,
                 onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/class',(route)=> false);
                 },
                 ),
                _buildActionCard(Icons.book, "Subjects", Colors.teal, onTap: () {
                  Navigator.pushNamed(context, '/subjects');
                }
                ),
                _buildActionCard(Icons.picture_as_pdf, "Reports", Colors.red, onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/reports', (route)=> false);
                },
                ),
                
              ],
            ),

            const SizedBox(height: 32),

                        // Recent Classes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Classes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/class'),
                  child: const Text("View All"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Scrolling Recent Classes
            SizedBox(
              height: 160,   // Fixed height for horizontal cards
              child: classes.isEmpty
                  ? const Center(child: Text("No classes yet"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                         cls = classes[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildHorizontalClassCard(cls),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
           if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(context, '/class', (route) => false);
            } else if (index== 3) {
              Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
            } else if (index==0) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false,);
            } else if (index == 4) {
              Navigator.pushNamedAndRemoveUntil(context, '/settings',(route)=> false);
            } else if (index==1) {
                Navigator.pushNamedAndRemoveUntil(context, '/group', (route) => false,);
            }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: classPlural),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "settings"),
        ],
      ),
    );
  }

  Widget _buildHorizontalClassCard(Map<String, dynamic> cls) {
    return Container(
      
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
       child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(classData: cls),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opened ${cls['class_name']}")),
          );
        },

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.school, color: Colors.blue),
                ),
                const Spacer(),
                Text(
                  "${cls['student_count'] ?? 0} students",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],



            ),
            const Spacer(),
            Text(
              cls['class_name'] ?? 'Unknown Class',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "${cls['level'] ?? ''} • ${cls['academic_year'] ?? '2026'}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ), ),
    );
  }
  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Expanded(
       
      child: Container(
        
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
     String label, 
     Color color,
     {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container (
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
      ),
    );
  }

  Widget _buildClassCard(String className, String students, String lastUpdated, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.school, color: color),
        ),
        title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(students),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(lastUpdated, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}