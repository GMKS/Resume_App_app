import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_resume.dart';
import '../models/branding.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart';
import '../services/ai_resume_service.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';
import '../services/resume_storage_service.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/phone_input_widget.dart';
import '../screens/customization_screen.dart';
import '../screens/professional_resume_preview.dart';
import '../widgets/skills_picker_field.dart';

class ProfessionalResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const ProfessionalResumeFormScreen({super.key, this.existing});

  @override
  State<ProfessionalResumeFormScreen> createState() =>
      _ProfessionalResumeFormScreenState();
}

class _ProfessionalResumeFormScreenState
    extends State<ProfessionalResumeFormScreen>
    with WidgetsBindingObserver {
  final List<WorkExperience> _workExperiences = [];
  final List<Education> _educations = [];
  BrandingTheme _currentBranding = BrandingTheme.professional;
  bool _atsFriendly = false;

  // Auto-save timer
  Timer? _autoSaveTimer;
  Timer? _markChangedTimer;
  bool _hasUnsavedChanges = false;

  // Store BuildContext for BaseResumeForm access
  BuildContext? _formContext;

  // Color theme for Professional template
  static const Color _accentColor = Color(0xFF2E3A47);

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
    // Initialize with one empty entry
    _workExperiences.add(WorkExperience(id: '1'));
    _educations.add(Education(id: '1'));
    _loadBrandingFromResume();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Start auto-save timer
    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel auto-save timer
    _autoSaveTimer?.cancel();
    _markChangedTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Auto-save when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      print('DEBUG: App lifecycle change detected: $state - Auto-saving...');
      _performAutoSave();
    }
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_hasUnsavedChanges) {
        print('DEBUG: Auto-save timer triggered');
        _performAutoSave();
      }
    });
  }

  void _performAutoSave() async {
    try {
      final state = _getFormState();
      if (state != null && _hasUnsavedChanges) {
        print('DEBUG: Performing auto-save...');
        await _saveResumeWithoutNavigation(state);
        setState(() {
          _hasUnsavedChanges = false;
        });
        print('DEBUG: Auto-save completed successfully');
      }
    } catch (e) {
      print('DEBUG: Auto-save failed: $e');
    }
  }

  // Save resume without navigation for auto-save
  Future<void> _saveResumeWithoutNavigation(dynamic state) async {
    try {
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
      data['branding'] = jsonEncode(_currentBranding.toJson());

      final title = state.controllers['name']?.text.isEmpty == true
          ? 'My Resume'
          : '${state.controllers['name']!.text} Resume';

      final resume = SavedResume(
        id: widget.existing?.id ?? ResumeStorageService.instance.generateId(),
        title: widget.existing?.title ?? title,
        template: 'Professional',
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        data: data,
      );

      await ResumeStorageService.instance.saveOrUpdate(resume);
      print('DEBUG: Resume saved without navigation');
    } catch (e) {
      print('DEBUG: Save without navigation failed: $e');
      rethrow;
    }
  }

  void _markAsChanged() {
    // Cancel previous timer to debounce rapid changes
    _markChangedTimer?.cancel();

    // Set a short delay before marking as changed to avoid excessive auto-saves during typing
    _markChangedTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        print('DEBUG: Data marked as changed - auto-save scheduled');
      }
    });
  }

  // Helper method to get BaseResumeForm state
  dynamic _getFormState() {
    if (_formContext == null) {
      print('DEBUG: Form context is null');
      return null;
    }
    return BaseResumeForm.of(_formContext!);
  }

  void _loadBrandingFromResume() {
    if (widget.existing == null) return;

    final data = widget.existing!.data;
    print('DEBUG: Loading existing resume data: ${data.keys.toList()}');

    // Load branding
    if (data['branding'] != null) {
      try {
        final brandingJson = jsonDecode(data['branding']);
        _currentBranding = BrandingTheme.fromJson(brandingJson);
        print('DEBUG: Loaded branding theme');
      } catch (e) {
        print('DEBUG: Error loading branding: $e');
        _currentBranding = BrandingTheme.professional;
      }
    }

    // Load ATS flag if present
    try {
      final atsv = (data['ats_friendly'] ?? '').toString();
      _atsFriendly = atsv == 'true';
      print('DEBUG: Loaded ATS friendly: $_atsFriendly');
    } catch (e) {
      print('DEBUG: Error loading ATS flag: $e');
    }

    // Load work experiences
    if (data['workExperiences'] != null &&
        data['workExperiences'].toString().isNotEmpty) {
      try {
        final workExpList =
            jsonDecode(data['workExperiences'].toString()) as List;
        _workExperiences.clear();
        _workExperiences.addAll(
          workExpList.map(
            (item) => WorkExperience.fromJson(item as Map<String, dynamic>),
          ),
        );
        print('DEBUG: Loaded ${_workExperiences.length} work experiences');
      } catch (e) {
        print('DEBUG: Error loading work experiences: $e');
        // Keep the default empty entry if loading fails
      }
    }

    // Load educations
    if (data['educations'] != null &&
        data['educations'].toString().isNotEmpty) {
      try {
        final educationsList =
            jsonDecode(data['educations'].toString()) as List;
        _educations.clear();
        _educations.addAll(
          educationsList.map(
            (item) => Education.fromJson(item as Map<String, dynamic>),
          ),
        );
        print('DEBUG: Loaded ${_educations.length} educations');
      } catch (e) {
        print('DEBUG: Error loading educations: $e');
        // Keep the default empty entry if loading fails
      }
    }
  }

  Future<void> _openCustomization() async {
    print('DEBUG: _openCustomization called');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CustomizationScreen(templateType: 'Professional'),
      ),
    );

    print('DEBUG: Customization result: $result');

    if (result is BrandingTheme) {
      print('DEBUG: Received BrandingTheme, updating state');
      setState(() {
        _currentBranding = result;
      });

      // Update the branding in BaseResumeForm
      final state = _getFormState();
      if (state != null) {
        state.controllerFor('branding').text = jsonEncode(
          _currentBranding.toJson(),
        );

        // Auto-save the changes to ensure they persist
        try {
          await state.saveResume();
          print('DEBUG: Branding saved successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branding theme applied and saved!')),
          );
        } catch (e) {
          print('DEBUG: Error saving branding: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theme applied but save failed: $e')),
          );
        }
      } else {
        print('DEBUG: BaseResumeForm state is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branding theme applied!')),
        );
      }
    } else {
      print('DEBUG: No branding result received');
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

    // Add professional summary
    if (controllers['executiveSummary']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nProfessional Summary: ${controllers['executiveSummary']!.text}',
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

    // Add projects
    if (controllers['projects']?.text.isNotEmpty == true) {
      buffer.writeln('\nProjects: ${controllers['projects']!.text}');
    }

    // Add languages
    if (controllers['languages']?.text.isNotEmpty == true) {
      buffer.writeln('\nLanguages: ${controllers['languages']!.text}');
    }

    // Add hobbies
    if (controllers['hobbies']?.text.isNotEmpty == true) {
      buffer.writeln('\nHobbies: ${controllers['hobbies']!.text}');
    }

    // Add references
    if (controllers['references']?.text.isNotEmpty == true) {
      buffer.writeln('\nReferences: ${controllers['references']!.text}');
    }

    return buffer.toString();
  }

  String _buildFullTextContent(String basicContent, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln(basicContent);

    // Add work experiences from JSON
    if (data['workExperiences'] != null) {
      try {
        final List<dynamic> experiences = jsonDecode(data['workExperiences']);
        if (experiences.isNotEmpty) {
          buffer.writeln('\n=== WORK EXPERIENCE ===');
          for (final exp in experiences) {
            buffer.writeln(
              '${exp['jobTitle'] ?? ''} at ${exp['company'] ?? ''}',
            );
            if (exp['location'] != null)
              buffer.writeln('Location: ${exp['location']}');
            if (exp['startDate'] != null || exp['endDate'] != null) {
              buffer.writeln(
                'Period: ${exp['startDate'] ?? ''} - ${exp['endDate'] ?? 'Present'}',
              );
            }
            if (exp['description'] != null)
              buffer.writeln('${exp['description']}');
            buffer.writeln();
          }
        }
      } catch (e) {
        print('Error parsing work experiences: $e');
      }
    }

    // Add education from JSON
    if (data['educations'] != null) {
      try {
        final List<dynamic> educations = jsonDecode(data['educations']);
        if (educations.isNotEmpty) {
          buffer.writeln('\n=== EDUCATION ===');
          for (final edu in educations) {
            buffer.writeln(
              '${edu['degree'] ?? ''} - ${edu['institution'] ?? edu['university'] ?? edu['school'] ?? ''}',
            );
            if (edu['startDate'] != null || edu['endDate'] != null) {
              buffer.writeln(
                'Period: ${edu['startDate'] ?? ''} - ${edu['endDate'] ?? 'Present'}',
              );
            }
            if (edu['description'] != null)
              buffer.writeln('${edu['description']}');
            buffer.writeln();
          }
        }
      } catch (e) {
        print('Error parsing educations: $e');
      }
    }

    buffer.writeln('\n--- End of Resume ---');
    buffer.writeln('Generated by Resume Builder App');
    buffer.writeln('ATS-Friendly Plain Text Format');

    return buffer.toString();
  }

  Future<void> _exportResume(String format) async {
    final state = _getFormState();
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
          await ShareExportService(context).exportAndOpenPdf(resume);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF export completed')));
          break;
        case 'DOCX':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DOCX export is not available in this version.'),
            ),
          );
          break;
        case 'TXT':
          // Create TXT version of resume
          final txtContent = _getResumeContent(state.controllers);
          // Add work experience and education data to TXT
          final fullTxtContent = _buildFullTextContent(txtContent, data);

          // Save to temporary file and share
          final tempDir = await getTemporaryDirectory();
          final txtFile = File(
            '${tempDir.path}/${title.replaceAll(' ', '_')}.txt',
          );
          await txtFile.writeAsString(fullTxtContent);

          await Share.shareXFiles([
            XFile(txtFile.path),
          ], text: 'Resume in text format (ATS-friendly)');

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('TXT export completed')));
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
        'title',
        'professionalTitle',
        'location',
        'linkedIn',
        'linkedin',
        'address',
        'website',
        'portfolio',
        'executiveSummary',
        'keySkills',
        'certifications',
        'projects',
        'awards',
        'languages',
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

          // Store the context for later use
          _formContext = ctx;

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
            // Initialize ATS flag controller
            if (state.controllerFor('ats_friendly').text.isEmpty) {
              state.controllerFor('ats_friendly').text = _atsFriendly
                  ? 'true'
                  : 'false';
            }
          });

          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
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
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    tooltip: 'Preview Resume',
                    onPressed: () {
                      print('DEBUG: Preview button clicked!');
                      _previewResume();
                    },
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
                        print('DEBUG: Share option selected: $choice');
                        if (choice == 'EMAIL') {
                          print('DEBUG: Initiating email share...');
                          await ShareExportService(
                            context,
                          ).shareViaEmail(resume);
                          print('DEBUG: Email share completed');
                        } else if (choice == 'WHATSAPP') {
                          print('DEBUG: Initiating WhatsApp share...');
                          await ShareExportService(
                            context,
                          ).shareViaWhatsApp(resume);
                          print('DEBUG: WhatsApp share completed');
                        }
                      } catch (e) {
                        print('DEBUG: Share error: $e');
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo Section
                    _professionalCollapsibleSection(
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
                            _markAsChanged();
                          },
                        ),
                      ],
                    ),

                    // Personal Information Section
                    _professionalCollapsibleSection(
                      'personal',
                      'Personal Information',
                      Icons.person,
                      [
                        state.buildTextField(
                          'name',
                          'Full Name',
                          required: true,
                          onChanged: _markAsChanged,
                        ),
                        const SizedBox(height: 16),
                        PhoneInputWidget(
                          initialPhoneNumber:
                              widget.existing?.data['phone'] ?? '',
                          onChanged:
                              (fullPhoneNumber, countryCode, phoneNumber) {
                                setState(() {
                                  state.controllers['phone']?.text =
                                      fullPhoneNumber;
                                });
                                _markAsChanged();
                              },
                        ),
                        const SizedBox(height: 16),
                        state.buildTextField(
                          'email',
                          'Email Address',
                          required: true,
                          keyboard: TextInputType.emailAddress,
                          onChanged: _markAsChanged,
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
                        const SizedBox(height: 16),
                        state.buildTextField(
                          'location',
                          'Location',
                          onChanged: _markAsChanged,
                        ),
                        const SizedBox(height: 16),
                        state.buildTextField(
                          'website',
                          'Website',
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // Executive Summary Section
                    _professionalCollapsibleSection(
                      'summary',
                      'Professional Summary',
                      Icons.description,
                      [
                        Row(
                          children: [
                            Expanded(
                              child: state.buildTextField(
                                'executiveSummary',
                                '3–4 line Professional Summary',
                                maxLines: 4,
                                required: true,
                                onChanged: _markAsChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    print('DEBUG: AI Generate button clicked!');
                                    _generateAISummary();
                                  },
                                  icon: Icon(Icons.auto_awesome, size: 16),
                                  label: Text('AI Generate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _currentBranding.primaryColor != null
                                        ? _hexToColor(
                                            _currentBranding.primaryColor!,
                                          )
                                        : _accentColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    print('DEBUG: AI Optimize button clicked!');
                                    _optimizeAISummary();
                                  },
                                  icon: Icon(Icons.tune, size: 16),
                                  label: Text('AI Optimize'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Key Skills Section
                    _professionalCollapsibleSection(
                      'skills',
                      'Key Skills',
                      Icons.lightbulb,
                      [
                        SkillsPickerField(
                          controller: state.controllerFor('keySkills'),
                          label: 'Key Skills',
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // Experience Section
                    _professionalCollapsibleSection(
                      'experience',
                      'Work Experience',
                      Icons.work,
                      [
                        DynamicWorkExperienceSection(
                          workExperiences: _workExperiences,
                          onWorkExperiencesChanged: (experiences) {
                            setState(() {
                              _workExperiences
                                ..clear()
                                ..addAll(experiences);
                              state
                                  .controllerFor('workExperiences')
                                  .text = jsonEncode(
                                experiences.map((e) => e.toJson()).toList(),
                              );
                            });
                            _markAsChanged();
                          },
                          accentColor: _accentColor,
                          atsFriendly: _atsFriendly,
                        ),
                      ],
                    ),

                    // Education Section
                    _professionalCollapsibleSection(
                      'education',
                      'Education',
                      Icons.school,
                      [
                        DynamicEducationSection(
                          educations: _educations,
                          onEducationsChanged: (educations) {
                            setState(() {
                              _educations
                                ..clear()
                                ..addAll(educations);
                              state
                                  .controllerFor('educations')
                                  .text = jsonEncode(
                                educations.map((e) => e.toJson()).toList(),
                              );
                            });
                            _markAsChanged();
                          },
                          accentColor: _accentColor,
                          atsFriendly: _atsFriendly,
                        ),
                      ],
                    ),

                    // Projects Section
                    _professionalCollapsibleSection(
                      'projects',
                      'Projects',
                      Icons.folder,
                      [
                        state.buildTextField(
                          'projects',
                          'Projects',
                          maxLines: 3,
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // Certifications Section
                    _professionalCollapsibleSection(
                      'certifications',
                      'Certifications',
                      Icons.verified,
                      [
                        state.buildTextField(
                          'certifications',
                          'Certifications',
                          maxLines: 2,
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // Languages Section
                    _professionalCollapsibleSection(
                      'languages',
                      'Languages',
                      Icons.language,
                      [
                        state.buildTextField(
                          'languages',
                          'Languages',
                          maxLines: 2,
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // Hobbies Section
                    _professionalCollapsibleSection(
                      'hobbies',
                      'Hobbies',
                      Icons.interests,
                      [
                        state.buildTextField(
                          'hobbies',
                          'Hobbies',
                          maxLines: 2,
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // References Section
                    _professionalCollapsibleSection(
                      'references',
                      'References',
                      Icons.people,
                      [
                        state.buildTextField(
                          'references',
                          'References',
                          maxLines: 3,
                          onChanged: _markAsChanged,
                        ),
                      ],
                    ),

                    // ATS Optimization Section
                    _professionalCollapsibleSection(
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
                          value: _atsFriendly,
                          onChanged: (v) {
                            setState(() => _atsFriendly = v);
                            state.controllerFor('ats_friendly').text = v
                                ? 'true'
                                : 'false';
                            _markAsChanged();
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
                        label: const Text('Save Professional Resume'),
                      ),
                    ),
                  ],
                ),
              ),
            ), // PopScope child closing
          );
        },
      ),
    );
  }

  // Back navigation handler with save prompt
  Future<bool> _onWillPop() async {
    print('DEBUG: _onWillPop called');
    final state = _getFormState();
    if (state == null) {
      print('DEBUG: BaseResumeForm state is null in _onWillPop');
      return true;
    }

    // Check if any data has been entered
    bool hasData = false;
    for (final entry in state.controllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        print(
          'DEBUG: Found data in field ${entry.key}: ${entry.value.text.substring(0, entry.value.text.length < 50 ? entry.value.text.length : 50)}...',
        );
        hasData = true;
        break;
      }
    }

    bool hasWorkExperience = _workExperiences.any((exp) => exp.hasData());
    bool hasEducation = _educations.any((edu) => edu.hasData());

    print(
      'DEBUG: hasData: $hasData, hasWorkExperience: $hasWorkExperience, hasEducation: $hasEducation, hasUnsavedChanges: $_hasUnsavedChanges',
    );

    if (hasWorkExperience || hasEducation || hasData || _hasUnsavedChanges) {
      print('DEBUG: Showing save dialog...');
      final result = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save Changes?'),
          content: const Text(
            'You have unsaved changes. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('DEBUG: Discard button pressed');
                Navigator.pop(context, 'discard');
              },
              child: const Text('Discard Changes'),
            ),
            TextButton(
              onPressed: () {
                print('DEBUG: Cancel button pressed');
                Navigator.pop(context, 'cancel');
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                print('DEBUG: Save & Exit button pressed');
                Navigator.pop(context, 'save');
              },
              child: const Text('Save & Exit'),
            ),
          ],
        ),
      );

      print('DEBUG: Dialog result: $result');

      switch (result) {
        case 'save':
          print('DEBUG: Saving and exiting...');
          await state.saveResume();
          return true;
        case 'discard':
          print('DEBUG: Discarding changes and exiting...');
          return true;
        default:
          print('DEBUG: Cancelling exit...');
          return false;
      }
    }

    print('DEBUG: No data found, allowing exit');
    return true; // No data, allow exit
  }

  // Preview resume method
  Future<void> _previewResume() async {
    print('DEBUG: _previewResume called');
    final state = _getFormState();
    if (state == null) {
      print('DEBUG: BaseResumeForm state is null for preview');
      return;
    }

    try {
      // First trigger auto-save to ensure all data is captured
      await _saveResumeWithoutNavigation(state);

      print('DEBUG: Creating resume data for preview');
      // Create resume data for preview
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
      data['branding'] = jsonEncode(_currentBranding.toJson());

      // Debug: Print all collected data
      print('DEBUG: Form data collected:');
      for (final entry in data.entries) {
        if (entry.value.toString().isNotEmpty) {
          print(
            '  ${entry.key}: ${entry.value.toString().substring(0, math.min(50, entry.value.toString().length))}...',
          );
        }
      }

      final title = state.controllers['name']?.text.isEmpty == true
          ? 'Preview'
          : '${state.controllers['name']!.text} Resume';

      print('DEBUG: Creating SavedResume object with title: $title');

      final resume = SavedResume(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        template: 'Professional',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: data,
      );

      print('DEBUG: Navigating to ProfessionalResumePreview');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalResumePreview(resume: resume),
        ),
      );
    } catch (e) {
      print('DEBUG: Error in _previewResume: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
    }
  }

  Widget _professionalCollapsibleSection(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: _accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E3A47),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: _accentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Content (only visible when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  // AI Summary Generation Methods
  Future<void> _generateAISummary() async {
    print('DEBUG: _generateAISummary called');
    final state = _getFormState();
    if (state == null) {
      print('DEBUG: BaseResumeForm state is null');
      return;
    }

    print('DEBUG: Checking premium status: ${PremiumService.isPremium}');
    if (!PremiumService.isPremium) {
      print('DEBUG: Not premium, showing upgrade dialog');
      PremiumService.showUpgradeDialog(context, 'AI Summary Generation');
      return;
    }
    try {
      // Show loading
      print('DEBUG: Showing loading snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating AI summary options...')),
      );

      // Gather context from form
      final name = state.controllers['name']?.text ?? '';
      print('DEBUG: Extracted name: $name');

      final targetRole = _workExperiences.isNotEmpty
          ? _workExperiences.first.jobTitle
          : state.controllers['professionalTitle']?.text ?? 'Professional';
      print('DEBUG: Extracted targetRole: $targetRole');

      final skillsText = state.controllers['keySkills']?.text ?? '';
      print('DEBUG: Raw skills text: $skillsText');

      List<String> skills = [];
      try {
        skills = skillsText
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        print('DEBUG: Processed skills: $skills');
      } catch (e) {
        print('DEBUG: Error processing skills: $e');
        skills = [];
      }

      List<String> experience = [];
      try {
        experience = _workExperiences
            .map((exp) => exp.description)
            .where((desc) => desc.isNotEmpty)
            .toList();
        print('DEBUG: Processed experience: ${experience.length} items');
      } catch (e) {
        print('DEBUG: Error processing experience: $e');
        experience = [];
      }

      print(
        'DEBUG: Calling AI service with: name=$name, role=$targetRole, skills=${skills.length}, experience=${experience.length}',
      );

      // Generate multiple summary options using AI service
      final summaryOptions = <String>[];

      // Generate 3 different summary variations
      for (int i = 0; i < 3; i++) {
        try {
          final summary = await AIResumeService.generateSummary(
            name: name,
            targetRole: targetRole,
            skills: skills,
            experience: experience,
          );
          if (summary.isNotEmpty && !summaryOptions.contains(summary)) {
            summaryOptions.add(summary);
          }
        } catch (e) {
          print('DEBUG: Error generating summary option ${i + 1}: $e');
        }
      }

      print('DEBUG: Generated ${summaryOptions.length} summary options');

      if (summaryOptions.isNotEmpty) {
        // Show selection dialog
        _showSummarySelectionDialog(summaryOptions, state);
      } else {
        print('DEBUG: No summary options generated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to generate summary options. Please try again.',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _generateAISummary: $e');
      print('DEBUG: Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating summary: $e')));
    }
  }

  void _showSummarySelectionDialog(List<String> summaryOptions, dynamic state) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose AI Generated Summary'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select one of the AI-generated professional summaries below:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...summaryOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        state.controllers['executiveSummary']?.text = summary;
                        _markAsChanged();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Summary option ${index + 1} applied successfully!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: _currentBranding.primaryColor != null
                                      ? _hexToColor(
                                          _currentBranding.primaryColor!,
                                        )
                                      : _accentColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Option ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _currentBranding.primaryColor != null
                                        ? _hexToColor(
                                            _currentBranding.primaryColor!,
                                          )
                                        : _accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(summary, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Generate more options
                Navigator.of(context).pop();
                _generateAISummary();
              },
              child: const Text('Generate More'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _optimizeAISummary() async {
    final state = _getFormState();
    if (state == null) return;

    if (!PremiumService.isPremium) {
      PremiumService.showUpgradeDialog(context, 'AI Summary Optimization');
      return;
    }

    final currentSummary = state.controllers['executiveSummary']?.text ?? '';
    print(
      'DEBUG: _optimizeAISummary called with current summary: $currentSummary',
    );

    if (currentSummary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a summary first to optimize'),
        ),
      );
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimizing summary with AI...')),
      );

      // Gather additional context
      final targetRole = _workExperiences.isNotEmpty
          ? _workExperiences.first.jobTitle
          : state.controllers['professionalTitle']?.text ?? 'Professional';
      print('DEBUG: Target role for optimization: $targetRole');

      List<String> skills = [];
      try {
        skills = (state.controllers['keySkills']?.text ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        print('DEBUG: Skills for optimization: $skills');
      } catch (e) {
        print('DEBUG: Error processing skills for optimization: $e');
        skills = [];
      }

      print(
        'DEBUG: Calling AI optimize with: currentSummary length=${currentSummary.length}, role=$targetRole, skills=${skills.length}',
      );

      // Optimize summary using AI service
      final optimizedSummary = await AIResumeService.optimizeSummary(
        currentSummary: currentSummary,
        targetRole: targetRole,
        keySkills: skills,
      );

      print(
        'DEBUG: AI optimization returned: ${optimizedSummary.length} characters',
      );

      if (optimizedSummary.isNotEmpty) {
        state.controllers['executiveSummary']?.text = optimizedSummary;
        print('DEBUG: Optimized summary set in controller');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary optimized successfully!')),
        );
        _markAsChanged();
      } else {
        print('DEBUG: Empty optimized summary returned');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to optimize summary. Please try again.'),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _optimizeAISummary: $e');
      print('DEBUG: Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error optimizing summary: $e')));
    }
  }

  // Helper method to convert hex color string to Color
  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
