import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/subscription_model.dart';
import 'package:resume_builder/core/models/subscription_pricing.dart';
import 'package:resume_builder/core/services/pricing_region_service.dart';
import 'package:resume_builder/core/services/subscription_pricing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionPricingService', () {
    test('returns updated India pricing and highlights', () {
      final monthly = SubscriptionPricingService.planFor(
        PricingRegion.india,
        SubscriptionPlan.monthly,
      );
      final yearly = SubscriptionPricingService.planFor(
        PricingRegion.india,
        SubscriptionPlan.yearly,
      );

      expect(monthly.price.formatCurrent(), '₹399');
      expect(monthly.price.formatOriginal(), '₹599');
      expect(monthly.highlightLabel, 'Most Popular');

      expect(yearly.price.formatCurrent(), '₹1,999');
      expect(yearly.highlightLabel, 'Best Value');
    });

    test('returns updated global pricing and quarterly savings', () {
      final weekly = SubscriptionPricingService.planFor(
        PricingRegion.global,
        SubscriptionPlan.weekly,
      );
      final quarterly = SubscriptionPricingService.planFor(
        PricingRegion.global,
        SubscriptionPlan.quarterly,
      );

      expect(weekly.price.formatCurrent(), r'$3.99');
      expect(weekly.price.formatOriginal(), r'$5.99');
      expect(quarterly.price.formatCurrent(), r'$29.99');
      expect(quarterly.savingsLabel, 'Save ~35%');
    });
  });

  group('PricingRegionService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('detects India from locale and caches the region', () async {
      final service = PricingRegionService();

      final region = await service.resolveRegion(
        localeOverride: const Locale('en', 'IN'),
      );
      final prefs = await SharedPreferences.getInstance();

      expect(region, PricingRegion.india);
      expect(prefs.getString('pricing_region'), PricingRegion.india.name);
      expect(prefs.getString('pricing_country_code'), 'IN');
    });

    test('uses cached region before applying a new locale override', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pricing_region': PricingRegion.global.name,
        'pricing_country_code': 'US',
      });

      final service = PricingRegionService();
      final region = await service.resolveRegion(
        localeOverride: const Locale('en', 'IN'),
      );

      expect(region, PricingRegion.global);
    });
  });
}