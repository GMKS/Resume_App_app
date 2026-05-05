
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/services/free_plan_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/feature_gate.dart';

class AIAssistantScreen extends ConsumerWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('AI Assistant'),
      ),
      body: FeatureGate(
        featureName: 'ai_assistant',
        upgradeMessage: 'Unlock AI-powered features to supercharge your resume',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!FreePlanService.isPremium)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${FreePlanService.remainingAiSuggestions} free AI suggestions left. Summary and bullet tools stay available until the limit is reached.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ).animate().fadeIn(duration: 250.ms),
            _AIFeatureCard(
              icon: Iconsax.document_text_1,
              title: 'AI Resume Generator',
              description: 'Create a professional resume from scratch using AI',
              color: AppColors.primary,
              isLocked: !FreePlanService.canAccessAiTool('resume_generator'),
              onTap: () => _handleToolTap(
                context,
                toolKey: 'resume_generator',
                route: '/ai-resume-generator',
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.user_tick,
              title: 'LinkedIn Import',
              description: 'Import your LinkedIn profile and turn it into a resume',
              color: const Color(0xFF0A66C2),
              isLocked: !FreePlanService.canAccessAiTool('linkedin_import'),
              onTap: () => _handleToolTap(
                context,
                toolKey: 'linkedin_import',
                route: '/linkedin-import',
              ),
            ).animate().fadeIn(delay: 175.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.document_text,
              title: 'AI Cover Letter',
              description: 'Generate personalized cover letters in seconds',
              color: AppColors.secondary,
              isLocked: !subscription.hasFeature(
                SubscriptionFeatures.coverLetterGenerator,
              ),
              onTap: () => _handlePremiumFeatureTap(
                context,
                subscription: subscription,
                featureName: SubscriptionFeatures.coverLetterGenerator,
                route: '/cover-letter',
                upgradeMessage:
                    'Cover letter generation is available on premium plans only.',
              ),
            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.search_normal_1,
              title: 'Resume Match Analyzer',
              description: 'Compare your resume with any job posting to see match score, missing skills, and tailored next steps',
              color: AppColors.info,
              isLocked: !FreePlanService.canAccessAiTool('job_tailor'),
              onTap: () => _handleToolTap(
                context,
                toolKey: 'job_tailor',
                route: '/ai-job-tailor',
              ),
            ).animate().fadeIn(delay: 325.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.edit_2,
              title: 'AI Content Enhancer',
              description: 'Generate professional summaries & ATS-optimized bullet points',
              color: AppColors.warning,
              isLocked: false,
              onTap: () => context.push('/ai-content-enhancer'),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.lamp_charge,
              title: 'Skill Suggestions',
              description: 'Get role-based skill recommendations for your field',
              color: const Color(0xFF8B5CF6),
              isLocked: !subscription.hasFeature(
                SubscriptionFeatures.skillAnalyzer,
              ),
              onTap: () => _handlePremiumFeatureTap(
                context,
                subscription: subscription,
                featureName: SubscriptionFeatures.skillAnalyzer,
                route: '/skill-analyzer',
                upgradeMessage:
                    'Role-based skill recommendations are available on premium plans only.',
              ),
            ).animate().fadeIn(delay: 475.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.clipboard_text,
              title: 'Summary Generator',
              description: 'Create compelling professional summaries with AI',
              color: const Color(0xFFEC4899),
              isLocked: false,
              onTap: () => context.push('/ai-content-enhancer'),
            ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.refresh_2,
              title: 'AI Resume Rewrite',
              description: 'Completely rewrite your resume with stronger language, metrics and ATS keywords',
              color: const Color(0xFF8B5CF6),
              isLocked: !FreePlanService.canAccessAiTool('resume_rewrite'),
              onTap: () => _handleToolTap(
                context,
                toolKey: 'resume_rewrite',
                route: '/ai-resume-rewrite',
              ),
            ).animate().fadeIn(delay: 625.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            _AIFeatureCard(
              icon: Iconsax.tag_right,
              title: 'AI Bullet Generator',
              description: 'Generate powerful ATS-optimised bullet points for experience entries',
              color: const Color(0xFF10B981),
              isLocked: false,
              onTap: () => context.push('/ai-bullet-generator'),
            ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),
            _AIFeatureCard(
              icon: Iconsax.magic_star,
              title: 'Resume Auto-Optimization (RAOE 2)',
              description: 'Auto-optimize your resume for any job description with keyword gap analysis, AI rewriting, and before/after preview.',
              color: Colors.teal,
              isLocked: false,
              onTap: () => context.push('/raoe2?resumeText=&jobDescription='),
            ).animate().fadeIn(delay: 775.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }

  void _handleToolTap(
    BuildContext context, {
    required String toolKey,
    required String route,
  }) {
    if (!FreePlanService.canAccessAiTool(toolKey)) {
      showUpgradePromptSheet(
        context,
        featureName: 'ai_assistant',
        message: FreePlanService.premiumAiToolMessage,
      );
      return;
    }

    context.push(route);
  }

  void _handlePremiumFeatureTap(
    BuildContext context, {
    required SubscriptionModel subscription,
    required String featureName,
    required String route,
    required String upgradeMessage,
  }) {
    if (!subscription.hasFeature(featureName)) {
      showUpgradePromptSheet(
        context,
        featureName: featureName,
        message: upgradeMessage,
      );
      return;
    }

    context.push(route);
  }

}

class _AIFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLocked;
  final VoidCallback onTap;

  const _AIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isLocked = false,
    required this.onTap,
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
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
              Icon(
                isLocked ? Iconsax.lock_1 : Iconsax.arrow_right_3,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
