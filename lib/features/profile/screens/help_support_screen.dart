import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/services/bug_report_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/feature_gate.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    _FAQ(
      question: 'How do I create a new resume?',
      answer:
          'Go to the Home tab and tap the "+" button. You can then choose a template and start filling in your details.',
    ),
    _FAQ(
      question: 'Can I edit a resume after saving?',
      answer:
          'Yes! Tap any resume from the Resumes tab to open the editor and make your changes. Everything is saved automatically.',
    ),
    _FAQ(
      question: 'How do I export my resume as PDF?',
      answer:
          'Open your resume, tap the share/export icon at the top right, and choose "Export as PDF".',
    ),
    _FAQ(
      question: 'What is included in the Premium plan?',
      answer:
          'Premium gives you access to all templates, AI-powered content enhancement, ATS optimisation, cover letter generation, unlimited resumes, and more.',
    ),
    _FAQ(
      question: 'How do I cancel my subscription?',
      answer:
          'Go to Profile, open your current plan, and tap "Cancel Subscription". Your premium access will continue until the current billing period ends.',
    ),
    _FAQ(
      question: 'Is my data secure?',
      answer:
          'Yes. Your data is stored securely on your device and is only uploaded to cloud storage when you use manual Backup & Sync. Phone numbers are used only for OTP authentication, and we never sell your personal data.',
    ),
    _FAQ(
      question: 'How does the AI content enhancer work?',
      answer:
          'Our AI analyses your existing resume content and suggests improvements for clarity, impact, and keyword optimisation based on industry standards. AI-generated content should be reviewed before use.',
    ),
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      query:
          'subject=${Uri.encodeQueryComponent('${AppInfo.appName} Support Request')}&body=Hi Support Team,',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Contact cards
          const _SectionHeader(title: 'Contact Us')
              .animate()
              .fadeIn(delay: 50.ms),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: Iconsax.sms,
                  title: 'Email Us',
                  subtitle: AppInfo.supportEmail,
                  color: AppColors.primary,
                  onTap: _launchEmail,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  icon: Iconsax.message_question,
                  title: 'Live Chat',
                  subtitle: FreePlanService.hasPrioritySupport
                      ? 'Chat with our\npriority team'
                      : 'Premium priority\nsupport',
                  color: Colors.green,
                  badge: !FreePlanService.hasPrioritySupport
                      ? const PremiumBadge(locked: true)
                      : const PremiumBadge(label: 'LIVE'),
                  onTap: () {
                    if (!FreePlanService.hasPrioritySupport) {
                      showUpgradePromptSheet(
                        context,
                        featureName: 'priority_support',
                        message: FreePlanService.premiumSupportMessage,
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Live chat coming soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick links
          const _SectionHeader(title: 'Resources')
              .animate()
              .fadeIn(delay: 200.ms),
          _buildLinkTile(
            context,
            icon: Iconsax.book_1,
            title: 'User Guide',
            subtitle: 'Full documentation and how-to guides',
            delay: 250,
            onTap: () => _launchUrl(AppInfo.userGuideUrl),
          ),
          _buildLinkTile(
            context,
            icon: Iconsax.book_1,
            title: 'App Guide',
            subtitle: 'Open step-by-step app walkthroughs',
            delay: 300,
            onTap: () => context.push('/app-guide'),
          ),
          _buildLinkTile(
            context,
            icon: Iconsax.warning_2,
            title: 'Report a Bug',
            subtitle: 'Found an issue? Let us know',
            delay: 350,
            onTap: () => _showFeedbackSheet(context, isReport: true),
          ),
          _buildLinkTile(
            context,
            icon: Iconsax.star,
            title: 'Rate the App',
            subtitle: 'Help us by leaving a review',
            delay: 400,
            onTap: () => _launchUrl(AppInfo.playStoreUrl),
          ),
          const SizedBox(height: 20),

          // FAQ Section
          const _SectionHeader(title: 'Frequently Asked Questions')
              .animate()
              .fadeIn(delay: 450.ms),
          ..._faqs.asMap().entries.map((e) {
            return _FAQTile(faq: e.value)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 500 + e.key * 50));
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int delay,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: -0.05, end: 0);
  }

  void _showFeedbackSheet(BuildContext context, {bool isReport = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FeedbackSheet(
        isReport: isReport,
        supportContext: context,
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({
    required this.isReport,
    required this.supportContext,
  });

  final bool isReport;
  final BuildContext supportContext;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isReport ? 'Report a Bug' : 'Send Feedback',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: widget.isReport
                  ? 'Describe the bug you encountered...'
                  : 'Share your thoughts...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please describe the issue before submitting.');
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(widget.supportContext) ??
        ScaffoldMessenger.of(context);

    setState(() => _submitting = true);

    final mediaQuery = MediaQuery.of(context);
    final result = widget.isReport
        ? await BugReportService.submit(
            BugReportSubmission(
              category: 'bug_report',
              screenName: 'Help & Support / Report a Bug',
              issueDescription: text,
              viewport: <String, dynamic>{
                'width': mediaQuery.size.width,
                'height': mediaQuery.size.height,
                'pixelRatio': mediaQuery.devicePixelRatio,
                'textScaleFactor': mediaQuery.textScaler.scale(1),
              },
            ),
          )
        : const BugReportResult(
            success: true,
            message: 'Feedback submitted. Thank you!',
          );

    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(widget.supportContext) ??
        ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? badge;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (badge != null) ...[
                const SizedBox(height: 8),
                badge!,
              ],
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  widget.faq.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
