import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';

class SubscriptionService extends StateNotifier<SubscriptionModel> {
  static const String _cancelAtPeriodEndKey =
      'subscription_cancel_at_period_end';
  static const String _providerKey = 'subscription_provider';
  static const String _activeKey = 'subscription_active';
  static const String _verifiedKey = 'subscription_verified';

  SubscriptionService() : super(SubscriptionModel.free()) {
    _loadSavedSubscription();
  }

  /// Load persisted subscription from SharedPreferences on startup.
  Future<void> _loadSavedSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString('subscription_plan');
    final expiryStr = prefs.getString('subscription_expiry');
    final cancelAtPeriodEnd = prefs.getBool(_cancelAtPeriodEndKey) ?? false;
    final providerName = prefs.getString(_providerKey);
    final billingProvider = BillingProvider.values.firstWhere(
      (provider) => provider.name == providerName,
      orElse: () => BillingProvider.local,
    );
    final verified = prefs.getBool(_verifiedKey) ?? false;

    if (planName == null) return;

    final plan = SubscriptionPlan.values.firstWhere(
      (p) => p.name == planName,
      orElse: () => SubscriptionPlan.free,
    );

    if (billingProvider == BillingProvider.googlePlay) {
      final isActive = prefs.getBool(_activeKey) ?? true;
      final expiry = expiryStr == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
      if (isActive && plan != SubscriptionPlan.free) {
        upgradeToPlan(
          plan,
          expiryDate: expiry,
          cancelAtPeriodEnd: cancelAtPeriodEnd,
          billingProvider: billingProvider,
        );
      } else if (plan != SubscriptionPlan.free) {
        await clearPersistedSubscriptionStorage(prefs);
      }
      return;
    }

    if (!verified) {
      await _clearPersistedSubscription(prefs);
      return;
    }

    if (expiryStr == null) return;

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (expiry.isBefore(DateTime.now())) {
      // Subscription expired — clear storage and stay free
      await _clearPersistedSubscription(prefs);
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
    await _clearPersistedSubscription(prefs);
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

  Future<void> _clearPersistedSubscription(SharedPreferences prefs) async {
    await clearPersistedSubscriptionStorage(prefs);
  }

  static Future<void> clearPersistedSubscriptionStorage(
    SharedPreferences prefs,
  ) async {
    await prefs.remove('subscription_plan');
    await prefs.remove('subscription_expiry');
    await prefs.remove('subscription_purchase_date');
    await prefs.remove('subscription_purchase_token');
    await prefs.remove('subscription_renewal_date');
    await prefs.remove('subscription_provider');
    await prefs.remove('subscription_status');
    await prefs.remove('subscription_store_order_id');
    await prefs.remove('subscription_payment_id');
    await prefs.remove('subscription_order_id');
    await prefs.remove('subscription_signature');
    await prefs.remove('subscription_verification_status');
    await prefs.remove('subscription_auto_renewing');
    await prefs.remove(_cancelAtPeriodEndKey);
    await prefs.remove(_providerKey);
    await prefs.remove(_activeKey);
    await prefs.remove(_verifiedKey);
  }
}

// Provider for subscription state
final subscriptionProvider =
    StateNotifierProvider<SubscriptionService, SubscriptionModel>((ref) {
  return SubscriptionService();
});
