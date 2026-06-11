import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import 'play_billing_service.dart';
import 'storage_service.dart';

const bool _storeScreenshotMode = bool.fromEnvironment('STORE_SCREENSHOT_MODE');

class SubscriptionService extends StateNotifier<SubscriptionModel> {
  static const String _cancelAtPeriodEndKey =
      'subscription_cancel_at_period_end';
  static const String _providerKey = 'subscription_provider';
  static const String _activeKey = 'subscription_active';
  static const String _productIdKey = 'subscription_product_id';
  static const String _purchaseTokenKey = 'subscription_purchase_token';
  static const String _orderIdKey = 'subscription_order_id';
  static const String _purchaseTimeKey = 'subscription_purchase_time';

  SubscriptionService() : super(SubscriptionModel.free()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedSubscription();
    if (PlayBillingService.supportsGooglePlayBilling && !_storeScreenshotMode) {
      await syncGooglePlayEntitlement();
    }
  }

  /// Load persisted subscription from SharedPreferences on startup.
  Future<void> _loadSavedSubscription() async {
    final prefs = StorageService.prefs;
    final planName = prefs.getString('subscription_plan');
    final expiryStr = prefs.getString('subscription_expiry');
    final cancelAtPeriodEnd = prefs.getBool(_cancelAtPeriodEndKey) ?? false;
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

  Future<void> activatePlan(
    SubscriptionPlan plan, {
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
    bool isActive = true,
    String? productId,
    String? purchaseToken,
    String? orderId,
    DateTime? purchaseTime,
  }) async {
    upgradeToPlan(
      plan,
      expiryDate: expiryDate,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
    );

    final prefs = StorageService.prefs;
    await prefs.setString('subscription_plan', plan.name);
    await prefs.setString(_providerKey, billingProvider.name);
    await prefs.setBool(_activeKey, isActive);
    if (expiryDate != null) {
      await prefs.setString(
        'subscription_expiry',
        expiryDate.millisecondsSinceEpoch.toString(),
      );
    } else {
      await prefs.remove('subscription_expiry');
    }
    await prefs.setBool(_cancelAtPeriodEndKey, cancelAtPeriodEnd);
    await _persistOptionalString(prefs, _productIdKey, productId);
    await _persistOptionalString(prefs, _purchaseTokenKey, purchaseToken);
    await _persistOptionalString(prefs, _orderIdKey, orderId);
    if (purchaseTime != null) {
      await prefs.setString(
        _purchaseTimeKey,
        purchaseTime.millisecondsSinceEpoch.toString(),
      );
    } else {
      await prefs.remove(_purchaseTimeKey);
    }
  }

  Future<void> syncGooglePlayEntitlement() async {
    if (!PlayBillingService.supportsGooglePlayBilling) {
      return;
    }

    final prefs = StorageService.prefs;
    final entitlement = await PlayBillingService.fetchActiveEntitlement();
    if (entitlement == null) {
      if (prefs.getString(_providerKey) == BillingProvider.googlePlay.name) {
        await cancelSubscription();
      }
      return;
    }

    await activatePlan(
      entitlement.plan,
      cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
      billingProvider: BillingProvider.googlePlay,
      productId: entitlement.productId,
      purchaseToken: entitlement.purchaseToken,
      orderId: entitlement.orderId,
      purchaseTime: entitlement.purchaseTime,
    );
  }

  Future<void> cancelSubscription() async {
    state = SubscriptionModel.free();
    final prefs = StorageService.prefs;
    await prefs.remove('subscription_plan');
    await prefs.remove('subscription_expiry');
    await prefs.remove(_cancelAtPeriodEndKey);
    await prefs.remove(_providerKey);
    await prefs.remove(_activeKey);
    await prefs.remove(_productIdKey);
    await prefs.remove(_purchaseTokenKey);
    await prefs.remove(_orderIdKey);
    await prefs.remove(_purchaseTimeKey);
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
    final prefs = StorageService.prefs;
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
    final prefs = StorageService.prefs;
    await prefs.setBool(_cancelAtPeriodEndKey, false);
  }

  bool hasFeatureAccess(String featureName) {
    return state.hasFeature(featureName);
  }

  Future<void> _persistOptionalString(
    AppPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }
}

// Provider for subscription state
final subscriptionProvider =
    StateNotifierProvider<SubscriptionService, SubscriptionModel>((ref) {
  return SubscriptionService();
});
