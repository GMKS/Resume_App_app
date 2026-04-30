import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/subscription_service.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Iconsax.user,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'John Doe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'john.doe@example.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Iconsax.edit, size: 18),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Subscription Card
          Card(
            child: InkWell(
              onTap: () => context.push('/subscription'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: subscription.isPremium()
                            ? AppColors.primaryGradient
                            : null,
                        color: subscription.isPremium()
                            ? null
                            : AppColors.textTertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.crown_1,
                        color: subscription.isPremium()
                            ? Colors.white
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subscription.isPremium()
                                ? 'Expires ${_formatDate(subscription.expiryDate!)}'
                                : 'Upgrade to unlock premium features',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Settings List
          _ProfileMenuItem(
            icon: Iconsax.setting_2,
            title: 'App Settings',
            onTap: () => context.push('/settings'),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 12),

          _ProfileMenuItem(
            icon: Iconsax.notification,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 12),

          _ProfileMenuItem(
            icon: Iconsax.shield_tick,
            title: 'Privacy & Security',
            onTap: () => context.push('/privacy-security'),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 12),

          _ProfileMenuItem(
            icon: Iconsax.message_question,
            title: 'Help & Support',
            onTap: () => context.push('/help-support'),
          ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 12),

          _ProfileMenuItem(
            icon: Iconsax.document_text_1,
            title: 'Terms & Conditions',
            onTap: () => context.push('/terms-conditions'),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 12),

          _ProfileMenuItem(
            icon: Iconsax.information,
            title: 'About',
            onTap: () => context.push('/about'),
          ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Logout Button
          Card(
            color: AppColors.error.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.logout, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLogoutDialog(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?\nYou will need to verify your phone again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              // Clear saved session
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              await prefs.remove('saved_phone');
              if (outerContext.mounted) {
                outerContext.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
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
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
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
