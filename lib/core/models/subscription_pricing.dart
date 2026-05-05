import 'package:intl/intl.dart';

import 'subscription_model.dart';

enum PricingRegion {
  india,
  global,
}

enum PricingHighlight {
  mostPopular,
  bestValue,
}

class SubscriptionPrice {
  final String currencyCode;
  final int amountInMinorUnits;
  final int originalAmountInMinorUnits;

  const SubscriptionPrice({
    required this.currencyCode,
    required this.amountInMinorUnits,
    required this.originalAmountInMinorUnits,
  });

  int get decimalDigits => currencyCode == 'INR' ? 0 : 2;

  String get currencySymbol => currencyCode == 'INR' ? '₹' : r'$';

  double get amount => amountInMinorUnits / 100;

  double get originalAmount => originalAmountInMinorUnits / 100;

  int get discountPercent {
    if (originalAmountInMinorUnits <= amountInMinorUnits) {
      return 0;
    }

    final savings = originalAmountInMinorUnits - amountInMinorUnits;
    return ((savings / originalAmountInMinorUnits) * 100).round();
  }

  String formatCurrent() => _formatter.format(amount);

  String formatOriginal() => _formatter.format(originalAmount);

  NumberFormat get _formatter => NumberFormat.currency(
        name: currencyCode,
        symbol: currencySymbol,
        decimalDigits: decimalDigits,
      );
}

class SubscriptionPricingOption {
  final SubscriptionPlan plan;
  final String name;
  final String periodLabel;
  final String checkoutDescription;
  final SubscriptionPrice price;
  final List<String> features;
  final PricingHighlight? highlight;
  final String? highlightLabel;
  final String? savingsLabel;

  const SubscriptionPricingOption({
    required this.plan,
    required this.name,
    required this.periodLabel,
    required this.checkoutDescription,
    required this.price,
    required this.features,
    this.highlight,
    this.highlightLabel,
    this.savingsLabel,
  });

  bool get isMostPopular => highlight == PricingHighlight.mostPopular;

  bool get isBestValue => highlight == PricingHighlight.bestValue;
}