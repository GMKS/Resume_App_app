import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/resume_card.dart';

class ResumesTabScreen extends ConsumerWidget {
  const ResumesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumes = ref.watch(resumesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
      ),
      body: resumes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.document_text,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No resumes yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first resume',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resumes.length,
              itemBuilder: (context, index) {
                final resume = resumes[index];
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
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewResume(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'New Resume',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
