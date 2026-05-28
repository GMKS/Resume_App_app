import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import '../widgets/user_custom_section_action_bar.dart';
import 'resume_editor_screen.dart';

class UserCustomSectionScreen extends ConsumerStatefulWidget {
  final String resumeId;
  final String sectionId;

  const UserCustomSectionScreen({
    super.key,
    required this.resumeId,
    required this.sectionId,
  });

  @override
  ConsumerState<UserCustomSectionScreen> createState() =>
      _UserCustomSectionScreenState();
}

class _UserCustomSectionScreenState
    extends ConsumerState<UserCustomSectionScreen> {
  CustomSection? _currentSection(ResumeModel resume) {
    for (final section in orderedUserCustomSections(resume)) {
      if (section.id == widget.sectionId) {
        return section;
      }
    }
    return null;
  }

  Future<void> _persistSection(
      ResumeModel resume, CustomSection updated) async {
    final latestResume =
        ref.read(currentResumeProvider(widget.resumeId)) ?? resume;
    final userSections = orderedUserCustomSections(latestResume);
    final index =
        userSections.indexWhere((section) => section.id == updated.id);
    if (index == -1) {
      return;
    }

    final nextUserSections = List<CustomSection>.from(userSections);
    nextUserSections[index] =
        updated.copyWith(order: userSections[index].order);

    await ref
        .read(currentResumeProvider(widget.resumeId).notifier)
        .updateResume(
          latestResume.copyWith(
            customSections: mergeUserCustomSections(
              existingSections: latestResume.customSections,
              orderedUserSections: nextUserSections,
            ),
          ),
        );
  }

  Future<void> _showTitleEditor(
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
                        'Edit Section Title',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    controller: controller,
                    label: 'Section Title',
                    hint: 'Awards, Publications, Leadership Experience...',
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
                                  'A custom section with this title already exists'),
                            ),
                          );
                          return;
                        }

                        await _persistSection(
                          resume,
                          section.copyWith(title: title),
                        );
                        if (!sheetContext.mounted) {
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

  Future<void> _showItemEditor(
    BuildContext context,
    ResumeModel resume,
    CustomSection section, {
    CustomSectionItem? existing,
  }) async {
    final contentController = TextEditingController(
      text: existing == null
          ? ''
          : userCustomSectionItemLines(existing).join('\n'),
    );

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
                        existing == null ? 'Add Entry' : 'Edit Entry',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    controller: contentController,
                    label: 'Description / Content',
                    hint: 'Add text or bullet points for this section entry',
                    prefixIcon: Iconsax.document_text,
                    maxLines: 6,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final content = contentController.text.trim();
                        if (content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Entry content is required'),
                            ),
                          );
                          return;
                        }

                        final item = buildUserCustomSectionItem(
                          id: existing?.id,
                          content: content,
                        );

                        final items =
                            List<CustomSectionItem>.from(section.items);
                        final index = items.indexWhere(
                          (entry) => entry.id == item.id,
                        );
                        if (index == -1) {
                          items.add(item);
                        } else {
                          items[index] = item;
                        }

                        await _persistSection(
                          resume,
                          section.copyWith(items: items),
                        );
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.pop(sheetContext);
                      },
                      child:
                          Text(existing == null ? 'Add Entry' : 'Save Entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    contentController.dispose();
  }

  Future<void> _deleteItem(
    ResumeModel resume,
    CustomSection section,
    CustomSectionItem item,
  ) async {
    final items = section.items.where((entry) => entry.id != item.id).toList();
    await _persistSection(resume, section.copyWith(items: items));
  }

  Future<void> _deleteSection(
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

    final latestResume =
        ref.read(currentResumeProvider(widget.resumeId)) ?? resume;
    final remaining = orderedUserCustomSections(latestResume)
        .where((entry) => entry.id != section.id)
        .toList(growable: false);

    await ref
        .read(currentResumeProvider(widget.resumeId).notifier)
        .updateResume(
          latestResume.copyWith(
            customSections: mergeUserCustomSections(
              existingSections: latestResume.customSections,
              orderedUserSections: remaining,
            ),
          ),
        );

    if (!context.mounted) {
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    if (resume == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!FreePlanService.canEditSection(kUserCustomSectionFeatureKey)) {
      return const Scaffold(
        body: SafeArea(
          child: UpgradePromptCard(
            featureName: 'premium_sections',
            message: 'Premium feature. Upgrade to edit this section.',
          ),
        ),
      );
    }

    final section = _currentSection(resume);
    if (section == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
          title: const Text('Custom Section'),
        ),
        body: const Center(
          child: Text('This custom section could not be found.'),
        ),
      );
    }

    final totalLines = section.items
        .expand(userCustomSectionItemLines)
        .where((line) => line.trim().isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: Text(displayUserCustomSectionTitle(section)),
        actions: [
          IconButton(
            tooltip: 'Rename section',
            onPressed: () => _showTitleEditor(context, resume, section),
            icon: const Icon(Iconsax.edit_2),
          ),
          IconButton(
            tooltip: 'Delete section',
            onPressed: () => _deleteSection(context, resume, section),
            icon: const Icon(Iconsax.trash),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EditorIntroCard(
            title: displayUserCustomSectionTitle(section),
            subtitle: section.items.isEmpty
                ? 'This custom section is saved but still empty. Add entries when you are ready and they will flow into preview, PDF, and exports.'
                : '${section.items.length} custom entr${section.items.length == 1 ? 'y' : 'ies'} are attached to this resume and will render anywhere the template supports user-defined sections.',
            icon: Iconsax.note_2,
            accentColor: AppColors.primary,
            stats: [
              EditorIntroStat(
                label: '${section.items.length} entries',
                icon: Iconsax.document_text,
              ),
              EditorIntroStat(
                label: '$totalLines text lines',
                icon: Iconsax.menu_board,
              ),
              const EditorIntroStat(
                label: 'user-defined section',
                icon: Iconsax.edit_2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formatting Guidance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep each entry concise and structured. Multi-line entries are preserved in preview and exports, so short readable lines work best.',
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
                  const Icon(
                    Iconsax.document_upload,
                    size: 36,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first entry to start filling this custom section.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showItemEditor(context, resume, section),
                    icon: const Icon(Iconsax.add),
                    label: const Text('Add First Entry'),
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
                            child: Text(
                              userCustomSectionItemPreview(item),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...userCustomSectionItemLines(item).map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  line,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      EditorStatPill(
                        label:
                            '${userCustomSectionItemLines(item).where((line) => line.trim().isNotEmpty).length} lines',
                        icon: Iconsax.menu_board,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: UserCustomSectionActionBar(
        onPressed: () => _showItemEditor(context, resume, section),
      ),
    );
  }
}
