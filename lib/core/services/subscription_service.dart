import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';

class SubscriptionService extends StateNotifier<SubscriptionModel> {
  SubscriptionService() : super(SubscriptionModel.free()) {
    _loadSavedSubscription();
  }

  /// Load persisted subscription from SharedPreferences on startup.
  Future<void> _loadSavedSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString('subscription_plan');
    final expiryStr = prefs.getString('subscription_expiry');

    if (planName == null || expiryStr == null) return;

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (expiry.isBefore(DateTime.now())) {
      // Subscription expired — clear storage and stay free
      await prefs.remove('subscription_plan');
      await prefs.remove('subscription_expiry');
      return;
    }

    final plan = SubscriptionPlan.values.firstWhere(
      (p) => p.name == planName,
      orElse: () => SubscriptionPlan.free,
    );
    if (plan != SubscriptionPlan.free) {
      upgradeToPlan(plan);
    }
  }

  void upgradeToPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        state = SubscriptionModel.weekly();
        break;
      case SubscriptionPlan.monthly:
        state = SubscriptionModel.monthly();
        break;
      case SubscriptionPlan.quarterly:
        state = SubscriptionModel.quarterly();
        break;
      case SubscriptionPlan.yearly:
        state = SubscriptionModel.yearly();
        break;
      case SubscriptionPlan.free:
        state = SubscriptionModel.free();
        break;
    }
  }

  Future<void> cancelSubscription() async {
    state = SubscriptionModel.free();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subscription_plan');
    await prefs.remove('subscription_expiry');
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
