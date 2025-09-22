import 'package:flutter/material.dart';
import '../screens/resume_template_selection_screen.dart';
import './saved_resumes_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F6FA),
    appBar: AppBar(
      title: const Text(
        'Resume Builder',
        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Colors.purple),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.purple),
          tooltip: 'Logout',
          onPressed: () async {
            await AuthService.instance.logout();
            loggedInNotifier.value = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully')),
            );
          },
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '👋 Hello!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Build, edit, and download resumes anytime, anywhere!',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: const Icon(Icons.description, color: Colors.purple),
              ),
              title: const Text(
                'Create New Resume',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Pick a template and start editing'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.purple,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResumeTemplateSelectionScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.folder, color: Colors.blue),
              ),
              title: const Text(
                'View Saved Resumes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Access your saved resumes'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedResumesScreen()),
                );
              },
            ),
          ),
          freePlanBanner(),
        ],
      ),
    ),
  );

  Widget freePlanBanner() => Card(
    color: Colors.yellow.shade50,
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Free Plan Features',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          SizedBox(height: 8),
          Text('• Save up to 5 resumes in the cloud'),
          Text('• Export in PDF (Classic only)'),
          Text('• Share via Email (Classic only)'),
          Text('• Classic & limited Modern templates'),
        ],
      ),
    ),
  );
}
