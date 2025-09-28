import 'package:flutter/material.dart';
import 'resume_template_selection_screen.dart';
import 'smart_assist_screen.dart';
import 'saved_resumes_screen.dart';
import 'settings_screen.dart';

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Resume Builder!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create professional resumes with Node.js backend',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Main Features Grid
            const Text(
              'Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Create Resume',
                    Icons.add_circle,
                    Colors.green,
                    'Start building your professional resume',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ResumeTemplateSelectionScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Smart Assist',
                    Icons.psychology,
                    Colors.purple,
                    'AI-powered resume suggestions',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmartAssistScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Customize',
                    Icons.palette,
                    Colors.orange,
                    'Personalize your resume design',
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customization - Coming Soon!'),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'My Resumes',
                    Icons.folder,
                    Colors.blue,
                    'View and manage your resumes',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedResumesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResumeTemplateSelectionScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
