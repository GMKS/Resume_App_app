import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/subscription_model.dart';
import 'app_config_service.dart';

String _readPlayBillingConfig(String key) {
  return AppConfigService.read(key);
}

class PlayPurchaseEntitlement {
  const PlayPurchaseEntitlement({
    required this.plan,
    required this.productId,
    required this.purchaseToken,
    required this.orderId,
    required this.purchaseTime,
    required this.cancelAtPeriodEnd,
    required this.purchase,
  });

  factory PlayPurchaseEntitlement.fromPurchase(
    GooglePlayPurchaseDetails purchase,
    SubscriptionPlan plan,
  ) {
    return PlayPurchaseEntitlement(
      plan: plan,
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      orderId: purchase.purchaseID ?? purchase.productID,
      purchaseTime: DateTime.fromMillisecondsSinceEpoch(
        purchase.billingClientPurchase.purchaseTime,
      ),
      cancelAtPeriodEnd: !purchase.billingClientPurchase.isAutoRenewing,
      purchase: purchase,
    );
  }

  final SubscriptionPlan plan;
  final String productId;
  final String purchaseToken;
  final String orderId;
  final DateTime purchaseTime;
  final bool cancelAtPeriodEnd;
  final GooglePlayPurchaseDetails purchase;
}

class PlayBillingService {
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
  void Function(PlayPurchaseEntitlement entitlement)? onEntitlementConfirmed;
  void Function(String message)? onPurchaseError;
  void Function(bool isPending)? onPendingStateChanged;

  static bool get supportsGooglePlayBilling =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

  static Future<PlayPurchaseEntitlement?> fetchActiveEntitlement() async {
    if (!supportsGooglePlayBilling) {
      return null;
    }

    final inAppPurchase = InAppPurchase.instance;
    final isAvailable = await inAppPurchase.isAvailable();
    if (!isAvailable) {
      return null;
    }

    final androidAddition = inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await androidAddition.queryPastPurchases();
    if (response.error != null) {
      throw StateError(
        response.error!.message.isNotEmpty
            ? response.error!.message
            : 'Google Play past purchases could not be queried.',
      );
    }

    final matchingPurchases = response.pastPurchases
        .where(_isActiveGooglePlayPurchase)
        .toList(growable: false)
      ..sort(
        (left, right) => right.billingClientPurchase.purchaseTime
            .compareTo(left.billingClientPurchase.purchaseTime),
      );

    if (matchingPurchases.isEmpty) {
      return null;
    }

    final purchase = matchingPurchases.first;
    final plan = planForProductId(purchase.productID);
    if (plan == null) {
      return null;
    }

    return PlayPurchaseEntitlement.fromPurchase(purchase, plan);
  }

  static String get _missingProductsMessage {
    final configuredIds = _productIds.toList(growable: false)..sort();
    final configuredList = configuredIds.join(', ');
    return configuredIds.isEmpty
        ? 'Google Play product IDs are missing for this build.'
        : 'Google Play returned no matching subscriptions for this install. Check that the app was installed from the Play testing track, the current account is an enrolled tester, and these products with active base plans exist for this package: $configuredList.';
  }

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
      onPurchaseError?.call(_missingProductsMessage);
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
      onPurchaseError?.call(_missingProductsMessage);
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

    PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    final previousPurchase = await _findActiveGooglePlayPurchase();
    if (previousPurchase != null && previousPurchase.productID != product.id) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: ChangeSubscriptionParam(
          oldPurchaseDetails: previousPurchase,
          replacementMode: ReplacementMode.withTimeProration,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      purchaseParam = GooglePlayPurchaseParam(productDetails: product);
    }

    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      onPendingStateChanged?.call(false);
      onPurchaseError?.call('Could not start the Google Play purchase flow.');
    }
  }

  Future<PlayPurchaseEntitlement?> restorePurchases() async {
    if (!supportsGooglePlayBilling) {
      return null;
    }
    await _inAppPurchase.restorePurchases();
    return refreshEntitlement();
  }

  Future<PlayPurchaseEntitlement?> refreshEntitlement() async {
    try {
      final entitlement = await fetchActiveEntitlement();
      if (entitlement != null) {
        onEntitlementConfirmed?.call(entitlement);
      }
      return entitlement;
    } catch (_) {
      onPurchaseError?.call(
        'Could not confirm the current Google Play subscription status.',
      );
      return null;
    }
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
          if (purchase is GooglePlayPurchaseDetails) {
            onEntitlementConfirmed?.call(
              PlayPurchaseEntitlement.fromPurchase(purchase, plan),
            );
          }
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

  Future<GooglePlayPurchaseDetails?> _findActiveGooglePlayPurchase() async {
    try {
      final entitlement = await fetchActiveEntitlement();
      return entitlement?.purchase;
    } catch (_) {
      return null;
    }
  }

  static bool _isActiveGooglePlayPurchase(GooglePlayPurchaseDetails purchase) {
    final plan = planForProductId(purchase.productID);
    return plan != null &&
        purchase.status != PurchaseStatus.error &&
        purchase.status != PurchaseStatus.canceled &&
        purchase.billingClientPurchase.purchaseState ==
            PurchaseStateWrapper.purchased;
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _initialized = false;
  }
}
