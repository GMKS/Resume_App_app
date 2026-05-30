import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/services/resume_quality_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/utils/validation_feedback.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/app_empty_state_card.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../utils/date_range_utils.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class EducationScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const EducationScreen({super.key, required this.resumeId});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  void _addEducation() {
    _showEducationDialog(null);
  }

  void _editEducation(Education education) {
    _showEducationDialog(education);
  }

  void _deleteEducation(String educationId) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updatedEducation =
          resume.education.where((e) => e.id != educationId).toList();
      final updatedResume = resume.copyWith(education: updatedEducation);
      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(updatedResume);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Education removed'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showEducationDialog(Education? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EducationForm(
        resumeId: widget.resumeId,
        existing: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Loading education',
          message: 'Preparing your education details.',
        ),
      );
    }
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
        title: const Text('Education'),
      ),
      body: resume.education.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildEmptyState(),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: resume.education.length,
              itemBuilder: (context, index) {
                final education = resume.education[index];
                return _EducationCard(
                  education: education,
                  onEdit: () => _editEducation(education),
                  onDelete: () => _deleteEducation(education.id),
                )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Iconsax.add),
              label: const Text('Add Education'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyStateCard(
      icon: Iconsax.teacher,
      accentColor: Color(0xFF0EA5E9),
      title: 'No Education Added',
      message:
          'Add degrees, institutions, and dates so your preview shows a complete learning timeline.',
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _EducationCard extends StatelessWidget {
  final Education education;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EducationCard({
    required this.education,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasGrade = (education.grade ?? '').trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.teacher, color: Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        education.degree,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        education.institution,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
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
                          Text('Delete',
                              style: TextStyle(color: AppColors.error))
                        ])),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (education.fieldOfStudy.trim().isNotEmpty)
                      EditorStatPill(
                        label: education.fieldOfStudy,
                        icon: Iconsax.book,
                        color: const Color(0xFF0EA5E9),
                      ),
                    EditorStatPill(
                      label: education.isCurrentlyStudying
                          ? 'currently studying'
                          : 'completed entry',
                      icon: education.isCurrentlyStudying
                          ? Iconsax.clock
                          : Iconsax.tick_circle,
                      color: education.isCurrentlyStudying
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    if (hasGrade)
                      EditorStatPill(
                        label: 'grade ${education.grade}',
                        icon: Iconsax.medal_star,
                        color: AppColors.info,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (education.fieldOfStudy.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Iconsax.book,
                          size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(education.fieldOfStudy,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Iconsax.calendar,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(education.startDate)} - ${education.isCurrentlyStudying ? 'Present' : education.endDate != null ? DateFormat('dd MMM yyyy').format(education.endDate!) : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (education.grade?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.medal_star,
                          size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text('Grade: ${education.grade}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationForm extends ConsumerStatefulWidget {
  final String resumeId;
  final Education? existing;

  const _EducationForm({required this.resumeId, this.existing});

  @override
  ConsumerState<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends ConsumerState<_EducationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _institutionController;
  late TextEditingController _degreeController;
  late TextEditingController _fieldController;
  late TextEditingController _gradeController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrently = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: widget.existing?.institution ?? '');
    _degreeController =
        TextEditingController(text: widget.existing?.degree ?? '');
    _fieldController =
        TextEditingController(text: widget.existing?.fieldOfStudy ?? '');
    _gradeController =
        TextEditingController(text: widget.existing?.grade ?? '');
    _startDate = widget.existing?.startDate;
    _endDate = widget.existing?.endDate;
    _isCurrently = widget.existing?.isCurrentlyStudying ?? false;
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: isStart ? DateTime(1950) : (_startDate ?? DateTime(1950)),
      lastDate: isStart ? (_endDate ?? DateTime.now()) : DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _validationMessage = null;
        if (isStart) {
          _startDate = date;
          // Clear end date if it is before the new start date
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  ResumeModel _buildDraftResume(ResumeModel resume) {
    final hasDraftInput = _institutionController.text.trim().isNotEmpty ||
        _degreeController.text.trim().isNotEmpty ||
        _fieldController.text.trim().isNotEmpty ||
        _gradeController.text.trim().isNotEmpty ||
        _startDate != null ||
        _endDate != null;

    if (!hasDraftInput) {
      return resume;
    }

    final draftEducation = Education(
      id: widget.existing?.id ?? 'draft-education',
      institution: _institutionController.text.trim(),
      degree: _degreeController.text.trim(),
      fieldOfStudy: _fieldController.text.trim(),
      grade: _gradeController.text.trim(),
      startDate: _startDate ?? DateTime.now(),
      endDate: _isCurrently ? null : _endDate,
      isCurrentlyStudying: _isCurrently,
    );

    final updatedEducation = widget.existing != null
        ? resume.education
            .map((item) => item.id == draftEducation.id ? draftEducation : item)
            .toList()
        : [...resume.education, draftEducation];

    return resume.copyWith(education: updatedEducation);
  }

  String? _liveGuidanceMessage() {
    if (_institutionController.text.trim().isEmpty) {
      return 'Add the institution name so this credential is recognizable in preview output.';
    }
    if (_degreeController.text.trim().isEmpty) {
      return 'Add the degree or program name to explain what this education entry represents.';
    }
    if (_startDate == null) {
      return 'Select a start date to keep your education timeline consistent.';
    }
    if (_endDate == null && !_isCurrently) {
      return 'Add an end date or mark this entry as current so exported timelines stay complete.';
    }
    return null;
  }

  void _saveEducation() {
    setState(() {
      _validationMessage = null;
    });

    final missingFields = <String>[];
    if (_institutionController.text.trim().isEmpty) {
      missingFields.add('Institution');
    }
    if (_degreeController.text.trim().isEmpty) {
      missingFields.add('Degree');
    }
    if (_startDate == null) {
      missingFields.add('Start Date');
    }

    if (missingFields.isNotEmpty) {
      showMissingFieldsSnackBar(context, missingFields);
      _formKey.currentState?.validate();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_startDate == null) {
      setState(() {
        _validationMessage = 'Please select a start date.';
      });
      return;
    }

    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final newStart = dateOnly(_startDate!);
    final newEnd = resolvedDateRangeEnd(
      startDate: _startDate!,
      endDate: _endDate,
      isCurrent: _isCurrently,
    );

    Education? conflictingEducation;
    for (final entry in resume.education) {
      if (entry.id == (widget.existing?.id ?? '')) {
        continue;
      }

      final existingStart = dateOnly(entry.startDate);
      final existingEnd = resolvedDateRangeEnd(
        startDate: entry.startDate,
        endDate: entry.endDate,
        isCurrent: entry.isCurrentlyStudying,
      );

      if (dateRangesOverlap(
        startA: newStart,
        endA: newEnd,
        startB: existingStart,
        endB: existingEnd,
      )) {
        conflictingEducation = entry;
        break;
      }
    }

    if (conflictingEducation != null) {
      final conflict = conflictingEducation;
      setState(() {
        _validationMessage =
            'Date range overlaps with "${conflict.degree}" at ${conflict.institution}';
      });
      return;
    }

    final education = Education(
      id: widget.existing?.id ?? const Uuid().v4(),
      institution: _institutionController.text.trim(),
      degree: _degreeController.text.trim(),
      fieldOfStudy: _fieldController.text.trim(),
      grade: _gradeController.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrently ? null : _endDate,
      isCurrentlyStudying: _isCurrently,
    );

    List<Education> updatedList;
    if (widget.existing != null) {
      updatedList = resume.education
          .map((e) => e.id == education.id ? education : e)
          .toList();
    } else {
      updatedList = [...resume.education, education];
    }

    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
          resume.copyWith(education: updatedList),
        );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(widget.existing != null
                  ? 'Education updated'
                  : 'Education added'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    final qualityReport = resume == null
        ? null
        : ResumeQualityService.analyzeResume(_buildDraftResume(resume));
    final liveGuidanceMessage = _liveGuidanceMessage();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Edit Education' : 'Add Education',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle)),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  EditorIntroCard(
                    title: widget.existing != null
                        ? 'Refine this credential'
                        : 'Add academic proof',
                    subtitle:
                        'Keep the institution, program, and dates complete so the resume preview presents a trustworthy academic path.',
                    icon: Iconsax.teacher,
                    accentColor: const Color(0xFF0EA5E9),
                    stats: [
                      EditorIntroStat(
                        label: _isCurrently ? 'current study' : 'dated entry',
                        icon: Iconsax.clock,
                      ),
                      EditorIntroStat(
                        label: _gradeController.text.trim().isNotEmpty
                            ? 'grade included'
                            : 'grade optional',
                        icon: Iconsax.medal_star,
                      ),
                    ],
                  ),
                  if (qualityReport != null) ...[
                    const SizedBox(height: 16),
                    ResumeQualityPanel(
                      report: qualityReport,
                      title: 'Draft Education Guidance',
                      subtitle:
                          'This score uses your in-progress education details before save.',
                      accentColor: const Color(0xFF0EA5E9),
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
                    controller: _institutionController,
                    label: 'Institution',
                    hint: 'University of Example',
                    prefixIcon: Iconsax.building,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  CustomTextField(
                    controller: _degreeController,
                    label: 'Degree',
                    hint: 'Bachelor of Science',
                    prefixIcon: Iconsax.award,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  CustomTextField(
                    controller: _fieldController,
                    label: 'Field of Study',
                    hint: 'Computer Science',
                    prefixIcon: Iconsax.book,
                    onChanged: (_) => setState(() {}),
                  ),
                  CustomTextField(
                    controller: _gradeController,
                    label: 'Grade / GPA',
                    hint: '3.8 / 4.0',
                    prefixIcon: Iconsax.medal_star,
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start Date',
                          date: _startDate,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!_isCurrently)
                        Expanded(
                          child: _DateField(
                            label: 'End Date',
                            date: _endDate,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _isCurrently,
                    onChanged: (v) => setState(() {
                      _isCurrently = v ?? false;
                      _validationMessage = null;
                      if (_isCurrently) {
                        _endDate = null;
                      }
                    }),
                    title: const Text('Currently studying here'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_validationMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _validationMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          // Pinned Save Button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveEducation,
                child: Text(widget.existing != null
                    ? 'Update Education'
                    : 'Save Education'),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.calendar,
                    size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('dd MMM yyyy').format(date!)
                      : 'Select',
                  style: TextStyle(
                      color: date != null ? null : AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
