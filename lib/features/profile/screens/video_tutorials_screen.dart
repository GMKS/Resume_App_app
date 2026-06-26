import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('App Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _GuideIntroCard()
              .animate()
              .fadeIn(delay: 50.ms)
              .slideY(begin: 0.06, end: 0),
          const SizedBox(height: 20),
          Text(
            'Feature walkthroughs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any guide to see the exact path and next action for that workflow.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          ..._guideTopics.asMap().entries.map((entry) {
            final topic = entry.value;
            return _GuideTopicCard(
              topic: topic,
              onTap: () => _showGuideSheet(context, topic),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + entry.key * 40))
                .slideY(begin: 0.04, end: 0);
          }),
        ],
      ),
    );
  }
}

final List<_GuideTopic> _guideTopics = <_GuideTopic>[
  const _GuideTopic(
    id: 'create-resume',
    icon: Iconsax.document_text,
    title: 'Create a New Resume',
    description:
        'Start a resume from Home, choose a template, add your details, and save it for later updates.',
    pathSteps: <String>[
      'Home',
      'Create Resume (+)',
      'Select Template',
      'Add Details',
      'Save Resume',
    ],
    helperText:
        'Use this flow when you want to build a fresh resume from scratch.',
  ),
  const _GuideTopic(
    id: 'edit-details',
    icon: Iconsax.edit_2,
    title: 'Edit Resume Details',
    description:
        'Open an existing resume, revise any section, and save your latest information in place.',
    pathSteps: <String>[
      'Resumes',
      'Select Resume',
      'Edit Sections',
      'Update Information',
      'Save Changes',
    ],
    helperText:
        'Best for updating experience, skills, education, or contact details before applying.',
  ),
  const _GuideTopic(
    id: 'templates-themes',
    icon: Iconsax.color_swatch,
    title: 'Choose Templates & Themes',
    description:
        'Switch layouts and styling quickly to match the role or presentation style you need.',
    pathSteps: <String>[
      'Resume',
      'Templates/Themes',
      'Select Design',
      'Apply Changes',
    ],
    helperText:
        'Preview different styles before exporting so the final resume fits the job target.',
  ),
  const _GuideTopic(
    id: 'ai-assistant',
    icon: Iconsax.magic_star,
    title: 'Use AI Assistant',
    description:
        'Generate, improve, or tailor content with AI and then apply the version that fits best.',
    pathSteps: <String>[
      'AI Assistant',
      'Choose Feature',
      'Generate/Improve Content',
      'Apply Changes',
    ],
    helperText:
        'Review AI suggestions before applying them so the final wording stays accurate to your experience.',
  ),
  const _GuideTopic(
    id: 'download-share',
    icon: Iconsax.document_download,
    title: 'Download & Share Resume',
    description:
        'Preview your resume, choose the right export action, and share the final file in the format you need.',
    pathSteps: <String>[
      'Resume',
      'Preview',
      'Download/Share',
      'Select Format',
    ],
    helperText:
        'Use preview first to confirm spacing and layout before downloading or sharing.',
  ),
  const _GuideTopic(
    id: 'portfolio-links',
    icon: Iconsax.link,
    title: 'Portfolio Sharing',
    description:
        'Generate a portfolio link from a resume and share it directly by copy, share sheet, or QR code.',
    pathSteps: <String>[
      'Portfolio',
      'Select Resume',
      'Generate Link',
      'Copy Link / Share / QR Code',
    ],
    helperText:
        'Choose the resume first so the portfolio reflects the version you want to publish.',
  ),
  const _GuideTopic(
    id: 'manage-resumes',
    icon: Iconsax.folder_open,
    title: 'Manage Resumes',
    description:
        'Review all saved resumes and quickly edit, duplicate, or remove the ones you no longer need.',
    pathSteps: <String>[
      'Resumes',
      'View All Resumes',
      'Edit / Duplicate / Delete',
    ],
    helperText:
        'This is the fastest way to manage multiple resume versions for different roles.',
  ),
  const _GuideTopic(
    id: 'backup-sync',
    icon: Iconsax.cloud,
    title: 'Backup & Sync',
    description:
        'Protect your data by enabling sync and using restore when you need to recover or move your information.',
    pathSteps: <String>[
      'Settings',
      'Backup & Sync',
      'Enable Sync',
      'Restore Data',
    ],
    helperText:
        'Turn on sync before changing devices so your latest resumes are easier to recover.',
  ),
  const _GuideTopic(
    id: 'upgrade-pro',
    icon: Iconsax.crown,
    title: 'Upgrade to Pro & Manage Subscription',
    description:
        'Choose a plan, subscribe, and return to the same area later to review or manage your subscription.',
    pathSteps: <String>[
      'Settings',
      'Upgrade to Pro',
      'Select Plan',
      'Subscribe',
      'Manage Subscription',
    ],
    helperText:
        'Use the same subscription area for new purchases, restores, and ongoing plan management.',
  ),
  const _GuideTopic(
    id: 'settings-support',
    icon: Iconsax.setting_2,
    title: 'Settings & Support',
    description:
        'Use the help and support area to find answers, contact support, or report an issue.',
    pathSteps: <String>[
      'Settings',
      'Help & Support',
      'FAQs / Contact Support / Report Issue',
    ],
    helperText:
        'Start here whenever you need guidance, troubleshooting help, or a way to report problems.',
  ),
];

void _showGuideSheet(BuildContext context, _GuideTopic topic) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(topic.icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            topic.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    topic.pathLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Step-by-step path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: topic.pathSteps.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _GuideStepRow(
                        stepNumber: index + 1,
                        label: topic.pathSteps[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    topic.helperText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _GuideIntroCard extends StatelessWidget {
  const _GuideIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Iconsax.book_1,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Guide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Follow these guided paths to learn the app workflow for resumes, portfolio sharing, AI tools, backup, subscription management, and support.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTopicCard extends StatelessWidget {
  const _GuideTopicCard({
    required this.topic,
    required this.onTap,
  });

  final _GuideTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideThumbnail(topic: topic),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      topic.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      topic.pathLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.book,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to view walkthrough',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideThumbnail extends StatelessWidget {
  const _GuideThumbnail({required this.topic});

  final _GuideTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(topic.icon, color: AppColors.primary, size: 24),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.book,
                size: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepRow extends StatelessWidget {
  const _GuideStepRow({
    required this.stepNumber,
    required this.label,
  });

  final int stepNumber;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTopic {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final List<String> pathSteps;
  final String helperText;

  const _GuideTopic({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.pathSteps,
    required this.helperText,
  });

  String get pathLabel => pathSteps.join(' -> ');
}
