import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/app_empty_state_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/resume_card.dart';

class ResumesTabScreen extends ConsumerWidget {
  const ResumesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumes = ref.watch(resumesProvider);

    return Scaffold(
      body: ResponsiveContent(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.paddingOf(context).bottom +
                  kBottomNavigationBarHeight +
                  24,
            ),
            children: [
              _ResumesHeader(
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                    return;
                  }
                  ref.read(currentTabProvider.notifier).state = 0;
                },
                onCreate: () => _createNewResume(context, ref),
              ),
              const SizedBox(height: 20),
              if (resumes.isEmpty)
                const AppEmptyStateCard(
                  icon: Iconsax.document_text,
                  accentColor: AppColors.primary,
                  title: 'No resumes yet',
                  message:
                      'Create your first resume to start editing, previewing, and exporting.',
                )
              else
                ...resumes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final resume = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ResumeCard(
                      resume: resume,
                      onTap: () => context.go('/editor/${resume.id}'),
                      onDelete: () => _showDeleteDialog(context, ref, resume),
                      onDuplicate: () => _duplicateResume(context, ref, resume),
                      onPreview: () => context.push('/preview/${resume.id}'),
                      onDownload: () => context.push('/preview/${resume.id}'),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (index * 50).ms)
                      .slideY(begin: 0.1, end: 0);
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _duplicateResume(
    BuildContext context,
    WidgetRef ref,
    ResumeModel resume,
  ) async {
    try {
      await ref.read(resumesProvider.notifier).duplicateResume(resume);
    } on StateError {
      if (context.mounted) {
        showUpgradePromptSheet(
          context,
          featureName: 'multiple_resumes',
          message: FreePlanService.resumeLimitMessage,
        );
      }
    }
  }

  void _createNewResume(BuildContext context, WidgetRef ref) async {
    try {
      final resume = await ref.read(resumesProvider.notifier).createResume();
      if (context.mounted) {
        context.push('/templates/${resume.id}?isNew=true');
      }
    } on StateError {
      if (context.mounted) {
        showUpgradePromptSheet(
          context,
          featureName: 'create_resume',
          message: FreePlanService.resumeLimitMessage,
        );
      }
    }
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ResumeModel resume) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resume?'),
        content: Text(
          'Are you sure you want to delete "${resume.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(resumesProvider.notifier).deleteResume(resume.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ResumesHeader extends StatelessWidget {
  const _ResumesHeader({
    required this.onBack,
    required this.onCreate,
  });

  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;
        final headerFontSize = isNarrow ? 16.0 : 17.0;
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: headerFontSize,
              height: 1,
            );
        final buttonTextStyle =
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: headerFontSize,
                  height: 1,
                );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Iconsax.arrow_left),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Resumes',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: titleStyle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: isNarrow ? 42 : 44,
                maxWidth: isNarrow ? 164 : 184,
              ),
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: Icon(Iconsax.add, size: isNarrow ? 15 : 16),
                label: Text(
                  'Create New',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: buttonTextStyle,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 10 : 12,
                    vertical: isNarrow ? 10 : 11,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  alignment: Alignment.center,
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
