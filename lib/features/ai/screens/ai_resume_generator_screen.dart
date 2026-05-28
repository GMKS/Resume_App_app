import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/skill_suggestions_service.dart';

class AIResumeGeneratorScreen extends ConsumerStatefulWidget {
  const AIResumeGeneratorScreen({super.key});

  @override
  ConsumerState<AIResumeGeneratorScreen> createState() =>
      _AIResumeGeneratorScreenState();
}

class _AIResumeGeneratorScreenState
    extends ConsumerState<AIResumeGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _industryController = TextEditingController();

  String _selectedRole = 'Software Engineer';
  String _experience = '0–2 years';
  bool _isGenerating = false;
  int _currentStep = 0;

  final List<String> _experienceLevels = [
    '0–2 years',
    '3–5 years',
    '6–10 years',
    '10+ years',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  // ── Generate resume content ────────────────────────────────────────────────

  Future<void> _generateResume() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    // Simulate brief "generating" delay for UX feel
    await Future.delayed(const Duration(milliseconds: 1200));

    final role = _selectedRole;
    final expLevel = _experience;
    final skills = SkillSuggestionsService.getSkillsForRole(role);
    final topSkills = skills.take(8).toList();
    final id = const Uuid().v4();

    final objective = _buildObjective(role, expLevel);
    final experiences = _buildExperience(role, expLevel);
    final skillList = topSkills
        .asMap()
        .entries
        .map((e) => Skill(
              id: const Uuid().v4(),
              name: e.value,
              proficiency: 3 + (e.key < 3 ? 1 : 0), // top 3 get proficiency 4
              category: e.key < 5 ? 'Technical' : 'Soft Skills',
            ))
        .toList();

    final resume = ResumeModel(
      id: id,
      title:
          '${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "My"} – $role Resume',
      personalInfo: PersonalInfo(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isNotEmpty
            ? _jobTitleController.text.trim()
            : role,
        address: '',
      ),
      objective: objective,
      education: [
        Education(
          id: const Uuid().v4(),
          institution: 'Your University / College',
          degree: _degreeForRole(role),
          fieldOfStudy: _fieldForRole(role),
          startDate: DateTime(2016),
          endDate: DateTime(2020),
          description: 'Edit to add your GPA, honors, and relevant coursework.',
        ),
      ],
      experience: experiences,
      skills: skillList,
      projects: [],
      certifications: [],
      languages: [
        Language(
          id: const Uuid().v4(),
          name: 'English',
          proficiency: 'Fluent',
        ),
      ],
      hobbies: [],
      references: [],
      templateId: 'modern',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveResume(resume);

    if (!mounted) return;

    setState(() => _isGenerating = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        margin: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        duration: const Duration(seconds: 3),
        content: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Resume generated! Review and customize it.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.go('/editor/$id');
  }

  // ── Content builders ───────────────────────────────────────────────────────

  String _buildObjective(String role, String exp) {
    final level = _expLabel(exp);
    return '$level $role with a track record of delivering high-quality solutions. '
        'Passionate about ${_industryController.text.trim().isNotEmpty ? _industryController.text.trim() : "technology"} '
        'and committed to continuous improvement. '
        'Seeking a challenging $role position where I can leverage my skills to drive meaningful impact.';
  }

  String _expLabel(String exp) {
    switch (exp) {
      case '0–2 years':
        return 'Motivated junior';
      case '3–5 years':
        return 'Experienced mid-level';
      case '6–10 years':
        return 'Senior';
      case '10+ years':
        return 'Principal/Lead';
      default:
        return 'Experienced';
    }
  }

  List<Experience> _buildExperience(String role, String exp) {
    if (exp == '0–2 years') {
      return [
        Experience(
          id: const Uuid().v4(),
          company: 'Company Name',
          position: role,
          startDate: DateTime(2023),
          isCurrentlyWorking: true,
          description: _bulletPoints(role, junior: true),
          location: 'City, Country',
        ),
      ];
    }
    return [
      Experience(
        id: const Uuid().v4(),
        company: 'Most Recent Company',
        position: 'Senior $role',
        startDate: DateTime(2021),
        isCurrentlyWorking: true,
        description: _bulletPoints(role, junior: false),
        location: 'City, Country',
      ),
      Experience(
        id: const Uuid().v4(),
        company: 'Previous Company',
        position: role,
        startDate: DateTime(2018),
        endDate: DateTime(2021),
        isCurrentlyWorking: false,
        description: _bulletPoints(role, junior: true),
        location: 'City, Country',
      ),
    ];
  }

  String _bulletPoints(String role, {required bool junior}) {
    final Map<String, List<String>> bullets = {
      'Software Engineer': [
        '• Designed and implemented scalable microservices that improved system throughput by 40%.',
        '• Reduced bug rate by 30% by introducing automated unit and integration testing.',
        '• Collaborated with cross-functional teams to deliver features on time in an Agile environment.',
        '• Mentored junior developers and conducted thorough code reviews.',
      ],
      'Frontend Developer': [
        '• Built responsive, accessible UI components increasing user retention by 25%.',
        '• Reduced page load time by 35% through lazy loading and code splitting.',
        '• Collaborated with designers to translate Figma mockups into pixel-perfect interfaces.',
        '• Implemented A/B tests that led to a 15% lift in conversion rate.',
      ],
      'Data Scientist': [
        '• Developed ML models achieving 92% accuracy in predicting customer churn.',
        '• Processed and analyzed datasets of 10M+ records using Python and Spark.',
        '• Built interactive dashboards with Tableau that reduced reporting time by 50%.',
        '• Published reproducible research notebooks used across data teams.',
      ],
      'Product Manager': [
        '• Defined and owned roadmap for a product serving 500K+ monthly active users.',
        '• Led cross-functional team of 12 to ship 3 major features ahead of schedule.',
        '• Reduced backlog debt by 40% through improved sprint planning and prioritization.',
        '• Increased NPS score from 32 to 54 by driving customer-centric feature decisions.',
      ],
      'UI/UX Designer': [
        '• Redesigned onboarding flow, reducing drop-off by 35% in user testing.',
        '• Built and maintained a design system adopted by 4 engineering squads.',
        '• Conducted 20+ moderated usability studies and synthesized actionable insights.',
        '• Delivered high-fidelity prototypes and design specs for mobile and web.',
      ],
    };

    final items = bullets[role] ??
        [
          '• Led key initiatives that improved team efficiency by 20%.',
          '• Delivered projects on time within budget and scope.',
          '• Collaborated with stakeholders across departments.',
          '• Mentored peers and contributed to knowledge-sharing sessions.',
        ];

    return junior ? items.take(3).join('\n') : items.join('\n');
  }

  String _degreeForRole(String role) {
    if ([
      'Software Engineer',
      'Frontend Developer',
      'Backend Developer',
      'Mobile Developer',
      'Full Stack Developer',
      'DevOps Engineer',
      'Cloud Architect',
      'QA Engineer',
      'Cybersecurity Analyst'
    ].contains(role)) {
      return "Bachelor's Degree";
    }
    if (['Data Scientist', 'Data Analyst'].contains(role)) {
      return "Bachelor's / Master's Degree";
    }
    return "Bachelor's Degree";
  }

  String _fieldForRole(String role) {
    if ([
      'Software Engineer',
      'Frontend Developer',
      'Backend Developer',
      'Mobile Developer',
      'Full Stack Developer'
    ].contains(role)) {
      return 'Computer Science / Software Engineering';
    }
    if (['Data Scientist', 'Data Analyst'].contains(role)) {
      return 'Computer Science / Statistics / Data Science';
    }
    if (['UI/UX Designer', 'Graphic Designer'].contains(role)) {
      return 'Design / Fine Arts / HCI';
    }
    if (['Marketing Manager', 'Content Writer'].contains(role)) {
      return 'Marketing / Communications';
    }
    return 'Relevant Field of Study';
  }

  // ── Stepper pages ──────────────────────────────────────────────────────────

  Widget _step0PersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Iconsax.user, 'Your Identity', AppColors.primary),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration('Full Name', Iconsax.user),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Name required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          decoration: _inputDecoration('Email Address', Iconsax.sms),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration('Phone Number', Iconsax.call),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _step1RoleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            Iconsax.briefcase, 'Role & Experience', AppColors.secondary),
        const SizedBox(height: 20),
        // Role dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: _inputDecoration('Target Role', Iconsax.briefcase),
          isExpanded: true,
          items: SkillSuggestionsService.allRoles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _jobTitleController,
          decoration:
              _inputDecoration('Custom Job Title (optional)', Iconsax.edit_2),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _industryController,
          decoration:
              _inputDecoration('Industry / Company Type', Iconsax.building_4),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        // Experience level chips
        Text('Years of Experience',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _experienceLevels
              .map((e) => ChoiceChip(
                    label: Text(e),
                    selected: _experience == e,
                    onSelected: (s) => setState(() => _experience = e),
                    selectedColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: _experience == e
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _step2Preview() {
    final role = _selectedRole;
    final skills =
        SkillSuggestionsService.getSkillsForRole(role).take(6).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const skillAccent = Color(0xFF7C3AED);
    final skillCardColor = isDark
        ? skillAccent.withValues(alpha: 0.18)
        : skillAccent.withValues(alpha: 0.09);
    final skillBorderColor = isDark
        ? skillAccent.withValues(alpha: 0.34)
        : skillAccent.withValues(alpha: 0.18);
    final skillTextColor = isDark ? Colors.white : const Color(0xFF5B21B6);
    final skillChipColor =
        isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE);
    final skillChipTextColor = isDark ? Colors.white : const Color(0xFF4C1D95);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Iconsax.eye, 'Preview', const Color(0xFF8B5CF6)),
        const SizedBox(height: 20),
        _previewRow(
            'Name',
            _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : '—'),
        _previewRow(
            'Email',
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : '—'),
        _previewRow('Role', role),
        _previewRow('Experience', _experience),
        _previewRow(
            'Industry',
            _industryController.text.trim().isNotEmpty
                ? _industryController.text.trim()
                : 'Technology'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: skillCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: skillBorderColor),
            boxShadow: [
              BoxShadow(
                color: skillAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.lamp_charge, size: 16, color: skillTextColor),
                  const SizedBox(width: 8),
                  Text('Suggested Skills',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700, color: skillTextColor)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((s) => Chip(
                          label: Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: skillChipTextColor,
                            ),
                          ),
                          avatar: Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: skillChipTextColor,
                          ),
                          backgroundColor: skillChipColor,
                          side: BorderSide(
                            color: skillBorderColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1.5,
                          shadowColor: skillAccent.withValues(alpha: 0.12),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.information, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The AI-generated resume will be pre-filled with smart content. '
                  'Review and edit every section in the resume editor before you use it.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = [
      _step0PersonalInfo(),
      _step1RoleInfo(),
      _step2Preview(),
    ];

    final stepTitles = ['Personal Info', 'Role & Experience', 'Preview'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('AI Resume Generator'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step ${_currentStep + 1} of ${steps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: i ~/ 2 < _currentStep
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    );
                  }
                  final step = i ~/ 2;
                  final isActive = step == _currentStep;
                  final isDone = step < _currentStep;
                  return AnimatedContainer(
                    duration: 250.ms,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success
                          : isActive
                              ? AppColors.primary
                              : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      color: (isDone || isActive)
                          ? Colors.white
                          : AppColors.border,
                      size: isDone ? 18 : 10,
                    ),
                  );
                }),
              ),
            ),

            // Step subtitle
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                stepTitles[_currentStep],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: 300.ms,
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: steps[_currentStep],
                  ),
                ),
              ),
            ),

            // Bottom navigation
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _currentStep--),
                          icon: const Icon(Iconsax.arrow_left),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating
                            ? null
                            : () {
                                if (_currentStep < steps.length - 1) {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _currentStep++);
                                  }
                                } else {
                                  _generateResume();
                                }
                              },
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_currentStep < steps.length - 1
                                ? Iconsax.arrow_right_3
                                : Iconsax.magic_star),
                        label: Text(
                          _isGenerating
                              ? 'Generating…'
                              : _currentStep < steps.length - 1
                                  ? 'Next'
                                  : 'Generate Resume',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
