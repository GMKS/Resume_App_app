import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../models/branding.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/requirements_banner.dart';
import '../services/ai_resume_service.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/dynamic_sections.dart';
import '../screens/customization_screen.dart';
import '../widgets/skills_picker_field.dart';

class ProfessionalResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const ProfessionalResumeFormScreen({super.key, this.existing});

  @override
  State<ProfessionalResumeFormScreen> createState() =>
      _ProfessionalResumeFormScreenState();
}

class _ProfessionalResumeFormScreenState
    extends State<ProfessionalResumeFormScreen> {
  final List<WorkExperience> _workExperiences = [];
  final List<Education> _educations = [];
  BrandingTheme _currentBranding = BrandingTheme.professional;

  // Color theme for Professional template
  static const Color _accentColor = Color(0xFF2E3A47);

  @override
  void initState() {
    super.initState();
    // Initialize with one empty entry
    _workExperiences.add(WorkExperience(id: '1'));
    _educations.add(Education(id: '1'));
    _loadBrandingFromResume();
  }

  void _loadBrandingFromResume() {
    if (widget.existing?.data['branding'] != null) {
      try {
        final brandingJson = jsonDecode(widget.existing!.data['branding']);
        _currentBranding = BrandingTheme.fromJson(brandingJson);
      } catch (e) {
        _currentBranding = BrandingTheme.professional;
      }
    }
  }

  Future<void> _openCustomization() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CustomizationScreen(templateType: 'Professional'),
      ),
    );

    if (result is BrandingTheme) {
      setState(() {
        _currentBranding = result;
      });

      // Update the branding in BaseResumeForm
      final state = BaseResumeForm.of(context);
      if (state != null) {
        state.controllerFor('branding').text = jsonEncode(
          _currentBranding.toJson(),
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Branding theme applied!')));
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

    // Add executive summary
    if (controllers['executiveSummary']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nExecutive Summary: ${controllers['executiveSummary']!.text}',
      );
    }

    // Add key skills
    if (controllers['keySkills']?.text.isNotEmpty == true) {
      buffer.writeln('\nKey Skills: ${controllers['keySkills']!.text}');
    }

    // Add work experiences
    if (_workExperiences.isNotEmpty) {
      buffer.writeln('\nWork Experience:');
      for (final exp in _workExperiences) {
        if (exp.jobTitle.isNotEmpty || exp.company.isNotEmpty) {
          buffer.writeln('${exp.jobTitle} at ${exp.company}');
          if (exp.description.isNotEmpty) {
            buffer.writeln(exp.description);
          }
        }
      }
    }

    // Add education
    if (_educations.isNotEmpty) {
      buffer.writeln('\nEducation:');
      for (final edu in _educations) {
        if (edu.degree.isNotEmpty || edu.institution.isNotEmpty) {
          buffer.writeln('${edu.degree} at ${edu.institution}');
        }
      }
    }

    return buffer.toString();
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

      // Add dynamic data
      data['workExperiences'] = jsonEncode(
        _workExperiences.map((e) => e.toJson()).toList(),
      );
      data['educations'] = jsonEncode(
        _educations.map((e) => e.toJson()).toList(),
      );

      final title = state.controllers['name']!.text.isEmpty
          ? 'My Resume'
          : '${state.controllers['name']!.text} Resume';

      final resume = SavedResume(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.existing?.title ?? title,
        template: 'Professional',
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        data: data,
      );

      switch (format) {
        case 'PDF':
          await ShareExportService.instance.exportAndOpenPdf(resume);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF export completed')));
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
      template: 'Professional',
      extraKeys: const [
        'linkedIn',
        'address',
        'executiveSummary',
        'keySkills',
        'certifications',
        'projects',
        'awards',
        'languages',
        'references',
        'profilePhotoBase64', // ADDED
        'workExperiences',
        'educations',
        'branding',
      ],
      child: Builder(
        builder: (ctx) {
          final state = BaseResumeForm.of(ctx)!;

          // Initialize branding data in controller if not already set
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
            if (state.controllerFor('branding').text.isEmpty) {
              state.controllerFor('branding').text = jsonEncode(
                _currentBranding.toJson(),
              );
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Professional Resume'),
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
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
                      title: state.controllers['name']!.text.isEmpty
                          ? 'My Resume'
                          : '${state.controllers['name']!.text} Resume',
                      template: 'Professional',
                      createdAt: widget.existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      data: data,
                    );
                    try {
                      if (choice == 'EMAIL') {
                        await ShareExportService.instance.shareViaEmail(resume);
                      } else if (choice == 'WHATSAPP') {
                        await ShareExportService.instance.shareViaWhatsApp(
                          resume,
                        );
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
                      'executiveSummary': 'Executive Summary',
                      'keySkills': 'Key Skills',
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

                  // Executive Summary
                  _section('Executive Summary'),
                  AISummaryGenerator(
                    name: state.controllers['name']?.text ?? '',
                    targetRole: _workExperiences.isNotEmpty
                        ? _workExperiences.first.jobTitle
                        : 'Professional',
                    skills: (state.controllers['keySkills']?.text ?? '')
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                    experience: _workExperiences
                        .map((exp) => exp.description)
                        .where((desc) => desc.isNotEmpty)
                        .toList(),
                    onGenerated: (summary) {
                      state.controllers['executiveSummary']?.text = summary;
                    },
                  ),
                  state.buildTextField(
                    'executiveSummary',
                    '3–4 line Executive Summary',
                    maxLines: 4,
                  ),

                  // Key Skills
                  _section('Key Skills'),
                  SkillsPickerField(
                    controller: state.controllerFor('keySkills'),
                    label: 'Key Skills',
                  ),

                  // (Share menu handled in the top AppBar)
                  _section('Experience'),
                  AIBulletPointGenerator(
                    jobTitle: 'Creative Professional',
                    company: '',
                    description: '',
                    onGenerated: (bulletPoints) {
                      state.controllers['experience']?.text = bulletPoints.join(
                        '\n• ',
                      );
                    },
                  ),
                  state.buildTextField('experience', 'Experience', maxLines: 4),

                  _section('Education'),
                  state.buildTextField('education', 'Education', maxLines: 3),

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
