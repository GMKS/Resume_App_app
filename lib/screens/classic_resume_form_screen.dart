import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/requirements_banner.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/reorderable_sections.dart';
// Removed skills keyword suggestions; adding summary keyword chips inline.

class ClassicResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const ClassicResumeFormScreen({super.key, this.existing});

  @override
  State<ClassicResumeFormScreen> createState() =>
      _ClassicResumeFormScreenState();
}

class _ClassicResumeFormScreenState extends State<ClassicResumeFormScreen> {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  bool _atsFriendly = true;

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
      buffer.writeln('\nProfessional Summary: ${controllers['summary']!.text}');
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

    // Add certifications
    if (controllers['certifications']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nCertifications: ${controllers['certifications']!.text}',
      );
    }

    return buffer.toString();
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        fontFamily: 'Calibri',
      ),
    ),
  );

  // Consistent section card wrapper for cleaner visual grouping
  Widget _sectionCard({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: _atsFriendly
          ? BorderSide(color: Colors.grey.shade300)
          : BorderSide(color: Colors.transparent),
    );
    return Card(
      elevation: _atsFriendly ? 0 : 1,
      shape: border,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!_atsFriendly && icon != null) ...[
                  Icon(icon, size: 20, color: Colors.black87),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // Inline keyword suggestions for Professional Summary
  static const List<String> _summarySuggestions = [
    'Results-driven',
    'Detail-oriented',
    'Proven track record',
    'Strong communication skills',
    'Team player',
    'Innovative thinker',
    'Self-motivated',
  ];

  Widget _buildSummarySuggestions(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Suggestions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _summarySuggestions.map((s) {
            return ActionChip(
              label: Text(s),
              onPressed: () {
                final existing = controller.text;
                // Avoid duplicates (case-insensitive contains)
                if (existing.toLowerCase().contains(s.toLowerCase())) return;
                final sep = existing.trim().isEmpty
                    ? ''
                    : (existing.trim().endsWith('.') ? ' ' : '. ');
                controller.text = existing + sep + s;
              },
            );
          }).toList(),
        ),
      ],
    );
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
      data['ats_friendly'] = _atsFriendly ? 'true' : 'false';

      final resume = SavedResume(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.controllerFor('name').text.isNotEmpty
            ? '${state.controllerFor('name').text} Resume'
            : 'Classic Resume',
        template: 'Classic',
        data: data,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Check premium access for different formats
      if (!PremiumService.canExportFormat(format)) {
        PremiumService.showUpgradeDialog(context, '$format Export');
        return;
      }

      switch (format) {
        case 'PDF':
          await ShareExportService.instance.exportAndOpenPdf(resume);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                PremiumService.hasWatermark
                    ? 'PDF exported with watermark - Upgrade to Premium for watermark-free exports!'
                    : 'PDF export completed',
              ),
            ),
          );
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
      template: 'Classic',
      extraKeys: const [
        'summary',
        'skills',
        'certifications',
        'workExperiences',
        'educations',
        // Persist the order of the main sections (summary, skills, experience)
        'sectionOrder',
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

          // Determine initial order for draggable sections
          List<String> order = ['summary', 'skills', 'experience'];
          try {
            final raw = state.controllerFor('sectionOrder').text;
            if (raw.isNotEmpty) {
              final parsed = jsonDecode(raw);
              if (parsed is List) {
                order = parsed.map((e) => e.toString()).toList();
              }
            }
          } catch (_) {}

          // Build SectionItem map
          Map<String, SectionItem> sectionBuilders() {
            return {
              'summary': SectionItem(
                keyId: 'summary',
                title: 'Professional Summary',
                build: () => _sectionCard(
                  title: 'Professional Summary',
                  icon: Icons.badge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      state.buildTextField(
                        'summary',
                        'Professional Summary',
                        maxLines: 3,
                        required: true,
                      ),
                      _buildSummarySuggestions(state.controllerFor('summary')),
                    ],
                  ),
                ),
              ),
              'skills': SectionItem(
                keyId: 'skills',
                title: 'Skills',
                build: () => _sectionCard(
                  title: 'Skills',
                  icon: Icons.handyman,
                  child: SkillsPickerField(
                    controller: state.controllerFor('skills'),
                    label: 'Skills',
                  ),
                ),
              ),
              'experience': SectionItem(
                keyId: 'experience',
                title: 'Work Experience',
                build: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Work Experience'),
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
                      atsFriendly: _atsFriendly,
                    ),
                  ],
                ),
              ),
            };
          }

          final all = sectionBuilders();
          final sections = order
              .where(all.containsKey)
              .map((k) => all[k]!)
              .toList(growable: false);

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Classic Resume',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey.shade200, height: 1),
              ),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.share),
                  onSelected: (choice) async {
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
                      title: state.controllerFor('name').text.isNotEmpty
                          ? '${state.controllerFor('name').text} Resume'
                          : 'Classic Resume',
                      template: 'Classic',
                      data: data,
                      createdAt: widget.existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    try {
                      if (!PremiumService.isPremium) {
                        PremiumService.showUpgradeDialog(context, 'Sharing');
                        return;
                      }
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
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RequirementsBanner(
                    requiredFieldLabels: {
                      'name': 'Full Name',
                      'phone': 'Mobile Number',
                      'email': 'Email Address',
                      'summary': 'Professional Summary',
                      'skills': 'Skills',
                    },
                  ),
                  _sectionCard(
                    title: 'Contact Info',
                    icon: Icons.contact_page,
                    child: Column(
                      children: [
                        state.buildTextField(
                          'name',
                          'Full Name',
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        state.buildTextField(
                          'email',
                          'Email Address',
                          required: true,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        state.buildTextField(
                          'phone',
                          'Mobile Number',
                          required: true,
                          keyboard: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  // Draggable sections: Summary, Skills, Experience (Premium)
                  if (PremiumService.hasDragDropFeature)
                    ReorderableResumeSections(
                      sections: sections,
                      onOrderChanged: (newOrder) {
                        // Persist order as JSON string in hidden controller
                        state.controllerFor('sectionOrder').text = jsonEncode(
                          newOrder,
                        );
                      },
                    ),

                  _sectionTitle('Education'),
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
                    atsFriendly: _atsFriendly,
                  ),

                  _sectionCard(
                    title: 'Certifications',
                    icon: Icons.workspace_premium,
                    child: state.buildTextField(
                      'certifications',
                      'Certifications',
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ATS-friendly mode toggle
                  SwitchListTile.adaptive(
                    value: _atsFriendly,
                    onChanged: (v) => setState(() => _atsFriendly = v),
                    title: const Text('ATS-friendly formatting'),
                    subtitle: const Text(
                      'Simplifies layout and headings for better ATS parsing.',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ATS Optimization Panel
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription:
                        '', // Could be enhanced to get from user input
                  ),

                  const SizedBox(height: 16),
                  if (_atsFriendly) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATS Preview (Plain Text)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getResumeContent(state.controllers),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: () => state.saveResume(),
                      label: const Text('Save Classic Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
}
