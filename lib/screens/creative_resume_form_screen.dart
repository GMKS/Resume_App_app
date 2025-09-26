import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/saved_resume.dart';
import '../models/branding.dart';
import '../screens/customization_screen.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/requirements_banner.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/ai_widgets.dart';
import '../services/share_export_service.dart';

class CreativeResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const CreativeResumeFormScreen({super.key, this.existing});

  @override
  State<CreativeResumeFormScreen> createState() =>
      _CreativeResumeFormScreenState();
}

class _CreativeResumeFormScreenState extends State<CreativeResumeFormScreen> {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  BrandingTheme _currentBranding = BrandingTheme.creative;

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

      // Load branding from JSON
      if (widget.existing!.data['branding'] != null) {
        try {
          final Map<String, dynamic> brandingData = jsonDecode(
            widget.existing!.data['branding'],
          );
          _currentBranding = BrandingTheme.fromJson(brandingData);
        } catch (e) {
          _currentBranding = BrandingTheme.creative;
        }
      }
    }
  }

  void _loadBrandingFromResume() {
    final state = BaseResumeForm.of(context);
    if (state != null && state.controllerFor('branding').text.isNotEmpty) {
      try {
        final Map<String, dynamic> brandingData = jsonDecode(
          state.controllerFor('branding').text,
        );
        setState(() {
          _currentBranding = BrandingTheme.fromJson(brandingData);
        });
      } catch (e) {
        // Keep current branding if parsing fails
      }
    }
  }

  void _openCustomization() async {
    final result = await Navigator.push<BrandingTheme>(
      context,
      MaterialPageRoute(builder: (context) => const CustomizationScreen()),
    );

    if (result != null) {
      setState(() {
        _currentBranding = result;
      });

      // Update the form controller
      final state = BaseResumeForm.of(context);
      if (state != null) {
        state.controllerFor('branding').text = jsonEncode(result.toJson());
      }
    }
  }

  Future<void> _exportResume(String format) async {
    final state = BaseResumeForm.of(context);
    if (state == null) return;

    // Check if required fields are filled
    if (state.controllers['name']?.text.isEmpty == true ||
        state.controllers['email']?.text.isEmpty == true ||
        state.controllers['phone']?.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields first'),
        ),
      );
      return;
    }

    try {
      // Create the resume object manually
      final Map<String, dynamic> data = {
        for (final e in state.controllers.entries) e.key: e.value.text,
      };

      final resume = SavedResume(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.controllers['name']?.text ?? 'Creative Resume',
        template: 'Creative',
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final shareService = ShareExportService.instance;
      File? file;

      switch (format) {
        case 'pdf':
          file = await shareService.exportPdf(resume);
          break;
        case 'docx':
          file = await shareService.exportDoc(resume);
          break;
        case 'txt':
          file = await shareService.exportTxt(resume);
          break;
      }

      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume exported as ${format.toUpperCase()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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

    // Add creative summary
    if (controllers['creativeSummary']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nCreative Summary: ${controllers['creativeSummary']!.text}',
      );
    }

    // Add skills
    if (controllers['skills']?.text.isNotEmpty == true) {
      buffer.writeln('\nSkills: ${controllers['skills']!.text}');
    }

    // Add tools
    if (controllers['tools']?.text.isNotEmpty == true) {
      buffer.writeln('\nTools & Software: ${controllers['tools']!.text}');
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

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: widget.existing,
      template: 'Creative',
      extraKeys: const [
        'portfolio',
        'socialLinks',
        'creativeSummary',
        'skillGraphs',
        'tools',
        'projects',
        'certifications',
        'languages',
        'hobbies',
        'references',
        'profilePhotoBase64',
        'workExperiences',
        'educations',
        'branding',
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
              title: const Text('Creative Resume'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.palette),
                  tooltip: 'Customize Branding',
                  onPressed: _openCustomization,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  onSelected: _exportResume,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text('Export as PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'docx',
                      child: Row(
                        children: [
                          Icon(Icons.description),
                          SizedBox(width: 8),
                          Text('Export as DOCX'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'txt',
                      child: Row(
                        children: [
                          Icon(Icons.text_snippet),
                          SizedBox(width: 8),
                          Text('Export as TXT'),
                        ],
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
                      'email': 'Email',
                      'portfolio': 'Portfolio / Website',
                      'creativeSummary': 'Creative Summary',
                      'skills': 'Skills',
                      'tools': 'Tools & Software',
                    },
                  ),
                  _section('Profile Photo'),
                  ProfilePhotoPicker(
                    initialBase64:
                        state.controllerFor('profilePhotoBase64').text.isEmpty
                        ? null
                        : state.controllerFor('profilePhotoBase64').text,
                    onChanged: (b64) {
                      state.controllerFor('profilePhotoBase64').text =
                          b64 ?? '';
                    },
                  ),
                  const SizedBox(height: 12),

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
                  state.buildTextField('portfolio', 'Portfolio / Website'),
                  state.buildTextField(
                    'socialLinks',
                    'LinkedIn / Behance / Dribbble',
                    maxLines: 2,
                  ),

                  _section('Creative Summary'),
                  AISummaryGenerator(
                    name: state.controllers['name']?.text ?? '',
                    targetRole: 'Creative Professional',
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
                      state.controllers['creativeSummary']?.text = summary;
                    },
                  ),
                  state.buildTextField(
                    'creativeSummary',
                    'Creative Summary',
                    maxLines: 4,
                  ),

                  _section('Skills'),
                  state.buildTextField(
                    'skills',
                    'Skills (comma separated)',
                    maxLines: 2,
                  ),
                  state.buildTextField(
                    'skillGraphs',
                    'Skill Graph Data (description)',
                    maxLines: 3,
                  ),

                  _section('Tools & Software'),
                  state.buildTextField(
                    'tools',
                    'Tools & Software',
                    maxLines: 3,
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

                  _section('Projects'),
                  state.buildTextField('projects', 'Projects', maxLines: 3),

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

                  _section('References'),
                  state.buildTextField('references', 'References', maxLines: 3),

                  const SizedBox(height: 24),
                  // ATS Optimization Panel
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription:
                        '', // Can be enhanced to accept job description input
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        state.saveResume();
                      },
                      label: const Text('Save Creative Resume'),
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
