import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/services/subscription_service.dart';
import '../../core/theme/app_theme.dart';

class PremiumBadge extends StatelessWidget {
  final String label;
  final bool locked;

  const PremiumBadge({
    super.key,
    this.label = 'PRO',
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            locked ? Iconsax.lock_1 : Iconsax.crown_1,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureGate extends ConsumerWidget {
  final String featureName;
  final Widget child;
  final String? upgradeMessage;

  const FeatureGate({
    super.key,
    required this.featureName,
    required this.child,
    this.upgradeMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    if (subscription.hasFeature(featureName)) {
      return child;
    }

    return UpgradePromptCard(
      featureName: featureName,
      message: upgradeMessage,
    );
  }
}

class UpgradePromptCard extends StatelessWidget {
  final String featureName;
  final String? message;

  const UpgradePromptCard({
    super.key,
    required this.featureName,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.crown_1,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Feature',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Upgrade to access this feature and unlock your career potential',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/subscription'),
              icon: const Icon(Iconsax.star_1),
              label: const Text('Upgrade Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showUpgradePromptSheet(
  BuildContext context, {
  required String featureName,
  String? message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: UpgradePromptCard(
          featureName: featureName,
          message: message,
        ),
      ),
    ),
  );
}
