import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart'; // ADD for photo picker
import '../widgets/phone_input_widget.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../services/share_export_service.dart';
import 'one_page_customization_screen.dart';
import 'one_page_resume_preview.dart';

class OnePageResumeFormScreen extends StatelessWidget {
  final SavedResume? existing;
  const OnePageResumeFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: existing,
      template: 'One Page',
      extraKeys: const [
        // Contact / Header
        'title', // Professional Title (optional)
        'portfolio',
        'linkedIn',
        // Content blocks
        'coreSkills',
        'experience', // bullet list / achievements
        'certifications',
        'projects',
        // Optional sections
        'awards',
        'languages',
        'volunteer',
        'memberships',
        'hobbies',
        // Photo
        'profilePhotoBase64',
        'photoSize', // For adjustable photo size
        // Dynamic data as JSON
        'workExperiencesJson',
        'educationsJson',
        // ATS flag
        'ats_friendly',
        // Section order for drag-drop functionality
        'sectionOrder',
        // Customization fields
        'accentColor',
        'fontStyle',
        'layoutStyle',
        // Template gallery selection
        'templateVariant',
      ],
      child: const _OnePageBody(),
    );
  }
}

class _OnePageBody extends StatefulWidget {
  const _OnePageBody();

  @override
  State<_OnePageBody> createState() => _OnePageBodyState();
}

class _OnePageBodyState extends State<_OnePageBody> {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];

  // Color theme for One Page template
  static const Color _accentColor = Color(0xFF1976D2);

  // Collapsible section states - all sections start collapsed
  Map<String, bool> _sectionExpanded = {
    'contact': false,
    'summary': false,
    'skills': false,
    'experience': false,
    'education': false,
    'certifications': false,
    'projects': false,
    'additional': false,
    'ats': false,
  };

  // Default section order for reordering functionality
  List<String> _sectionOrder = [
    'summary',
    'skills',
    'experience',
    'education',
    'projects',
    'certifications',
    'additional',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with one empty entry
    _workExperiences.add(WorkExperience(id: '1'));
    _educations.add(Education(id: '1'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadExistingData();
    _loadSectionOrder();
  }

  void _loadSectionOrder() {
    final state = BaseResumeForm.of(context);
    if (state != null) {
      final orderJson = state.controllerFor('sectionOrder').text;
      if (orderJson.isNotEmpty) {
        try {
          final parsed = jsonDecode(orderJson) as List;
          _sectionOrder = parsed.map((e) => e.toString()).toList();
        } catch (e) {
          // Keep default order if parsing fails
        }
      }
    }
  }

  void _loadExistingData() {
    final state = BaseResumeForm.of(context);
    if (state?.widget.existingResume != null) {
      final resume = state!.widget.existingResume!;

      // Load work experiences from JSON
      final workJson = resume.data['workExperiencesJson'] as String?;
      if (workJson != null && workJson.isNotEmpty) {
        try {
          final List<dynamic> workList = json.decode(workJson);
          _workExperiences = workList
              .map((e) => WorkExperience.fromJson(e))
              .toList();
          // Ensure hidden controller is in sync for saving/export
          state.controllerFor('workExperiencesJson').text = workJson;
        } catch (e) {
          // If parsing fails, keep default
        }
      }

      // Load educations from JSON
      final eduJson = resume.data['educationsJson'] as String?;
      if (eduJson != null && eduJson.isNotEmpty) {
        try {
          final List<dynamic> eduList = json.decode(eduJson);
          _educations = eduList.map((e) => Education.fromJson(e)).toList();
          // Ensure hidden controller is in sync for saving/export
          state.controllerFor('educationsJson').text = eduJson;
        } catch (e) {
          // If parsing fails, keep default
        }
      }
    }
  }

  // Collapsible section wrapper for One Page resume sections
  Widget _onePageCollapsibleSection({
    Key? key,
    required String title,
    required String sectionKey,
    required Widget child,
    IconData? icon,
    int? dragIndex, // when provided, show a drag handle in header
  }) {
    final isExpanded = _sectionExpanded[sectionKey] ?? false;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _accentColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _sectionExpanded[sectionKey] = !isExpanded;
                });
              },
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: _accentColor, size: 24),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (dragIndex != null) ...[
                    // Visible drag handle for reordering in the list
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                  ],
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    size: 24,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[const SizedBox(height: 16), child],
          ],
        ),
      ),
    );
  }

  String _getResumeContent(Map<String, TextEditingController> controllers) {
    final buffer = StringBuffer();

    // Add basic info
    if (controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${controllers['name']!.text}');
    }
    if (controllers['title']?.text.isNotEmpty == true) {
      buffer.writeln('Title: ${controllers['title']!.text}');
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
    if (controllers['coreSkills']?.text.isNotEmpty == true) {
      buffer.writeln('\nCore Skills: ${controllers['coreSkills']!.text}');
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

  @override
  Widget build(BuildContext context) {
    final state = BaseResumeForm.of(context)!;

    // Initialize ATS flag controller if empty (default OFF)
    if (state.controllerFor('ats_friendly').text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.controllerFor('ats_friendly').text = 'false';
      });
    }
    final isAts = state.controllerFor('ats_friendly').text == 'true';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('One Page Resume'),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (value) {
              switch (value) {
                case 'customize':
                  _openCustomization(state);
                  break;
                case 'preview':
                  _previewResume(state);
                  break;
                case 'export_pdf':
                  _exportResume(state, 'PDF');
                  break;
                case 'export_docx':
                  _exportResume(state, 'DOCX');
                  break;
                case 'export_txt':
                  _exportResume(state, 'TXT');
                  break;
                case 'share_email':
                  _shareResume(state, 'email');
                  break;
                case 'share_whatsapp':
                  _shareResume(state, 'whatsapp');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'customize',
                child: ListTile(
                  leading: Icon(Icons.palette),
                  title: Text('Customize Branding'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: ListTile(
                  leading: Icon(Icons.remove_red_eye),
                  title: Text('Preview Resume'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Export as PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_docx',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Export as DOCX'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_txt',
                child: ListTile(
                  leading: Icon(Icons.text_snippet),
                  title: Text('Export as TXT'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'share_email',
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share_whatsapp',
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _onePageCollapsibleSection(
              title: 'Contact Information',
              sectionKey: 'contact',
              icon: Icons.contact_page,
              child: Column(
                children: [
                  Center(
                    child: ProfilePhotoPicker(
                      size: 90,
                      buttonBelow: true,
                      initialBase64:
                          state.controllerFor('profilePhotoBase64').text.isEmpty
                          ? null
                          : state.controllerFor('profilePhotoBase64').text,
                      onChanged: (b64) {
                        state.controllerFor('profilePhotoBase64').text =
                            b64 ?? '';
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  state.buildTextField('name', 'Full Name', required: true),
                  state.buildTextField('title', 'Professional Title'),
                  PhoneInputWidget(
                    initialPhoneNumber: state.controllerFor('phone').text,
                    onChanged: (fullPhoneNumber, countryCode, phoneNumber) {
                      state.controllerFor('phone').text = fullPhoneNumber;
                    },
                  ),
                  state.buildTextField(
                    'email',
                    'Email Address',
                    required: true,
                    keyboard: TextInputType.emailAddress,
                    customValidator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email Address is required';
                      }
                      // Check for @ symbol
                      if (!value.contains('@')) {
                        return 'Email must contain @';
                      }
                      // Split by @ and validate domain
                      final parts = value.split('@');
                      if (parts.length != 2 || parts[1].isEmpty) {
                        return 'Invalid email format';
                      }
                      // Check domain has at least one dot and valid format
                      final domain = parts[1];
                      if (!domain.contains('.')) {
                        return 'Email must include domain (e.g., gmail.com)';
                      }
                      // Basic domain validation
                      final domainParts = domain.split('.');
                      if (domainParts.any((part) => part.isEmpty)) {
                        return 'Invalid domain format';
                      }
                      return null;
                    },
                  ),
                  state.buildTextField(
                    'linkedIn',
                    'LinkedIn Profile (optional)',
                  ),
                  state.buildTextField(
                    'portfolio',
                    'Personal Website / Portfolio',
                  ),
                ],
              ),
            ),

            // Reorderable main content sections - using simple ReorderableListView
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _sectionOrder.removeAt(oldIndex);
                  _sectionOrder.insert(newIndex, item);
                  // Save section order to controller for persistence
                  state.controllerFor('sectionOrder').text = jsonEncode(
                    _sectionOrder,
                  );
                });
              },
              children: [
                for (int i = 0; i < _sectionOrder.length; i++)
                  _buildSection(_sectionOrder[i], i, state),
              ],
            ),

            _onePageCollapsibleSection(
              title: 'ATS Optimization',
              sectionKey: 'ats',
              icon: Icons.tune,
              child: Column(
                children: [
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription:
                        '', // Can be enhanced to accept job description input
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: isAts,
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save One Page Resume'),
                onPressed: () => state.saveResume(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual sections for reordering
  Widget _buildSection(String sectionKey, int index, dynamic state) {
    final isAts = state.controllerFor('ats_friendly').text == 'true';

    switch (sectionKey) {
      case 'summary':
        return _onePageCollapsibleSection(
          key: ValueKey('summary'),
          title: 'Professional Summary / Objective',
          sectionKey: 'summary',
          icon: Icons.badge,
          dragIndex: index,
          child: Column(
            children: [
              state.buildTextField(
                'summary',
                '2–3 line Professional Summary',
                required: true,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              AISummaryGenerator(
                name: state.controllers['name']?.text ?? '',
                targetRole: _workExperiences.isNotEmpty
                    ? _workExperiences.first.jobTitle
                    : '',
                skills:
                    ((state.controllers['coreSkills']?.text ?? '') as String)
                        .split(',')
                        .map((String s) => s.trim())
                        .where((String s) => s.isNotEmpty)
                        .toList(),
                experience: _workExperiences
                    .map((WorkExperience exp) => exp.description)
                    .where((String desc) => desc.isNotEmpty)
                    .toList(),
                seed: state
                    .controllers['summary']
                    ?.text, // Use current summary as seed for optimization
                onGenerated: (summary) {
                  state.controllers['summary']?.text = summary;
                },
              ),
            ],
          ),
        );
      case 'skills':
        return _onePageCollapsibleSection(
          key: ValueKey('skills'),
          title: 'Key Skills',
          sectionKey: 'skills',
          icon: Icons.handyman,
          dragIndex: index,
          child: SkillsPickerField(
            controller: state.controllerFor('coreSkills'),
            label: '6–10 Relevant Skills',
          ),
        );
      case 'experience':
        return _onePageCollapsibleSection(
          key: ValueKey('experience'),
          title: 'Work Experience',
          sectionKey: 'experience',
          icon: Icons.work,
          dragIndex: index,
          child: DynamicWorkExperienceSection(
            workExperiences: _workExperiences,
            onWorkExperiencesChanged: (experiences) {
              setState(() {
                _workExperiences = experiences;
                // Store as JSON in a hidden controller for saving
                state.controllerFor('workExperiencesJson').text = json.encode(
                  experiences.map((e) => e.toJson()).toList(),
                );
              });
            },
            accentColor: _accentColor,
            atsFriendly: isAts,
          ),
        );
      case 'education':
        return _onePageCollapsibleSection(
          key: ValueKey('education'),
          title: 'Education',
          sectionKey: 'education',
          icon: Icons.school,
          dragIndex: index,
          child: DynamicEducationSection(
            educations: _educations,
            onEducationsChanged: (educations) {
              setState(() {
                _educations = educations;
                // Store as JSON in a hidden controller for saving
                state.controllerFor('educationsJson').text = json.encode(
                  educations.map((e) => e.toJson()).toList(),
                );
              });
            },
            accentColor: _accentColor,
            atsFriendly: isAts,
          ),
        );
      case 'projects':
        return _onePageCollapsibleSection(
          key: ValueKey('projects'),
          title: 'Projects (if relevant)',
          sectionKey: 'projects',
          icon: Icons.code,
          dragIndex: index,
          child: state.buildTextField(
            'projects',
            'Project Title – Brief Description – Tech / Role',
            maxLines: 4,
          ),
        );
      case 'certifications':
        return _onePageCollapsibleSection(
          key: ValueKey('certifications'),
          title: 'Certifications (if relevant)',
          sectionKey: 'certifications',
          icon: Icons.workspace_premium,
          dragIndex: index,
          child: state.buildTextField(
            'certifications',
            'Certification Name | Issuer | Year',
            maxLines: 3,
          ),
        );
      case 'additional':
        return _onePageCollapsibleSection(
          key: ValueKey('additional'),
          title: 'Additional (Optional)',
          sectionKey: 'additional',
          icon: Icons.more_horiz,
          dragIndex: index,
          child: Column(
            children: [
              state.buildTextField('awards', 'Awards & Honors', maxLines: 3),
              state.buildTextField('languages', 'Languages Known', maxLines: 2),
              state.buildTextField(
                'volunteer',
                'Volunteer Experience',
                maxLines: 3,
              ),
              state.buildTextField(
                'memberships',
                'Professional Memberships',
                maxLines: 3,
              ),
              state.buildTextField(
                'hobbies',
                'Hobbies / Interests (only if relevant)',
                maxLines: 2,
              ),
            ],
          ),
        );
      default:
        return Container(key: ValueKey(sectionKey));
    }
  }

  void _openCustomization(state) {
    // Build resume data manually for customization
    final Map<String, dynamic> data = {
      for (final e in state.controllers.entries) e.key: e.value.text,
    };

    // Add dynamic data (work experiences and educations)
    data['workExperiencesJson'] = jsonEncode(
      _workExperiences.map((exp) => exp.toJson()).toList(),
    );
    data['educationsJson'] = jsonEncode(
      _educations.map((edu) => edu.toJson()).toList(),
    );

    final title = state.controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${state.controllers['name']!.text} Resume';

    final existingResume = state.widget.existingResume;
    final tempResume = SavedResume(
      id:
          existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: existingResume?.title ?? title,
      template: 'One Page',
      createdAt: existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    // Navigate to customization screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnePageCustomizationScreen(
          resume: tempResume,
          onCustomizationChanged: (customizationData) {
            // Update the resume data with customization
            for (final entry in customizationData.entries) {
              state.controllerFor(entry.key).text = entry.value;
            }
          },
        ),
      ),
    );
  }

  void _previewResume(state) {
    // Build resume data manually for preview
    final Map<String, dynamic> data = {
      for (final e in state.controllers.entries) e.key: e.value.text,
    };

    // Add dynamic data (work experiences and educations)
    data['workExperiencesJson'] = jsonEncode(
      _workExperiences.map((exp) => exp.toJson()).toList(),
    );
    data['educationsJson'] = jsonEncode(
      _educations.map((edu) => edu.toJson()).toList(),
    );

    final title = state.controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${state.controllers['name']!.text} Resume';

    final existingResume = state.widget.existingResume;
    final tempResume = SavedResume(
      id:
          existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: existingResume?.title ?? title,
      template: 'One Page',
      createdAt: existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    // Navigate to One Page Resume preview (direct route to avoid missing named route)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnePageResumePreview(resume: tempResume),
      ),
    );
  }

  void _exportResume(state, String format) async {
    // Build resume data manually for export
    final Map<String, dynamic> data = {
      for (final e in state.controllers.entries) e.key: e.value.text,
    };

    // Add dynamic data (work experiences and educations)
    data['workExperiencesJson'] = jsonEncode(
      _workExperiences.map((exp) => exp.toJson()).toList(),
    );
    data['educationsJson'] = jsonEncode(
      _educations.map((edu) => edu.toJson()).toList(),
    );

    final title = state.controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${state.controllers['name']!.text} Resume';

    final existingResume = state.widget.existingResume;
    final tempResume = SavedResume(
      id:
          existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: existingResume?.title ?? title,
      template: 'One Page',
      createdAt: existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    final shareService = ShareExportService(context);

    try {
      switch (format) {
        case 'PDF':
          await shareService.exportAndOpenPdf(tempResume);
          break;
        case 'DOCX':
          await shareService.exportAndOpenDocx(tempResume);
          break;
        case 'TXT':
          await shareService.exportAndOpenTxt(tempResume);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareResume(state, String platform) async {
    // Build resume data manually for sharing
    final Map<String, dynamic> data = {
      for (final e in state.controllers.entries) e.key: e.value.text,
    };

    // Add dynamic data (work experiences and educations)
    data['workExperiencesJson'] = jsonEncode(
      _workExperiences.map((exp) => exp.toJson()).toList(),
    );
    data['educationsJson'] = jsonEncode(
      _educations.map((edu) => edu.toJson()).toList(),
    );

    final title = state.controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${state.controllers['name']!.text} Resume';

    final existingResume = state.widget.existingResume;
    final tempResume = SavedResume(
      id:
          existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: existingResume?.title ?? title,
      template: 'One Page',
      createdAt: existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    final shareService = ShareExportService(context);

    try {
      switch (platform) {
        case 'email':
          await shareService.shareViaEmail(tempResume);
          break;
        case 'whatsapp':
          await shareService.shareViaWhatsApp(tempResume);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
