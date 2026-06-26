import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/services/data_deletion_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_sync_service.dart';
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
  String _appVersionLabel = 'Loading...';
  int _resumeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  void _loadInfo() async {
    final versionInfo = await AppVersionService.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _appVersionLabel = versionInfo.shortLabel;
      _resumeCount = StorageService.getAllResumes().length;
    });
  }

  void _showThemeDialog() {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete All Data'),
          ],
        ),
        content: const Text(
            'Are you sure you want to delete all resumes? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DataDeletionService.deleteUserData(deleteCloudData: false);
              if (!mounted) {
                return;
              }
              ref.read(resumesProvider.notifier).loadResumes();
              setState(() => _resumeCount = 0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All data deleted'),
                    backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlayStoreListing() async {
    final messenger = ScaffoldMessenger.of(context);
    final marketUri = Uri.tryParse(
      'market://details?id=${AppInfo.playStorePackageId}',
    );
    final webUri = Uri.tryParse(AppInfo.playStoreUrl);

    if (marketUri != null && await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (webUri != null && await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open store'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareApp() {
    final playStoreUri = Uri.tryParse(AppInfo.playStoreUrl);
    if (playStoreUri == null ||
        !playStoreUri.hasScheme ||
        playStoreUri.host.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share app link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out this awesome Resume Builder app!\n${playStoreUri.toString()}',
        subject: 'Resume Builder App',
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
            Text('Resume Builder',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version $_appVersionLabel',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const Text(
              'Create professional resumes with ease. Choose from beautiful templates, customize colors, and export to PDF.',
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
                  Iconsax.instagram,
                  'Instagram',
                  'https://www.instagram.com/'),
                const SizedBox(width: 16),
                _buildSocialButton(Iconsax.message, 'Support',
                    'mailto:${AppInfo.supportEmail}'),
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
        'Yes, all changes are saved automatically to your device. Data is stored locally and not uploaded to any server.'
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
            const Text('Last updated: January 2025',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...[
              (
                'Data Collection',
                'Resume Builder does not collect or transmit any personal data. All resume information you enter is stored locally on your device only.'
              ),
              (
                'Local Storage',
                'Your resumes and preferences are saved in your device\'s internal storage using Hive (a local NoSQL database). No data is sent to external servers.'
              ),
              (
                'Permissions',
                'The app may request storage access to export PDF resumes, camera/gallery access for profile photos, and internet access only for optional features like sharing.'
              ),
              (
                'Third Parties',
                'We do not sell, trade, or share your personal data with any third parties.'
              ),
              (
                'Data Deletion',
                'You can delete all your data at any time via Settings → Delete All Data. Uninstalling the app also removes all stored data.'
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
            const Text('Effective: January 2025',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...[
              (
                'Acceptance',
                'By using Resume Builder, you agree to these terms. If you do not agree, please uninstall the app.'
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
              onTap: () => context.push('/my-resumes'),
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
              subtitle: 'Remove all resumes and settings',
              onTap: _showDeleteAllDialog,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT'),
            _buildSettingTile(
              icon: Iconsax.star_1,
              title: 'Rate App',
              subtitle: 'Love the app? Give us 5 stars!',
              onTap: _openPlayStoreListing,
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
              onTap: _shareApp,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('ABOUT'),
            _buildSettingTile(
              icon: Iconsax.info_circle,
              title: 'About',
              subtitle: 'Version $_appVersionLabel',
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
  CloudIdentityStatus? _identity;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    final identity = await SupabaseSyncService.getCloudIdentityStatus();
    if (identity.legacySharedSyncDetected) {
      await SupabaseSyncService.clearLegacySharedSyncCode();
    }
    if (mounted) {
      setState(() {
        _identity = identity;
        if (identity.legacySharedSyncDetected) {
          _statusMessage =
              'ℹ️ Legacy sync codes were disabled for security. Cloud sync now uses your authenticated workspace only. Back up again from this device to migrate safely.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
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
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Iconsax.arrow_left_2),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
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
                  '1. Sign in on each device with the same account to access the same private cloud workspace.',
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
                  '3. On another device logged into the same account, tap Restore from Cloud to pull that data down.',
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
                  'Cloud data is isolated by authenticated user. Another account can never read this workspace, even if it knows an old sync code or document ID.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                SizedBox(height: 6),
                Text(
                  'This is manual sync right now. It does not auto-sync in the background.',
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

          // ── Cloud workspace panel ────────────────────────────────────────
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
                Row(
                  children: [
                    const Icon(Iconsax.link,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          identity?.hasSharedCloudAccess == true
                              ? 'Cloud Workspace'
                              : 'Private Workspace',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  identity?.hasSharedCloudAccess == true
                      ? 'This workspace is linked to your authenticated account. Devices signed into the same account can back up and restore the same private data.'
                      : 'This device is currently using an anonymous private workspace. Sign in with the same account on each device to enable secure multi-device sync.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (identity?.hasSharedCloudAccess == true
                            ? AppColors.success
                            : AppColors.warning)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (identity?.hasSharedCloudAccess == true
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        identity?.hasSharedCloudAccess == true
                            ? Iconsax.tick_circle
                            : Iconsax.warning_2,
                        size: 14,
                        color: identity?.hasSharedCloudAccess == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          identity?.hasSharedCloudAccess == true
                              ? 'Linked to ${identity?.displayLabel ?? 'your account'}'
                              : 'Guest workspace only on this device',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: identity?.hasSharedCloudAccess == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (identity != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    identity.hasSharedCloudAccess
                        ? 'Cloud user ID: ${identity.uid.substring(0, 8)}…'
                        : 'Device ID: ${identity.deviceId.substring(0, 8)}…',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
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
              onPressed: _inProgress ? null : _confirmBackup,
              icon: _inProgress
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Iconsax.cloud_add),
              label: Text(_inProgress ? 'Processing...' : 'Backup to Cloud'),
            ),
          ),
          const SizedBox(height: 10),

          // ── Restore from Cloud button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _inProgress ? null : _confirmRestore,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from Cloud'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmBackup() async {
    final confirmed = await _confirmSyncAction(
      title: 'Backup to Cloud?',
      message:
          'This uploads the latest resumes and job tracker updates to your authenticated cloud workspace. On another device, sign in with the same account and tap Restore there.',
      confirmLabel: 'Backup Now',
    );
    if (confirmed) {
      await _doBackup();
    }
  }

  Future<void> _confirmRestore() async {
    final confirmed = await _confirmSyncAction(
      title: 'Restore from Cloud?',
      message:
          'This pulls the latest backup from your authenticated cloud workspace and updates this device. Newer cloud items will be merged into your local data.',
      confirmLabel: 'Restore Now',
    );
    if (confirmed) {
      await _doRestore();
    }
  }

  Future<bool> _confirmSyncAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed ?? false;
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
        _statusMessage =
            'ℹ️ Nothing to back up yet. Create or edit a resume or tracked job first, then try again.';
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
    final label = _identity?.hasSharedCloudAccess == true
        ? 'your account workspace'
        : 'this private guest workspace';
    final backedUp = <String>[
      if (resumeError == null && resumes.isNotEmpty)
        '${resumes.length} resume(s)',
      if (jobError == null && jobs.isNotEmpty) '${jobs.length} tracked job(s)',
    ];
    final failures = <String>[
      if (resumeError != null) 'Resumes: $resumeError',
      if (jobError != null) 'Job tracker: $jobError',
    ];

    setState(() {
      _inProgress = false;
      _statusMessage = failures.isEmpty
          ? '✅ Backup complete. Saved ${backedUp.join(' and ')} to $label. Sign in with the same account on your other device, then tap Restore from Cloud there.'
          : backedUp.isEmpty
              ? '❌ Backup could not finish. Please try again.\n${failures.join('\n')}'
              : '✅ Backup saved ${backedUp.join(' and ')} to $label, but some items still need attention.\n${failures.join('\n')}';
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
      for (final resume in cloudResumes) {
        final local = StorageService.getResume(resume.id);
        if (!shouldApplyCloudResume(
          localResume: local,
          cloudResume: resume,
        )) {
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
      for (final job in cloudJobs) {
        final local = localJobsById[job.jobId];
        if (local == null) {
          createdJobs++;
        } else if (job.updatedAt.isAfter(local.updatedAt)) {
          updatedJobs++;
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
      final hint = _identity?.hasSharedCloudAccess == true
          ? ''
          : ' Sign in with the same account on both devices to enable secure cross-device sync.';
      final summaries = <String>[
        if (cloudResumes.isNotEmpty)
          created == 0 && updated == 0
              ? 'resumes already up to date'
              : 'resumes: $created new, $updated updated',
        if (cloudJobs.isNotEmpty)
          createdJobs == 0 && updatedJobs == 0
              ? 'job tracker already up to date'
              : 'job tracker: $createdJobs new, $updatedJobs updated',
      ];
      if (!mounted) return;
      setState(() {
        _inProgress = false;
        _statusMessage = summaries.isEmpty
            ? 'ℹ️ No cloud backup was found for this workspace.$hint'
            : '✅ Restore complete. ${summaries.join(' • ')}. If another device has newer changes, run Backup there first and Restore here again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inProgress = false;
        _statusMessage =
            '❌ Restore could not finish. Check your internet connection and account session, then try again.\n$e';
      });
    }
  }
}
