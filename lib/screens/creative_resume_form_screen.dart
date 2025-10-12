import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../models/branding.dart';
import '../screens/customization_screen.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../widgets/ai_widgets.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';

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

  // Collapsible state for all sections - all start collapsed
  final Map<String, bool> _sectionExpanded = {
    'profile': false,
    'personal': false,
    'summary': false,
    'skills': false,
    'experience': false,
    'education': false,
    'projects': false,
    'certifications': false,
    'languages': false,
    'hobbies': false,
    'references': false,
    'ats': false,
  };

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
      // Include ATS flag if present
      final ats = state.controllers['ats_friendly']?.text ?? '';
      if (ats.isNotEmpty) data['ats_friendly'] = ats;

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

      switch (format) {
        case 'pdf':
          await ShareExportService(context).exportAndOpenPdf(resume);
          break;
        case 'docx':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DOCX export is not available in this version.'),
            ),
          );
          break;
        case 'txt':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('TXT export is not available in this version.'),
            ),
          );
          break;
      }
      if (mounted) {
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
        'ats_friendly',
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
                  icon: const Icon(Icons.share),
                  onSelected: (choice) async {
                    if (!PremiumService.isPremium) {
                      PremiumService.showUpgradeDialog(context, 'Sharing');
                      return;
                    }
                    final state = BaseResumeForm.of(context);
                    if (state == null) return;
                    final data = {
                      for (final e in state.controllers.entries)
                        e.key: e.value.text,
                    };
                    final resume = SavedResume(
                      id:
                          widget.existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title:
                          state.controllers['name']?.text ?? 'Creative Resume',
                      template: 'Creative',
                      data: data,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    try {
                      if (choice == 'EMAIL') {
                        await ShareExportService(context).shareViaEmail(resume);
                      } else if (choice == 'WHATSAPP') {
                        await ShareExportService(
                          context,
                        ).shareViaWhatsApp(resume);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share failed: $e')),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'EMAIL',
                      child: ListTile(
                        leading: Icon(Icons.email_outlined),
                        title: Text('Share via Email (Premium)'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'WHATSAPP',
                      child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Share via WhatsApp (Premium)'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
                  // Profile Photo Section
                  _creativeCollapsibleSection(
                    'profile',
                    'Profile Photo',
                    Icons.account_circle,
                    [
                      ProfilePhotoPicker(
                        initialBase64:
                            state
                                .controllerFor('profilePhotoBase64')
                                .text
                                .isEmpty
                            ? null
                            : state.controllerFor('profilePhotoBase64').text,
                        onChanged: (b64) {
                          state.controllerFor('profilePhotoBase64').text =
                              b64 ?? '';
                        },
                      ),
                    ],
                  ),

                  // Personal Information Section
                  _creativeCollapsibleSection(
                    'personal',
                    'Personal Information',
                    Icons.person,
                    [
                      state.buildTextField('name', 'Full Name', required: true),
                      const SizedBox(height: 16),
                      state.buildTextField(
                        'phone',
                        'Mobile Number',
                        required: true,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      state.buildTextField(
                        'email',
                        'Email Address',
                        required: true,
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      state.buildTextField('portfolio', 'Portfolio / Website'),
                      const SizedBox(height: 16),
                      state.buildTextField(
                        'socialLinks',
                        'LinkedIn / Behance / Dribbble',
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Creative Summary Section
                  _creativeCollapsibleSection(
                    'summary',
                    'Creative Summary',
                    Icons.description,
                    [
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
                        seed: state.controllers['creativeSummary']?.text,
                        onGenerated: (summary) {
                          state.controllers['creativeSummary']?.text = summary;
                        },
                      ),
                      const SizedBox(height: 12),
                      state.buildTextField(
                        'creativeSummary',
                        'Creative Summary',
                        maxLines: 4,
                      ),
                    ],
                  ),

                  // Skills Section
                  _creativeCollapsibleSection(
                    'skills',
                    'Skills',
                    Icons.lightbulb,
                    [
                      SkillsPickerField(
                        controller: state.controllerFor('skills'),
                        label: 'Skills',
                      ),
                      const SizedBox(height: 16),
                      state.buildTextField(
                        'skillGraphs',
                        'Skill Graph Data (description)',
                        maxLines: 3,
                      ),
                    ],
                  ),

                  // Tools & Software Section
                  _creativeCollapsibleSection(
                    'tools',
                    'Tools & Software',
                    Icons.build,
                    [
                      state.buildTextField(
                        'tools',
                        'Tools & Software',
                        maxLines: 3,
                      ),
                    ],
                  ),

                  // Experience Section
                  _creativeCollapsibleSection(
                    'experience',
                    'Experience',
                    Icons.work,
                    [
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
                    ],
                  ),

                  // Education Section
                  _creativeCollapsibleSection(
                    'education',
                    'Education',
                    Icons.school,
                    [
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
                    ],
                  ),

                  // Projects Section
                  _creativeCollapsibleSection(
                    'projects',
                    'Projects',
                    Icons.folder,
                    [state.buildTextField('projects', 'Projects', maxLines: 3)],
                  ),

                  // Certifications Section
                  _creativeCollapsibleSection(
                    'certifications',
                    'Certifications',
                    Icons.verified,
                    [
                      state.buildTextField(
                        'certifications',
                        'Certifications',
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Languages Section
                  _creativeCollapsibleSection(
                    'languages',
                    'Languages',
                    Icons.language,
                    [
                      state.buildTextField(
                        'languages',
                        'Languages',
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Hobbies Section
                  _creativeCollapsibleSection(
                    'hobbies',
                    'Hobbies',
                    Icons.interests,
                    [state.buildTextField('hobbies', 'Hobbies', maxLines: 2)],
                  ),

                  // References Section
                  _creativeCollapsibleSection(
                    'references',
                    'References',
                    Icons.people,
                    [
                      state.buildTextField(
                        'references',
                        'References',
                        maxLines: 3,
                      ),
                    ],
                  ),

                  // ATS Optimization Section
                  _creativeCollapsibleSection(
                    'ats',
                    'ATS Optimization',
                    Icons.tune,
                    [
                      ATSOptimizationPanel(
                        content: _getResumeContent(state.controllers),
                        jobDescription:
                            '', // Can be enhanced to accept job description input
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        value:
                            (state.controllerFor('ats_friendly').text ==
                            'true'),
                        onChanged: (v) {
                          state.controllerFor('ats_friendly').text = v
                              ? 'true'
                              : 'false';
                          setState(() {});
                        },
                        title: const Text('ATS-friendly formatting'),
                        subtitle: const Text(
                          'Simplifies layout and headings for better ATS parsing.',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
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

  Widget _creativeCollapsibleSection(
    String sectionKey,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final isExpanded = _sectionExpanded[sectionKey] ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.05),
            Colors.pink.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with expand/collapse functionality
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[sectionKey] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content (only visible when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}
