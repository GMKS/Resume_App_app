import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/resume_model.dart';
import '../../../shared/widgets/responsive_content.dart';

class CareerToolsTabScreen extends ConsumerWidget {
  const CareerToolsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Tools'),
      ),
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _CareerToolCard(
            icon: Iconsax.task_square,
            title: 'Job Tracker',
            description: 'Track your job applications and interviews',
            color: AppColors.primary,
            onTap: () => context.push('/job-tracker'),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.document_text_1,
            title: 'Cover Letter Generator',
            description: 'AI-powered cover letter creation',
            color: AppColors.secondary,
            onTap: () => context.push('/cover-letter'),
            isPremium: true,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.message_question,
            title: 'Interview Prep',
            description: 'Practice common interview questions',
            color: AppColors.info,
            onTap: () => context.push('/interview-prep'),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.chart_success,
            title: 'Skill Gap Analyzer',
            description: 'Identify skills to improve for your dream job',
            color: AppColors.warning,
            onTap: () => context.push('/skill-analyzer'),
            isPremium: true,
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.global_search,
            title: 'Career Path Guide',
            description: 'Explore career paths and requirements',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/career-path'),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.search_normal_1,
            title: 'Job Search',
            description: 'Search jobs on LinkedIn, Indeed, Glassdoor and more',
            color: const Color(0xFF0EA5E9),
            onTap: () => context.push('/job-search'),
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.book_1,
            title: 'Career Articles',
            description: 'Expert tips on resumes, interviews and career growth',
            color: const Color(0xFFF59E0B),
            onTap: () => context.push('/career-articles'),
          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.global,
            title: 'Global Style Converter',
            description: 'Adapt your resume for US, UK, Germany, and more',
            color: const Color(0xFF8B5CF6),
            onTap: () => _handleResumeToolTap(context, 'style-converter'),
            isPremium: true,
          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _CareerToolCard(
            icon: Iconsax.magic_star,
            title: 'Roast My Resume',
            description: 'Get a brutally honest AI critique of your resume',
            color: const Color(0xFFEF4444),
            onTap: () => _handleResumeToolTap(context, 'roast-resume'),
          ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }

  void _handleResumeToolTap(BuildContext context, String route) async {
    final resumes = StorageService.getAllResumes();
    if (resumes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Resumes Found'),
          content: const Text('You need to create a resume first.'),
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
    if (resumes.length == 1) {
      context.push('/$route?resumeId=${resumes.first.id}');
      return;
    }
    final selected = await showDialog<ResumeModel>(
      context: context,
      builder: (context) => _ResumePickerDialog(resumes: resumes),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    context.push('/$route?resumeId=${selected.id}');
  }
}

// Move _ResumePickerDialog to top-level
class _ResumePickerDialog extends StatelessWidget {
  final List<ResumeModel> resumes;
  const _ResumePickerDialog({required this.resumes});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a Resume'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: resumes.length,
          itemBuilder: (context, index) {
            final resume = resumes[index];
            return ListTile(
              title: Text(resume.title),
              subtitle: Text(resume.personalInfo.fullName),
              onTap: () => Navigator.pop(context, resume),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CareerToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isPremium;

  const _CareerToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
