import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/startup_profile_sections.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class CustomSectionScreen extends ConsumerStatefulWidget {
  final String resumeId;
  final String sectionId;

  const CustomSectionScreen({
    super.key,
    required this.resumeId,
    required this.sectionId,
  });

  @override
  ConsumerState<CustomSectionScreen> createState() => _CustomSectionScreenState();
}

class _CustomSectionScreenState extends ConsumerState<CustomSectionScreen> {
  String? _configTitle(Object? config) {
    if (config is StartupOptionalSectionConfig) {
      return config.title;
    }
    if (config is ProfessionalRoleSectionConfig) {
      return config.title;
    }
    return null;
  }

  String? _configDescription(Object? config) {
    if (config is StartupOptionalSectionConfig) {
      return config.description;
    }
    if (config is ProfessionalRoleSectionConfig) {
      return config.description;
    }
    return null;
  }

  String? _configEmptyPrompt(Object? config) {
    if (config is StartupOptionalSectionConfig) {
      return config.emptyPrompt;
    }
    if (config is ProfessionalRoleSectionConfig) {
      return config.emptyPrompt;
    }
    return null;
  }

  Future<void> _saveSection(ResumeModel resume, CustomSection section) async {
    final latestResume = ref.read(currentResumeProvider(widget.resumeId)) ?? resume;
    final baseResume = latestResume.templateId == 'startup'
        ? latestResume.copyWith(
            customSections: ensureStartupProfileSections(latestResume),
          )
        : ['executive', 'designer_profile', 'professional_tone', 'elegant_gold_layout'].contains(latestResume.templateId)
        ? latestResume.copyWith(
            customSections: ensureProfessionalRoleSections(latestResume),
          )
        : latestResume;
    final sections = List<CustomSection>.from(baseResume.customSections);
    final index = sections.indexWhere((item) => item.id == section.id);
    if (index == -1) {
      sections.add(section);
    } else {
      sections[index] = section;
    }

    await ref
        .read(currentResumeProvider(widget.resumeId).notifier)
      .updateResume(baseResume.copyWith(customSections: sections));
  }

  Future<void> _showItemEditor(
    BuildContext context,
    ResumeModel resume,
    CustomSection section, {
    CustomSectionItem? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController = TextEditingController(text: existing?.subtitle ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        existing == null ? 'Add Item' : 'Edit Item',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                    controller: titleController,
                    label: 'Title',
                    hint: 'Enter the headline for this item',
                    prefixIcon: Iconsax.document_text,
                  ),
                  CustomTextField(
                    controller: subtitleController,
                    label: 'Subtitle',
                    hint: 'Company, institution, credential, or context',
                    prefixIcon: Iconsax.note,
                  ),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'Add details, impact, or supporting notes',
                    maxLines: 4,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Title is required')),
                          );
                          return;
                        }

                        final item = CustomSectionItem(
                          id: existing?.id ?? const Uuid().v4(),
                          title: title,
                          subtitle: subtitleController.text.trim().isEmpty
                              ? null
                              : subtitleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          date: existing?.date,
                        );

                        final items = List<CustomSectionItem>.from(section.items);
                        final index = items.indexWhere((entry) => entry.id == item.id);
                        if (index == -1) {
                          items.add(item);
                        } else {
                          items[index] = item;
                        }

                        await _saveSection(
                          resume,
                          section.copyWith(items: items),
                        );

                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.pop(sheetContext);
                      },
                      child: Text(existing == null ? 'Add Item' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    titleController.dispose();
    subtitleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteItem(
    ResumeModel resume,
    CustomSection section,
    CustomSectionItem item,
  ) async {
    final items = section.items.where((entry) => entry.id != item.id).toList();
    await _saveSection(resume, section.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!FreePlanService.canEditSection(widget.sectionId)) {
      return const Scaffold(
        body: SafeArea(
          child: UpgradePromptCard(
            featureName: 'premium_sections',
            message: 'Premium feature. Upgrade to edit this section.',
          ),
        ),
      );
    }

    final config = startupSectionConfigById(widget.sectionId) ??
        professionalRoleSectionConfigById(resume.templateId, widget.sectionId);
    final section = resume.customSections.firstWhere(
      (item) => item.id == widget.sectionId,
      orElse: () => CustomSection(
        id: widget.sectionId,
      title: _configTitle(config) ?? 'Custom Section',
      ),
    );

    final title = section.title.trim().isNotEmpty
        ? section.title
      : _configTitle(config) ?? 'Custom Section';
    final description =
      _configDescription(config) ?? 'Add structured supporting details.';
    final emptyPrompt =
      _configEmptyPrompt(config) ?? 'Add your first item for this section.';
    final entriesWithSubtitle = section.items
        .where((item) => (item.subtitle ?? '').trim().isNotEmpty)
        .length;
    final entriesWithDescription = section.items
        .where((item) => (item.description ?? '').trim().isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: () => _showItemEditor(context, resume, section),
            icon: const Icon(Iconsax.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EditorIntroCard(
            title: title,
            subtitle:
                '$description This section stays tied to your resume data and will appear in preview, PDF, and export wherever the template supports it.',
            icon: Iconsax.note_2,
            accentColor: AppColors.primary,
            stats: [
              EditorIntroStat(
                label: '${section.items.length} items',
                icon: Iconsax.document_text,
              ),
              EditorIntroStat(
                label: '$entriesWithSubtitle with subtitle',
                icon: Iconsax.note,
              ),
              EditorIntroStat(
                label: '$entriesWithDescription with detail',
                icon: Iconsax.menu_board,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section Impact',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use concise titles and supporting lines so this custom section reads clearly when it is injected into the preview layout.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (section.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Iconsax.document_upload, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    emptyPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showItemEditor(context, resume, section),
                    icon: const Icon(Iconsax.add),
                    label: const Text('Add First Item'),
                  ),
                ],
              ),
            )
          else
            ...section.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if ((item.subtitle ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.subtitle!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showItemEditor(
                                  context,
                                  resume,
                                  section,
                                  existing: item,
                                );
                              }
                              if (value == 'delete') {
                                _deleteItem(resume, section, item);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      if ((item.description ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            item.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if ((item.subtitle ?? '').trim().isNotEmpty)
                            const EditorStatPill(
                              label: 'context added',
                              icon: Iconsax.note,
                              color: AppColors.primary,
                            ),
                          if ((item.description ?? '').trim().isNotEmpty)
                            const EditorStatPill(
                              label: 'detail added',
                              icon: Iconsax.menu_board,
                              color: AppColors.info,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemEditor(context, resume, section),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Item'),
      ),
    );
  }
}