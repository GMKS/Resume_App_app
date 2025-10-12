import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';

class ClassicResumeToastFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const ClassicResumeToastFormScreen({super.key, this.existing});

  @override
  State<ClassicResumeToastFormScreen> createState() =>
      _ClassicResumeToastFormScreenState();
}

class _ClassicResumeToastFormScreenState
    extends State<ClassicResumeToastFormScreen>
    with TickerProviderStateMixin {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  final bool _atsFriendly = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Collapsible section states
  final Map<String, bool> _sectionExpanded = {
    'contact': false,
    'summary': false,
    'skills': false,
    'experience': false,
    'education': false,
    'certifications': false,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final existingResume = widget.existing;
    if (existingResume != null) {
      // Load work experiences from JSON
      if (existingResume.data['workExperiences'] != null) {
        try {
          final List<dynamic> workExpData = jsonDecode(
            existingResume.data['workExperiences'],
          );
          _workExperiences = workExpData
              .map((item) => WorkExperience.fromJson(item))
              .toList();
        } catch (e) {
          _workExperiences = [];
        }
      }

      // Load education from JSON
      if (existingResume.data['educations'] != null) {
        try {
          final List<dynamic> educationData = jsonDecode(
            existingResume.data['educations'],
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

  // Toast-style notification card for form fields with collapsible functionality
  Widget _toastFieldCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? accentColor,
    bool isRequired = false,
    int delay = 0,
    String? sectionKey,
  }) {
    final color = accentColor ?? const Color(0xFF667eea);
    final isExpanded = sectionKey != null
        ? (_sectionExpanded[sectionKey] ?? false)
        : true;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: Offset(0, 0.2 + (delay * 0.1)),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay * 0.1, 1.0, curve: Curves.easeOutBack),
              ),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toast-style header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: InkWell(
                  onTap: sectionKey != null
                      ? () {
                          setState(() {
                            _sectionExpanded[sectionKey] = !isExpanded;
                          });
                        }
                      : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (sectionKey != null)
                        Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      if (isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Content area - only show when expanded
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Toast-style success indicator for completed fields
  Widget _toastSuccessIndicator(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced text field with toast-style design
  Widget _buildToastTextField(
    String key,
    String label, {
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboard,
    String? hint,
  }) {
    final state = BaseResumeForm.of(context);
    if (state == null) return const SizedBox.shrink();
    final controller = state.controllerFor(key);
    final hasContent = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasContent) _toastSuccessIndicator('✓ Completed'),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasContent
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            onChanged: (value) {
              setState(() {}); // Rebuild to show success indicator
              HapticFeedback.lightImpact();
            },
          ),
        ),
      ],
    );
  }

  // Professional Summary suggestions as toast chips
  Widget _buildSummaryToastSuggestions(TextEditingController controller) {
    const suggestions = [
      'Results-driven',
      'Detail-oriented',
      'Proven track record',
      'Strong communication skills',
      'Team player',
      'Innovative thinker',
      'Self-motivated',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Quick Suggestions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: suggestions.map((suggestion) {
            return GestureDetector(
              onTap: () {
                final text = controller.text;
                if (text.isNotEmpty && !text.endsWith(' ')) {
                  controller.text = '$text $suggestion';
                } else {
                  controller.text = text + suggestion;
                }
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                HapticFeedback.lightImpact();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _exportResume(String format) async {
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
          : 'Classic Resume',
      template: 'Classic',
      data: data,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (!PremiumService.isPremium) {
        PremiumService.showUpgradeDialog(context, 'Export');
        return;
      }
      await ShareExportService(context).exportAndOpenPdf(resume);
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
      ],
      child: Builder(
        builder: (ctx) {
          final state = BaseResumeForm.of(ctx);
          if (state == null) {
            return const Center(
              child: Text('Error: Unable to initialize form'),
            );
          }

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
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: const Text(
                'Classic Resume Builder',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF667eea),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: false,
              actions: [
                // Toast-style export button
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onSelected: _exportResume,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'PDF',
                        child: ListTile(
                          leading: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text('Export as PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'DOCX',
                        child: ListTile(
                          leading: Icon(Icons.description, color: Colors.blue),
                          title: Text('Export as DOCX'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'TXT',
                        child: ListTile(
                          leading: Icon(Icons.text_snippet, color: Colors.grey),
                          title: Text('Export as TXT'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toast-style progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classic Resume Builder',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Fill out the sections below to create your professional resume',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contact Information Toast Card
                  _toastFieldCard(
                    title: 'Contact Information',
                    icon: Icons.contact_page,
                    accentColor: const Color(0xFF4facfe),
                    isRequired: true,
                    delay: 0,
                    sectionKey: 'contact',
                    child: Column(
                      children: [
                        _buildToastTextField(
                          'name',
                          'Full Name',
                          required: true,
                          hint: 'e.g., John Smith',
                        ),
                        const SizedBox(height: 16),
                        _buildToastTextField(
                          'email',
                          'Email Address',
                          required: true,
                          keyboard: TextInputType.emailAddress,
                          hint: 'e.g., john.smith@email.com',
                        ),
                        const SizedBox(height: 16),
                        _buildToastTextField(
                          'phone',
                          'Mobile Number',
                          required: true,
                          keyboard: TextInputType.phone,
                          hint: 'e.g., +1 (555) 123-4567',
                        ),
                      ],
                    ),
                  ),

                  // Professional Summary Toast Card
                  _toastFieldCard(
                    title: 'Professional Summary',
                    icon: Icons.badge,
                    accentColor: const Color(0xFF9C27B0),
                    isRequired: true,
                    delay: 1,
                    sectionKey: 'summary',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToastTextField(
                          'summary',
                          'Professional Summary',
                          maxLines: 4,
                          required: true,
                          hint:
                              'Describe your professional background, key achievements, and career goals...',
                        ),
                        Builder(
                          builder: (context) {
                            final formState = BaseResumeForm.of(context);
                            if (formState == null) {
                              return const SizedBox.shrink();
                            }
                            return _buildSummaryToastSuggestions(
                              formState.controllerFor('summary'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Skills Toast Card
                  _toastFieldCard(
                    title: 'Skills & Expertise',
                    icon: Icons.handyman,
                    accentColor: const Color(0xFFE91E63),
                    isRequired: true,
                    delay: 2,
                    sectionKey: 'skills',
                    child: SkillsPickerField(
                      controller: state.controllerFor('skills'),
                      label: 'Add your skills',
                    ),
                  ),

                  // Work Experience Toast Card
                  _toastFieldCard(
                    title: 'Work Experience',
                    icon: Icons.work,
                    accentColor: const Color(0xFFFF9800),
                    isRequired: true,
                    delay: 3,
                    sectionKey: 'experience',
                    child: DynamicWorkExperienceSection(
                      workExperiences: _workExperiences,
                      onWorkExperiencesChanged: (experiences) {
                        setState(() {
                          _workExperiences = experiences;
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

                  // Education Toast Card
                  _toastFieldCard(
                    title: 'Education',
                    icon: Icons.school,
                    accentColor: const Color(0xFF4CAF50),
                    delay: 4,
                    sectionKey: 'education',
                    child: DynamicEducationSection(
                      educations: _educations,
                      onEducationsChanged: (educations) {
                        setState(() {
                          _educations = educations;
                          state.controllerFor('educations').text = jsonEncode(
                            educations.map((e) => e.toJson()).toList(),
                          );
                        });
                      },
                      atsFriendly: _atsFriendly,
                    ),
                  ),

                  // Certifications Toast Card
                  _toastFieldCard(
                    title: 'Certifications',
                    icon: Icons.workspace_premium,
                    accentColor: const Color(0xFFFF5722),
                    delay: 5,
                    sectionKey: 'certifications',
                    child: _buildToastTextField(
                      'certifications',
                      'Certifications',
                      maxLines: 3,
                      hint:
                          'List your professional certifications, licenses, or awards...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 32),

                  // Save button as toast-style
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.saveResume();
                        // Show toast-style success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Resume saved successfully!',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.white,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      label: const Text(
                        'Save Classic Resume',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
