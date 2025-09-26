import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/requirements_banner.dart';
import '../widgets/dynamic_sections.dart';
import '../services/share_export_service.dart';
import '../widgets/ai_widgets.dart';

class MinimalResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const MinimalResumeFormScreen({super.key, this.existing});

  @override
  State<MinimalResumeFormScreen> createState() =>
      _MinimalResumeFormScreenState();
}

class _MinimalResumeFormScreenState extends State<MinimalResumeFormScreen> {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existing != null) {
      // Load work experiences from JSON
      if (widget.existing!.data['workExperiences'] != null) {
        try {
          final List<dynamic> workExpData = jsonDecode(
            widget.existing!.data['workExperiences'],
          );
          _workExperiences = workExpData
              .map((item) => WorkExperience.fromJson(item))
              .toList();
        } catch (e) {
          _workExperiences = [];
        }
      }

      // Load education from JSON
      if (widget.existing!.data['educations'] != null) {
        try {
          final List<dynamic> educationData = jsonDecode(
            widget.existing!.data['educations'],
          );
          _educations = educationData
              .map((item) => Education.fromJson(item))
              .toList();
        } catch (e) {
          _educations = [];
        }
      }
    }
  }

  String _getResumeContent(Map<String, TextEditingController> controllers) {
    final buffer = StringBuffer();

    // Add basic info
    if (controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${controllers['name']!.text}');
    }
    if (controllers['email']?.text.isNotEmpty == true) {
      buffer.writeln('Email: ${controllers['email']!.text}');
    }
    if (controllers['phone']?.text.isNotEmpty == true) {
      buffer.writeln('Phone: ${controllers['phone']!.text}');
    }

    // Add summary
    if (controllers['summary']?.text.isNotEmpty == true) {
      buffer.writeln('\nSummary: ${controllers['summary']!.text}');
    }

    // Add skills
    if (controllers['skills']?.text.isNotEmpty == true) {
      buffer.writeln('\nSkills: ${controllers['skills']!.text}');
    }

    // Add dynamic work experiences
    if (_workExperiences.isNotEmpty) {
      buffer.writeln('\nWork Experience:');
      for (final exp in _workExperiences) {
        buffer.writeln('• ${exp.jobTitle} at ${exp.company}');
        if (exp.description.isNotEmpty) {
          buffer.writeln('  ${exp.description}');
        }
      }
    }

    // Add dynamic education
    if (_educations.isNotEmpty) {
      buffer.writeln('\nEducation:');
      for (final edu in _educations) {
        buffer.writeln('• ${edu.degree} from ${edu.institution}');
        if (edu.description.isNotEmpty) {
          buffer.writeln('  ${edu.description}');
        }
      }
    }

    // Add other sections
    if (controllers['certifications']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nCertifications: ${controllers['certifications']!.text}',
      );
    }
    if (controllers['languages']?.text.isNotEmpty == true) {
      buffer.writeln('\nLanguages: ${controllers['languages']!.text}');
    }
    if (controllers['hobbies']?.text.isNotEmpty == true) {
      buffer.writeln('\nHobbies: ${controllers['hobbies']!.text}');
    }

    return buffer.toString();
  }

  Future<void> _exportResume(String format) async {
    final state = BaseResumeForm.of(context);
    if (state == null) return;

    // Validate form first (check if key fields are filled)
    if (state.controllerFor('name').text.isEmpty ||
        state.controllerFor('email').text.isEmpty ||
        state.controllerFor('phone').text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields first'),
        ),
      );
      return;
    }

    try {
      // Create resume object manually for export
      final Map<String, dynamic> data = {
        for (final e in state.controllers.entries) e.key: e.value.text,
      };

      final resume = SavedResume(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.controllerFor('name').text.isNotEmpty
            ? '${state.controllerFor('name').text} Resume'
            : 'Minimal Resume',
        template: 'Minimal',
        data: data,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      switch (format) {
        case 'PDF':
          await ShareExportService.instance.exportAndOpenPdf(resume);
          break;
        case 'DOCX':
          final file = await ShareExportService.instance.exportDoc(resume);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DOCX exported to: ${file.path}')),
          );
          break;
        case 'TXT':
          final file = await ShareExportService.instance.exportTxt(resume);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TXT exported to: ${file.path}')),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: widget.existing,
      template: 'Minimal',
      extraKeys: const [
        'languages',
        'hobbies',
        'certifications',
        'workExperiences',
        'educations',
      ],
      child: Builder(
        builder: (ctx) {
          final state = BaseResumeForm.of(ctx)!;

          // Initialize JSON data in controllers if not already set
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.controllerFor('workExperiences').text.isEmpty) {
              state.controllerFor('workExperiences').text = jsonEncode(
                _workExperiences.map((e) => e.toJson()).toList(),
              );
            }
            if (state.controllerFor('educations').text.isEmpty) {
              state.controllerFor('educations').text = jsonEncode(
                _educations.map((e) => e.toJson()).toList(),
              );
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Minimal Resume'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  onSelected: _exportResume,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'PDF',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf),
                        title: Text('Export as PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'DOCX',
                      child: ListTile(
                        leading: Icon(Icons.description),
                        title: Text('Export as DOCX'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'TXT',
                      child: ListTile(
                        leading: Icon(Icons.text_snippet),
                        title: Text('Export as TXT'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RequirementsBanner(
                    requiredFieldLabels: {
                      'name': 'Full Name',
                      'phone': 'Mobile Number',
                      'email': 'Email Address',
                      'summary': 'Summary',
                      'skills': 'Skills',
                    },
                  ),

                  _section('Personal Information'),
                  state.buildTextField('name', 'Full Name', required: true),
                  state.buildTextField(
                    'phone',
                    'Mobile Number',
                    required: true,
                    keyboard: TextInputType.phone,
                  ),
                  state.buildTextField(
                    'email',
                    'Email Address',
                    required: true,
                    keyboard: TextInputType.emailAddress,
                  ),

                  _section('Summary'),
                  AISummaryGenerator(
                    name: state.controllers['name']?.text ?? '',
                    targetRole: 'Professional',
                    skills: (state.controllers['skills']?.text ?? '')
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                    experience: _workExperiences
                        .map(
                          (exp) =>
                              '${exp.jobTitle} at ${exp.company}: ${exp.description}',
                        )
                        .toList(),
                    onGenerated: (summary) {
                      state.controllers['summary']?.text = summary;
                    },
                  ),
                  state.buildTextField(
                    'summary',
                    'Summary',
                    maxLines: 3,
                    required: true,
                  ),

                  _section('Experience'),
                  DynamicWorkExperienceSection(
                    workExperiences: _workExperiences,
                    onWorkExperiencesChanged: (experiences) {
                      setState(() {
                        _workExperiences = experiences;
                        // Update JSON in hidden controller for BaseResumeForm
                        state
                            .controllerFor('workExperiences')
                            .text = jsonEncode(
                          experiences.map((e) => e.toJson()).toList(),
                        );
                      });
                    },
                  ),

                  _section('Education'),
                  DynamicEducationSection(
                    educations: _educations,
                    onEducationsChanged: (educations) {
                      setState(() {
                        _educations = educations;
                        // Update JSON in hidden controller for BaseResumeForm
                        state.controllerFor('educations').text = jsonEncode(
                          educations.map((e) => e.toJson()).toList(),
                        );
                      });
                    },
                  ),

                  _section('Skills'),
                  state.buildTextField(
                    'skills',
                    'Skills (comma separated)',
                    maxLines: 2,
                    required: true,
                  ),

                  _section('Certifications'),
                  state.buildTextField(
                    'certifications',
                    'Certifications',
                    maxLines: 2,
                  ),

                  _section('Languages'),
                  state.buildTextField('languages', 'Languages', maxLines: 2),

                  _section('Hobbies'),
                  state.buildTextField('hobbies', 'Hobbies', maxLines: 2),

                  const SizedBox(height: 24),

                  // ATS Optimization Panel
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription:
                        '', // Could be enhanced to get from user input
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: () => state.saveResume(),
                      label: const Text('Save Minimal Resume'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );
}
