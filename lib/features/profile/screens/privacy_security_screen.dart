import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/services/data_deletion_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _twoFactor = false;
  bool _biometricLogin = false;
  bool _dataCollection = true;
  bool _analyticsSharing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = StorageService.prefs;
    setState(() {
      _twoFactor = prefs.getBool('sec_2fa') ?? false;
      _biometricLogin = prefs.getBool('sec_biometric') ?? false;
      _dataCollection = prefs.getBool('sec_data_collection') ?? true;
      _analyticsSharing = prefs.getBool('sec_analytics') ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = StorageService.prefs;
    await prefs.setBool(key, value);
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete My Data'),
          ],
        ),
        content: const Text(
          'Users can delete their data anytime. Delete the app data stored on this device and remove any synced backups tied to your current sync code or device? This also signs you out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DataDeletionService.deleteUserData();
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your app data has been deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Delete Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const _SectionHeader(title: 'Security').animate().fadeIn(delay: 50.ms),
          _buildToggle(
            icon: Iconsax.shield_tick,
            title: 'Two-Factor Authentication',
            subtitle: 'Require OTP on every login',
            value: _twoFactor,
            delay: 100,
            onChanged: (v) {
              setState(() => _twoFactor = v);
              _savePref('sec_2fa', v);
            },
          ),
          _buildToggle(
            icon: Iconsax.finger_scan,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or Face ID',
            value: _biometricLogin,
            delay: 150,
            onChanged: (v) {
              setState(() => _biometricLogin = v);
              _savePref('sec_biometric', v);
            },
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Privacy').animate().fadeIn(delay: 200.ms),
          _buildToggle(
            icon: Iconsax.data,
            title: 'Data Collection',
            subtitle: 'Allow us to collect usage data to improve the app',
            value: _dataCollection,
            delay: 250,
            onChanged: (v) {
              setState(() => _dataCollection = v);
              _savePref('sec_data_collection', v);
            },
          ),
          _buildToggle(
            icon: Iconsax.chart_2,
            title: 'Analytics Sharing',
            subtitle: 'Share anonymised analytics with third parties',
            value: _analyticsSharing,
            delay: 300,
            onChanged: (v) {
              setState(() => _analyticsSharing = v);
              _savePref('sec_analytics', v);
            },
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Data').animate().fadeIn(delay: 350.ms),
          _buildActionTile(
            icon: Iconsax.export,
            title: 'Export My Data',
            subtitle: 'Download a copy of all your data',
            iconColor: AppColors.primary,
            delay: 400,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export feature coming soon.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildActionTile(
            icon: Iconsax.trash,
            title: 'Delete My Data',
            subtitle: 'Clear local data and synced app backups anytime',
            iconColor: Colors.red,
            delay: 450,
            onTap: _showDeleteAccountDialog,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required int delay,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
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
                            ?.copyWith(
                                fontWeight: FontWeight.w600, color: iconColor)),
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
