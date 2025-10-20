import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../widgets/phone_input_widget.dart';
import '../services/share_export_service.dart';
import '../widgets/ai_widgets.dart';
import '../services/premium_service.dart';
import '../widgets/reorderable_sections.dart';
import '../widgets/speech_to_text_field.dart';
import 'template_selection_screen.dart';

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

  // Collapsible state for all sections - all start collapsed
  final Map<String, bool> _sectionExpanded = {
    'personal': false,
    'summary': false,
    'skills': false,
    'experience': false,
    'education': false,
    'additional': false,
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
          final List<dynamic> eduData = jsonDecode(
            widget.existing!.data['educations'],
          );
          _educations = eduData
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

    // Basic info
    if (controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${controllers['name']!.text}');
    }
    if (controllers['email']?.text.isNotEmpty == true) {
      buffer.writeln('Email: ${controllers['email']!.text}');
    }
    if (controllers['phone']?.text.isNotEmpty == true) {
      buffer.writeln('Phone: ${controllers['phone']!.text}');
    }

    // Summary
    if (controllers['summary']?.text.isNotEmpty == true) {
      buffer.writeln('\nSummary:');
      buffer.writeln(controllers['summary']!.text);
    }

    // Skills
    if (controllers['skills']?.text.isNotEmpty == true) {
      buffer.writeln('\nSkills: ${controllers['skills']!.text}');
    }

    // Add dynamic work experience
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
      // Persist ATS flag if present in controller
      final ats = state.controllers['ats_friendly']?.text ?? '';
      if (ats.isNotEmpty) data['ats_friendly'] = ats;

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

      // Export using ShareExportService
      if (format == 'PDF') {
        await ShareExportService(context).exportAndOpenPdf(resume);
      } else if (format == 'DOCX') {
        await ShareExportService(context).exportAndOpenDocx(resume);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _navigateToTemplateSelection(BuildContext ctx) async {
    final state = BaseResumeForm.of(ctx);
    if (state == null) return;

    // Create resume with current data
    final data = <String, dynamic>{
      for (final e in state.controllers.entries) e.key: e.value.text,
    };

    // Add dynamic sections
    data['workExperiences'] = jsonEncode(
      _workExperiences.map((e) => e.toJson()).toList(),
    );
    data['educations'] = jsonEncode(
      _educations.map((e) => e.toJson()).toList(),
    );

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

    // Show dialog to choose template type
    final templateType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Template Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Minimal Templates'),
              subtitle: const Text('Clean and simple designs'),
              onTap: () => Navigator.pop(ctx, 'minimal'),
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.purple),
              title: const Text('Colorful Templates'),
              subtitle: const Text('Creative and vibrant designs'),
              onTap: () => Navigator.pop(ctx, 'creative'),
            ),
          ],
        ),
      ),
    );

    if (templateType == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateSelectionScreen(
          resumeData: resume,
          templateType: templateType,
        ),
      ),
    );
  }

  Future<void> _previewResume(BuildContext ctx) async {
    final state = BaseResumeForm.of(ctx);
    if (state == null) return;

    // Check if required fields are filled
    if (state.controllerFor('name').text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first')),
      );
      return;
    }

    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    try {
      // Create resume with current data
      final data = <String, dynamic>{
        for (final e in state.controllers.entries) e.key: e.value.text,
        // Add work experiences and educations
        'workExperiences': jsonEncode(
          _workExperiences.map((e) => e.toJson()).toList(),
        ),
        'educations': jsonEncode(_educations.map((e) => e.toJson()).toList()),
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

      // Navigate to template selection screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateSelectionScreen(
            resumeData: resume,
            templateType: 'minimal',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
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
        'sectionOrder',
        'ats_friendly',
        'project_topic',
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

          // Load persisted order or default
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

          Map<String, SectionItem> sectionBuilders() {
            return {
              'summary': SectionItem(
                keyId: 'summary',
                title: 'Summary',
                build: () => _buildSummaryCard(ctx),
              ),
              'skills': SectionItem(
                keyId: 'skills',
                title: 'Skills',
                build: () => _buildSkillsCard(ctx),
              ),
              'experience': SectionItem(
                keyId: 'experience',
                title: 'Work Experience',
                build: () => _buildExperienceCard(ctx),
              ),
            };
          }

          final sections = sectionBuilders();

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: _buildModernAppBar(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header removed per design request
                  const SizedBox(height: 20),

                  // Personal Information Card
                  _buildPersonalInfoCard(ctx),

                  // Draggable sections: Summary, Skills, Experience (Premium)
                  if (PremiumService.hasDragDropFeature)
                    ReorderableResumeSections(
                      sections: order.map((key) => sections[key]!).toList(),
                      onOrderChanged: (newOrder) {
                        state.controllerFor('sectionOrder').text = jsonEncode(
                          newOrder,
                        );
                      },
                    )
                  else
                    ...order.map((sectionKey) {
                      final section = sections[sectionKey];
                      return section != null
                          ? section.build()
                          : const SizedBox.shrink();
                    }),

                  // Education Card
                  _buildEducationCard(ctx),

                  // Additional Sections Card
                  _buildAdditionalSectionsCard(ctx),

                  // ATS Settings Card
                  _buildATSSettingsCard(ctx),

                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(ctx),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6C5CE7),
      foregroundColor: Colors.white,
      title: const Text(
        'Minimal Resume',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      centerTitle: false,
      actions: [
        // Template Selection Button
        IconButton(
          icon: const Icon(Icons.view_list, color: Colors.white),
          tooltip: 'Select Template',
          onPressed: () => _navigateToTemplateSelection(context),
        ),
        // Export Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.file_download_outlined, color: Colors.white),
          onSelected: _exportResume,
          onOpened: () {
            // Dismiss keyboard when opening menu
            FocusScope.of(context).unfocus();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'PDF',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Export as PDF'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'DOCX',
              child: ListTile(
                leading: Icon(Icons.article),
                title: Text('Export as DOCX'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        // Share Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.share, color: Colors.white),
          onOpened: () {
            // Dismiss keyboard when opening menu
            FocusScope.of(context).unfocus();
          },
          onSelected: (choice) async {
            if (!PremiumService.isPremium) {
              PremiumService.showUpgradeDialog(context, 'Sharing');
              return;
            }
            final state = BaseResumeForm.of(context);
            if (state == null) return;
            final data = {
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
            try {
              if (choice == 'EMAIL') {
                await ShareExportService(context).shareViaEmail(resume);
              } else if (choice == 'WHATSAPP') {
                await ShareExportService(context).shareViaWhatsApp(resume);
              }
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'EMAIL',
              child: ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Email'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'WHATSAPP',
              child: ListTile(
                leading: Icon(Icons.message_outlined),
                title: Text('WhatsApp'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Header card removed

  Widget _buildPersonalInfoCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'personal',
      'Personal Information',
      Icons.person_outline,
      const Color(0xFF00B894),
      [
        SpeechToTextField(
          controller: state.controllerFor('name'),
          label: 'Full Name *',
          hint: 'Enter your full name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Full Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        PhoneInputWidget(
          key: const Key('phone_input'),
          initialPhoneNumber: state.controllerFor('phone').text,
          onChanged: (fullPhoneNumber, countryCode, phoneNumber) {
            state.controllerFor('phone').text = fullPhoneNumber;
          },
        ),
        const SizedBox(height: 16),
        state.buildTextField(
          'email',
          'Email Address',
          required: true,
          keyboard: TextInputType.emailAddress,
          customValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email (e.g., user@domain.com)';
            }
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email format';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'summary',
      'Professional Summary',
      Icons.text_snippet_outlined,
      const Color(0xFFE17055),
      [
        // Project/Topic input field
        SpeechToTextField(
          controller: state.controllerFor('project_topic'),
          label: 'Project/Topic (Optional)',
          hint:
              'e.g., Automation Selenium, Data Analytics, Mobile App Development',
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        // Generate from Profile button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final generated = _generateDynamicSummary(context);
              state.controllerFor('summary').text = generated;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Summary generated from your profile!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.stars, size: 18),
            label: const Text('Generate from Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE17055),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SpeechToTextField(
          controller: state.controllerFor('summary'),
          label: 'Professional Summary *',
          hint: 'Write a brief summary about yourself...',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Professional Summary is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSkillsCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'skills',
      'Skills & Expertise',
      Icons.lightbulb_outline,
      const Color(0xFFFF7675),
      [SkillsPickerField(controller: state.controllerFor('skills'))],
    );
  }

  Widget _buildExperienceCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'experience',
      'Work Experience',
      Icons.work_outline,
      const Color(0xFF74B9FF),
      [
        DynamicWorkExperienceSection(
          workExperiences: _workExperiences,
          onWorkExperiencesChanged: (experiences) {
            setState(() {
              _workExperiences = experiences;
              // Update JSON in hidden controller for BaseResumeForm
              state.controllerFor('workExperiences').text = jsonEncode(
                experiences.map((e) => e.toJson()).toList(),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildEducationCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'education',
      'Education',
      Icons.school_outlined,
      const Color(0xFFA29BFE),
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
    );
  }

  Widget _buildAdditionalSectionsCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'additional',
      'Additional Information',
      Icons.add_circle_outline,
      const Color(0xFF00CEC9),
      [
        _buildSectionField(
          context,
          'certifications',
          'Certifications',
          'List your certifications...',
        ),
        const SizedBox(height: 16),
        _buildSectionField(
          context,
          'languages',
          'Languages',
          'Languages you speak...',
        ),
        const SizedBox(height: 16),
        _buildSectionField(
          context,
          'hobbies',
          'Hobbies & Interests',
          'Your hobbies and interests...',
        ),
      ],
    );
  }

  Widget _buildATSSettingsCard(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return _buildMinimalCollapsibleCard(
      'ats',
      'ATS Optimization',
      Icons.tune,
      const Color(0xFFE84393),
      [
        ATSOptimizationPanel(
          content: _getResumeContent(state.controllers),
          jobDescription: '', // Could be enhanced to get from user input
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE84393).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE84393).withValues(alpha: 0.3),
            ),
          ),
          child: SwitchListTile.adaptive(
            value: (state.controllerFor('ats_friendly').text == 'true'),
            onChanged: (v) {
              state.controllerFor('ats_friendly').text = v ? 'true' : 'false';
              setState(() {});
            },
            title: const Text(
              'ATS-friendly formatting',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Simplifies layout and headings for better ATS parsing.',
              style: TextStyle(fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFE84393),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext ctx) {
    final state = BaseResumeForm.of(ctx)!;
    return Column(
      children: [
        // Choose Colorful Template Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.palette),
            onPressed: () => _navigateToTemplateSelection(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            label: const Text(
              'Choose Colorful Template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Preview Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            onPressed: () => _previewResume(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            label: const Text(
              'Preview Resume',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Save Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.save),
            onPressed: () => state.saveResume(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            label: const Text(
              'Save Minimal Resume',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalCollapsibleCard(
    String sectionKey,
    String title,
    IconData icon,
    Color accentColor,
    List<Widget> children,
  ) {
    final isExpanded = _sectionExpanded[sectionKey] ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: accentColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Content (only visible when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionField(
    BuildContext context,
    String key,
    String label,
    String hint,
  ) {
    final state = BaseResumeForm.of(context)!;
    return state.buildTextField(key, hint, maxLines: 2);
  }

  String _generateDynamicSummary(BuildContext ctx) {
    final state = BaseResumeForm.of(ctx)!;
    final name = state.controllerFor('name').text.trim();
    final skills = state.controllerFor('skills').text.trim();
    final projectTopic = state.controllerFor('project_topic').text.trim();

    // Extract years of experience from work history
    int totalYears = 0;
    if (_workExperiences.isNotEmpty) {
      for (var exp in _workExperiences) {
        try {
          final start = exp.startDate;
          final end = exp.isCurrentlyWorking ? DateTime.now() : exp.endDate;
          if (start != null && end != null) {
            totalYears += end.difference(start).inDays ~/ 365;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    // Extract degree from education
    String degree = '';
    if (_educations.isNotEmpty && _educations.first.degree != null) {
      degree = _educations.first.degree!;
    }

    // Extract latest job title
    String latestRole = '';
    if (_workExperiences.isNotEmpty &&
        _workExperiences.first.jobTitle != null) {
      latestRole = _workExperiences.first.jobTitle!;
    }

    // Build dynamic summary
    List<String> summaryParts = [];

    // PRIORITY: Use project/topic if provided
    if (projectTopic.isNotEmpty) {
      if (totalYears > 0) {
        summaryParts.add(
          'Experienced professional specializing in $projectTopic with $totalYears+ years of hands-on expertise.',
        );
      } else if (degree.isNotEmpty) {
        summaryParts.add(
          '$degree graduate with strong knowledge and practical experience in $projectTopic.',
        );
      } else {
        summaryParts.add(
          'Skilled professional with demonstrated expertise in $projectTopic and a proven track record of successful project delivery.',
        );
      }

      if (skills.isNotEmpty) {
        final skillsList = skills
            .split(',')
            .take(3)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (skillsList.isNotEmpty) {
          summaryParts.add(
            'Proficient in ${skillsList.join(", ")}, with strong problem-solving abilities and attention to detail.',
          );
        }
      } else {
        summaryParts.add(
          'Adept at analyzing complex requirements and delivering innovative solutions that exceed expectations.',
        );
      }

      summaryParts.add(
        'Committed to continuous learning and staying current with industry best practices to drive project success.',
      );
    } else {
      // FALLBACK: Generic summary if no project/topic provided
      if (totalYears > 0 && latestRole.isNotEmpty) {
        summaryParts.add(
          'Accomplished $latestRole with $totalYears+ years of progressive experience in delivering results.',
        );
      } else if (totalYears > 0) {
        summaryParts.add(
          'Experienced professional with $totalYears+ years of demonstrated expertise in the field.',
        );
      } else if (degree.isNotEmpty) {
        summaryParts.add(
          '$degree graduate with a strong academic foundation and passion for excellence.',
        );
      } else {
        summaryParts.add(
          'Motivated professional committed to delivering high-quality results.',
        );
      }

      if (skills.isNotEmpty) {
        final skillsList = skills
            .split(',')
            .take(3)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (skillsList.isNotEmpty) {
          summaryParts.add(
            'Proficient in ${skillsList.join(", ")}, with a proven ability to adapt and excel in dynamic environments.',
          );
        }
      } else {
        summaryParts.add(
          'Quick learner with strong analytical and problem-solving abilities, eager to contribute to organizational success.',
        );
      }

      if (_workExperiences.length > 1) {
        summaryParts.add(
          'Track record of successfully managing multiple projects and consistently exceeding expectations.',
        );
      } else {
        summaryParts.add(
          'Dedicated team player focused on achieving goals and driving positive outcomes.',
        );
      }
    }

    return summaryParts.take(3).join(' ');
  }
}
