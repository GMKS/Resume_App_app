import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'resume_template_selection_screen.dart';
import 'saved_resumes_screen.dart';
import 'smart_assist_screen.dart';
import 'settings_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  // Add your real screen widgets (ensure each file & const constructor exists)
  final List<Widget> _screens = const [
    HomeScreen(),
    ResumeTemplateSelectionScreen(),
    SavedResumesScreen(),
    SmartAssistScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) {
          FocusScope.of(context).unfocus();
          setState(() => _currentIndex = i);
        },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
