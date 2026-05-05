import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/user_session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/subscription_service.dart';

class _ProfileIdentity {
  const _ProfileIdentity({
    required this.displayName,
    required this.contact,
    this.photoUrl,
  });

  final String displayName;
  final String contact;
  final String? photoUrl;
}

class ProfileTabScreen extends ConsumerStatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  ConsumerState<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends ConsumerState<ProfileTabScreen> {
  late Future<_ProfileIdentity> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileIdentity();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfileIdentity();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: FutureBuilder<_ProfileIdentity>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data ??
                      const _ProfileIdentity(
                        displayName: 'User',
                        contact: 'Not signed in',
                      );

                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _profileImageProvider(profile.photoUrl),
                        child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                            ? const Icon(
                                Iconsax.user,
                                size: 40,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.contact,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showEditProfileSheet(profile),
                        icon: const Icon(Iconsax.edit, size: 18),
                        label: const Text('Edit Profile'),
                      ),
                    ],
                  );
                },
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
                              ? subscription.isStoreManaged
                                ? 'Managed in Google Play'
                                : subscription.cancelAtPeriodEnd
                                    ? 'Cancels ${_formatDate(subscription.expiryDate!)}'
                                    : 'Expires ${_formatDate(subscription.expiryDate!)}'
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

  Future<_ProfileIdentity> _loadProfileIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDisplayName = prefs.getString('display_name')?.trim() ?? '';
    final rawContact =
        UserSessionService.formatContactForDisplay(
          UserSessionService.readStoredContact(prefs),
        );
    final rawPhotoUrl = prefs.getString('photo_url')?.trim() ?? '';

    final displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : _fallbackDisplayName(rawContact);

    final contact = rawContact.isNotEmpty ? rawContact : 'Not signed in';

    return _ProfileIdentity(
      displayName: displayName,
      contact: contact,
      photoUrl: rawPhotoUrl.isNotEmpty ? rawPhotoUrl : null,
    );
  }

  String _fallbackDisplayName(String contact) {
    if (contact.isEmpty) {
      return 'User';
    }

    if (contact.contains('•')) {
      return 'User';
    }

    if (contact.contains('@')) {
      final localPart = contact.split('@').first.trim();
      if (localPart.isEmpty) {
        return contact;
      }

      return localPart
          .split(RegExp(r'[._-]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }

    return contact;
  }

  ImageProvider<Object>? _profileImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    return NetworkImage(photoUrl);
  }

  Future<void> _showEditProfileSheet(_ProfileIdentity profile) async {
    final savedName = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _EditProfileSheet(
        currentDisplayName: profile.displayName,
        contact: profile.contact,
      ),
    );

    if (savedName == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final trimmed = savedName.trim();
    if (trimmed.isEmpty) {
      await prefs.remove('display_name');
    } else {
      await prefs.setString('display_name', trimmed);
    }

    _refreshProfile();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              await UserSessionService.clearStoredContact(prefs);
              await prefs.remove('display_name');
              await prefs.remove('photo_url');
              await prefs.remove('auth_provider');
              if (outerContext.mounted) {
                outerContext.go('/login?loggedOut=true');
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.currentDisplayName,
    required this.contact,
  });

  final String currentDisplayName;
  final String contact;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.currentDisplayName);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave the name blank if you want the profile card to fall back to your login phone or email automatically.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Enter your name',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login contact',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contact,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _displayNameController.text,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
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
