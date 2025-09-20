import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';

class SavedResumesScreen extends StatefulWidget {
  const SavedResumesScreen({super.key});
  @override
  State<SavedResumesScreen> createState() => _SavedResumesScreenState();
}

class _SavedResumesScreenState extends State<SavedResumesScreen> {
  List<SavedResume> _resumes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    final resumes = await ResumeStorageService.getResumes();
    setState(() {
      _resumes = resumes;
      _loading = false;
    });
  }

  void _editResume(SavedResume resume) {
    Widget targetScreen;
    switch (resume.template.toLowerCase()) {
      case 'classic':
        targetScreen = ClassicResumeFormScreen(existingResume: resume);
        break;
      case 'modern':
        targetScreen = ModernResumeFormScreen(existingResume: resume);
        break;
      case 'minimal':
        targetScreen = MinimalResumeFormScreen(existingResume: resume);
        break;
      default:
        targetScreen = ClassicResumeFormScreen(existingResume: resume);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    ).then((_) => _loadResumes());
  }

  void _duplicateResume(SavedResume resume) async {
    final newResume = SavedResume(
      id: ResumeStorageService.generateId(),
      title: '${resume.title} (Copy)',
      template: resume.template,
      data: Map<String, String>.from(resume.data),
      applications: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ResumeStorageService.saveResume(newResume);
    _loadResumes();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume duplicated successfully')),
    );
  }

  void _confirmDelete(SavedResume resume) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text('Are you sure you want to delete "${resume.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ResumeStorageService.deleteResume(resume.id);
              _loadResumes();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: const Text('Saved Resumes'),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResumes),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _resumes.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No saved resumes yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _resumes.length,
            itemBuilder: (context, index) {
              final resume = _resumes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTemplateColor(resume.template),
                    child: Text(
                      resume.template[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    resume.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Template: ${resume.template}\nApplications: ${resume.applications.length}',
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editResume(resume);
                          break;
                        case 'duplicate':
                          _duplicateResume(resume);
                          break;
                        case 'delete':
                          _confirmDelete(resume);
                          break;
                      }
                    },
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResumeDetailsScreen(resume: resume),
                    ),
                  ).then((_) => _loadResumes()),
                ),
              );
            },
          ),
  );

  Color _getTemplateColor(String template) {
    switch (template.toLowerCase()) {
      case 'classic':
        return Colors.blue;
      case 'modern':
        return Colors.purple;
      case 'minimal':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }
}

class ResumeDetailsScreen extends StatelessWidget {
  final SavedResume resume;
  const ResumeDetailsScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(resume.title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Template: ${resume.template}'),
                Text('Applications: ${resume.applications.length}'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
