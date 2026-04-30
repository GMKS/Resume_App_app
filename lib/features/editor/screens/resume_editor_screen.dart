import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../../core/utils/resume_translations.dart';
import '../../../core/utils/startup_profile_sections.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_tile.dart';
import '../widgets/progress_header.dart';
import '../widgets/resume_customization_sheets.dart';
import '../widgets/user_custom_section_tile.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;

// Provider for current resume
final currentResumeProvider =
    StateNotifierProvider.family<CurrentResumeNotifier, ResumeModel?, String>(
  (ref, resumeId) => CurrentResumeNotifier(resumeId),
);

/// Small icon + label button used in the editor toolbar.
class _LabeledToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool highlighted;

  const _LabeledToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highlighted ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(12),
          border: highlighted
              ? Border.all(color: color.withValues(alpha: 0.28))
              : null,
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentResumeNotifier extends StateNotifier<ResumeModel?> {
  final String resumeId;

  CurrentResumeNotifier(this.resumeId) : super(null) {
    loadResume();
  }

  void loadResume() {
    state = StorageService.getResume(resumeId);
  }

  Future<void> updateResume(ResumeModel resume) async {
    final updatedResume = resume.copyWith(updatedAt: DateTime.now());
    await StorageService.saveResume(updatedResume);
    state = updatedResume;
  }
}

// Section display metadata used by drag-drop reorder
const _kSectionLabels = {
  'personal': 'Personal Information',
  'summary': 'Professional Summary',
  'experience': 'Work Experience',
  'education': 'Education',
  'skills': 'Skills',
  'projects': 'Projects',
  'certifications': 'Certifications',
  'languages': 'Languages',
};

const _kSectionIcons = {
  'personal': Iconsax.user,
  'summary': Iconsax.document_text,
  'experience': Iconsax.briefcase,
  'education': Iconsax.teacher,
  'skills': Iconsax.code,
  'projects': Iconsax.folder_open,
  'certifications': Iconsax.medal_star,
  'languages': Iconsax.translate,
};

const _kSectionColors = {
  'personal': Color(0xFF6366F1),
  'summary': Color(0xFF8B5CF6),
  'experience': Color(0xFF10B981),
  'education': Color(0xFF0EA5E9),
  'skills': Color(0xFFF59E0B),
  'projects': Color(0xFFEC4899),
  'certifications': Color(0xFF14B8A6),
  'languages': Color(0xFF64748B),
  'startup_achievements': Color(0xFFEF4444),
  'startup_tools': Color(0xFFF97316),
  'startup_internships': Color(0xFF0EA5E9),
  'startup_teaching_experience': Color(0xFF8B5CF6),
  'startup_licenses': Color(0xFF14B8A6),
  'startup_references': Color(0xFF64748B),
  'business_leadership_achievements': Color(0xFF1D4ED8),
  'business_board_memberships': Color(0xFF475569),
  'business_management_certifications': Color(0xFF0F766E),
  'design_portfolio_highlights': Color(0xFF7C3AED),
  'design_awards_recognition': Color(0xFFEA580C),
  'design_tools_software': Color(0xFF2563EB),
  'design_specializations': Color(0xFFDB2777),
  'healthcare_licenses_certifications': Color(0xFF0F766E),
  'healthcare_specializations': Color(0xFF2563EB),
  'healthcare_clinical_skills': Color(0xFF059669),
  'healthcare_hospital_affiliations': Color(0xFF4F46E5),
  'hr_certifications': Color(0xFFC2410C),
  'hr_talent_management': Color(0xFF7C3AED),
  'hr_compliance_programs': Color(0xFF0891B2),
  'hr_employee_relations': Color(0xFFBE185D),
};

const _kStartupSectionIcons = {
  'startup_achievements': Iconsax.medal,
  'startup_tools': Iconsax.setting_2,
  'startup_internships': Iconsax.briefcase,
  'startup_teaching_experience': Iconsax.teacher,
  'startup_licenses': Iconsax.card,
  'startup_references': Iconsax.people,
};

const _kProfessionalRoleSectionIcons = {
  'business_leadership_achievements': Iconsax.chart_success,
  'business_board_memberships': Iconsax.people,
  'business_management_certifications': Iconsax.medal_star,
  'design_portfolio_highlights': Iconsax.gallery,
  'design_awards_recognition': Iconsax.cup,
  'design_tools_software': Iconsax.setting_2,
  'design_specializations': Iconsax.brush_2,
  'healthcare_licenses_certifications': Iconsax.card,
  'healthcare_specializations': Iconsax.health,
  'healthcare_clinical_skills': Iconsax.activity,
  'healthcare_hospital_affiliations': Iconsax.building_4,
  'hr_certifications': Iconsax.medal_star,
  'hr_talent_management': Iconsax.profile_2user,
  'hr_compliance_programs': Iconsax.document_text,
  'hr_employee_relations': Iconsax.people,
};

const _kUserCustomSectionPalette = <Color>[
  Color(0xFF7C3AED),
  Color(0xFF0EA5E9),
  Color(0xFF14B8A6),
  Color(0xFFEA580C),
  Color(0xFFDB2777),
  Color(0xFF16A34A),
];

class _PendingUserCustomSectionDraft {
  final String title;
  final String initialContent;

  const _PendingUserCustomSectionDraft({
    required this.title,
    required this.initialContent,
  });
}

class ResumeEditorScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const ResumeEditorScreen({
    super.key,
    required this.resumeId,
  });

  @override
  ConsumerState<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends ConsumerState<ResumeEditorScreen> {
  Timer? _autoSaveTimer;
  ProviderSubscription<ResumeModel?>? _resumeSubscription;
  ResumeModel? _lastSavedResume;
  List<String>? _customSectionOrder;
  String _resumeFormat = 'chronological'; // chronological | functional | hybrid

  @override
  void initState() {
    super.initState();
    _loadSectionPrefs();
    _bindResumeListener();
    // Invalidate the provider when entering this screen to load fresh data from storage
    // This ensures AI-generated content is visible after being saved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(currentResumeProvider(widget.resumeId));
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _resumeSubscription?.close();
    super.dispose();
  }

  void _bindResumeListener() {
    _resumeSubscription?.close();
    _resumeSubscription = ref.listenManual<ResumeModel?>(
      currentResumeProvider(widget.resumeId),
      (previous, next) {
        if (next != null && previous != next) {
          _scheduleAutoSave(next);
        }
      },
    );
  }

  Future<void> _waitForBottomSheetToSettle() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Schedules an auto-save 3 seconds after the last change.
  void _scheduleAutoSave(ResumeModel resume) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && resume != _lastSavedResume) {
        _lastSavedResume = resume;
        ref
            .read(currentResumeProvider(widget.resumeId).notifier)
            .updateResume(resume);
      }
    });
  }

  @override
  void didUpdateWidget(ResumeEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if the resume ID changes
    if (oldWidget.resumeId != widget.resumeId) {
      _bindResumeListener();
      ref.invalidate(currentResumeProvider(oldWidget.resumeId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(currentResumeProvider(widget.resumeId));
      });
    }
  }

  void _saveResume(BuildContext context, WidgetRef ref, ResumeModel resume) {
    ref
        .read(currentResumeProvider(widget.resumeId).notifier)
        .updateResume(resume);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Resume saved successfully'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPlanUpgrade(String featureName, String message) {
    showUpgradePromptSheet(
      context,
      featureName: featureName,
      message: message,
    );
  }

  void _openSectionOrUpgrade(String sectionKey, String route) {
    if (!FreePlanService.canEditSection(sectionKey)) {
      _showPlanUpgrade(
        'premium_sections',
        FreePlanService.premiumSectionMessage,
      );
      return;
    }

    context.push(route);
  }

  Future<void> _loadSectionPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final orderStr = prefs.getString('section_order_${widget.resumeId}');
    final format =
        prefs.getString('resume_format_${widget.resumeId}') ?? 'chronological';
    final resume = StorageService.getResume(widget.resumeId);
    if (mounted) {
      setState(() {
        _resumeFormat = format;
        if (orderStr != null && orderStr.isNotEmpty) {
          final loaded = orderStr.split(',');
          final allSectionKeys = resume == null
              ? const [
                  'personal',
                  'summary',
                  'experience',
                  'education',
                  'skills',
                  'projects',
                  'certifications',
                  'languages',
                ]
              : _availableSectionKeys(resume);
          final normalized = loaded.where(allSectionKeys.contains).toList();
          final missing =
              allSectionKeys.where((key) => !normalized.contains(key)).toList();
          _customSectionOrder = [...normalized, ...missing];
        }
      });
    }
  }

  Future<void> _saveSectionOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('section_order_${widget.resumeId}', order.join(','));
  }

  Future<void> _saveResumeFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_format_${widget.resumeId}', format);
  }

  List<String> _withOrderedUserCustomSectionKeys(
    ResumeModel resume,
    List<String> orderedUserIds,
  ) {
    final orderedSet = orderedUserIds.toSet();
    final currentOrder = _normalizedSectionOrderForResume(resume);
    final result = <String>[];
    var inserted = false;

    for (final key in currentOrder) {
      if (orderedSet.contains(key)) {
        if (!inserted) {
          result.addAll(orderedUserIds);
          inserted = true;
        }
        continue;
      }
      result.add(key);
    }

    if (!inserted && orderedUserIds.isNotEmpty) {
      result.addAll(orderedUserIds);
    }

    return result;
  }

  List<CustomSection> _orderedUserCustomSectionsForKeys(
    ResumeModel resume,
    List<String> order,
  ) {
    final remaining = <String, CustomSection>{
      for (final section in orderedUserCustomSections(resume))
        section.id: section,
    };
    final ordered = <CustomSection>[];

    for (final key in order) {
      final section = remaining.remove(key);
      if (section != null) {
        ordered.add(section);
      }
    }

    ordered.addAll(remaining.values);
    return ordered;
  }

  CustomSection? _findUserCustomSectionByTitle(
    ResumeModel resume,
    String title, {
    String? excludingId,
  }) {
    final normalizedTitle = normalizeUserCustomSectionTitle(title).toLowerCase();
    if (normalizedTitle.isEmpty) {
      return null;
    }

    for (final section in orderedUserCustomSections(resume)) {
      if (section.id == excludingId) {
        continue;
      }
      if (normalizeUserCustomSectionTitle(section.title).toLowerCase() ==
          normalizedTitle) {
        return section;
      }
    }

    return null;
  }

  void _showSingleSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _saveUserCustomSections(
    ResumeModel resume,
    List<CustomSection> orderedUserSections, {
    List<String>? nextOrder,
  }) async {
    final latestResume =
        ref.read(currentResumeProvider(widget.resumeId)) ?? resume;
    final mergedSections = mergeUserCustomSections(
      existingSections: latestResume.customSections,
      orderedUserSections: orderedUserSections.toList(growable: false),
    );
    final updatedResume = latestResume.copyWith(customSections: mergedSections);

    await ref
        .read(currentResumeProvider(widget.resumeId).notifier)
        .updateResume(updatedResume);

    final availableKeys = _availableSectionKeys(updatedResume);
    final desiredOrder = nextOrder ??
        _withOrderedUserCustomSectionKeys(
          updatedResume,
          orderedUserSections
              .map((section) => section.id)
              .toList(growable: false),
        );
    final persisted = desiredOrder.where(availableKeys.contains).toList();
    final missing =
        availableKeys.where((key) => !persisted.contains(key)).toList();
    final finalOrder = [...persisted, ...missing];

    if (mounted) {
      setState(() => _customSectionOrder = finalOrder);
    }
    await _saveSectionOrder(finalOrder);
  }

  Future<bool> _confirmSaveEmptyUserCustomSection(
    BuildContext context,
    String title,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Save Empty Section?'),
            content: Text(
              '"$title" will be created without any entries. You can add content later from the section screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save Section'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showAddUserCustomSectionSheet(
    BuildContext context,
    ResumeModel resume,
  ) async {
    if (!FreePlanService.canEditSection(kUserCustomSectionFeatureKey)) {
      _showPlanUpgrade(
        'premium_sections',
        FreePlanService.premiumSectionMessage,
      );
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    var isSubmitting = false;

    final draft = await showModalBottomSheet<_PendingUserCustomSectionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add Custom Section',
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(sheetContext),
                            icon: const Icon(Iconsax.close_circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kSuggestedUserCustomSectionTitles
                            .map(
                              (suggestion) => ActionChip(
                                label: Text(suggestion),
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        titleController.text = suggestion;
                                      },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: titleController,
                        label: 'Section Title',
                        hint:
                            'Awards, Leadership Experience, Open Source Contributions...',
                        prefixIcon: Iconsax.text,
                        enabled: !isSubmitting,
                      ),
                      CustomTextField(
                        controller: contentController,
                        label: 'Description / Content',
                        hint:
                            'Optional first entry. You can add more entries later.',
                        prefixIcon: Iconsax.document_text,
                        maxLines: 5,
                        enabled: !isSubmitting,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setSheetState(() => isSubmitting = true);

                                  final title = normalizeUserCustomSectionTitle(
                                    titleController.text,
                                  );
                                  if (title.isEmpty) {
                                    _showSingleSnackBar(
                                      sheetContext,
                                      'Section title is required',
                                    );
                                    if (sheetContext.mounted) {
                                      setSheetState(() => isSubmitting = false);
                                    }
                                    return;
                                  }
                                  if (hasDuplicateUserCustomSectionTitle(
                                    resume.customSections,
                                    title,
                                  )) {
                                    _showSingleSnackBar(
                                      sheetContext,
                                      'A custom section with this title already exists',
                                    );
                                    if (sheetContext.mounted) {
                                      setSheetState(() => isSubmitting = false);
                                    }
                                    return;
                                  }

                                  final initialContent =
                                      contentController.text.trim();
                                  if (initialContent.isEmpty) {
                                    final confirmEmpty =
                                        await _confirmSaveEmptyUserCustomSection(
                                      sheetContext,
                                      title,
                                    );
                                    if (!confirmEmpty) {
                                      if (sheetContext.mounted) {
                                        setSheetState(
                                          () => isSubmitting = false,
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  if (!sheetContext.mounted) {
                                    return;
                                  }

                                  Navigator.pop(
                                    sheetContext,
                                    _PendingUserCustomSectionDraft(
                                      title: title,
                                      initialContent: initialContent,
                                    ),
                                  );
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Section'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _waitForBottomSheetToSettle();

    titleController.dispose();
    contentController.dispose();

    if (!mounted || draft == null) {
      return;
    }

    final latestResume = ref.read(currentResumeProvider(widget.resumeId)) ?? resume;
    final normalizedTitle = normalizeUserCustomSectionTitle(draft.title);
    if (normalizedTitle.isEmpty) {
      return;
    }

    final existingSection = _findUserCustomSectionByTitle(
      latestResume,
      normalizedTitle,
    );
    if (existingSection != null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      context.push(
        '/editor/${widget.resumeId}/user-custom/${existingSection.id}',
      );
      return;
    }

    final userSections = _orderedUserCustomSectionsForKeys(
      latestResume,
      _normalizedSectionOrderForResume(latestResume),
    );
    final newSection = CustomSection(
      id: buildUserCustomSectionId(),
      title: normalizedTitle,
      items: draft.initialContent.isEmpty
          ? const <CustomSectionItem>[]
          : <CustomSectionItem>[
              buildUserCustomSectionItem(
                content: draft.initialContent,
              ),
            ],
      order: userSections.length,
    );

    await _saveUserCustomSections(
      latestResume,
      [...userSections, newSection],
    );

    if (!mounted) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    context.push(
      '/editor/${widget.resumeId}/user-custom/${newSection.id}',
    );
  }

  Future<void> _showRenameUserCustomSectionSheet(
    BuildContext context,
    ResumeModel resume,
    CustomSection section,
  ) async {
    final controller = TextEditingController(text: section.title);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rename Custom Section',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Iconsax.close_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: controller,
                    label: 'Section Title',
                    hint: 'Enter a unique section title',
                    prefixIcon: Iconsax.text,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = normalizeUserCustomSectionTitle(
                          controller.text,
                        );
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Section title is required'),
                            ),
                          );
                          return;
                        }
                        if (hasDuplicateUserCustomSectionTitle(
                          resume.customSections,
                          title,
                          excludingId: section.id,
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A custom section with this title already exists',
                              ),
                            ),
                          );
                          return;
                        }

                        final sections = _orderedUserCustomSectionsForKeys(
                          resume,
                          _normalizedSectionOrderForResume(resume),
                        );
                        final index = sections.indexWhere(
                          (entry) => entry.id == section.id,
                        );
                        if (index == -1) {
                          return;
                        }

                        sections[index] =
                            sections[index].copyWith(title: title);
                        await _saveUserCustomSections(resume, sections);
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Save Title'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deleteUserCustomSection(
    BuildContext context,
    ResumeModel resume,
    CustomSection section,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Custom Section?'),
            content: Text(
              '"${section.title}" and all of its entries will be removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    final remainingSections = _orderedUserCustomSectionsForKeys(
      resume,
      _normalizedSectionOrderForResume(resume),
    ).where((entry) => entry.id != section.id).toList(growable: false);
    await _saveUserCustomSections(resume, remainingSections);
  }

  void _showReorderBottomSheet(BuildContext context, ResumeModel resume) {
    final order = List<String>.from(_normalizedSectionOrderForResume(resume));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Iconsax.menu, size: 22),
                    const SizedBox(width: 10),
                    Text('Reorder Sections',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final nextOrder = List<String>.from(order);
                        final orderedUserSections =
                            _orderedUserCustomSectionsForKeys(
                                resume, nextOrder);
                        if (orderedUserSections.isNotEmpty) {
                          await _saveUserCustomSections(
                            resume,
                            orderedUserSections,
                            nextOrder: nextOrder,
                          );
                        } else {
                          setState(() => _customSectionOrder = nextOrder);
                          await _saveSectionOrder(nextOrder);
                        }
                        if (!ctx.mounted) {
                          return;
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              Expanded(
                child: ReorderableListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: order.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    setModalState(() {
                      final item = order.removeAt(oldIndex);
                      order.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (_, i) {
                    final key = order[i];
                    final color = _sectionColorForKey(key);
                    return ListTile(
                      key: ValueKey(key),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_sectionIconForKey(key),
                            color: color, size: 20),
                      ),
                      title: Text(
                        _sectionLabelForKey(key),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.drag_handle_rounded,
                          color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFormatPicker(BuildContext context) {
    final formats = [
      {
        'key': 'chronological',
        'label': 'Chronological',
        'icon': Iconsax.calendar,
        'color': AppColors.primary,
        'description':
            'Lists experience newest-first. Best for steady careers.',
      },
      {
        'key': 'functional',
        'label': 'Functional',
        'icon': Iconsax.chart_success,
        'color': const Color(0xFF10B981),
        'description': 'Skills first. Ideal for career changers or gaps.',
      },
      {
        'key': 'hybrid',
        'label': 'Hybrid / Combination',
        'icon': Iconsax.element_4,
        'color': const Color(0xFF8B5CF6),
        'description': 'Blends skills summary + chronological experience.',
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.element_4, size: 22),
                const SizedBox(width: 10),
                Text('Resume Format',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ...formats.map((f) {
              final selected = _resumeFormat == f['key'];
              final color = f['color'] as Color;
              return GestureDetector(
                onTap: () {
                  setState(() => _resumeFormat = f['key'] as String);
                  _saveResumeFormat(f['key'] as String);
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(f['icon'] as IconData, color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['label'] as String,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected ? color : null)),
                            Text(f['description'] as String,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Iconsax.tick_circle, color: color, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAiBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.82;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.magic_star,
                              color: Color(0xFF8B5CF6), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Tools',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Powered by Gemini',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _AiSheetOption(
                      icon: Iconsax.search_normal_1,
                      title: 'Job-Specific Resume Generator',
                      subtitle: 'Compare against a job description, review match gaps, and generate AI tailoring',
                      color: AppColors.info,
                      isLocked: !FreePlanService.canAccessAiTool('job_tailor'),
                      onTap: () {
                        if (!FreePlanService.canAccessAiTool('job_tailor')) {
                          Navigator.pop(ctx);
                          _showPlanUpgrade(
                            'ai_assistant',
                            FreePlanService.premiumAiToolMessage,
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        context
                            .push('/ai-job-tailor?resumeId=${widget.resumeId}');
                      },
                    ),
                    const SizedBox(height: 12),
                    _AiSheetOption(
                      icon: Iconsax.magic_star,
                      title: 'Enhance Content',
                      subtitle:
                          'Generate professional summaries & bullet points',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(
                            '/ai-content-enhancer?resumeId=${widget.resumeId}');
                      },
                    ),
                    const SizedBox(height: 12),
                    _AiSheetOption(
                      icon: Iconsax.user_tick,
                      title: 'LinkedIn Profile Import',
                      subtitle:
                          'Import a LinkedIn profile and build a resume from it',
                      color: const Color(0xFF0A66C2),
                      isLocked:
                          !FreePlanService.canAccessAiTool('linkedin_import'),
                      onTap: () {
                        if (!FreePlanService.canAccessAiTool(
                            'linkedin_import')) {
                          Navigator.pop(ctx);
                          _showPlanUpgrade(
                            'ai_assistant',
                            FreePlanService.premiumAiToolMessage,
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        context.push('/linkedin-import');
                      },
                    ),
                    const SizedBox(height: 12),
                    _AiSheetOption(
                      icon: Iconsax.chart_2,
                      title: 'Resume Score Checker',
                      subtitle:
                          'Get an AI score breakdown and improvement tips',
                      color: const Color(0xFFEF4444),
                      isLocked:
                          !FreePlanService.canAccessAiTool('resume_roast'),
                      onTap: () {
                        if (!FreePlanService.canAccessAiTool('resume_roast')) {
                          Navigator.pop(ctx);
                          _showPlanUpgrade(
                            'ai_assistant',
                            FreePlanService.premiumAiToolMessage,
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        context
                            .push('/roast-resume?resumeId=${widget.resumeId}');
                      },
                    ),
                    const SizedBox(height: 12),
                    _AiSheetOption(
                      icon: Iconsax.tag_right,
                      title: 'AI Bullet Point Generator',
                      subtitle:
                          'Generate stronger experience bullets for your resume',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/ai-bullet-generator');
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AdaptiveTooltip(
                        message: 'Back to resumes',
                        button: true,
                        child: IconButton(
                          onPressed: () {
                            ref.invalidate(resumesProvider);
                            context.go('/home');
                          },
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Iconsax.arrow_left,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resume.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${resume.completionPercentage}% Complete',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle,
                                    size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text('Auto-save on',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: const Color(0xFF10B981),
                                            fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Toolbar row below name
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _LabeledToolbarButton(
                          icon: Iconsax.save_2,
                          label: 'Save',
                          color: AppColors.primary,
                          onPressed: () => _saveResume(context, ref, resume),
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.brush_2,
                          label: 'Theme',
                          color: AppColors.secondary,
                          onPressed: () async {
                            await context.push('/templates/${widget.resumeId}');
                            if (mounted) {
                              ref
                                  .read(currentResumeProvider(widget.resumeId)
                                      .notifier)
                                  .loadResume();
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.eye,
                          label: 'Preview',
                          color: AppColors.accent,
                          onPressed: () =>
                              context.push('/preview/${widget.resumeId}'),
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.search_normal,
                          label: 'ATS',
                          color: AppColors.info,
                          onPressed: () {
                            if (!FreePlanService.isPremium) {
                              _showPlanUpgrade(
                                'ats_optimization',
                                'ATS analysis is available on premium plans only.',
                              );
                              return;
                            }

                            context.push('/ats/${widget.resumeId}');
                          },
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.menu,
                          label: 'Reorder',
                          color: const Color(0xFF14B8A6),
                          onPressed: () {
                            if (!FreePlanService.canReorderSections) {
                              _showPlanUpgrade(
                                'section_reorder',
                                FreePlanService.premiumLayoutMessage,
                              );
                              return;
                            }

                            _showReorderBottomSheet(context, resume);
                          },
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.element_4,
                          label: 'Format',
                          color: const Color(0xFFF59E0B),
                          onPressed: () => _showFormatPicker(context),
                        ),
                        const SizedBox(width: 4),
                        _LabeledToolbarButton(
                          icon: Iconsax.magic_star,
                          label: 'AI',
                          color: const Color(0xFF8B5CF6),
                          highlighted: true,
                          onPressed: () => _showAiBottomSheet(context),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

            // Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProgressHeader(
                progress: resume.completionPercentage,
                sectionsCompleted: _getCompletedSections(resume),
                totalSections: 8,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Sections List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    'Resume Sections',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  // ── Choose Template tile ──────────────────────────────────────
                  _buildTemplateTile(context, resume),
                  const SizedBox(height: 8),

                  // ── Writing Language tile ─────────────────────────────────────
                  _buildWritingLanguageTile(context, resume),
                  const SizedBox(height: 8),

                  // ── Font Family tile ──────────────────────────────────────────
                  _buildFontTile(context, resume),
                  const SizedBox(height: 8),

                  // ── Color Theme tile ──────────────────────────────────────────
                  _buildColorThemeTile(context, resume),
                  const SizedBox(height: 8),

                  // ── Layout Style tile ─────────────────────────────────────────
                  _buildLayoutTile(context, resume),
                  const SizedBox(height: 8),

                  // ── Resume Format tile ────────────────────────────────────────
                  _buildResumeFormatTile(context),
                  const SizedBox(height: 8),

                  const Divider(height: 24),

                  // ── Section tiles (ordered) ───────────────────────────────────
                  ..._buildOrderedSections(context, resume),

                  _buildAddUserCustomSectionTile(context, resume)
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 400.ms)
                      .slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCompletedSections(ResumeModel resume) {
    int count = 0;
    if (resume.personalInfo.fullName.isNotEmpty) count++;
    if (resume.objective?.isNotEmpty ?? false) count++;
    if (resume.experience.isNotEmpty) count++;
    if (resume.education.isNotEmpty) count++;
    if (resume.skills.isNotEmpty) count++;
    if (resume.projects.isNotEmpty) count++;
    if (resume.certifications.isNotEmpty) count++;
    if (resume.languages.isNotEmpty) count++;
    return count;
  }

  String _templateName(String templateId) {
    final names = {
      'modern': 'Modern Nova',
      'classic': 'Classic',
      'professional': 'Professional',
      'minimal': 'Minimal',
      'creative': 'Creative',
      'executive': 'Business Management Resume',
      'two_column': 'Two Column',
      'academic': 'Academic',
      'developer': 'Developer',
      'startup': 'Startup',
      'infographic': 'Infographic',
      'sales': 'Sales & Marketing',
      'elegant_pink': 'Pink Rosé Modern',
      'blue_gray': 'FlexColor Sidebar',
      'modern_aesthetic': 'SharpLine Resume',
      'classic_ats': 'Classic ATS Optimized',
      'classic2': 'Classic Plus',
      'education_resume': 'Education Resume',
      'modern_resume': 'Elite Resume',
      'professional_accountant': 'Prof. Accountant',
      'one_page_resume': 'One Page Resume',
      'classic_temp': 'Classic Temp',
      'emerald_executive': 'Emerald Executive',
      'cool_blue': 'VividPro',
      'multicolor': 'MultiColor',
      'entry_level': 'Entry Level',
      'ats_optimized_clean': 'ATS Optimized Clean',
      'ats_standard_format': 'ATS Standard Format',
      'ats_friendly_modern': 'ATS Friendly Modern',
      'executive_classic': 'Executive Classic',
      'vertical_timeline': 'Vertical Timeline',
      'corporate_template': 'Corporate Template',
      'mono_nova': 'Black and White',
      'slate_arc': 'Slate Arc',
      'editorial_frame': 'Editorial Frame',
      'graphite_column': 'Graphite Column',
      'rosewood_panel': 'Rosewood Panel',
      'designer_profile': 'Design/Creative Resume',
      'modern_edge': 'Persona Pro CV',
      'minimal_clean': 'Minimal Clean',
      'minimal_clean_ats': 'Minimal Clean ATS',
      'professional_tone': 'HealthCare Resume',
      'elegant_design': 'Elegant design',
      'creative_professional': 'Creative professional',
      'bluewave_tech': 'Bluewave Tech',
      'balanced_two_column_layout': 'Balanced two-column layout',
      'elegant_gold_layout': 'Human Resources Resume',
      'corporate_navy': 'Corporate Navy',
      'forest_edge_classic': 'Forest Edge Classic',
      'forest_edge': 'Forest Edge',
    };
    return names[templateId] ?? 'Not selected';
  }

  Widget _buildTemplateTile(BuildContext context, ResumeModel resume) {
    final templateId = resume.templateId;
    return GestureDetector(
      onTap: () async {
        await context.push('/templates/${widget.resumeId}');
        if (mounted) {
          ref
              .read(currentResumeProvider(widget.resumeId).notifier)
              .loadResume();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.brush_2,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume Template',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _templateName(templateId),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingLanguageTile(BuildContext context, ResumeModel resume) {
    final lang = resume.writingLanguage;
    final flag = ResumeTranslations.supportedLanguages.firstWhere(
        (l) => l['name'] == lang,
        orElse: () => {'flag': '🌐'})['flag']!;

    return GestureDetector(
      onTap: () => _pickWritingLanguage(context, resume),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              const Color(0xFF0EA5E9).withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume Language',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang,
                    style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontTile(BuildContext context, ResumeModel resume) {
    return GestureDetector(
      onTap: () {
        if (!FreePlanService.canCustomizeFonts) {
          _showPlanUpgrade(
            'font_customization',
            FreePlanService.premiumFontMessage,
          );
          return;
        }

        showFontPicker(
          context: context,
          currentFont: resume.fontFamily,
          onSelected: (font) {
            final updated = resume.copyWith(fontFamily: font);
            ref
                .read(currentResumeProvider(widget.resumeId).notifier)
                .updateResume(updated);
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              const Color(0xFF8B5CF6).withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child:
                  const Icon(Iconsax.text, color: Color(0xFF8B5CF6), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Font Family',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(resume.fontFamily,
                        style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Change',
                  style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorThemeTile(BuildContext context, ResumeModel resume) {
    final theme = kResumeColorThemes[resume.colorScheme];
    return GestureDetector(
      onTap: () => showColorThemePicker(
        context: context,
        currentScheme: resume.colorScheme,
        allowedSchemes: FreePlanService.isPremium
            ? null
            : FreePlanService.freeColorSchemeIds,
        onSelected: (scheme) {
          final updated = resume.copyWith(colorScheme: scheme);
          ref
              .read(currentResumeProvider(widget.resumeId).notifier)
              .updateResume(updated);
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (theme?.color ?? AppColors.primary).withValues(alpha: 0.08),
              (theme?.color ?? AppColors.primary).withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: (theme?.color ?? AppColors.primary).withValues(alpha: 0.3),
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: (theme?.color ?? AppColors.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Iconsax.colorfilter,
                  color: theme?.color ?? AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Color Theme',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(theme?.name ?? 'Indigo',
                        style: TextStyle(
                            color: theme?.color ?? AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ]),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: theme?.color ?? AppColors.primary,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: (theme?.color ?? AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Change',
                  style: TextStyle(
                      color: theme?.color ?? AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutTile(BuildContext context, ResumeModel resume) {
    final layout = kResumeLayouts[resume.layoutStyle];
    return GestureDetector(
      onTap: () {
        if (!FreePlanService.canCustomizeLayouts) {
          _showPlanUpgrade(
            'layout_customization',
            FreePlanService.premiumLayoutMessage,
          );
          return;
        }

        showLayoutPicker(
          context: context,
          currentLayout: resume.layoutStyle,
          resume: resume,
          onSelected: (style) {
            final templateId = resolveTemplateForLayoutStyle(
              layoutStyle: style,
              currentTemplateId: resume.templateId,
            );

            final updated = resume.copyWith(
              layoutStyle: style,
              templateId: templateId,
            );
            ref
                .read(currentResumeProvider(widget.resumeId).notifier)
                .updateResume(updated);
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.08),
              AppColors.accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                layout?.icon ?? Iconsax.document_text,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Layout Style',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    layout?.label ?? 'Standard',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickWritingLanguage(BuildContext context, ResumeModel resume) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Iconsax.translate, size: 20),
                    const SizedBox(width: 8),
                    Text('Resume Writing Language',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Preview and export will translate your resume into this language. Names, company names, schools, links, and skill tags stay as entered, while section headers and narrative content are localized automatically.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: ResumeTranslations.supportedLanguages.length,
                  itemBuilder: (_, i) {
                    final l = ResumeTranslations.supportedLanguages[i];
                    final name = l['name']!;
                    final flag = l['flag']!;
                    final selected = name == resume.writingLanguage;
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(name,
                          style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal)),
                      trailing: selected
                          ? const Icon(Iconsax.tick_circle,
                              color: Color(0xFF0EA5E9), size: 20)
                          : null,
                      onTap: () {
                        final updated = resume.copyWith(writingLanguage: name);
                        ref
                            .read(
                                currentResumeProvider(widget.resumeId).notifier)
                            .updateResume(updated);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns section keys in the order that best fits the selected template
  List<String> _getSectionOrder(ResumeModel resume) {
    switch (resume.templateId) {
      case 'blue_gray':
      case 'two_column':
        // Sidebar templates: personal/contact + sidebar items first, then main content
        return [
          'personal',
          'summary',
          'experience',
          'education',
          'projects',
          'skills',
          'languages',
          'certifications'
        ];
      case 'developer':
        return [
          'personal',
          'skills',
          'experience',
          'projects',
          'education',
          'certifications',
          'languages',
          'summary'
        ];
      case 'academic':
        return [
          'personal',
          'summary',
          'education',
          'skills',
          'experience',
          'projects',
          'certifications',
          'languages'
        ];
      case 'startup':
        return [
          'personal',
          ...startupSectionOrder(resume),
        ];
      case 'executive_classic':
        return [
          'personal',
          'summary',
          'experience',
          'education',
          'skills',
          'certifications',
          'languages',
          'projects'
        ];
      case 'executive':
        return [
          'personal',
          'summary',
          ...professionalRoleOptionalSectionKeys(resume),
          'experience',
          'skills',
          'projects',
          'certifications',
          'education',
          'languages'
        ];
      case 'designer_profile':
        return [
          'personal',
          'summary',
          ...professionalRoleOptionalSectionKeys(resume),
          'projects',
          'experience',
          'skills',
          'certifications',
          'education',
          'languages'
        ];
      case 'professional_tone':
        return [
          'personal',
          'summary',
          ...professionalRoleOptionalSectionKeys(resume),
          'experience',
          'skills',
          'certifications',
          'education',
          'projects',
          'languages'
        ];
      case 'elegant_gold_layout':
        return [
          'personal',
          'summary',
          ...professionalRoleOptionalSectionKeys(resume),
          'experience',
          'skills',
          'projects',
          'certifications',
          'education',
          'languages'
        ];
      case 'sales':
        return [
          'personal',
          'summary',
          'experience',
          'education',
          'skills',
          'projects',
          'certifications',
          'languages'
        ];
      default:
        return [
          'personal',
          'summary',
          'experience',
          'education',
          'skills',
          'projects',
          'certifications',
          'languages'
        ];
    }
  }

  /// Returns a small badge label for templates with a sidebar layout
  String? _getSidebarBadge(String templateId, String sectionKey) {
    const sidebarTemplates = ['blue_gray', 'two_column'];
    if (!sidebarTemplates.contains(templateId)) return null;
    const sidebarSections = {
      'personal',
      'skills',
      'languages',
      'certifications'
    };
    return sidebarSections.contains(sectionKey) ? 'Sidebar' : 'Main';
  }

  List<String> _availableSectionKeys(ResumeModel resume) {
    final baseKeys = [
      ..._getSectionOrder(resume),
      ...orderedUserCustomSections(resume)
          .map((section) => section.id)
          ,
    ];
    final deduped = <String>[];
    for (final key in baseKeys) {
      if (!deduped.contains(key)) {
        deduped.add(key);
      }
    }
    return deduped;
  }

  List<String> _normalizedSectionOrderForResume(ResumeModel resume) {
    final available = _availableSectionKeys(resume);
    final custom = _customSectionOrder ?? const <String>[];
    final preserved = custom.where(available.contains).toList();
    final missing = available.where((key) => !preserved.contains(key)).toList();
    return [...preserved, ...missing];
  }

  String _sectionLabelForKey(String key) {
    if (isUserCustomSectionId(key)) {
      final resume = ref.read(currentResumeProvider(widget.resumeId));
      if (resume != null) {
        for (final section in resume.customSections) {
          if (section.id == key) {
            final title = normalizeUserCustomSectionTitle(section.title);
            return title.isEmpty ? 'Custom Section' : title;
          }
        }
      }
      return 'Custom Section';
    }

    return _kSectionLabels[key] ??
        startupSectionConfigById(key)?.title ??
        professionalRoleSectionConfigById(
          ref.read(currentResumeProvider(widget.resumeId))?.templateId ?? '',
          key,
        )?.title ??
        key;
  }

  IconData _sectionIconForKey(String key) {
    if (isUserCustomSectionId(key)) {
      return Iconsax.note_2;
    }

    return _kSectionIcons[key] ??
        _kStartupSectionIcons[key] ??
        _kProfessionalRoleSectionIcons[key] ??
        Iconsax.document;
  }

  Color _sectionColorForKey(String key) {
    final configured = _kSectionColors[key];
    if (configured != null) {
      return configured;
    }
    if (isUserCustomSectionId(key)) {
      final hash = key.codeUnits.fold<int>(0, (value, unit) => value + unit);
      return _kUserCustomSectionPalette[
          hash % _kUserCustomSectionPalette.length];
    }
    return AppColors.primary;
  }

  bool _sameCustomSections(
    List<CustomSection> current,
    List<CustomSection> next,
  ) {
    if (identical(current, next)) {
      return true;
    }
    if (current.length != next.length) {
      return false;
    }
    for (var index = 0; index < current.length; index++) {
      final left = current[index];
      final right = next[index];
      if (left.id != right.id || left.title != right.title) {
        return false;
      }
    }
    return true;
  }

  void _ensureStartupOptionalSections(ResumeModel resume) {
    if (resume.templateId != 'startup') {
      return;
    }

    final ensured = ensureStartupProfileSections(resume);
    if (_sameCustomSections(resume.customSections, ensured)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(resume.copyWith(customSections: ensured));
    });
  }

  void _ensureProfessionalOptionalSections(ResumeModel resume) {
    if (!const {
      'executive',
      'designer_profile',
      'professional_tone',
      'elegant_gold_layout',
    }.contains(resume.templateId)) {
      return;
    }

    final ensured = ensureProfessionalRoleSections(resume);
    if (_sameCustomSections(resume.customSections, ensured)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(resume.copyWith(customSections: ensured));
    });
  }

  Widget _buildResumeFormatTile(BuildContext context) {
    final formatData = {
      'chronological': {
        'label': 'Chronological',
        'icon': Iconsax.calendar,
        'color': AppColors.primary,
      },
      'functional': {
        'label': 'Functional',
        'icon': Iconsax.chart_success,
        'color': const Color(0xFF10B981),
      },
      'hybrid': {
        'label': 'Hybrid',
        'icon': Iconsax.element_4,
        'color': const Color(0xFF8B5CF6),
      },
    };
    final data = formatData[_resumeFormat] ?? formatData['chronological']!;
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;
    final label = data['label'] as String;

    return GestureDetector(
      onTap: () => _showFormatPicker(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.04)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resume Format',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Change',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserCustomSectionTile(
    BuildContext context,
    ResumeModel resume,
  ) {
    final userSectionCount = orderedUserCustomSections(resume).length;
    return SectionTile(
      icon: Iconsax.add,
      title: userSectionCount == 0
          ? 'Add Custom Section'
          : 'Add Another Custom Section',
      subtitle: userSectionCount == 0
          ? 'Create sections like Awards, Publications, Leadership, or Volunteering.'
          : 'Create another custom section. Current custom sections: $userSectionCount.',
      isCompleted: false,
      isLocked: !FreePlanService.canEditSection(kUserCustomSectionFeatureKey),
      color: const Color(0xFF7C3AED),
      onTap: () => _showAddUserCustomSectionSheet(context, resume),
    );
  }

  List<Widget> _buildOrderedSections(BuildContext context, ResumeModel resume) {
    _ensureStartupOptionalSections(resume);
    _ensureProfessionalOptionalSections(resume);

    // Use custom drag-drop order if set, otherwise fall back to template-default order
    final order = _normalizedSectionOrderForResume(resume);
    final orderedUserSections =
        _orderedUserCustomSectionsForKeys(resume, order);
    final tiles = <String, Widget Function()>{
      'personal': () => SectionTile(
            icon: Iconsax.user,
            title: 'Personal Information',
            subtitle: resume.personalInfo.fullName.isEmpty
                ? 'Add your contact details'
                : resume.personalInfo.fullName,
            isCompleted: resume.personalInfo.fullName.isNotEmpty &&
                resume.personalInfo.email.isNotEmpty,
            color: const Color(0xFF6366F1),
            badge: _getSidebarBadge(resume.templateId, 'personal'),
            onTap: () => _openSectionOrUpgrade(
              'personal',
              '/editor/${widget.resumeId}/personal',
            ),
          ),
      'summary': () => SectionTile(
            icon: Iconsax.document_text,
            title: 'Professional Summary',
            subtitle: resume.objective?.isEmpty ?? true
                ? 'Add a compelling summary'
                : 'Summary added',
            isCompleted: resume.objective?.isNotEmpty ?? false,
            color: const Color(0xFF8B5CF6),
            badge: _getSidebarBadge(resume.templateId, 'summary'),
            onTap: () => _openSectionOrUpgrade(
              'summary',
              '/editor/${widget.resumeId}/summary',
            ),
          ),
      'experience': () => SectionTile(
            icon: Iconsax.briefcase,
            title: 'Work Experience',
            subtitle: resume.experience.isEmpty
                ? 'Add your work history'
                : '${resume.experience.length} experience(s) added',
            isCompleted: resume.experience.isNotEmpty,
            color: const Color(0xFF10B981),
            badge: _getSidebarBadge(resume.templateId, 'experience'),
            onTap: () => _openSectionOrUpgrade(
              'experience',
              '/editor/${widget.resumeId}/experience',
            ),
          ),
      'education': () => SectionTile(
            icon: Iconsax.teacher,
            title: 'Education',
            subtitle: resume.education.isEmpty
                ? 'Add your education'
                : '${resume.education.length} education(s) added',
            isCompleted: resume.education.isNotEmpty,
            color: const Color(0xFF0EA5E9),
            badge: _getSidebarBadge(resume.templateId, 'education'),
            onTap: () => _openSectionOrUpgrade(
              'education',
              '/editor/${widget.resumeId}/education',
            ),
          ),
      'skills': () => SectionTile(
            icon: Iconsax.code,
            title: 'Skills',
            subtitle: resume.skills.isEmpty
                ? 'Add your skills'
                : '${resume.skills.length} skill(s) added',
            isCompleted: resume.skills.isNotEmpty,
            color: const Color(0xFFF59E0B),
            badge: _getSidebarBadge(resume.templateId, 'skills'),
            onTap: () => _openSectionOrUpgrade(
              'skills',
              '/editor/${widget.resumeId}/skills',
            ),
          ),
      'projects': () => SectionTile(
            icon: Iconsax.folder_open,
            title: 'Projects',
            subtitle: resume.projects.isEmpty
                ? 'Add your projects'
                : '${resume.projects.length} project(s) added',
            isCompleted: resume.projects.isNotEmpty,
            isLocked: !FreePlanService.canEditSection('projects'),
            color: const Color(0xFFEC4899),
            badge: _getSidebarBadge(resume.templateId, 'projects'),
            onTap: () => _openSectionOrUpgrade(
              'projects',
              '/editor/${widget.resumeId}/projects',
            ),
          ),
      'certifications': () => SectionTile(
            icon: Iconsax.medal_star,
            title: 'Certifications',
            subtitle: resume.certifications.isEmpty
                ? 'Add your certifications'
                : '${resume.certifications.length} certification(s) added',
            isCompleted: resume.certifications.isNotEmpty,
            isLocked: !FreePlanService.canEditSection('certifications'),
            color: const Color(0xFF14B8A6),
            badge: _getSidebarBadge(resume.templateId, 'certifications'),
            onTap: () => _openSectionOrUpgrade(
              'certifications',
              '/editor/${widget.resumeId}/certifications',
            ),
          ),
      'languages': () => SectionTile(
            icon: Iconsax.translate,
            title: 'Languages',
            subtitle: resume.languages.isEmpty
                ? 'Add languages you know'
                : '${resume.languages.length} language(s) added',
            isCompleted: resume.languages.isNotEmpty,
            isLocked: !FreePlanService.canEditSection('languages'),
            color: const Color(0xFF64748B),
            badge: _getSidebarBadge(resume.templateId, 'languages'),
            onTap: () => _openSectionOrUpgrade(
              'languages',
              '/editor/${widget.resumeId}/languages',
            ),
          ),
    };

    for (final section in ensureStartupProfileSections(resume)
        .where((entry) => isStartupOptionalSectionKey(entry.id))) {
      final config = startupSectionConfigById(section.id);
      tiles[section.id] = () => SectionTile(
            icon: _sectionIconForKey(section.id),
            title: config?.title ?? section.title,
            subtitle: section.items.isEmpty
                ? '${config?.description ?? 'Add optional profile-specific details.'} Recommended for ${startupProfileLabel(detectStartupProfileType(resume))} profiles.'
                : '${section.items.length} item(s) added',
            isCompleted: section.items.isNotEmpty,
            isLocked: !FreePlanService.canEditSection(section.id),
            color: _sectionColorForKey(section.id),
            onTap: () => _openSectionOrUpgrade(
              section.id,
              '/editor/${widget.resumeId}/custom/${section.id}',
            ),
          );
    }

    for (final section in ensureProfessionalRoleSections(resume).where(
        (entry) => isProfessionalRoleOptionalSectionKey(
            resume.templateId, entry.id))) {
      final config = professionalRoleSectionConfigById(
        resume.templateId,
        section.id,
      );
      tiles[section.id] = () => SectionTile(
            icon: _sectionIconForKey(section.id),
            title: config?.title ?? section.title,
            subtitle: section.items.isEmpty
                ? config?.description ?? 'Add role-specific supporting details.'
                : '${section.items.length} item(s) added',
            isCompleted: section.items.isNotEmpty,
            isLocked: !FreePlanService.canEditSection(section.id),
            color: _sectionColorForKey(section.id),
            onTap: () => _openSectionOrUpgrade(
              section.id,
              '/editor/${widget.resumeId}/custom/${section.id}',
            ),
          );
    }

    for (final section in orderedUserSections) {
      final color = _sectionColorForKey(section.id);
      final itemCount = section.items.length;
      final subtitle = itemCount == 0
          ? 'No entries yet. Add content to include this section in preview.'
          : '$itemCount entr${itemCount == 1 ? 'y' : 'ies'} | ${userCustomSectionItemPreview(section.items.first)}';

      tiles[section.id] = () => UserCustomSectionTile(
            title: normalizeUserCustomSectionTitle(section.title).isEmpty
                ? 'Custom Section'
                : normalizeUserCustomSectionTitle(section.title),
            subtitle: subtitle,
            itemCount: itemCount,
            color: color,
            onTap: () => _openSectionOrUpgrade(
              kUserCustomSectionFeatureKey,
              '/editor/${widget.resumeId}/user-custom/${section.id}',
            ),
            onRename: () =>
                _showRenameUserCustomSectionSheet(context, resume, section),
            onDelete: () => _deleteUserCustomSection(context, resume, section),
            dragHandle: const Icon(
              Iconsax.menu,
              color: AppColors.textTertiary,
              size: 18,
            ),
          );
    }

    return order
        .asMap()
        .entries
        .where((e) => tiles.containsKey(e.value))
        .map((e) => tiles[e.value]!()
            .animate()
            .fadeIn(delay: ((e.key + 1) * 50).ms, duration: 400.ms)
            .slideX(begin: 0.1, end: 0))
        .toList();
  }
}

/// Bottom-sheet option row for AI tools
class _AiSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLocked;
  final VoidCallback onTap;

  const _AiSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isLocked ? Iconsax.lock_1 : Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
