import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _developer = 'Seenai GMK';
  static const String _linkedinUrl = 'https://www.linkedin.com/in/seenai';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      query:
          'subject=${Uri.encodeQueryComponent('Inquiry - ${AppInfo.appName} App')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.document_text_1,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppInfo.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<AppVersionInfo>(
                future: AppVersionService.load(),
                builder: (context, snapshot) {
                  final label = switch (snapshot.connectionState) {
                    ConnectionState.waiting => 'Version loading...',
                    _ => (snapshot.data ?? AppVersionService.unavailable)
                        .displayLabel,
                  };

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Craft your perfect resume with AI-powered tools',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 28),
          const Row(
            children: [
              _StatCard(value: '20+', label: 'Templates', icon: Iconsax.layer),
              SizedBox(width: 10),
              _StatCard(value: 'AI', label: 'Powered', icon: Iconsax.cpu),
              SizedBox(width: 10),
              _StatCard(value: 'ATS', label: 'Optimised', icon: Iconsax.chart),
            ],
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Developer')
              .animate()
              .fadeIn(delay: 200.ms),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.user, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _developer,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppInfo.supportEmail,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.sms),
                    onPressed: _launchEmail,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Links').animate().fadeIn(delay: 300.ms),
          _buildLinkTile(
            context,
            icon: Iconsax.global,
            title: 'Visit Website',
            subtitle: AppInfo.websiteUrl,
            delay: 350,
            onTap: () => _launchUrl(AppInfo.websiteUrl),
          ),
          _buildLinkTile(
            context,
            icon: Iconsax.shield_tick,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            delay: 400,
            onTap: () => _launchUrl(AppInfo.privacyPolicyUrl),
          ),
          _buildLinkTile(
            context,
            icon: Iconsax.star,
            title: 'Rate Us on Play Store',
            subtitle: 'Your feedback helps us grow',
            delay: 450,
            onTap: () => _launchUrl(AppInfo.playStoreUrl),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Follow Us')
              .animate()
              .fadeIn(delay: 500.ms),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'LinkedIn',
                  icon: Icons.link,
                  color: const Color(0xFF0077B5),
                  onTap: () => _launchUrl(_linkedinUrl),
                ).animate().fadeIn(delay: 550.ms),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text(
                  '© 2026 $_developer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ in India',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 650.ms),
          const SizedBox(height: 60),
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
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      )),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      )),
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
