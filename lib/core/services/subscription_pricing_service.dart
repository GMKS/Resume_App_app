import '../models/subscription_model.dart';
import '../models/subscription_pricing.dart';

class SubscriptionPricingService {
  static const List<String> _weeklyFeatures = <String>[
    'All premium templates',
    'Unlimited resumes',
    'Unlimited PDF export without watermark',
    'Premium sections and layouts',
    'AI tools and ATS optimisation',
    'Cover letter builder',
  ];

  static const List<String> _monthlyFeatures = <String>[
    'Everything in Weekly',
    'DOCX and TXT exports',
    'Photo and signature support',
    'Cloud sync across devices',
    'Priority support',
    'Premium media support',
  ];

  static const List<String> _quarterlyFeatures = <String>[
    'Everything in Monthly',
    'Interview preparation tools',
    'Skill analysis and career tools',
    'Extended premium support',
    'Save about 35% on longer access',
  ];

  static const List<String> _yearlyFeatures = <String>[
    'Everything in Quarterly',
    'Priority support all year',
    'Best annual savings',
    'All future premium unlocks',
    'Complete pro toolkit',
  ];

  static const Map<PricingRegion,
          Map<SubscriptionPlan, SubscriptionPricingOption>> _pricingByRegion =
      <PricingRegion, Map<SubscriptionPlan, SubscriptionPricingOption>>{
    PricingRegion.india: <SubscriptionPlan, SubscriptionPricingOption>{
      SubscriptionPlan.weekly: SubscriptionPricingOption(
        plan: SubscriptionPlan.weekly,
        name: 'Weekly Pro',
        periodLabel: '/week',
        checkoutDescription: '7 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'INR',
          amountInMinorUnits: 19900,
          originalAmountInMinorUnits: 19900,
        ),
        savingsLabel: 'Intro pricing',
        features: _weeklyFeatures,
      ),
      SubscriptionPlan.monthly: SubscriptionPricingOption(
        plan: SubscriptionPlan.monthly,
        name: 'Monthly Pro',
        periodLabel: '/month',
        checkoutDescription: '30 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'INR',
          amountInMinorUnits: 59900,
          originalAmountInMinorUnits: 59900,
        ),
        highlight: PricingHighlight.mostPopular,
        highlightLabel: 'Most Popular',
        savingsLabel: 'Best monthly value',
        features: _monthlyFeatures,
      ),
      SubscriptionPlan.quarterly: SubscriptionPricingOption(
        plan: SubscriptionPlan.quarterly,
        name: 'Quarterly Pro',
        periodLabel: '/3 months',
        checkoutDescription: '90 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'INR',
          amountInMinorUnits: 79900,
          originalAmountInMinorUnits: 79900,
        ),
        savingsLabel: 'Save ~35%',
        features: _quarterlyFeatures,
      ),
      SubscriptionPlan.yearly: SubscriptionPricingOption(
        plan: SubscriptionPlan.yearly,
        name: 'Yearly Pro',
        periodLabel: '/year',
        checkoutDescription: '365 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'INR',
          amountInMinorUnits: 249900,
          originalAmountInMinorUnits: 249900,
        ),
        highlight: PricingHighlight.bestValue,
        highlightLabel: 'Best Value',
        savingsLabel: 'Lowest effective monthly price',
        features: _yearlyFeatures,
      ),
    },
    PricingRegion.global: <SubscriptionPlan, SubscriptionPricingOption>{
      SubscriptionPlan.weekly: SubscriptionPricingOption(
        plan: SubscriptionPlan.weekly,
        name: 'Weekly Pro',
        periodLabel: '/week',
        checkoutDescription: '7 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'USD',
          amountInMinorUnits: 399,
          originalAmountInMinorUnits: 599,
        ),
        savingsLabel: 'Intro pricing',
        features: _weeklyFeatures,
      ),
      SubscriptionPlan.monthly: SubscriptionPricingOption(
        plan: SubscriptionPlan.monthly,
        name: 'Monthly Pro',
        periodLabel: '/month',
        checkoutDescription: '30 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'USD',
          amountInMinorUnits: 1299,
          originalAmountInMinorUnits: 1999,
        ),
        highlight: PricingHighlight.mostPopular,
        highlightLabel: 'Most Popular',
        savingsLabel: 'Best monthly value',
        features: _monthlyFeatures,
      ),
      SubscriptionPlan.quarterly: SubscriptionPricingOption(
        plan: SubscriptionPlan.quarterly,
        name: 'Quarterly Pro',
        periodLabel: '/3 months',
        checkoutDescription: '90 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'USD',
          amountInMinorUnits: 2999,
          originalAmountInMinorUnits: 4599,
        ),
        savingsLabel: 'Save ~35%',
        features: _quarterlyFeatures,
      ),
      SubscriptionPlan.yearly: SubscriptionPricingOption(
        plan: SubscriptionPlan.yearly,
        name: 'Yearly Pro',
        periodLabel: '/year',
        checkoutDescription: '365 days of full premium access',
        price: SubscriptionPrice(
          currencyCode: 'USD',
          amountInMinorUnits: 5999,
          originalAmountInMinorUnits: 9999,
        ),
        highlight: PricingHighlight.bestValue,
        highlightLabel: 'Best Value',
        savingsLabel: 'Lowest effective monthly price',
        features: _yearlyFeatures,
      ),
    },
  };

  static List<SubscriptionPricingOption> plansForRegion(PricingRegion region) {
    final pricing =
        _pricingByRegion[region] ?? _pricingByRegion[PricingRegion.global]!;
    return SubscriptionPlan.values
        .where((plan) => plan != SubscriptionPlan.free)
        .map((plan) => pricing[plan]!)
        .toList(growable: false);
  }

  static SubscriptionPricingOption planFor(
    PricingRegion region,
    SubscriptionPlan plan,
  ) {
    final pricing =
        _pricingByRegion[region] ?? _pricingByRegion[PricingRegion.global]!;
    return pricing[plan] ?? pricing[SubscriptionPlan.monthly]!;
  }

  static PricingRegion regionFromCountryCode(String? countryCode) {
    if (countryCode?.toUpperCase() == 'IN') {
      return PricingRegion.india;
    }
    return PricingRegion.global;
  }
}
