import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription_model.dart';
import 'app_config_service.dart';

String _readPlayBillingConfig(String key) {
  return AppConfigService.read(key);
}

class PlayBillingService {
  static bool get _isDisabledForCurrentBuild =>
      AppConfigService.readBool('DISABLE_GOOGLE_PLAY_BILLING');

  static String get weeklyProductId =>
      _readPlayBillingConfig('PLAY_WEEKLY_PRODUCT_ID');
  static String get monthlyProductId =>
      _readPlayBillingConfig('PLAY_MONTHLY_PRODUCT_ID');
  static String get quarterlyProductId =>
      _readPlayBillingConfig('PLAY_QUARTERLY_PRODUCT_ID');
  static String get yearlyProductId =>
      _readPlayBillingConfig('PLAY_YEARLY_PRODUCT_ID');

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<SubscriptionPlan, ProductDetails> _productsByPlan =
      <SubscriptionPlan, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _initialized = false;

  void Function(PurchaseDetails purchase, SubscriptionPlan plan)?
      onPurchaseSuccess;
  void Function(String message)? onPurchaseError;
  void Function(bool isPending)? onPendingStateChanged;

  static bool get supportsGooglePlayBilling =>
      !_isDisabledForCurrentBuild &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static bool get canUseTestPurchaseFallback =>
      supportsGooglePlayBilling && !kReleaseMode;

  static String? productIdForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return weeklyProductId.isEmpty ? null : weeklyProductId;
      case SubscriptionPlan.monthly:
        return monthlyProductId;
      case SubscriptionPlan.quarterly:
        return quarterlyProductId.isEmpty ? null : quarterlyProductId;
      case SubscriptionPlan.yearly:
        return yearlyProductId;
      case SubscriptionPlan.free:
        return null;
    }
  }

  static SubscriptionPlan? planForProductId(String productId) {
    if (weeklyProductId.isNotEmpty && productId == weeklyProductId) {
      return SubscriptionPlan.weekly;
    }
    if (productId == monthlyProductId) {
      return SubscriptionPlan.monthly;
    }
    if (quarterlyProductId.isNotEmpty && productId == quarterlyProductId) {
      return SubscriptionPlan.quarterly;
    }
    if (productId == yearlyProductId) {
      return SubscriptionPlan.yearly;
    }
    return null;
  }

  static Set<String> get _productIds => <String>{
        if (weeklyProductId.isNotEmpty) weeklyProductId,
        monthlyProductId,
        if (quarterlyProductId.isNotEmpty) quarterlyProductId,
        yearlyProductId,
      };

  Future<Map<SubscriptionPlan, ProductDetails>> initialize() async {
    if (!supportsGooglePlayBilling) {
      return const <SubscriptionPlan, ProductDetails>{};
    }

    if (!_initialized) {
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: dispose,
        onError: (_) {
          onPendingStateChanged?.call(false);
          onPurchaseError?.call(
            'Google Play purchase updates are unavailable right now.',
          );
        },
      );
      _initialized = true;
    }

    return loadProducts();
  }

  Future<Map<SubscriptionPlan, ProductDetails>> loadProducts() async {
    _productsByPlan.clear();

    if (_productIds.isEmpty) {
      onPurchaseError?.call(
        'Google Play subscriptions are not configured for this build yet.',
      );
      return const <SubscriptionPlan, ProductDetails>{};
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      onPurchaseError?.call('Google Play is unavailable on this device.');
      return const <SubscriptionPlan, ProductDetails>{};
    }

    final response = await _inAppPurchase.queryProductDetails(_productIds);
    if (response.error != null) {
      onPurchaseError?.call(
        response.error!.message.isNotEmpty
            ? response.error!.message
            : 'Unable to load Google Play subscriptions.',
      );
    }

    for (final product in response.productDetails) {
      final plan = planForProductId(product.id);
      if (plan != null) {
        _productsByPlan[plan] = product;
      }
    }

    if (_productsByPlan.isEmpty) {
      onPurchaseError?.call(
        'Google Play subscriptions are not configured for this build yet.',
      );
    }

    return Map<SubscriptionPlan, ProductDetails>.unmodifiable(_productsByPlan);
  }

  Future<void> purchasePlan(SubscriptionPlan plan) async {
    var product = _productsByPlan[plan];
    if (product == null) {
      final products = await loadProducts();
      product = products[plan];
    }

    if (product == null) {
      onPurchaseError?.call(
        'This subscription plan is not available in Google Play yet.',
      );
      onPendingStateChanged?.call(false);
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      onPendingStateChanged?.call(false);
      onPurchaseError?.call('Could not start the Google Play purchase flow.');
    }
  }

  Future<void> restorePurchases() async {
    if (!supportsGooglePlayBilling) {
      return;
    }
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      final plan = planForProductId(purchase.productID);
      if (plan == null) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPendingStateChanged?.call(true);
          break;
        case PurchaseStatus.error:
          onPendingStateChanged?.call(false);
          onPurchaseError?.call(_errorMessage(purchase.error));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onPendingStateChanged?.call(false);
          onPurchaseSuccess?.call(purchase, plan);
          break;
        case PurchaseStatus.canceled:
          onPendingStateChanged?.call(false);
          onPurchaseError?.call('Purchase canceled.');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  String _errorMessage(IAPError? error) {
    if (error == null) {
      return 'Google Play could not complete the purchase.';
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Google Play could not complete the purchase.';
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _initialized = false;
  }
}