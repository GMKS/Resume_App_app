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
import '../../../core/utils/resume_translations.dart';
import '../../../core/utils/validation_feedback.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/app_empty_state_card.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const ExperienceScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  void _addExperience() => _showExperienceDialog(null);
  void _editExperience(Experience exp) => _showExperienceDialog(exp);

  Future<void> _handleQualitySuggestion(
    ResumeQualitySuggestion suggestion,
  ) async {
    String? route;
    switch (suggestion.sectionKey) {
      case 'personal':
        route = '/editor/${widget.resumeId}/personal';
        break;
      case 'summary':
        route = '/editor/${widget.resumeId}/summary';
        break;
      case 'experience':
        return;
      case 'education':
        route = '/editor/${widget.resumeId}/education';
        break;
      case 'skills':
        route = '/editor/${widget.resumeId}/skills';
        break;
      case 'projects':
        route = '/editor/${widget.resumeId}/projects';
        break;
      default:
        return;
    }

    await context.push(route);
  }

  Widget _buildScreenHeader(
    BuildContext context,
    ResumeModel resume,
    ResumeQualityReport qualityReport,
  ) {
    final currentRoles =
        resume.experience.where((exp) => exp.isCurrentlyWorking).length;
    final impactReadyRoles = resume.experience
        .where(
          (exp) =>
              exp.description.trim().isNotEmpty || exp.achievements.isNotEmpty,
        )
        .length;

    return Column(
      children: [
        EditorIntroCard(
          title: 'Timeline & Impact',
          subtitle:
              'Arrange roles in the order you want recruiters to scan them. Each change here flows straight into preview and export once it is saved.',
          icon: Iconsax.briefcase,
          accentColor: AppColors.success,
          stats: [
            EditorIntroStat(
              label: '${resume.experience.length} roles',
              icon: Iconsax.briefcase,
            ),
            EditorIntroStat(
              label: '$currentRoles current',
              icon: Iconsax.clock,
            ),
            EditorIntroStat(
              label: '$impactReadyRoles with impact notes',
              icon: Iconsax.chart_success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResumeQualityPanel(
          report: qualityReport,
          title: 'Experience Guidance',
          subtitle:
              'Strong date coverage and measurable scope improve both ATS parsing and the confidence of the preview output.',
          accentColor: AppColors.success,
          maxSuggestions: 2,
          onSuggestionTap: _handleQualitySuggestion,
        ),
      ],
    );
  }

  void _deleteExperience(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updated = resume.experience.where((e) => e.id != id).toList();
      ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
            resume.copyWith(experience: updated),
          );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Experience removed'),
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

  void _showExperienceDialog(Experience? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ExperienceForm(resumeId: widget.resumeId, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Loading experience',
          message: 'Preparing your work history editor.',
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
        title: const Text('Work Experience'),
      ),
      body: SafeArea(
        bottom: false,
        child: resume.experience.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                children: [
                  _buildScreenHeader(context, resume, qualityReport),
                  const SizedBox(height: 20),
                  _buildEmptyState(),
                ],
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                header: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildScreenHeader(context, resume, qualityReport),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: resume.experience.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final items = List<Experience>.from(resume.experience);
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  ref
                      .read(currentResumeProvider(widget.resumeId).notifier)
                      .updateResume(
                        resume.copyWith(experience: items),
                      );
                },
                itemBuilder: (context, index) {
                  final exp = resume.experience[index];
                  return _ExperienceCard(
                    key: ValueKey(exp.id),
                    experience: exp,
                    onEdit: () => _editExperience(exp),
                    onDelete: () => _deleteExperience(exp.id),
                    dragHandle: ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Iconsax.menu_1,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _addExperience,
              icon: const Icon(Iconsax.add),
              label: const Text('Add Work Experience'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyStateCard(
      icon: Iconsax.briefcase,
      accentColor: AppColors.success,
      title: 'No Experience Added',
      message:
          'Add your work history to highlight progression, ownership, and measurable impact.',
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _ExperienceCard extends StatelessWidget {
  final Experience experience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? dragHandle;

  const _ExperienceCard(
      {super.key,
      required this.experience,
      required this.onEdit,
      required this.onDelete,
      this.dragHandle});

  @override
  Widget build(BuildContext context) {
    final achievementCount =
        experience.achievements.where((item) => item.trim().isNotEmpty).length;
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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Iconsax.briefcase, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(experience.position,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(experience.company,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (experience.isCurrentlyWorking)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Current',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
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
                if (dragHandle != null) ...[
                  const SizedBox(width: 8),
                  dragHandle!,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.calendar,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? 'Present' : experience.endDate != null ? DateFormat('MMM yyyy').format(experience.endDate!) : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EditorStatPill(
                      label: achievementCount > 0
                          ? '$achievementCount achievements'
                          : 'add outcomes',
                      icon: Iconsax.chart_success,
                      color: achievementCount > 0
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    if ((experience.location ?? '').trim().isNotEmpty)
                      EditorStatPill(
                        label: experience.location!.trim(),
                        icon: Iconsax.location,
                        color: AppColors.info,
                      ),
                  ],
                ),
                if (experience.location?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.location,
                          size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(experience.location!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
                if (experience.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(experience.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.5)),
                ],
                if (experience.achievements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...experience.achievements.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(color: AppColors.success)),
                            Expanded(
                                child: Text(a,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceForm extends ConsumerStatefulWidget {
  final String resumeId;
  final Experience? existing;

  const _ExperienceForm({required this.resumeId, this.existing});

  @override
  ConsumerState<_ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends ConsumerState<_ExperienceForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  final List<TextEditingController> _achievementControllers = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrently = false;

  String _getLanguage() {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    return resume?.writingLanguage ?? 'English';
  }

  @override
  void initState() {
    super.initState();
    _companyController =
        TextEditingController(text: widget.existing?.company ?? '');
    _positionController =
        TextEditingController(text: widget.existing?.position ?? '');
    _locationController =
        TextEditingController(text: widget.existing?.location ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _startDate = widget.existing?.startDate;
    _endDate = widget.existing?.endDate;
    _isCurrently = widget.existing?.isCurrentlyWorking ?? false;

    if (widget.existing?.achievements.isNotEmpty ?? false) {
      for (var a in widget.existing!.achievements) {
        _achievementControllers.add(TextEditingController(text: a));
      }
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    for (var c in _achievementControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAchievement() {
    setState(() => _achievementControllers.add(TextEditingController()));
  }

  void _removeAchievement(int index) {
    setState(() {
      _achievementControllers[index].dispose();
      _achievementControllers.removeAt(index);
    });
  }

  ResumeModel _buildDraftResume(ResumeModel resume) {
    final hasDraftInput = _positionController.text.trim().isNotEmpty ||
        _companyController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _achievementControllers
            .any((controller) => controller.text.trim().isNotEmpty) ||
        _startDate != null ||
        _endDate != null;

    if (!hasDraftInput) {
      return resume;
    }

    final draftExperience = Experience(
      id: widget.existing?.id ?? 'draft-experience',
      company: _companyController.text.trim(),
      position: _positionController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate ?? DateTime.now(),
      endDate: _isCurrently ? null : _endDate,
      isCurrentlyWorking: _isCurrently,
      achievements: _achievementControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    );

    final updatedExperience = widget.existing != null
        ? resume.experience
            .map((item) =>
                item.id == draftExperience.id ? draftExperience : item)
            .toList()
        : [...resume.experience, draftExperience];

    return resume.copyWith(experience: updatedExperience);
  }

  String? _liveValidationMessage() {
    if (_positionController.text.trim().isEmpty) {
      return 'Add a role title so the preview can establish seniority at a glance.';
    }
    if (_companyController.text.trim().isEmpty) {
      return 'Add the employer name to keep your experience timeline credible.';
    }
    if (_startDate == null) {
      return 'Select a start date to anchor the timeline and avoid preview ambiguity.';
    }
    if (_endDate == null && !_isCurrently) {
      return 'Add an end date or mark this role as current so exported timelines stay consistent.';
    }
    if (_descriptionController.text.trim().isEmpty &&
        !_achievementControllers
            .any((controller) => controller.text.trim().isNotEmpty)) {
      return 'Add responsibilities or results so this role contributes meaningful proof, not just a title.';
    }
    return null;
  }

  void _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ??
              (_startDate != null
                  ? DateTime(_startDate!.year, _startDate!.month + 1, 1)
                  : DateTime.now())),
      firstDate: isStart ? DateTime(1950) : (_startDate ?? DateTime(1950)),
      lastDate: isStart ? (_endDate ?? DateTime.now()) : DateTime.now(),
    );
    if (date != null) {
      setState(() {
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

  void _saveExperience() {
    final missingFields = <String>[];
    if (_positionController.text.trim().isEmpty) {
      missingFields.add('Job Title');
    }
    if (_companyController.text.trim().isEmpty) {
      missingFields.add('Company');
    }
    if (_startDate == null) {
      missingFields.add('Start Date');
    }
    if (_endDate == null && !_isCurrently) {
      missingFields.add('End Date or Currently Working');
    }

    if (missingFields.isNotEmpty) {
      showMissingFieldsSnackBar(context, missingFields);
      _formKey.currentState?.validate();
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Please select a start date')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      if (_endDate == null && !_isCurrently) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select an end date, or tick "Currently working here"',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final resume = ref.read(currentResumeProvider(widget.resumeId));
      if (resume == null) return;

      // Check for overlapping date ranges (same month/year = overlap)
      final endForCheck =
          _isCurrently ? DateTime.now() : (_endDate ?? DateTime.now());
      final conflicts = resume.experience
          .where((e) => e.id != (widget.existing?.id ?? ''))
          .where((e) {
        final eEnd = e.isCurrentlyWorking
            ? DateTime.now()
            : (e.endDate ?? DateTime.now());
        // Overlaps if date ranges share any month (same-month boundary counts as overlap)
        final newStartBeforeExistingEnd = _startDate!.year < eEnd.year ||
            (_startDate!.year == eEnd.year && _startDate!.month <= eEnd.month);
        final newEndAfterExistingStart = endForCheck.year > e.startDate.year ||
            (endForCheck.year == e.startDate.year &&
                endForCheck.month >= e.startDate.month);
        return newStartBeforeExistingEnd && newEndAfterExistingStart;
      }).toList();
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final conflictDates =
            '${DateFormat('MMM yyyy').format(c.startDate)} - ${c.isCurrentlyWorking ? 'Present' : DateFormat('MMM yyyy').format(c.endDate!)}';

        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overlapping Dates'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'This date range conflicts with an existing experience:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.position,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(c.company,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(conflictDates,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Please adjust the dates to avoid overlap, or mark it as "Currently working here".',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final experience = Experience(
        id: widget.existing?.id ?? const Uuid().v4(),
        company: _companyController.text.trim(),
        position: _positionController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
        isCurrentlyWorking: _isCurrently,
        achievements: _achievementControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );

      List<Experience> updated;
      if (widget.existing != null) {
        updated = resume.experience
            .map((e) => e.id == experience.id ? experience : e)
            .toList();
      } else {
        updated = [...resume.experience, experience];
      }

      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(resume.copyWith(experience: updated));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.existing != null
                    ? 'Experience updated'
                    : 'Experience added'),
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
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    final qualityReport = resume == null
        ? null
        : ResumeQualityService.analyzeResume(_buildDraftResume(resume));
    final liveValidationMessage = _liveValidationMessage();
    final achievementCount = _achievementControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;

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
                        ? 'Edit Experience'
                        : 'Add Experience',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
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
                        ? 'Refine this role'
                        : 'Add a stronger role story',
                    subtitle:
                        'Focus on the scope, dates, and impact you want to preserve in preview, export, and ATS parsing.',
                    icon: Iconsax.briefcase,
                    accentColor: AppColors.success,
                    stats: [
                      EditorIntroStat(
                        label: _isCurrently ? 'current role' : 'dated role',
                        icon: Iconsax.clock,
                      ),
                      EditorIntroStat(
                        label: achievementCount > 0
                            ? '$achievementCount impact bullets'
                            : 'add impact bullets',
                        icon: Iconsax.chart_success,
                      ),
                    ],
                  ),
                  if (qualityReport != null) ...[
                    const SizedBox(height: 16),
                    ResumeQualityPanel(
                      report: qualityReport,
                      title: 'Draft Experience Guidance',
                      subtitle:
                          'This uses your in-progress role details before save so you can catch weak spots early.',
                      accentColor: AppColors.success,
                      maxSuggestions: 2,
                    ),
                  ],
                  if (liveValidationMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.18),
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
                              liveValidationMessage,
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
                    controller: _positionController,
                    label: ResumeTranslations.getFieldLabel(
                      ResumeTranslations.kJobTitle,
                      _getLanguage(),
                    ),
                    hint: 'Software Engineer',
                    prefixIcon: Iconsax.user,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  CustomTextField(
                    controller: _companyController,
                    label: ResumeTranslations.getFieldLabel(
                      ResumeTranslations.kCompany,
                      _getLanguage(),
                    ),
                    hint: 'Acme Inc.',
                    prefixIcon: Iconsax.building,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  CustomTextField(
                    controller: _locationController,
                    label: ResumeTranslations.getFieldLabel(
                      ResumeTranslations.kLocation,
                      _getLanguage(),
                    ),
                    hint: 'New York, NY',
                    prefixIcon: Iconsax.location,
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _DateField(
                              label: ResumeTranslations.getFieldLabel(
                                  ResumeTranslations.kStartDate,
                                  _getLanguage()),
                              date: _startDate,
                              onTap: () => _selectDate(true))),
                      const SizedBox(width: 16),
                      if (!_isCurrently)
                        Expanded(
                            child: _DateField(
                                label: ResumeTranslations.getFieldLabel(
                                    ResumeTranslations.kEndDate,
                                    _getLanguage()),
                                date: _endDate,
                                onTap: () => _selectDate(false))),
                    ],
                  ),
                  CheckboxListTile(
                    value: _isCurrently,
                    onChanged: (v) => setState(() => _isCurrently = v ?? false),
                    title: const Text('Currently working here'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CustomTextField(
                    controller: _descriptionController,
                    label: ResumeTranslations.getFieldLabel(
                      ResumeTranslations.kDescription,
                      _getLanguage(),
                    ),
                    hint: 'Describe your role and responsibilities...',
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          ResumeTranslations.getFieldLabel(
                              ResumeTranslations.kAchievements, _getLanguage()),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                          onPressed: _addAchievement,
                          icon: const Icon(Iconsax.add, size: 16),
                          label: const Text('Add')),
                    ],
                  ),
                  ..._achievementControllers.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: e.value,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Achievement ${e.key + 1}',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            IconButton(
                                onPressed: () => _removeAchievement(e.key),
                                icon: const Icon(Iconsax.trash,
                                    color: AppColors.error, size: 20)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],
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
                onPressed: _saveExperience,
                child: Text(widget.existing != null
                    ? 'Update Experience'
                    : 'Save Experience'),
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
      ],
    );
  }
}
