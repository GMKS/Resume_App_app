import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';

class SubscriptionService extends StateNotifier<SubscriptionModel> {
  static const String _cancelAtPeriodEndKey =
      'subscription_cancel_at_period_end';
  static const String _providerKey = 'subscription_provider';
  static const String _activeKey = 'subscription_active';

  SubscriptionService() : super(SubscriptionModel.free()) {
    _loadSavedSubscription();
  }

  /// Load persisted subscription from SharedPreferences on startup.
  Future<void> _loadSavedSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString('subscription_plan');
    final expiryStr = prefs.getString('subscription_expiry');
    final cancelAtPeriodEnd =
        prefs.getBool(_cancelAtPeriodEndKey) ?? false;
    final providerName = prefs.getString(_providerKey);
    final billingProvider = BillingProvider.values.firstWhere(
      (provider) => provider.name == providerName,
      orElse: () => BillingProvider.local,
    );

    if (planName == null) return;

    final plan = SubscriptionPlan.values.firstWhere(
      (p) => p.name == planName,
      orElse: () => SubscriptionPlan.free,
    );

    if (billingProvider == BillingProvider.googlePlay) {
      final isActive = prefs.getBool(_activeKey) ?? true;
      if (isActive && plan != SubscriptionPlan.free) {
        upgradeToPlan(
          plan,
          billingProvider: billingProvider,
        );
      }
      return;
    }

    if (expiryStr == null) return;

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (expiry.isBefore(DateTime.now())) {
      // Subscription expired — clear storage and stay free
      await prefs.remove('subscription_plan');
      await prefs.remove('subscription_expiry');
      await prefs.remove(_cancelAtPeriodEndKey);
      await prefs.remove(_providerKey);
      await prefs.remove(_activeKey);
      return;
    }

    if (plan != SubscriptionPlan.free) {
      upgradeToPlan(
        plan,
        expiryDate: expiry,
        cancelAtPeriodEnd: cancelAtPeriodEnd,
        billingProvider: billingProvider,
      );
    }
  }

  void upgradeToPlan(
    SubscriptionPlan plan, {
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    state = SubscriptionModel.forPlan(
      plan,
      expiryDate: expiryDate,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
    );
  }

  Future<void> cancelSubscription() async {
    state = SubscriptionModel.free();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subscription_plan');
    await prefs.remove('subscription_expiry');
    await prefs.remove(_cancelAtPeriodEndKey);
    await prefs.remove(_providerKey);
    await prefs.remove(_activeKey);
  }

  Future<void> scheduleCancellation() async {
    if (!state.isPremium() || state.isStoreManaged) {
      return;
    }

    final expiryDate = state.expiryDate;
    if (expiryDate == null) {
      await cancelSubscription();
      return;
    }

    state = SubscriptionModel.forPlan(
      state.plan,
      expiryDate: expiryDate,
      cancelAtPeriodEnd: true,
      billingProvider: state.billingProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cancelAtPeriodEndKey, true);
  }

  Future<void> keepSubscription() async {
    if (!state.isPremium() || state.isStoreManaged) {
      return;
    }

    state = SubscriptionModel.forPlan(
      state.plan,
      expiryDate: state.expiryDate,
      cancelAtPeriodEnd: false,
      billingProvider: state.billingProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cancelAtPeriodEndKey, false);
  }

  bool hasFeatureAccess(String featureName) {
    return state.hasFeature(featureName);
  }
}

// Provider for subscription state
final subscriptionProvider =
    StateNotifierProvider<SubscriptionService, SubscriptionModel>((ref) {
  return SubscriptionService();
});
