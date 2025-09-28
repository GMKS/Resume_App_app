import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';
import 'professional_resume_form_screen.dart';
import 'creative_resume_form_screen.dart';
import 'saved_resumes_screen.dart';
import 'settings_screen.dart';

class MockHomeScreen extends StatelessWidget {
  const MockHomeScreen({super.key});

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
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 32, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                'User: ${MockAuthService.instance.currentUser}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              Text(
                                'Login Type: ${MockAuthService.instance.loginType}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Resume Templates Section
            Text(
              'Resume Templates',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildTemplateCard(
                  context,
                  'Professional',
                  Icons.business_center,
                  Colors.blue,
                  () => _openTemplate(context, 'Professional'),
                ),
                _buildTemplateCard(
                  context,
                  'Creative',
                  Icons.palette,
                  Colors.purple,
                  () => _openTemplate(context, 'Creative'),
                ),
                _buildTemplateCard(
                  context,
                  'Modern',
                  Icons.trending_up,
                  Colors.green,
                  () => _openTemplate(context, 'Modern'),
                ),
                _buildTemplateCard(
                  context,
                  'Minimal',
                  Icons.minimize,
                  Colors.orange,
                  () => _openTemplate(context, 'Minimal'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'My Resumes',
                    Icons.folder,
                    Colors.indigo,
                    () => _showMyResumes(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Smart Assist',
                    Icons.auto_awesome,
                    Colors.teal,
                    () => _showSmartAssist(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login System Working!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mock Mode - All features available for testing',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewResume(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to create',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTemplate(BuildContext context, String templateName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$templateName Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Create a new resume using the $templateName template?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTemplateForm(context, templateName);
              },
              child: const Text('Create Resume'),
            ),
          ],
        );
      },
    );
  }

  void _showTemplateForm(BuildContext context, String templateName) {
    Widget screen;
    switch (templateName) {
      case 'Professional':
        screen = const ProfessionalResumeFormScreen();
        break;
      case 'Creative':
        screen = const CreativeResumeFormScreen();
        break;
      case 'Modern':
        screen = const ModernResumeFormScreen();
        break;
      case 'Minimal':
        screen = const MinimalResumeFormScreen();
        break;
      case 'Classic':
        screen = const ClassicResumeFormScreen();
        break;
      default:
        screen = const ClassicResumeFormScreen();
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _createNewResume(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a Template',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.business_center, color: Colors.blue),
                title: const Text('Professional'),
                subtitle: const Text('Perfect for corporate jobs'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openTemplate(context, 'Professional');
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.purple),
                title: const Text('Creative'),
                subtitle: const Text('Stand out with creativity'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openTemplate(context, 'Creative');
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.green),
                title: const Text('Modern'),
                subtitle: const Text('Clean and contemporary'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openTemplate(context, 'Modern');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMyResumes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedResumesScreen()),
    );
  }

  void _showSmartAssist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Smart Assist feature - Navigation working!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await MockAuthService.instance.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
