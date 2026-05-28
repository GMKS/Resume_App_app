import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/resume_quality_service.dart';
import '../../../core/utils/resume_translations.dart';
import '../../../core/utils/validation_feedback.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const PersonalInfoScreen({
    super.key,
    required this.resumeId,
  });

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _jobTitleController;
  late TextEditingController _linkedInController;
  late TextEditingController _githubController;
  late TextEditingController _websiteController;

  bool _isInitialized = false;
  Uint8List? _pendingImageBytes; // holds newly picked photo before save
  final _imagePicker = ImagePicker();

  String _countryCode = '+91';

  static const _countryCodes = [
    ('+1', '🇺🇸 US/CA'),
    ('+44', '🇬🇧 UK'),
    ('+91', '🇮🇳 IN'),
    ('+61', '🇦🇺 AU'),
    ('+49', '🇩🇪 DE'),
    ('+33', '🇫🇷 FR'),
    ('+81', '🇯🇵 JP'),
    ('+86', '🇨🇳 CN'),
    ('+55', '🇧🇷 BR'),
    ('+971', '🇦🇪 AE'),
    ('+65', '🇸🇬 SG'),
    ('+60', '🇲🇾 MY'),
    ('+27', '🇿🇦 ZA'),
    ('+234', '🇳🇬 NG'),
    ('+966', '🇸🇦 SA'),
    ('+92', '🇵🇰 PK'),
    ('+94', '🇱🇰 LK'),
    ('+977', '🇳🇵 NP'),
    ('+880', '🇧🇩 BD'),
    ('+62', '🇮🇩 ID'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _jobTitleController = TextEditingController();
    _linkedInController = TextEditingController();
    _githubController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initializeControllers(ResumeModel resume) {
    if (!_isInitialized) {
      _nameController.text = resume.personalInfo.fullName;
      _emailController.text = resume.personalInfo.email;
      // Parse country code from stored phone
      final rawPhone = resume.personalInfo.phone;
      bool codeFound = false;
      // Sort by longest code first to avoid e.g. '+9' matching '+91'
      final sortedCodes = List.of(_countryCodes)
        ..sort((a, b) => b.$1.length.compareTo(a.$1.length));
      for (final cc in sortedCodes) {
        if (rawPhone.startsWith(cc.$1)) {
          _countryCode = cc.$1;
          _phoneController.text = rawPhone.substring(cc.$1.length).trimLeft();
          codeFound = true;
          break;
        }
      }
      if (!codeFound) {
        _phoneController.text = rawPhone;
      }
      _addressController.text = resume.personalInfo.address;
      _jobTitleController.text = resume.personalInfo.jobTitle ?? '';
      _linkedInController.text = resume.personalInfo.linkedIn ?? '';
      _githubController.text = resume.personalInfo.github ?? '';
      _websiteController.text = resume.personalInfo.website ?? '';
      // Pre-fill pending image from saved base64 if any
      if (_pendingImageBytes == null &&
          resume.personalInfo.profileImage?.isNotEmpty == true) {
        try {
          _pendingImageBytes = base64Decode(resume.personalInfo.profileImage!);
        } catch (_) {}
      }
      _isInitialized = true;
    }
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (!FreePlanService.canUploadPhoto) {
      showUpgradePromptSheet(
        context,
        featureName: 'media_support',
        message: FreePlanService.premiumPhotoMessage,
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _pendingImageBytes = bytes);
  }

  void _showImageSourceSheet() {
    if (!FreePlanService.canUploadPhoto) {
      showUpgradePromptSheet(
        context,
        featureName: 'media_support',
        message: FreePlanService.premiumPhotoMessage,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Choose Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Iconsax.camera, color: Colors.white, size: 20),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Iconsax.gallery, color: Colors.white, size: 20),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pendingImageBytes != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Iconsax.trash, color: Colors.white, size: 20),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _pendingImageBytes = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Template helpers ──────────────────────────────────────────────────────

  /// Templates where a profile photo is rendered in the PDF output
  bool _isPhotoTemplate(String templateId) => const {
        'blue_gray',
        'two_column',
        'emerald_executive',
        'vertical_timeline',
        'corporate_template',
        'slate_arc',
        'editorial_frame',
        'graphite_column',
        'rosewood_panel',
        'designer_profile',
        'modern_edge',
        'minimal_clean',
        'minimal_clean_ats',
        'professional_tone',
        'elegant_design',
        'creative_professional',
        'bluewave_tech',
        'balanced_two_column_layout',
        'elegant_gold_layout',
        'corporate_navy',
      }.contains(templateId);

  /// Templates that highlight GitHub / dev-profile links
  bool _isDeveloperTemplate(String templateId) =>
      const {'developer', 'startup'}.contains(templateId);

  void _saveChanges() {
    final missingFields = <String>[];
    if (_nameController.text.trim().isEmpty) {
      missingFields.add('Full Name');
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmailFormat(email)) {
      missingFields.add('Email');
    }

    if (missingFields.isNotEmpty) {
      showMissingFieldsSnackBar(context, missingFields);
      _formKey.currentState?.validate();
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final resume = ref.read(currentResumeProvider(widget.resumeId));
      if (resume != null) {
        // Encode newly picked photo as base64, or keep existing stored value
        final String? imageBase64 = _pendingImageBytes != null
            ? base64Encode(_pendingImageBytes!)
            : (resume.personalInfo.profileImage?.isNotEmpty == true
                ? resume.personalInfo.profileImage
                : null);
        final updatedResume = resume.copyWith(
          personalInfo: PersonalInfo(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone:
                '${_countryCode.trim()} ${_phoneController.text.trim()}'.trim(),
            address: _addressController.text.trim(),
            jobTitle: _jobTitleController.text.trim(),
            linkedIn: _linkedInController.text.trim(),
            github: _githubController.text.trim(),
            website: _websiteController.text.trim(),
            profileImage: imageBase64,
            dateOfBirth: resume.personalInfo.dateOfBirth,
          ),
        );
        ref
            .read(currentResumeProvider(widget.resumeId).notifier)
            .updateResume(updatedResume);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Personal information saved'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        context.pop();
      }
    }
  }

  ResumeModel _buildDraftResume(ResumeModel resume) {
    return resume.copyWith(
      personalInfo: resume.personalInfo.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '${_countryCode.trim()} ${_phoneController.text.trim()}'.trim(),
        address: _addressController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        linkedIn: _linkedInController.text.trim(),
        github: _githubController.text.trim(),
        website: _websiteController.text.trim(),
        profileImage: _pendingImageBytes != null
            ? 'draft-profile-image'
            : resume.personalInfo.profileImage,
      ),
    );
  }

  bool _isValidEmailFormat(String value) {
    if (value.isEmpty || !value.contains('@')) {
      return false;
    }
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value);
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildChecklistTile({
    required bool isReady,
    required String title,
    required String subtitle,
  }) {
    final color = isReady ? AppColors.success : AppColors.warning;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isReady ? Iconsax.tick_circle : Iconsax.info_circle,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _initializeControllers(resume);
    final draftResume = _buildDraftResume(resume);
    final qualityReport = ResumeQualityService.analyzeResume(draftResume);
    final contactChannels = [
      draftResume.personalInfo.email,
      draftResume.personalInfo.phone,
      draftResume.personalInfo.linkedIn,
      draftResume.personalInfo.github,
      draftResume.personalInfo.website,
    ].where((value) => (value ?? '').trim().isNotEmpty).length;
    final digitalProfiles = [
      draftResume.personalInfo.linkedIn,
      draftResume.personalInfo.github,
      draftResume.personalInfo.website,
    ].where((value) => (value ?? '').trim().isNotEmpty).length;
    final hasPhoto = draftResume.personalInfo.profileImage?.isNotEmpty == true;
    final emailValid = _isValidEmailFormat(draftResume.personalInfo.email);
    final hasJobTitle =
        (draftResume.personalInfo.jobTitle ?? '').trim().isNotEmpty;
    final hasLocation = draftResume.personalInfo.address.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Personal Information'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EditorIntroCard(
              title: 'Identity & Reachability',
              subtitle:
                  'Shape the personal block that appears across resume templates, exports, and imported edits. The guidance below reflects your in-progress typing before you save.',
              icon: Iconsax.profile_circle,
              accentColor: const Color(0xFF0F766E),
              stats: [
                EditorIntroStat(
                  label: '$contactChannels contact channels',
                  icon: Iconsax.sms,
                ),
                EditorIntroStat(
                  label: '$digitalProfiles live links',
                  icon: Iconsax.global,
                ),
                EditorIntroStat(
                  label: hasPhoto ? 'photo ready' : 'photo optional',
                  icon: Iconsax.camera,
                ),
              ],
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            ResumeQualityPanel(
              report: qualityReport,
              title: 'Live Resume Guidance',
              subtitle:
                  'Your personal details affect resume quality, ATS readiness, and the polish of shared exports. Save when this looks right.',
              accentColor: const Color(0xFF0F766E),
              maxSuggestions: 2,
            ).animate().fadeIn(delay: 60.ms),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Readiness',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      EditorStatPill(
                        label: emailValid
                            ? 'email verified'
                            : 'email needs review',
                        icon: Iconsax.sms,
                        color:
                            emailValid ? AppColors.success : AppColors.warning,
                      ),
                      EditorStatPill(
                        label: hasJobTitle
                            ? 'role headline added'
                            : 'role headline missing',
                        icon: Iconsax.briefcase,
                        color:
                            hasJobTitle ? AppColors.success : AppColors.warning,
                      ),
                      EditorStatPill(
                        label: hasLocation
                            ? 'location included'
                            : 'location optional',
                        icon: Iconsax.location,
                        color: hasLocation ? AppColors.success : AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildChecklistTile(
                    isReady: emailValid,
                    title: 'Professional email',
                    subtitle:
                        'A valid email is required in most templates and makes exported resumes look trustworthy.',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistTile(
                    isReady: digitalProfiles > 0,
                    title: 'Digital presence',
                    subtitle:
                        'Add LinkedIn, GitHub, or a portfolio so global recruiters can verify your work quickly.',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistTile(
                    isReady: !_isPhotoTemplate(resume.templateId) || hasPhoto,
                    title: _isPhotoTemplate(resume.templateId)
                        ? 'Photo-enabled template'
                        : 'Text-first template',
                    subtitle: _isPhotoTemplate(resume.templateId)
                        ? 'This selected template can display a profile photo. Add one if you want the preview to feel more complete.'
                        : 'Your current template relies on text hierarchy, so strong contact details matter more than a portrait.',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Photo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Useful for templates that surface a headshot. The actual save flow is unchanged, so your preview updates after you save.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  if (_isPhotoTemplate(resume.templateId)) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.camera,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This template shows your profile photo in the PDF. Add a photo below for the best result.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                                if (!FreePlanService.canUploadPhoto) ...[
                                  const SizedBox(height: 8),
                                  const PremiumBadge(
                                    locked: true,
                                    label: 'PHOTO',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 3,
                              ),
                            ),
                            child: _pendingImageBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _pendingImageBytes!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  )
                                : Icon(
                                    Iconsax.user,
                                    size: 50,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.5),
                                  ),
                          ),
                        ),
                        if (!FreePlanService.canUploadPhoto)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: PremiumBadge(
                                    locked: true,
                                    label: 'PHOTO',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: Icon(
                                FreePlanService.canUploadPhoto
                                    ? Iconsax.camera
                                    : Iconsax.lock_1,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms).scale(
                  duration: 320.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 20),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Keep this block precise. These fields anchor the header seen in the preview, shared exports, and template switching flow.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _nameController,
                    label: ResumeTranslations.getFieldLabel(
                        ResumeTranslations.kFullName, resume.writingLanguage),
                    hint: 'John Doe',
                    prefixIcon: Iconsax.user,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
                  CustomTextField(
                    controller: _jobTitleController,
                    label: ResumeTranslations.getFieldLabel(
                        ResumeTranslations.kJobTitle, resume.writingLanguage),
                    hint: 'Software Engineer',
                    prefixIcon: Iconsax.briefcase,
                    onChanged: (_) => setState(() {}),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                  CustomTextField(
                    controller: _emailController,
                    label: ResumeTranslations.getFieldLabel(
                        ResumeTranslations.kEmail, resume.writingLanguage),
                    hint: 'john.doe@email.com',
                    prefixIcon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!value!.contains('@')) {
                        return 'Email must contain @ symbol (e.g., name@domain.com)';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email format (e.g., name@domain.com)';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1, end: 0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ResumeTranslations.getFieldLabel(
                              ResumeTranslations.kPhone,
                              resume.writingLanguage),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _countryCode,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  items: _countryCodes
                                      .map(
                                        (cc) => DropdownMenuItem(
                                          value: cc.$1,
                                          child: Text('${cc.$2}  ${cc.$1}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _countryCode = value ?? _countryCode,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) => setState(() {}),
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: '9916750642',
                                  prefixIcon: const Icon(
                                    Iconsax.call,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'City, Country',
                    prefixIcon: Iconsax.location,
                    onChanged: (_) => setState(() {}),
                  ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Social Links',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      if (_isDeveloperTemplate(resume.templateId)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GitHub featured in PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Use these links to localize your resume for technical, creative, and international applications without changing the saved data model.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_isDeveloperTemplate(resume.templateId)) ...[
                    CustomTextField(
                      controller: _githubController,
                      label: 'GitHub  ★',
                      hint: 'github.com/johndoe',
                      prefixIcon: Iconsax.code,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    )
                        .animate()
                        .fadeIn(delay: 440.ms)
                        .slideX(begin: 0.1, end: 0),
                    CustomTextField(
                      controller: _linkedInController,
                      label: 'LinkedIn',
                      hint: 'linkedin.com/in/johndoe',
                      prefixIcon: Iconsax.link,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    )
                        .animate()
                        .fadeIn(delay: 470.ms)
                        .slideX(begin: 0.1, end: 0),
                  ] else ...[
                    CustomTextField(
                      controller: _linkedInController,
                      label: 'LinkedIn',
                      hint: 'linkedin.com/in/johndoe',
                      prefixIcon: Iconsax.link,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms)
                        .slideX(begin: 0.1, end: 0),
                    CustomTextField(
                      controller: _githubController,
                      label: 'GitHub',
                      hint: 'github.com/johndoe',
                      prefixIcon: Iconsax.code,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideX(begin: 0.1, end: 0),
                  ],
                  CustomTextField(
                    controller: _websiteController,
                    label: 'Website / Portfolio',
                    hint: 'www.johndoe.com',
                    prefixIcon: Iconsax.global,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.1, end: 0),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Information'),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
