import 'package:flutter/material.dart';
import '../screens/resume_template_selection_screen.dart';
import 'saved_resumes_screen.dart';
import 'cover_letter_form_screen.dart';
import 'prewritten_content_screen.dart';
import 'video_resume_screen.dart';
import 'premium_upgrade_screen.dart';
import 'premium_test_screen.dart';
import 'settings_screen.dart';
import 'premium_testing_screen.dart';
import '../services/premium_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (AppConfig.enableTestingMode) ...[
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              tooltip: 'Premium Testing',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumTestingScreen(),
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.purple),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
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
                subtitle: const Text('Choose from professional templates'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple,
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ResumeTemplateSelectionScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.folder, color: Colors.blue),
                ),
                title: const Text(
                  'My Resumes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Access your saved resumes'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue,
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedResumesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // New Features Section
            const Text(
              'Enhanced Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),

            // Cover Letter Builder
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.email, color: Colors.teal),
                ),
                title: Row(
                  children: [
                    const Text(
                      'Cover Letter Builder',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (!PremiumService.hasCoverLetterFeature) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                    ),
                  ),
                ),
                subtitle: const Text('AI-powered cover letter templates'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.teal,
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoverLetterFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Content Assistant
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.edit_note, color: Colors.indigo),
                ),
                title: const Text(
                  'Content Assistant',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Pre-written content and guidance'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.indigo,
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrewrittenContentScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Video Resume
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: const Icon(Icons.videocam, color: Colors.purple),
                ),
                title: Row(
                  children: [
                    const Text(
                      'Video Resume',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (!PremiumService.hasVideoResumeFeature) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: const Text('Create professional video resumes'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple,
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VideoResumeScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            freePlanBanner(context),
          ],
        ),
      ),
    );
  }

  Widget freePlanBanner(BuildContext context) {
    if (PremiumService.isPremium) {
      return Card(
        color: Colors.deepPurple.shade50,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Active! 🎉',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    Text(
                      'Enjoy unlimited features and premium templates',
                      style: TextStyle(color: Colors.deepPurple.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Free Plan Limitations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Only ${PremiumService.availableTemplates.join(" & ")} templates',
              style: TextStyle(color: Colors.orange[700]),
            ),
            Text(
              '• Max ${PremiumService.maxResumes} resumes',
              style: TextStyle(color: Colors.orange[700]),
            ),
            Text(
              '• PDF export with watermark',
              style: TextStyle(color: Colors.orange[700]),
            ),
            Text(
              '• No AI features or cloud sync',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ],
        ),
      ),
    );
  }
}
