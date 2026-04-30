import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import 'resume_editor_screen.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const SummaryScreen({super.key, required this.resumeId});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final _summaryController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updatedResume = resume.copyWith(
        objective: _summaryController.text.trim(),
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
              Text('Summary saved'),
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

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sync controller with provider data on first load OR when objective was externally updated
    // (e.g. after AI content enhancer applies a summary)
    final latestObjective = resume.objective ?? '';
    if (!_isInitialized) {
      _summaryController.text = latestObjective;
      _isInitialized = true;
    } else if (_summaryController.text.isEmpty && latestObjective.isNotEmpty) {
      // External update arrived (AI applied) — sync without overwriting user edits
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _summaryController.text = latestObjective);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Professional Summary'),
        actions: [
          TextButton(onPressed: _saveChanges, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tips Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.1),
                  AppColors.info.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.lamp_on,
                      color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro Tip',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Write 2-4 sentences highlighting your key achievements and what you can bring to the role.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          Text(
            'Your Professional Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 8),

          Text(
            'A compelling summary helps recruiters quickly understand your value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          TextFormField(
            controller: _summaryController,
            maxLines: 8,
              maxLength: 2500,
            decoration: InputDecoration(
              hintText:
                  'Press Enter between each achievement point\nE.g.:\n5+ years of experience in software development\nExpertise in Flutter and cloud technologies\nProven track record of delivering high-quality applications',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          // Helper Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Each line will appear as a bullet point in your PDF resume',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          // Example Summaries
          Text(
            'Example Summaries',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          _ExampleCard(
            title: 'Software Developer',
            text:
                'Innovative software developer with 5+ years of experience building scalable web applications. Proficient in React, Node.js, and cloud technologies. Passionate about creating efficient, user-friendly solutions.',
            onTap: () => _summaryController.text =
                'Innovative software developer with 5+ years of experience building scalable web applications. Proficient in React, Node.js, and cloud technologies. Passionate about creating efficient, user-friendly solutions.',
          ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0),

          _ExampleCard(
            title: 'Marketing Manager',
            text:
                'Strategic marketing professional with 7+ years of experience driving brand growth and digital campaigns. Expert in SEO, content strategy, and analytics. Proven track record of increasing engagement by 150%.',
            onTap: () => _summaryController.text =
                'Strategic marketing professional with 7+ years of experience driving brand growth and digital campaigns. Expert in SEO, content strategy, and analytics. Proven track record of increasing engagement by 150%.',
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Summary'),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),
                  const Icon(Iconsax.copy,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
