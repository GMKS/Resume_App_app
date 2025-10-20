import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../widgets/phone_input_widget.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';
import '../widgets/ai_widgets.dart';
import 'classic_resume_preview.dart';
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
  List<CustomField> _customFields = [];
  bool _atsFriendly = true;
  int _bottomIndex =
      1; // default highlight Preview (Home, Preview, Share, Save)

  // Collapsible section states - All collapsed by default
  Map<String, bool> _sectionExpanded = {
    'title': false,
    'contact': false,
    'summary': false,
    'skills': false,
    'experience': false,
    'education': false,
    'certifications': false,
    'custom': false,
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

      // Load custom fields from JSON
      if (widget.existing!.data['customFields'] != null) {
        try {
          final List<dynamic> customFieldsData = jsonDecode(
            widget.existing!.data['customFields'],
          );
          _customFields = customFieldsData
              .map((item) => CustomField.fromJson(item))
              .toList();
        } catch (e) {
          _customFields = [];
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

    // Add custom field
    if (controllers['customField']?.text.isNotEmpty == true) {
      final customLabel =
          controllers['customFieldLabel']?.text.isNotEmpty == true
          ? controllers['customFieldLabel']!.text
          : 'Additional Information';
      buffer.writeln('\n$customLabel: ${controllers['customField']!.text}');
    }

    return buffer.toString();
  }

  // Collapsible section card wrapper for cleaner visual grouping
  Widget _sectionCard({
    required String title,
    IconData? icon,
    required Widget child,
    String? sectionKey,
  }) {
    final isExpanded = sectionKey != null
        ? (_sectionExpanded[sectionKey] ?? false)
        : true;

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
            InkWell(
              onTap: sectionKey != null
                  ? () {
                      setState(() {
                        // Collapse all others; toggle the tapped one
                        for (final key in _sectionExpanded.keys) {
                          _sectionExpanded[key] = false;
                        }
                        _sectionExpanded[sectionKey] = !isExpanded;
                      });
                    }
                  : null,
              child: Row(
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
                  if (sectionKey != null)
                    Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
            ),
            if (isExpanded) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
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
          await ShareExportService(context).exportAndOpenPdf(resume);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DOCX export is not available in this version.'),
            ),
          );
          break;
        case 'TXT':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('TXT export is not available in this version.'),
            ),
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
        'resumeTitle',
        'summary',
        'skills',
        'certifications',
        'workExperiences',
        'educations',
        'customField',
        'customFieldLabel',
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
            ),
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resume Title Section
                  _sectionCard(
                    title: 'Resume Title',
                    icon: Icons.title,
                    sectionKey: 'title',
                    child: Column(
                      children: [
                        state.buildTextField(
                          'resumeTitle',
                          'Resume Title (e.g., Senior Project Manager)',
                          required: false,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a descriptive title that includes your name and position',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  _sectionCard(
                    title: 'Contact Info',
                    icon: Icons.contact_page,
                    sectionKey: 'contact',
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
                        const SizedBox(height: 12),
                        PhoneInputWidget(
                          key: const Key('phone_input'),
                          initialPhoneNumber: state.controllerFor('phone').text,
                          onChanged:
                              (fullPhoneNumber, countryCode, phoneNumber) {
                                state.controllerFor('phone').text =
                                    fullPhoneNumber;
                              },
                        ),
                      ],
                    ),
                  ),

                  // Professional Summary
                  _sectionCard(
                    title: 'Professional Summary',
                    icon: Icons.badge,
                    sectionKey: 'summary',
                    child: state.buildTextField(
                      'summary',
                      'Professional Summary',
                      maxLines: 3,
                      required: true,
                    ),
                  ),

                  // Skills
                  _sectionCard(
                    title: 'Skills',
                    icon: Icons.handyman,
                    sectionKey: 'skills',
                    child: SkillsPickerField(
                      controller: state.controllerFor('skills'),
                      label: 'Skills',
                    ),
                  ),

                  // Work Experience
                  _sectionCard(
                    title: 'Work Experience',
                    icon: Icons.work,
                    sectionKey: 'experience',
                    child: DynamicWorkExperienceSection(
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
                  ),

                  _sectionCard(
                    title: 'Education',
                    icon: Icons.school,
                    sectionKey: 'education',
                    child: DynamicEducationSection(
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
                  ),

                  _sectionCard(
                    title: 'Certifications',
                    icon: Icons.workspace_premium,
                    sectionKey: 'certifications',
                    child: state.buildTextField(
                      'certifications',
                      'Certifications',
                      maxLines: 2,
                    ),
                  ),

                  _sectionCard(
                    title: 'Custom Fields',
                    icon: Icons.add_box,
                    sectionKey: 'custom',
                    child: DynamicCustomFieldsSection(
                      customFields: _customFields,
                      onCustomFieldsChanged: (fields) {
                        setState(() {
                          _customFields = fields;
                          // Update JSON in hidden controller for BaseResumeForm
                          state.controllerFor('customFields').text = jsonEncode(
                            fields.map((f) => f.toJson()).toList(),
                          );
                        });
                      },
                      atsFriendly: _atsFriendly,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Analyze ATS button (replaces toggle)
                  StatefulBuilder(
                    builder: (context, setLocal) {
                      bool isAnalyzing = false;
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Analyze ATS'),
                        onPressed: isAnalyzing
                            ? null
                            : () async {
                                setLocal(() => isAnalyzing = true);
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Running ATS analysis...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  await Future.delayed(
                                    const Duration(milliseconds: 800),
                                  );
                                } finally {
                                  setLocal(() => isAnalyzing = false);
                                }
                              },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // ATS Optimization Panel always visible with latest content
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription: '',
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Use a Builder so the BottomNavigationBar has a context
            // that is a descendant of BaseResumeForm. This ensures
            // BaseResumeForm.of(ctx) resolves correctly.
            bottomNavigationBar: Builder(
              builder: (navCtx) => BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blueAccent,
                unselectedItemColor: Colors.grey.shade600,
                backgroundColor: Colors.white,
                elevation: 8,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 12,
                unselectedFontSize: 11,
                currentIndex: _bottomIndex,
                onTap: (index) {
                  setState(() => _bottomIndex = index);
                  _handleBottomNavTap(navCtx, index);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded, size: 28),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.visibility_rounded, size: 28),
                    label: 'Preview',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.share_rounded, size: 28),
                    label: 'Share',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.save_rounded, size: 28),
                    label: 'Save',
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

extension on _ClassicResumeFormScreenState {
  void _handleBottomNavTap(BuildContext ctx, int index) async {
    final state = BaseResumeForm.of(ctx);
    if (state == null) return;

    switch (index) {
      case 0: // Home
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: const Text('Save before leaving?'),
            content: const Text('Do you want me to save your resume?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: const Text('Yes, Save'),
              ),
            ],
          ),
        );
        if (shouldSave == true) {
          await state.saveResume();
        }
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        break;
      case 1: // Preview
        await _previewResumeWithState(state);
        break;
      case 2: // Share
        _showShareOptions(state);
        break;
      case 3: // Save
        await state.saveResume();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume saved successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
    }
  }

  Future<void> _previewResume() async {
    final state = BaseResumeForm.of(context);
    if (state == null) return;
    try {
      // Collect current controllers into data map
      final Map<String, dynamic> data = {
        for (final e in state.controllers.entries) e.key: e.value.text,
      };
      // Ensure dynamic sections are encoded
      data['workExperiences'] = jsonEncode(
        _workExperiences.map((e) => e.toJson()).toList(),
      );
      data['educations'] = jsonEncode(
        _educations.map((e) => e.toJson()).toList(),
      );

      final title = state.controllers['name']?.text.isEmpty == true
          ? 'Preview'
          : '${state.controllers['name']!.text} Resume';

      final resume = SavedResume(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        template: 'Classic',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: data,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassicResumePreview(resume: resume)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
      }
    }
  }

  // Helper to preview using an already-obtained BaseResumeForm state
  Future<void> _previewResumeWithState(dynamic state) async {
    try {
      final Map<String, dynamic> data = {
        for (final e in state.controllers.entries) e.key: e.value.text,
      };
      data['workExperiences'] = jsonEncode(
        _workExperiences.map((e) => e.toJson()).toList(),
      );
      data['educations'] = jsonEncode(
        _educations.map((e) => e.toJson()).toList(),
      );

      final title = state.controllers['name']?.text.isEmpty == true
          ? 'Preview'
          : '${state.controllers['name']!.text} Resume';

      final resume = SavedResume(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        template: 'Classic',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: data,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassicResumePreview(resume: resume)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
      }
    }
  }

  void _showShareOptions(dynamic state) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Save as PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  final resume = _createResumeFromState(state);
                  final service = ShareExportService(this.context);
                  await service.exportAndOpenPdf(resume);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('Save as DOCX'),
                onTap: () async {
                  Navigator.pop(context);
                  final resume = _createResumeFromState(state);
                  final service = ShareExportService(this.context);
                  await service.exportAndOpenDocx(resume);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.green),
                title: const Text('Share via Email'),
                onTap: () async {
                  Navigator.pop(context);
                  final resume = _createResumeFromState(state);
                  final service = ShareExportService(this.context);
                  await service.shareViaEmail(resume);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.teal),
                title: const Text('Share via WhatsApp'),
                onTap: () async {
                  Navigator.pop(context);
                  final resume = _createResumeFromState(state);
                  final service = ShareExportService(this.context);
                  await service.shareViaWhatsApp(resume);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  SavedResume _createResumeFromState(dynamic state) {
    final Map<String, dynamic> data = {
      for (final e in state.controllers.entries) e.key: e.value.text,
    };
    data['workExperiences'] = jsonEncode(
      _workExperiences.map((e) => e.toJson()).toList(),
    );
    data['educations'] = jsonEncode(
      _educations.map((e) => e.toJson()).toList(),
    );
    data['customFields'] = jsonEncode(
      _customFields.map((e) => e.toJson()).toList(),
    );

    final title = state.controllers['name']?.text.isEmpty == true
        ? 'Classic Resume'
        : '${state.controllers['name']!.text} Resume';

    return SavedResume(
      id:
          widget.existing?.id ??
          'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      template: 'Classic',
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );
  }
}
