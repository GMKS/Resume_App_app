import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _resumeReminders = true;
  bool _jobAlerts = true;
  bool _subscriptionAlerts = true;
  bool _tipsAndUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = StorageService.prefs;
    setState(() {
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _emailNotifications = prefs.getBool('notif_email') ?? false;
      _resumeReminders = prefs.getBool('notif_resume_reminders') ?? true;
      _jobAlerts = prefs.getBool('notif_job_alerts') ?? true;
      _subscriptionAlerts = prefs.getBool('notif_subscription') ?? true;
      _tipsAndUpdates = prefs.getBool('notif_tips') ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = StorageService.prefs;
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const _SectionHeader(title: 'General').animate().fadeIn(delay: 50.ms),
          _buildToggle(
            icon: Iconsax.notification,
            title: 'Push Notifications',
            subtitle: 'Receive alerts on your device',
            value: _pushNotifications,
            delay: 100,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _savePref('notif_push', v);
            },
          ),
          _buildToggle(
            icon: Iconsax.sms,
            title: 'Email Notifications',
            subtitle: 'Receive updates to your email',
            value: _emailNotifications,
            delay: 150,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _savePref('notif_email', v);
            },
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Activity').animate().fadeIn(delay: 200.ms),
          _buildToggle(
            icon: Iconsax.document_text,
            title: 'Resume Reminders',
            subtitle: 'Reminders to update your resume',
            value: _resumeReminders,
            delay: 250,
            onChanged: (v) {
              setState(() => _resumeReminders = v);
              _savePref('notif_resume_reminders', v);
            },
          ),
          _buildToggle(
            icon: Iconsax.briefcase,
            title: 'Job Alerts',
            subtitle: 'New job opportunities matching your profile',
            value: _jobAlerts,
            delay: 300,
            onChanged: (v) {
              setState(() => _jobAlerts = v);
              _savePref('notif_job_alerts', v);
            },
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Account').animate().fadeIn(delay: 350.ms),
          _buildToggle(
            icon: Iconsax.crown_1,
            title: 'Subscription Alerts',
            subtitle: 'Renewal reminders and plan updates',
            value: _subscriptionAlerts,
            delay: 400,
            onChanged: (v) {
              setState(() => _subscriptionAlerts = v);
              _savePref('notif_subscription', v);
            },
          ),
          _buildToggle(
            icon: Iconsax.lamp_on,
            title: 'Tips & Updates',
            subtitle: 'App tips, news and feature announcements',
            value: _tipsAndUpdates,
            delay: 450,
            onChanged: (v) {
              setState(() => _tipsAndUpdates = v);
              _savePref('notif_tips', v);
            },
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
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.05, end: 0);
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
