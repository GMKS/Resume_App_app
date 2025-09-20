import 'package:flutter/material.dart';
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';

class ResumeTemplateSelectionScreen extends StatefulWidget {
  const ResumeTemplateSelectionScreen({super.key});

  @override
  State<ResumeTemplateSelectionScreen> createState() =>
      _ResumeTemplateSelectionScreenState();
}

class _ResumeTemplateSelectionScreenState
    extends State<ResumeTemplateSelectionScreen> {
  int selected = 0;
  final List<Map<String, dynamic>> templates = [
    {
      'title': 'Classic Template 1',
      'icon': Icons.description,
      'desc': 'Simple, professional, clean.',
    },
    {
      'title': 'Modern Template 1',
      'icon': Icons.auto_awesome,
      'desc': 'Stylish, bold headings, color.',
    },
    {
      'title': 'Minimal',
      'icon': Icons.minimize,
      'desc': 'Minimalist, lots of whitespace.',
    },
  ];

  String _getTemplatePreview(int index) {
    switch (index) {
      case 0:
        return 'Classic Template Example:\n\nJohn Doe\nSoftware Engineer\nSummary: ...\nSkills: ...\nExperience: ...';
      case 1:
        return 'Modern Template Example:\n\nJane Smith\nUI/UX Designer\nSummary: ...\nSkills: ...\nExperience: ...';
      case 2:
        return 'Minimal Template Example:\n\nAlex Lee\nData Analyst\nSummary: ...\nSkills: ...\nExperience: ...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose resume template')),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = selected == index;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(template['icon']),
                    title: Text(template['title']),
                    subtitle: Text(template['desc']),
                    selected: isSelected,
                    onTap: () => setState(() => selected = index),
                  ),
                  if (isSelected) ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Colors.grey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _getTemplatePreview(index),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Widget targetScreen;
              switch (selected) {
                case 0:
                  targetScreen = const ClassicResumeFormScreen();
                  break;
                case 1:
                  targetScreen = const ModernResumeFormScreen();
                  break;
                case 2:
                  targetScreen = const MinimalResumeFormScreen();
                  break;
                default:
                  targetScreen = const ClassicResumeFormScreen();
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => targetScreen),
              );
            },
            child: const Text('Next'),
          ),
        ),
      ],
    ),
  );
}
