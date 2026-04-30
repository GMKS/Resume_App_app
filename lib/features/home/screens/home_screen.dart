import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_sync_service.dart';
import '../../../core/utils/cloud_resume_sync.dart';
import '../widgets/stats_card.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../shared/widgets/feature_gate.dart';

// Provider for resumes list
final resumesProvider =
    StateNotifierProvider<ResumesNotifier, List<ResumeModel>>((ref) {
  return ResumesNotifier();
});

class ResumesNotifier extends StateNotifier<List<ResumeModel>> {
  ResumesNotifier() : super([]) {
    loadResumes();
  }

  void loadResumes() {
    state = StorageService.getAllResumes()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Restores resumes from Supabase into local Hive storage then refreshes.
  Future<void> restoreFromCloud() async {
    final cloudResumes = await SupabaseSyncService.loadAll();
    for (final resume in cloudResumes) {
      final local = StorageService.getResume(resume.id);
      if (shouldApplyCloudResume(
        localResume: local,
        cloudResume: resume,
      )) {
        await StorageService.saveResume(resume);
      }
    }
    loadResumes();
  }

  Future<ResumeModel> createResume() async {
    final resume = ResumeModel(
      id: const Uuid().v4(),
      title: 'My Resume ${state.length + 1}',
      personalInfo: PersonalInfo(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await StorageService.saveResume(resume);
    loadResumes();
    return resume;
  }

  Future<void> deleteResume(String id) async {
    await StorageService.deleteResume(id);
    loadResumes();
  }

  Future<void> duplicateResume(ResumeModel resume) async {
    final newResume = ResumeModel(
      id: const Uuid().v4(),
      title: '${resume.title} (Copy)',
      personalInfo: resume.personalInfo,
      objective: resume.objective,
      education: List.from(resume.education),
      experience: List.from(resume.experience),
      skills: List.from(resume.skills),
      projects: List.from(resume.projects),
      certifications: List.from(resume.certifications),
      languages: List.from(resume.languages),
      hobbies: List.from(resume.hobbies),
      references: List.from(resume.references),
      templateId: resume.templateId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorScheme: resume.colorScheme,
      customSections: resume.customSections
          .map(
            (section) => section.copyWith(
              items: section.items
                  .map((item) => item.copyWith())
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
    await StorageService.saveResume(newResume);
    loadResumes();
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Restore from Supabase cloud on startup (handles reinstall / cache clear).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resumesProvider.notifier).restoreFromCloud();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createNewResume() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Resume'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Give your resume a name:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Software Engineer, Product Manager...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _submitNewResume(nameController.text, ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitNewResume(nameController.text, ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewResume(String name, BuildContext dialogContext) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resume name')),
      );
      return;
    }
    
    Navigator.pop(dialogContext);
    
    final resume = ResumeModel(
      id: const Uuid().v4(),
      title: trimmedName,
      personalInfo: PersonalInfo(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await StorageService.saveResume(resume);
      ref.read(resumesProvider.notifier).loadResumes();
    } on StateError {
      if (mounted) {
        showUpgradePromptSheet(
          context,
          featureName: 'multiple_resumes',
          message: FreePlanService.resumeLimitMessage,
        );
      }
      return;
    }
    
    if (mounted) {
      context.go('/editor/${resume.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumes = ref.watch(resumesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello! 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resume Builder',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.push('/settings'),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                              ),
                              icon: const Icon(
                                Iconsax.setting_2,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            icon: Iconsax.document_text_1,
                            title: '${resumes.length}',
                            subtitle: 'Total Resumes',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            icon: Iconsax.tick_circle,
                            title:
                                '${resumes.where((r) => r.completionPercentage == 100).length}',
                            subtitle: 'Completed',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            icon: Iconsax.edit_2,
                            title:
                                '${resumes.where((r) => r.completionPercentage < 100).length}',
                            subtitle: 'In Progress',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // My Resumes Summary Card — tap to go to Resumes tab
                    GestureDetector(
                      onTap: () =>
                          ref.read(currentTabProvider.notifier).state = 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Iconsax.document_text_1,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Resumes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    resumes.isEmpty
                                        ? 'No resumes yet — create one!'
                                        : '${resumes.length} resume${resumes.length == 1 ? '' : 's'} saved',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Iconsax.arrow_right_3,
                                color: AppColors.primary),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),

            // AI Tools Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI Tools',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.push('/ai-assistant'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AiQuickCard(
                            icon: Iconsax.refresh_2,
                            label: 'Resume\nRewrite',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => context.push('/ai-resume-rewrite'),
                          ),
                          const SizedBox(width: 10),
                          _AiQuickCard(
                            icon: Iconsax.search_normal_1,
                            label: 'Job\nTailor',
                            color: AppColors.info,
                            onTap: () => context.push('/ai-job-tailor'),
                          ),
                          const SizedBox(width: 10),
                          _AiQuickCard(
                            icon: Iconsax.edit_2,
                            label: 'Content\nEnhancer',
                            color: AppColors.warning,
                            onTap: () => context.push('/ai-content-enhancer'),
                          ),
                          const SizedBox(width: 10),
                          _AiQuickCard(
                            icon: Iconsax.document_text_1,
                            label: 'Resume\nGenerator',
                            color: AppColors.primary,
                            onTap: () => context.push('/ai-resume-generator'),
                          ),
                          const SizedBox(width: 10),
                          _AiQuickCard(
                            icon: Iconsax.document_text,
                            label: 'Cover\nLetter',
                            color: AppColors.secondary,
                            onTap: () => context.push('/cover-letter'),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            ),

            // Create Resume Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _createNewResume,
                    icon: const Icon(Iconsax.add),
                    label: const Text('Create New Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Quick-access card ───────────────────────────────────────────────────

class _AiQuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AiQuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
