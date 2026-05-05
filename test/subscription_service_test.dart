import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/subscription_model.dart';
import 'package:resume_builder/core/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads stored expiry date and cancellation flag without resetting them', () async {
    final expiry = DateTime(2026, 12, 31, 10, 30);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'subscription_plan': SubscriptionPlan.monthly.name,
      'subscription_expiry': expiry.millisecondsSinceEpoch.toString(),
      'subscription_cancel_at_period_end': true,
    });

    final service = SubscriptionService();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.state.plan, SubscriptionPlan.monthly);
    expect(service.state.expiryDate, expiry);
    expect(service.state.cancelAtPeriodEnd, isTrue);
  });

  test('scheduleCancellation keeps premium active until expiry', () async {
    final service = SubscriptionService();
    final expiry = DateTime(2026, 8, 15);
    service.upgradeToPlan(
      SubscriptionPlan.yearly,
      expiryDate: expiry,
    );

    await service.scheduleCancellation();
    final prefs = await SharedPreferences.getInstance();

    expect(service.state.plan, SubscriptionPlan.yearly);
    expect(service.state.expiryDate, expiry);
    expect(service.state.cancelAtPeriodEnd, isTrue);
    expect(prefs.getBool('subscription_cancel_at_period_end'), isTrue);
  });
}