import 'package:flutter/material.dart';
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';
import 'creative_resume_form_screen.dart';
import 'one_page_resume_form_screen.dart';
import '../widgets/new_resume_title_dialog.dart';
import 'professional_setup_wizard.dart';

class ResumeTemplateSelectionScreen extends StatelessWidget {
  const ResumeTemplateSelectionScreen({super.key});

  /// Helper method to navigate to the appropriate form screen based on template
  void _navigateToTemplateFormScreen(
    BuildContext context,
    String templateName,
  ) {
    Widget screen;
    switch (templateName) {
      case 'Classic':
        screen = const ClassicResumeFormScreen();
        break;
      case 'Modern':
        screen = const ModernResumeFormScreen();
        break;
      case 'Minimal':
        screen = const MinimalResumeFormScreen();
        break;
      case 'Professional':
        _createProfessionalFlow(context);
        return;
      case 'Creative':
        screen = const CreativeResumeFormScreen();
        break;
      case 'One Page':
        screen = const OnePageResumeFormScreen();
        break;
      default:
        screen = const ClassicResumeFormScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _createProfessionalFlow(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const NewResumeTitleDialog(),
    );
    if (title == null || title.trim().isEmpty) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalSetupWizard(title: title.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Template'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Resume Template',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildTemplateCard(
                    context,
                    'Classic',
                    Icons.description,
                    'Traditional layout',
                    Colors.blue,
                  ),
                  _buildTemplateCard(
                    context,
                    'Modern',
                    Icons.auto_awesome,
                    'Contemporary design',
                    Colors.purple,
                  ),
                  _buildTemplateCard(
                    context,
                    'Minimal',
                    Icons.crop_square,
                    'Clean & simple',
                    Colors.green,
                  ),
                  _buildTemplateCard(
                    context,
                    'Professional',
                    Icons.business_center,
                    'Business formal',
                    Colors.orange,
                  ),
                  _buildTemplateCard(
                    context,
                    'Creative',
                    Icons.palette,
                    'Artistic layout',
                    Colors.red,
                  ),
                  _buildTemplateCard(
                    context,
                    'One Page',
                    Icons.description_outlined,
                    'Compact format',
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          _navigateToTemplateFormScreen(context, title);
        },
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
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
