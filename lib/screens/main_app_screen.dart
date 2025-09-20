import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'resume_template_selection_screen.dart';
import 'saved_resumes_screen.dart';

// Create these files if they don't exist
import 'smart_assist_screen.dart';
import 'settings_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const ResumeTemplateSelectionScreen(),
    const SavedResumesScreen(),
    const SmartAssistScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screens[_currentIndex],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Templates',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Saved'),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'Smart Assist',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );
}
