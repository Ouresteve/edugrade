import 'package:flutter/material.dart';
import 'theme.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class ReportsArchiveScreen extends StatefulWidget {
  const ReportsArchiveScreen({super.key});

  @override
  State<ReportsArchiveScreen> createState() => _ReportsArchiveScreenState();
}

class _ReportsArchiveScreenState extends State<ReportsArchiveScreen> {
  List<File> reportFiles = [];
  bool isLoading = true;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _deleteReport(File file) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Report?"),
      content: Text("Are you sure you want to delete\n${file.uri.pathSegments.last}?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      await file.delete();
      _loadReports(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report deleted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e")),
        );
      }
    }
  }
}

  Future<void> _requestPermission() async {
    setState(() => isLoading = true);

    final status = await Permission.storage.request();
    final manageStatus = await Permission.manageExternalStorage.request();

    setState(() {
      hasPermission = status.isGranted || manageStatus.isGranted;
    });

    if (hasPermission) {
      _loadReports();
    } else {
      setState(() => isLoading = false);
    }
  }
Future<void> _loadReports() async {
  setState(() => isLoading = true);
  reportFiles.clear();

  try {
    // Try public Downloads folder first
    final externalDir = await getExternalStorageDirectory();
    
    if (externalDir != null) {
      // Look in a dedicated EduGrade folder inside Downloads
      final reportsDir = Directory('${externalDir.path}/EduGrade_Reports');
      
      if (await reportsDir.exists()) {
        final files = reportsDir.listSync().whereType<File>();

        reportFiles = files.where((file) => 
          file.path.toLowerCase().endsWith('.pdf') || 
          file.path.toLowerCase().endsWith('.xlsx')
        ).toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      }
    }

    // Fallback: Check app documents directory
    if (reportFiles.isEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync().whereType<File>();

      reportFiles = files.where((file) => 
        file.path.toLowerCase().endsWith('.pdf') || 
        file.path.toLowerCase().endsWith('.xlsx')
      ).toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
  } catch (e) {
    print("Error loading reports: $e");
  } finally {
    setState(() => isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: AppTheme.primary,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
            if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(context, '/class', (route) => false);
            } else if (index== 3) {
              Navigator.pushNamedAndRemoveUntil(context, '/reports', (route) => false);
            } else if (index==0) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false,);
            } else if (index==1) {
                Navigator.pushNamedAndRemoveUntil(context, '/group', (route) => false,);
            } else if (index==4) {
                Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false,);
            } 
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "class"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "settings"),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_off, size: 70, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Storage Permission Required", style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: const Text("Grant Permission"),
                      ),
                    ],
                  ),
                )
              : reportFiles.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off, size: 70, color: Colors.grey),
                          SizedBox(height: 16),
                          Text("No reports generated yet", style: TextStyle(fontSize: 18)),
                          Text("Generate reports from Class Detail", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: reportFiles.length,
                      itemBuilder: (context, index) {
                        final file = reportFiles[index];
                        final isPdf = file.path.endsWith('.pdf');
                        final fileName = file.uri.pathSegments.last;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child:ListTile(
  leading: Icon(
    isPdf ? Icons.picture_as_pdf : Icons.table_chart,
    color: isPdf ? Colors.red : Colors.green,
    size: 48,
  ),
  title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500)),
  subtitle: Text(
    file.lastModifiedSync().toString().substring(0, 16),
  ),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.open_in_new),
        onPressed: () async {
          final result = await OpenFile.open(file.path);
          if (result.type != ResultType.done && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Could not open file")),
            );
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _deleteReport(file),
      ),
    ],
  ),
),
                        );
                      },
                    ),
    );

    
  }

   
}