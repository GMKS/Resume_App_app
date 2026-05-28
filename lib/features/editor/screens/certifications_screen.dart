import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/services/free_plan_service.dart';
import '../../../core/services/resume_quality_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/utils/validation_feedback.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/app_empty_state_card.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class CertificationsScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const CertificationsScreen({super.key, required this.resumeId});

  @override
  ConsumerState<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen> {
  void _showCertDialog(Certification? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CertForm(resumeId: widget.resumeId, existing: existing),
    );
  }

  void _deleteCert(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updated = resume.certifications.where((c) => c.id != id).toList();
      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(resume.copyWith(certifications: updated));
    }
  }

  Widget _buildScreenHeader(
    BuildContext context,
    ResumeModel resume,
    ResumeQualityReport qualityReport,
  ) {
    final withLinks = resume.certifications
        .where((cert) => (cert.credentialUrl ?? '').trim().isNotEmpty)
        .length;
    final withExpiry =
        resume.certifications.where((cert) => cert.expiryDate != null).length;

    return Column(
      children: [
        EditorIntroCard(
          title: 'Verification & Trust Signals',
          subtitle:
              'Certifications add proof points that sit alongside your skills and experience. Keep issuer, dates, and links clean so exported resumes stay credible.',
          icon: Iconsax.medal_star,
          accentColor: const Color(0xFF14B8A6),
          stats: [
            EditorIntroStat(
              label: '${resume.certifications.length} certs',
              icon: Iconsax.medal_star,
            ),
            EditorIntroStat(
              label: '$withLinks linked',
              icon: Iconsax.link,
            ),
            EditorIntroStat(
              label: '$withExpiry with expiry',
              icon: Iconsax.calendar,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResumeQualityPanel(
          report: qualityReport,
          title: 'Certification Guidance',
          subtitle:
              'This section strengthens preview output when the credentials are named clearly and supported with date or verification metadata.',
          accentColor: const Color(0xFF14B8A6),
          maxSuggestions: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FreePlanService.canEditSection('certifications')) {
      return const Scaffold(
        body: SafeArea(
          child: UpgradePromptCard(
            featureName: 'premium_sections',
            message: 'Premium feature. Upgrade to edit this section.',
          ),
        ),
      );
    }

    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Loading certifications',
          message: 'Preparing your credential list.',
        ),
      );
    }
    final qualityReport = ResumeQualityService.analyzeResume(resume);

    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveTooltip(
          message: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
        ),
        title: const Text('Certifications'),
      ),
      body: resume.certifications.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildScreenHeader(context, resume, qualityReport),
                const SizedBox(height: 20),
                _buildEmptyState(),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: resume.certifications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildScreenHeader(context, resume, qualityReport),
                  );
                }

                final cert = resume.certifications[index - 1];
                return _CertCard(
                  cert: cert,
                  onEdit: () => _showCertDialog(cert),
                  onDelete: () => _deleteCert(cert.id),
                )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _showCertDialog(null),
            icon: const Icon(Iconsax.add),
            label: const Text(
              'Add Certification',
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyStateCard(
      icon: Iconsax.medal_star,
      accentColor: Color(0xFF14B8A6),
      title: 'No Certifications Added',
      message:
          'Add certifications with issuer and date details so they survive every template and export path.',
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _CertCard extends StatelessWidget {
  final Certification cert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CertCard(
      {required this.cert, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasLink = (cert.credentialUrl ?? '').trim().isNotEmpty;
    final hasId = (cert.credentialId ?? '').trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.medal_star, color: Color(0xFF14B8A6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EditorStatPill(
                      label: cert.issueDate != null
                          ? 'dated credential'
                          : 'date optional',
                      icon: Iconsax.calendar,
                      color: cert.issueDate != null
                          ? AppColors.success
                          : AppColors.info,
                    ),
                    if (hasId)
                      const EditorStatPill(
                        label: 'credential id',
                        icon: Iconsax.tag,
                        color: Color(0xFF14B8A6),
                      ),
                    if (hasLink)
                      const EditorStatPill(
                        label: 'verification link',
                        icon: Iconsax.link,
                        color: Color(0xFF0EA5E9),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(cert.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(cert.issuer,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                if (cert.issueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.calendar,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Issued ${DateFormat('MMM yyyy').format(cert.issueDate!)}${cert.expiryDate != null ? ' • Expires ${DateFormat('MMM yyyy').format(cert.expiryDate!)}' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (cert.credentialId?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text('ID: ${cert.credentialId}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          Semantics(
            label: 'Certification actions',
            button: true,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Iconsax.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit')
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Iconsax.trash, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error))
                    ])),
              ],
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertForm extends ConsumerStatefulWidget {
  final String resumeId;
  final Certification? existing;

  const _CertForm({required this.resumeId, this.existing});

  @override
  ConsumerState<_CertForm> createState() => _CertFormState();
}

class _CertFormState extends ConsumerState<_CertForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _issuerController;
  late TextEditingController _credIdController;
  late TextEditingController _urlController;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _issuerController =
        TextEditingController(text: widget.existing?.issuer ?? '');
    _credIdController =
        TextEditingController(text: widget.existing?.credentialId ?? '');
    _urlController =
        TextEditingController(text: widget.existing?.credentialUrl ?? '');
    _issueDate = widget.existing?.issueDate;
    _expiryDate = widget.existing?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _credIdController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _selectDate(bool isIssue) async {
    final initialDate = isIssue
        ? (_issueDate ?? DateTime.now())
        : (_expiryDate ?? _issueDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isIssue ? DateTime(1990) : (_issueDate ?? DateTime(1990)),
      lastDate: isIssue ? (_expiryDate ?? DateTime(2100)) : DateTime(2100),
    );
    if (date == null) return;

    if (isIssue) {
      final shouldClearExpiry =
          _expiryDate != null && _expiryDate!.isBefore(date);
      setState(() {
        _issueDate = date;
        if (shouldClearExpiry) {
          _expiryDate = null;
        }
      });

      if (shouldClearExpiry && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Expiry date was cleared because it cannot be earlier than the issue date.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _expiryDate = date);
  }

  ResumeModel _buildDraftResume(ResumeModel resume) {
    final hasDraftInput = _nameController.text.trim().isNotEmpty ||
        _issuerController.text.trim().isNotEmpty ||
        _credIdController.text.trim().isNotEmpty ||
        _urlController.text.trim().isNotEmpty ||
        _issueDate != null ||
        _expiryDate != null;

    if (!hasDraftInput) {
      return resume;
    }

    final draftCertification = Certification(
      id: widget.existing?.id ?? 'draft-certification',
      name: _nameController.text.trim(),
      issuer: _issuerController.text.trim(),
      credentialId: _credIdController.text.trim(),
      credentialUrl: _urlController.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
    );

    final updatedCertifications = widget.existing != null
        ? resume.certifications
            .map((item) =>
                item.id == draftCertification.id ? draftCertification : item)
            .toList()
        : [...resume.certifications, draftCertification];

    return resume.copyWith(certifications: updatedCertifications);
  }

  String? _liveGuidanceMessage() {
    if (_nameController.text.trim().isEmpty) {
      return 'Add the certification name so this proof point is recognizable in preview output.';
    }
    if (_issuerController.text.trim().isEmpty) {
      return 'Add the issuing organization to make the credential trustworthy.';
    }
    if (_issueDate != null &&
        _expiryDate != null &&
        _expiryDate!.isBefore(_issueDate!)) {
      return 'Expiry date must stay after the issue date so exported certification timelines remain consistent.';
    }
    if (_urlController.text.trim().isEmpty &&
        _credIdController.text.trim().isEmpty) {
      return 'Add a credential URL or ID when possible so recruiters can verify this certification quickly.';
    }
    return null;
  }

  void _save() {
    final missingFields = <String>[];
    if (_nameController.text.trim().isEmpty) {
      missingFields.add('Certification Name');
    }
    if (_issuerController.text.trim().isEmpty) {
      missingFields.add('Issuing Organization');
    }

    if (missingFields.isNotEmpty) {
      showMissingFieldsSnackBar(context, missingFields);
      _formKey.currentState?.validate();
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_issueDate != null &&
          _expiryDate != null &&
          _expiryDate!.isBefore(_issueDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiry date cannot be earlier than the issue date.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final resume = ref.read(currentResumeProvider(widget.resumeId));
      if (resume == null) return;

      final cert = Certification(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        credentialId: _credIdController.text.trim(),
        credentialUrl: _urlController.text.trim(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
      );

      List<Certification> updated;
      if (widget.existing != null) {
        updated = resume.certifications
            .map((c) => c.id == cert.id ? cert : c)
            .toList();
      } else {
        updated = [...resume.certifications, cert];
      }

      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(resume.copyWith(certifications: updated));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.viewPadding.bottom;
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    final qualityReport = resume == null
        ? null
        : ResumeQualityService.analyzeResume(_buildDraftResume(resume));
    final liveGuidanceMessage = _liveGuidanceMessage();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    widget.existing != null
                        ? 'Edit Certification'
                        : 'Add Certification',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AdaptiveTooltip(
                  message: 'Close certification form',
                  button: true,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  EditorIntroCard(
                    title: widget.existing != null
                        ? 'Refine certification proof'
                        : 'Add a verified credential',
                    subtitle:
                        'Use issuer, date, and verification details to make this credential durable across templates and exports.',
                    icon: Iconsax.medal_star,
                    accentColor: const Color(0xFF14B8A6),
                    stats: [
                      EditorIntroStat(
                        label: _issueDate != null ? 'dated' : 'date optional',
                        icon: Iconsax.calendar,
                      ),
                      EditorIntroStat(
                        label: _urlController.text.trim().isNotEmpty
                            ? 'link included'
                            : 'add link or id',
                        icon: Iconsax.link,
                      ),
                    ],
                  ),
                  if (qualityReport != null) ...[
                    const SizedBox(height: 16),
                    ResumeQualityPanel(
                      report: qualityReport,
                      title: 'Draft Certification Guidance',
                      subtitle:
                          'This score updates from your in-progress certification details before save.',
                      accentColor: const Color(0xFF14B8A6),
                      maxSuggestions: 2,
                    ),
                  ],
                  if (liveGuidanceMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Iconsax.info_circle,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              liveGuidanceMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CustomTextField(
                      controller: _nameController,
                      label: 'Certification Name',
                      hint: 'AWS Solutions Architect',
                      prefixIcon: Iconsax.medal_star,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                  CustomTextField(
                      controller: _issuerController,
                      label: 'Issuing Organization',
                      hint: 'Amazon Web Services',
                      prefixIcon: Iconsax.building,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                  CustomTextField(
                      controller: _credIdController,
                      label: 'Credential ID',
                      hint: 'ABC123XYZ',
                      prefixIcon: Iconsax.tag,
                      onChanged: (_) => setState(() {})),
                  CustomTextField(
                      controller: _urlController,
                      label: 'Credential URL',
                      hint: 'https://...',
                      prefixIcon: Iconsax.link,
                      onChanged: (_) => setState(() {})),
                  Row(
                    children: [
                      Expanded(
                          child: _DateField(
                              label: 'Issue Date',
                              date: _issueDate,
                              onTap: () => _selectDate(true))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _DateField(
                              label: 'Expiry Date',
                              date: _expiryDate,
                              onTap: () => _selectDate(false))),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              bottomInset + safeBottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  widget.existing != null
                      ? 'Update Certification'
                      : 'Add Certification',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Iconsax.calendar,
                    size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(
                    date != null
                        ? DateFormat('MMM yyyy').format(date!)
                        : 'Select',
                    style: TextStyle(
                        color: date != null ? null : AppColors.textTertiary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
