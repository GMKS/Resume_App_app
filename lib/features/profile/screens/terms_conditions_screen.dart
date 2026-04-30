import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String _lastUpdated = 'February 2026';

  static const _sections = <_TermsSection>[
    _TermsSection(
      title: '1. Acceptance of Terms',
      content:
          'By downloading, installing, or using the Resume Builder app ("App"), you agree to be bound by these Terms & Conditions. If you do not agree to these terms, please do not use the App.',
    ),
    _TermsSection(
      title: '2. Use of the App',
      content:
          'You may use the App for personal, non-commercial purposes only. You agree not to misuse the App, attempt to gain unauthorised access to any part of the service, or use the App in any way that violates applicable laws or regulations.',
    ),
    _TermsSection(
      title: '3. User Accounts',
      content:
          'To access some features, you must register using your phone number. You are responsible for maintaining the confidentiality of your account and for all activities that occur under it. You agree to notify us immediately of any unauthorised use of your account.',
    ),
    _TermsSection(
      title: '4. Intellectual Property',
      content:
          'All content within the App, including but not limited to text, graphics, icons, templates, and software, is the property of Resume Builder and is protected by applicable intellectual property laws. You may not reproduce, distribute, or create derivative works without explicit written permission.',
    ),
    _TermsSection(
      title: '5. Subscription & Payments',
      content:
          'Some features are available only with a paid subscription. Subscriptions are billed in advance on a monthly or annual basis. Payments are processed securely through Razorpay. You can cancel your subscription at any time; cancellation takes effect at the end of the current billing period. No refunds are provided for partial billing periods.',
    ),
    _TermsSection(
      title: '6. User Content',
      content:
          'You retain ownership of all content you create using the App, including resume data and documents. By using the App, you grant us a limited licence to store and process your content solely for the purpose of providing the service.',
    ),
    _TermsSection(
      title: '7. Privacy',
      content:
          'Your use of the App is also governed by our Privacy Policy. We are committed to protecting your personal information and will not sell or share it with third parties except as described in the Privacy Policy.',
    ),
    _TermsSection(
      title: '8. Disclaimer of Warranties',
      content:
          'The App is provided "as is" and "as available" without any warranties of any kind, either express or implied. We do not guarantee that the App will be error-free, uninterrupted, or that employment outcomes will result from using the App.',
    ),
    _TermsSection(
      title: '9. Limitation of Liability',
      content:
          'To the maximum extent permitted by law, Resume Builder shall not be liable for any indirect, incidental, or consequential damages arising out of your use of the App, including loss of data or revenue.',
    ),
    _TermsSection(
      title: '10. Termination',
      content:
          'We reserve the right to suspend or terminate your access to the App at any time if you violate these Terms. You may also delete your account at any time from within the App.',
    ),
    _TermsSection(
      title: '11. Changes to Terms',
      content:
          'We may update these Terms & Conditions from time to time. We will notify you of significant changes via the App or email. Continued use of the App after changes constitutes acceptance of the new Terms.',
    ),
    _TermsSection(
      title: '12. Governing Law',
      content:
          'These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Bangalore, Karnataka.',
    ),
    _TermsSection(
      title: '13. Contact',
      content:
          'If you have any questions regarding these Terms & Conditions, please contact us at: legal@resumebuilder.app',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.document_text_1,
                    color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: $_lastUpdated',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          Text(
            'Please read these Terms & Conditions carefully before using the Resume Builder application.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Sections
          ..._sections.asMap().entries.map((e) {
            return _TermsSectionCard(section: e.value)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 150 + e.key * 40));
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _TermsSection {
  final String title;
  final String content;
  const _TermsSection({required this.title, required this.content});
}

class _TermsSectionCard extends StatelessWidget {
  final _TermsSection section;
  const _TermsSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              section.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
