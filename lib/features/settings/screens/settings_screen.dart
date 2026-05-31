import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_deletion_service.dart';
import '../../../core/services/ai_api_key_storage_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_sync_service.dart';
import '../../../core/services/sync_status_service.dart';
import '../../../core/utils/cloud_resume_sync.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../career_tools/models/job_tracker_models.dart';
import '../../career_tools/services/job_tracker_service.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;

// Theme Mode Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadTheme());

  static ThemeMode _loadTheme() {
    final saved = StorageService.getThemeMode();
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await StorageService.setThemeMode(modeStr);
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final String _appVersion = '1.0.1';
  int _resumeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  void _loadInfo() async {
    // App version is set statically for now
    setState(() {
      _resumeCount = StorageService.getAllResumes().length;
    });
  }

  void _showThemeDialog() {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Theme',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildThemeOption(ThemeMode.system, 'System Default',
                Iconsax.mobile, currentMode == ThemeMode.system),
            _buildThemeOption(ThemeMode.light, 'Light Mode', Iconsax.sun_1,
                currentMode == ThemeMode.light),
            _buildThemeOption(ThemeMode.dark, 'Dark Mode', Iconsax.moon,
                currentMode == ThemeMode.dark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      ThemeMode mode, String title, IconData icon, bool isSelected) {
    return ListTile(
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(mode);
        if (mounted) {
          Navigator.pop(context);
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected
          ? const Icon(Iconsax.tick_circle5, color: AppColors.primary)
          : null,
    );
  }

  void _showAiApiKeySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _AiApiKeySheet(),
    );
  }

  void _showBackupSyncSheet() {
    if (!FreePlanService.canUseCloudSync) {
      showUpgradePromptSheet(
        context,
        featureName: 'cloud_sync',
        message: FreePlanService.premiumCloudSyncMessage,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _BackupSyncSheet(
        onRestored: () {
          if (mounted) {
            setState(
                () => _resumeCount = StorageService.getAllResumes().length);
            // Reload the global resumesProvider so My Resumes tab updates immediately
            ref.read(resumesProvider.notifier).loadResumes();
          }
        },
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete All Data'),
          ],
        ),
        content: const Text(
            'Users can delete their data anytime. Delete your resumes, job tracker entries, saved settings, AI preferences, and any synced cloud backup for this app? You will be signed out on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DataDeletionService.deleteUserData();
              if (!mounted) {
                return;
              }
              setState(() => _resumeCount = 0);
              ref.read(resumesProvider.notifier).loadResumes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Your app data has been deleted.'),
                    backgroundColor: AppColors.success),
              );
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Iconsax.document_text5,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(AppInfo.appName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version $_appVersion',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const Text(
              'Build polished, ATS-aware resumes with AI assistance, premium templates, and export tools.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                    Iconsax.global, 'Website', AppInfo.websiteUrl),
                const SizedBox(width: 16),
                _buildSocialButton(
                    Iconsax.shield_tick, 'Privacy', AppInfo.privacyPolicyUrl),
                const SizedBox(width: 16),
                _buildSocialButton(
                  Iconsax.message,
                  'Support',
                  'mailto:${AppInfo.supportEmail}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Made with ❤️ using Flutter',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showFaqSheet() {
    final faqs = [
      (
        'How do I create a resume?',
        'Tap "New Resume" on the Resumes tab, choose a template, then fill in your details section by section.'
      ),
      (
        'Can I have multiple resumes?',
        'Yes! You can create as many resumes as you need and switch between them.'
      ),
      (
        'How do I export my resume as PDF?',
        'Open a resume, then tap "Preview & Export". You can download, print, or share the PDF from there.'
      ),
      (
        'How do I change the template?',
        'Open any resume, then tap the paintbrush icon at the top right (or the "Resume Template" tile) to choose a different template.'
      ),
      (
        'Is my data saved automatically?',
        'Yes, all changes are saved automatically to your device. Resume and job data stay local unless you manually use Backup & Sync or use a feature that clearly requires network processing, such as OTP or AI generation.'
      ),
      (
        'Will I lose my data if I reinstall?',
        'Yes — reinstalling the app clears all app data. Use "Backup & Sync" to protect your resumes and tracked jobs.'
      ),
      (
        'How do I delete a resume?',
        'On the Resumes tab, swipe left on a resume card or tap the delete option in the card menu.'
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Help & FAQ',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AdaptiveTooltip(
                  message: 'Close help and FAQ',
                  button: true,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...faqs.map((faq) => ExpansionTile(
                  title: Text(faq.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq.$2,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Privacy Policy',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AdaptiveTooltip(
                  message: 'Close privacy policy',
                  button: true,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Last updated: February 2026',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...[
              (
                'Data We Process',
                'The app stores resume content, portfolio items, job tracker entries, settings, and subscription state locally on your device. Resume and job data stay on this device unless you manually use Backup & Sync. Cloud backup is optional and is not uploaded automatically when you edit a resume.'
              ),
              (
                'Cloud Backup Consent',
                'Resumes are not stored in the cloud without your action. Tapping Backup to Cloud is the explicit action that uploads your current resume and job-tracker data snapshot for cross-device restore.'
              ),
              (
                'Sign-In And Verification',
                'Phone numbers are sent to the configured verification provider only to send and verify OTP codes. Phone number is used only for authentication (OTP) and is not stored or shared as a full number after verification. Social sign-in providers may return profile data such as your email, display name, and profile photo. Limited session details such as a masked contact label may be stored locally so you can stay signed in.'
              ),
              (
                'Data Safety Summary',
                'Data collected: Phone number\nPurpose: Authentication\nSharing: Not shared\nSecurity: Encrypted in transit'
              ),
              (
                'AI Features',
                'When you use AI-powered tools, the text you submit can be sent to the configured AI provider so the app can generate suggestions or rewritten content. AI-generated content should always be reviewed before use. The app does not promise interviews, job offers, or guaranteed resume success.'
              ),
              (
                'Permissions And Network Access',
                'The app may request camera or gallery access for profile photos, file access for import and export actions, and internet access for OTP, AI requests, cloud sync, sign-in, and sharing features.'
              ),
              (
                'Third-Party Services',
                'The app integrates with a configured OTP delivery provider, Firebase for authentication and cloud sync, optional AI providers for content generation, and platform billing or app-store services for subscriptions. We do not sell your data.'
              ),
              (
                'Data Deletion',
                'Users can delete their data anytime. Use Settings → Delete All Data to remove local app data and request deletion of synced backups tied to your current device or sync code. Uninstalling the app removes local data stored on the device.'
              ),
              (
                'Contact',
                'For privacy concerns, contact us at ${AppInfo.supportEmail}'
              ),
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item.$2,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(AppInfo.privacyPolicyUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Iconsax.export_1),
                label: const Text('Open Full Privacy Policy'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Terms of Service',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AdaptiveTooltip(
                  message: 'Close terms of service',
                  button: true,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Effective: February 2026',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...[
              (
                'Acceptance',
                'By using ${AppInfo.appName}, you agree to these terms. If you do not agree, please stop using the app.'
              ),
              (
                'License',
                'We grant you a limited, non-exclusive license to use this app for personal, non-commercial purposes.'
              ),
              (
                'User Content',
                'You retain full ownership of all resume content you create. We do not claim any rights over your data.'
              ),
              (
                'Prohibited Use',
                'You may not use this app to create fraudulent, misleading, or illegal content.'
              ),
              (
                'Disclaimer',
                'The app is provided "as is". We make no warranties about its fitness for any particular purpose.'
              ),
              (
                'Limitation of Liability',
                'We are not liable for any loss of data or damages arising from your use of the app.'
              ),
              (
                'Changes',
                'We may update these terms at any time. Continued use of the app constitutes acceptance of updated terms.'
              ),
              ('Contact', 'Questions? Email us at ${AppInfo.supportEmail}'),
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item.$2,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveTooltip(
          message: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionHeader('APPEARANCE'),
            _buildSettingTile(
              icon: Iconsax.paintbucket,
              title: 'Theme',
              subtitle: _getThemeLabel(themeMode),
              onTap: _showThemeDialog,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('AI FEATURES'),
            _buildSettingTile(
              icon: Iconsax.key,
              title: 'Groq API Key (Free)',
              subtitle: 'Free AI — No credit card required',
              onTap: _showAiApiKeySheet,
            ),
            _buildSettingTile(
              icon: Iconsax.magic_star,
              iconColor: const Color(0xFF8B5CF6),
              title: 'AI Assistant',
              subtitle: 'Generate & tailor resume content with AI',
              onTap: () => context.push('/ai-assistant'),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('DATA'),
            _buildSettingTile(
              icon: Iconsax.document_text,
              title: 'My Resumes',
              subtitle: '$_resumeCount resumes saved',
              onTap: () => context.pop(),
            ),
            _buildSettingTile(
              icon: Iconsax.cloud,
              title: 'Backup & Sync',
              subtitle: FreePlanService.canUseCloudSync
                  ? 'Back up & restore resumes and job tracker data'
                  : 'Premium cloud backup across devices',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!FreePlanService.canUseCloudSync)
                    const PremiumBadge(locked: true),
                  const SizedBox(width: 8),
                  const Icon(Iconsax.arrow_right_3,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
              onTap: _showBackupSyncSheet,
            ),
            _buildSettingTile(
              icon: Iconsax.trash,
              iconColor: AppColors.error,
              title: 'Delete All Data',
              subtitle: 'Clear local data and synced app backups',
              onTap: _showDeleteAllDialog,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT'),
            _buildSettingTile(
              icon: Iconsax.star_1,
              title: 'Rate App',
              subtitle: 'Love the app? Give us 5 stars!',
              onTap: () async {
                final uri = Uri.parse(AppInfo.playStoreUrl);
                final messenger = ScaffoldMessenger.of(context);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Could not open store'),
                        behavior: SnackBarBehavior.floating),
                  );
                }
              },
            ),
            _buildSettingTile(
              icon: Iconsax.message_question,
              title: 'Help & FAQ',
              subtitle: 'Get answers to common questions',
              onTap: _showFaqSheet,
            ),
            _buildSettingTile(
              icon: Iconsax.flash_1,
              title: 'Priority Support',
              subtitle: FreePlanService.hasPrioritySupport
                  ? 'Fast-track premium help'
                  : 'Premium-only faster response lane',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!FreePlanService.hasPrioritySupport)
                    const PremiumBadge(locked: true),
                  const SizedBox(width: 8),
                  const Icon(Iconsax.arrow_right_3,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
              onTap: () {
                if (!FreePlanService.hasPrioritySupport) {
                  showUpgradePromptSheet(
                    context,
                    featureName: 'priority_support',
                    message: FreePlanService.premiumSupportMessage,
                  );
                  return;
                }
                context.push('/help-support');
              },
            ),
            _buildSettingTile(
              icon: Iconsax.message_text,
              title: 'Contact Support',
              subtitle: 'We\'re here to help',
              onTap: () async {
                final uri = Uri.parse(
                    'mailto:${AppInfo.supportEmail}?subject=${Uri.encodeComponent('${AppInfo.appName} Support')}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildSettingTile(
              icon: Iconsax.share,
              title: 'Share App',
              subtitle: 'Tell your friends about us',
              onTap: () {
                Share.share(
                  'Check out ${AppInfo.appName}: smart resume building with AI tools and premium templates.\n${AppInfo.playStoreUrl}',
                  subject: '${AppInfo.appName} App',
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('ABOUT'),
            _buildSettingTile(
              icon: Iconsax.info_circle,
              title: 'About',
              subtitle: 'Version $_appVersion',
              onTap: _showAboutDialog,
            ),
            _buildSettingTile(
              icon: Iconsax.shield_tick,
              title: 'Privacy Policy',
              subtitle: 'How we protect your data',
              onTap: _showPrivacyPolicy,
            ),
            _buildSettingTile(
              icon: Iconsax.document,
              title: 'Terms of Service',
              subtitle: 'Our agreement with you',
              onTap: _showTermsOfService,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Iconsax.arrow_right_3,
                    size: 18, color: AppColors.textSecondary)
                : null),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05, end: 0);
  }
}

// ─── Backup & Sync bottom-sheet widget ───────────────────────────────────────
class _BackupSyncSheet extends StatefulWidget {
  final VoidCallback? onRestored;
  const _BackupSyncSheet({this.onRestored});

  @override
  State<_BackupSyncSheet> createState() => _BackupSyncSheetState();
}

class _BackupSyncSheetState extends State<_BackupSyncSheet> {
  static const JobTrackerService _jobTrackerService = JobTrackerService();
  static const String _jobTrackerCollection = 'job_tracker';
  static const String _jobTrackerField = 'jobs';

  String? _statusMessage;
  bool _inProgress = false;

  // ── Sync Code state ───────────────────────────────────────────────────────
  final _codeController = TextEditingController();
  String? _currentCode; // what's saved in prefs
  String? _deviceId; // per-device fallback UUID
  bool _editingCode = false;
  String? _lastSyncSummary;
  DateTime? _lastBackupAt;
  DateTime? _lastRestoreAt;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    final code = await SupabaseSyncService.getSyncCode();
    final deviceId = await SupabaseSyncService.getDeviceId();
    final syncStatus = await SyncStatusService.load();
    if (mounted) {
      setState(() {
        _currentCode = code;
        _deviceId = deviceId;
        _lastSyncSummary = syncStatus.lastSummary;
        _lastBackupAt = syncStatus.lastBackupAt;
        _lastRestoreAt = syncStatus.lastRestoreAt;
        if (code != null) _codeController.text = code;
      });
    }
  }

  String _formatSyncTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Never';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
  }

  DateTime? get _lastSyncedAt {
    final backupAt = _lastBackupAt;
    final restoreAt = _lastRestoreAt;
    if (backupAt == null) {
      return restoreAt;
    }
    if (restoreAt == null) {
      return backupAt;
    }
    return backupAt.isAfter(restoreAt) ? backupAt : restoreAt;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Iconsax.arrow_left,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.cloud,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backup & Sync',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                        'Manual cloud sync for resumes and job tracker across devices',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.18),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How sync works',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Set the same Sync Code on every device you want to connect.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                Text(
                  '2. On the device with your latest changes, tap Backup to Cloud.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                Text(
                  '3. On the other device, tap Restore from Cloud to pull that data down.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                Text(
                  '4. Repeat Backup whenever you make changes. Restore whenever another device needs the newest copy.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                SizedBox(height: 6),
                Text(
                  'Cloud backup and restore are manual. Resume restore is also checked on app launch, but uploads are never pushed automatically in the background.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                      height: 1.5),
                ),
                SizedBox(height: 6),
                Text(
                  'Resumes stay on this device unless you tap Backup to Cloud. Restore keeps the most recently updated local or cloud version to avoid overwriting newer edits.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sync Code panel ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    const Icon(Iconsax.link,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Sync Code',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    if (!_editingCode)
                      TextButton(
                        onPressed: () => setState(() => _editingCode = true),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(
                            _currentCode == null ? 'Set Code' : 'Change',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Explanation
                const Text(
                  'To sync between mobile and Chrome (or any two devices), set the SAME sync code on both. '
                  'Any device using the same code shares the same cloud data.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 12),

                // Current status chip
                if (!_editingCode) ...[
                  if (_currentCode != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.tick_circle,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text('Code: $_currentCode',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            await SupabaseSyncService.setSyncCode(null);
                            if (!mounted) return;
                            _codeController.clear();
                            setState(() => _currentCode = null);
                          },
                          child: const Text('Clear',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.warning_2,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Device-only mode — syncs to this device only',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_deviceId != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Device ID: ${_deviceId!.substring(0, 8)}…',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ],

                // Code editing field
                if (_editingCode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'e.g. john-resume-2025',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final code = _codeController.text.trim();
                          if (code.isEmpty) {
                            setState(() => _editingCode = false);
                            return;
                          }
                          await SupabaseSyncService.setSyncCode(code);
                          if (mounted) {
                            setState(() {
                              _currentCode = code.toLowerCase();
                              _editingCode = false;
                              _statusMessage =
                                  'Sync code set. Set the same code on your other device, then use Backup or Restore.';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => setState(() => _editingCode = false),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use letters, numbers and hyphens. Enter the exact same code on every device you want to sync.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Status',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildStatusRow(
                    'Last synced', _formatSyncTimestamp(_lastSyncedAt)),
                const SizedBox(height: 8),
                _buildStatusRow(
                    'Last cloud backup', _formatSyncTimestamp(_lastBackupAt)),
                const SizedBox(height: 8),
                _buildStatusRow(
                    'Last restore', _formatSyncTimestamp(_lastRestoreAt)),
                if (_lastSyncSummary != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _lastSyncSummary!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status message ────────────────────────────────────────────────
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: (_statusMessage!.startsWith('✅') ||
                        _statusMessage!.startsWith('ℹ️'))
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_statusMessage!.startsWith('✅') ||
                          _statusMessage!.startsWith('ℹ️'))
                      ? AppColors.success
                      : AppColors.error,
                  width: 0.8,
                ),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                    fontSize: 13,
                    color: (_statusMessage!.startsWith('✅') ||
                            _statusMessage!.startsWith('ℹ️'))
                        ? AppColors.success
                        : AppColors.error),
              ),
            ),
          ],

          // ── Backup to Cloud button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _inProgress ? null : _doBackup,
              icon: _inProgress
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Iconsax.cloud_add),
              label: Text(
                  _inProgress ? 'Processing...' : 'Manual Backup to Cloud'),
            ),
          ),
          const SizedBox(height: 10),

          // ── Restore from Cloud button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _inProgress ? null : _doRestore,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from Cloud'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _doBackup() async {
    setState(() {
      _inProgress = true;
      _statusMessage = null;
    });
    final resumes = StorageService.getAllResumes();
    final jobs = await _jobTrackerService.loadJobs();
    if (resumes.isEmpty && jobs.isEmpty) {
      setState(() {
        _inProgress = false;
        _statusMessage = 'ℹ️ No resumes or tracked jobs to back up.';
      });
      return;
    }

    final resumeError = resumes.isEmpty
        ? null
        : await SupabaseSyncService.manualBackupAll(resumes);
    final jobError = jobs.isEmpty
        ? null
        : await SupabaseSyncService.manualBackupJsonList(
            collection: _jobTrackerCollection,
            field: _jobTrackerField,
            items: jobs.map((job) => job.toMap()).toList(growable: false),
          );

    if (!mounted) return;
    final label = _currentCode != null ? 'code "$_currentCode"' : 'this device';
    final backedUp = <String>[
      if (resumeError == null && resumes.isNotEmpty)
        '${resumes.length} resume(s)',
      if (jobError == null && jobs.isNotEmpty) '${jobs.length} tracked job(s)',
    ];
    final failures = <String>[
      if (resumeError != null) 'Resumes: $resumeError',
      if (jobError != null) 'Job tracker: $jobError',
    ];
    final nextStatusMessage = failures.isEmpty
        ? '✅ Backed up ${backedUp.join(' and ')} to $label.'
        : backedUp.isEmpty
            ? '❌ ${failures.join('\n')}'
            : '✅ Backed up ${backedUp.join(' and ')} to $label.\n${failures.join('\n')}';
    final backupRecordedAt = DateTime.now();

    if (failures.isEmpty || backedUp.isNotEmpty) {
      await SyncStatusService.recordBackup(
        nextStatusMessage,
        at: backupRecordedAt,
      );
    } else {
      await SyncStatusService.recordStatus(nextStatusMessage);
    }

    setState(() {
      _inProgress = false;
      _statusMessage = nextStatusMessage;
      _lastSyncSummary = nextStatusMessage;
      if (failures.isEmpty || backedUp.isNotEmpty) {
        _lastBackupAt = backupRecordedAt;
      }
    });
  }

  Future<void> _doRestore() async {
    setState(() {
      _inProgress = true;
      _statusMessage = null;
    });
    try {
      final cloudResumes = await SupabaseSyncService.manualRestoreAll();
      int created = 0;
      int updated = 0;
      int keptLocalResumes = 0;
      for (final resume in cloudResumes) {
        final local = StorageService.getResume(resume.id);
        if (!shouldApplyCloudResume(
          localResume: local,
          cloudResume: resume,
        )) {
          keptLocalResumes++;
          continue;
        }

        await StorageService.saveResume(resume);
        if (local == null) {
          created++;
        } else {
          updated++;
        }
      }

      final cloudJobMaps = await SupabaseSyncService.manualRestoreJsonList(
        collection: _jobTrackerCollection,
        field: _jobTrackerField,
      );
      final cloudJobs = cloudJobMaps
          .map(JobApplicationRecord.fromMap)
          .toList(growable: false);
      final localJobs = await _jobTrackerService.loadJobs();
      final localJobsById = <String, JobApplicationRecord>{
        for (final job in localJobs) job.jobId: job,
      };

      int createdJobs = 0;
      int updatedJobs = 0;
      int keptLocalJobs = 0;
      for (final job in cloudJobs) {
        final local = localJobsById[job.jobId];
        if (local == null) {
          createdJobs++;
        } else if (job.updatedAt.isAfter(local.updatedAt)) {
          updatedJobs++;
        } else {
          keptLocalJobs++;
        }
      }

      if (cloudJobs.isNotEmpty) {
        final mergedJobs = _jobTrackerService.mergeByMostRecent(
          localJobs: localJobs,
          cloudJobs: cloudJobs,
        );
        await _jobTrackerService.persistJobs(mergedJobs);
      }

      widget.onRestored?.call();
      final hint = _currentCode == null
          ? ' TIP: Set a Sync Code to access data from other devices.'
          : '';
      final summaries = <String>[
        if (cloudResumes.isNotEmpty)
          created == 0 && updated == 0
              ? keptLocalResumes > 0
                  ? 'resumes: kept $keptLocalResumes newer local version(s)'
                  : 'resumes already up to date'
              : 'resumes: $created new, $updated updated${keptLocalResumes > 0 ? ', $keptLocalResumes kept local' : ''}',
        if (cloudJobs.isNotEmpty)
          createdJobs == 0 && updatedJobs == 0
              ? keptLocalJobs > 0
                  ? 'job tracker: kept $keptLocalJobs newer local item(s)'
                  : 'job tracker already up to date'
              : 'job tracker: $createdJobs new, $updatedJobs updated${keptLocalJobs > 0 ? ', $keptLocalJobs kept local' : ''}',
      ];
      final nextStatusMessage = summaries.isEmpty
          ? 'ℹ️ No backups found.$hint'
          : '✅ Restore complete: ${summaries.join(' • ')}.';
      final restoreRecordedAt = DateTime.now();
      await SyncStatusService.recordRestore(
        nextStatusMessage,
        at: restoreRecordedAt,
      );

      if (!mounted) return;
      setState(() {
        _inProgress = false;
        _statusMessage = nextStatusMessage;
        _lastSyncSummary = nextStatusMessage;
        _lastRestoreAt = restoreRecordedAt;
      });
    } catch (e) {
      final nextStatusMessage = '❌ Restore failed: $e';
      await SyncStatusService.recordStatus(nextStatusMessage);
      if (!mounted) return;
      setState(() {
        _inProgress = false;
        _statusMessage = nextStatusMessage;
        _lastSyncSummary = nextStatusMessage;
      });
    }
  }
}

// ─── AI API Key bottom-sheet widget ─────────────────────────────────────────
class _AiApiKeySheet extends StatefulWidget {
  const _AiApiKeySheet();

  @override
  State<_AiApiKeySheet> createState() => _AiApiKeySheetState();
}

class _AiApiKeySheetState extends State<_AiApiKeySheet> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saved = false;

  static final Uri _groqConsoleUri = Uri.parse('https://console.groq.com');

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await AiApiKeyStorageService.read();
    if (!mounted) return;
    setState(() => _controller.text = key);
  }

  Future<void> _saveKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final key = String.fromCharCodes(
      _controller.text.trim().codeUnits.where((c) => c >= 0x20 && c <= 0x7E),
    );
    if (key.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Paste your Groq API key first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!key.startsWith('gsk_')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This does not look like a Groq key. Use the key from console.groq.com that starts with gsk_, not a Firebase/Google key.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await AiApiKeyStorageService.save(key);
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearKey() async {
    await AiApiKeyStorageService.clear();
    setState(() {
      _controller.clear();
      _saved = false;
    });
  }

  Future<void> _openGroqConsole() async {
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(_groqConsoleUri)) {
      await launchUrl(_groqConsoleUri, mode: LaunchMode.externalApplication);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open Groq console'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
      _saved = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.viewPadding.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: bottomInset > 0 ? bottomInset + 20 : safeBottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.key, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Groq API Key',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '100% Free • No credit card needed',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdaptiveTooltip(
                    message: 'Close API key sheet',
                    button: true,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Iconsax.information,
                        color: AppColors.info,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Free key at: console.groq.com\n(Sign up → API Keys → Create key)',
                        style: TextStyle(color: AppColors.info, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openGroqConsole,
                      icon: const Icon(Iconsax.export_3),
                      label: const Text('Open Groq Console'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Iconsax.clipboard_text),
                      label: const Text('Paste Key'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Groq API Key',
                  helperText:
                      'Paste the Groq key from console.groq.com. It should start with gsk_.',
                  prefixIcon: const Icon(Iconsax.key),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdaptiveTooltip(
                        message: _obscure ? 'Show API key' : 'Hide API key',
                        button: true,
                        child: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Iconsax.eye : Iconsax.eye_slash,
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        AdaptiveTooltip(
                          message: 'Clear API key',
                          button: true,
                          child: IconButton(
                            onPressed: _clearKey,
                            icon: const Icon(
                              Iconsax.close_circle,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() => _saved = false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveKey,
                  icon: Icon(
                    _saved ? Iconsax.tick_circle : Iconsax.key,
                    color: Colors.white,
                  ),
                  label: Text(
                    _saved ? 'Saved!' : 'Save API Key',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _saved ? AppColors.success : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Stored securely on your device only',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
