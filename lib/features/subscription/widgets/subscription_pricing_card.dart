import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/models/subscription_pricing.dart';
import '../../../core/theme/app_theme.dart';

class SubscriptionPricingCard extends StatelessWidget {
  final SubscriptionPricingOption pricing;
  final String currentPrice;
  final String originalPrice;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final String? availabilityLabel;

  const SubscriptionPricingCard({
    super.key,
    required this.pricing,
    required this.currentPrice,
    required this.originalPrice,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    this.availabilityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = pricing.isBestValue
        ? AppColors.secondary
        : pricing.isMostPopular
            ? AppColors.accent
            : AppColors.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isEnabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? highlightColor.withValues(alpha: 0.08)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? highlightColor : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
                  blurRadius: isSelected ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: pricing.highlightLabel ?? 'Intro Pricing',
                            backgroundColor: highlightColor.withValues(alpha: 0.12),
                            foregroundColor: highlightColor,
                          ),
                          _Badge(
                            label: '${pricing.price.discountPercent}% OFF',
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            foregroundColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.tick_circle5,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pricing.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentPrice,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: highlightColor,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        pricing.periodLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      originalPrice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                    ),
                    if (pricing.savingsLabel != null)
                      Text(
                        pricing.savingsLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  availabilityLabel ?? 'Cancel anytime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isEnabled ? AppColors.textSecondary : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 16),
                ...pricing.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Iconsax.tick_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}