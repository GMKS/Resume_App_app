// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart'
    show InAppPurchasePlatform;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_model.dart';
import 'app_config_service.dart';
import 'subscription_service.dart';

String _readPlayBillingConfig(String key) {
  return AppConfigService.read(key);
}

class PlayBillingService {
  static const Duration _purchaseTimeout = Duration(seconds: 45);

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
  Timer? _purchaseTimeoutTimer;
  bool _initialized = false;
  bool _hasPendingPurchaseUpdate = false;
  bool _purchaseFlowActive = false;
  SubscriptionPlan? _activePurchasePlan;
  String? _lastDiagnosticsMessage;

  void Function(PurchaseDetails purchase, SubscriptionPlan plan)?
      onPurchaseSuccess;
  void Function(String message)? onPurchaseError;
  void Function(PlayBillingPurchaseFailure failure)? onPurchaseFailure;
  void Function(bool isPending)? onPendingStateChanged;

  String? get lastDiagnosticsMessage => _lastDiagnosticsMessage;
  bool get hasActivePurchaseSession => _purchaseFlowActive;

  static bool get supportsGooglePlayBilling =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (kReleaseMode || !_isDisabledForCurrentBuild);

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

  static Future<bool> syncPersistedGooglePlayEntitlement({
    String source = 'unknown',
  }) async {
    if (!supportsGooglePlayBilling) {
      return false;
    }

    final platform = InAppPurchasePlatform.instance;
    if (platform is! InAppPurchaseAndroidPlatform) {
      return false;
    }

    try {
      final response = await platform.billingClientManager.runWithClient(
        (client) => client.queryPurchases(ProductType.subs),
      );

      debugPrint(
        'PlayBillingService.startupSync: source=$source '
        'response=${response.responseCode.name} '
        'purchaseCount=${response.purchasesList.length}',
      );

      if (response.responseCode != BillingResponse.ok) {
        return false;
      }

      final activePurchases = response.purchasesList
          .where(
            (purchase) =>
                purchase.purchaseState == PurchaseStateWrapper.purchased &&
                purchase.purchaseToken.trim().isNotEmpty,
          )
          .toList(growable: false)
        ..sort(
            (left, right) => right.purchaseTime.compareTo(left.purchaseTime));

      final prefs = await SharedPreferences.getInstance();
      for (final purchase in activePurchases) {
        final matchingPlan = purchase.products
            .map(planForProductId)
            .whereType<SubscriptionPlan>()
            .firstOrNull;
        if (matchingPlan == null) {
          continue;
        }

        final purchaseDate =
            DateTime.fromMillisecondsSinceEpoch(purchase.purchaseTime);
        final renewalDate = _projectGooglePlayRenewalDate(
          purchaseDate: purchaseDate,
          plan: matchingPlan,
        );
        final cancelAtPeriodEnd = !purchase.isAutoRenewing;

        await prefs.setString('subscription_plan', matchingPlan.name);
        await prefs.setString(
            'subscription_provider', BillingProvider.googlePlay.name);
        await prefs.setBool('subscription_active', true);
        await prefs.setBool('subscription_verified', true);
        await prefs.setString('subscription_status', 'active');
        await prefs.setString(
          'subscription_purchase_date',
          purchaseDate.millisecondsSinceEpoch.toString(),
        );
        await prefs.setString(
            'subscription_purchase_token', purchase.purchaseToken);
        await prefs.setString('subscription_store_order_id', purchase.orderId);
        await prefs.setString('subscription_payment_id', purchase.orderId);
        await prefs.setString('subscription_order_id', purchase.orderId);
        await prefs.setString('subscription_signature', purchase.signature);
        await prefs.setString('subscription_verification_status', 'active');
        await prefs.setBool(
            'subscription_auto_renewing', purchase.isAutoRenewing);
        await prefs.setBool(
            'subscription_cancel_at_period_end', cancelAtPeriodEnd);
        await prefs.setString(
          'subscription_expiry',
          renewalDate.millisecondsSinceEpoch.toString(),
        );
        await prefs.setString(
          'subscription_renewal_date',
          renewalDate.millisecondsSinceEpoch.toString(),
        );

        debugPrint(
          'PlayBillingService.startupSync: source=$source '
          'plan=${matchingPlan.name} orderId=${purchase.orderId} '
          'tokenPresent=${purchase.purchaseToken.isNotEmpty} '
          'acknowledged=${purchase.isAcknowledged} '
          'autoRenewing=${purchase.isAutoRenewing} '
          'purchaseTime=${purchase.purchaseTime} '
          'renewalDate=${renewalDate.toIso8601String()}',
        );
        return true;
      }

      if (prefs.getString('subscription_provider') ==
          BillingProvider.googlePlay.name) {
        debugPrint(
          'PlayBillingService.startupSync: source=$source clearing-stale-google-play-entitlement',
        );
        await SubscriptionService.clearPersistedSubscriptionStorage(prefs);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'PlayBillingService.startupSync: source=$source failed with $error\n$stackTrace',
      );
    }

    return false;
  }

  static String get _missingProductsMessage {
    final configuredIds = _productIds.toList(growable: false)..sort();
    return configuredIds.isEmpty
        ? 'Google Play product IDs are missing for this build.'
        : 'Subscription products could not be loaded. Verify Play Console configuration and tester installation.';
  }

  static DateTime _projectGooglePlayRenewalDate({
    required DateTime purchaseDate,
    required SubscriptionPlan plan,
  }) {
    var renewalDate = purchaseDate.add(_durationForPlan(plan));
    final now = DateTime.now();
    while (renewalDate.isBefore(now)) {
      renewalDate = renewalDate.add(_durationForPlan(plan));
    }
    return renewalDate;
  }

  static Duration _durationForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return const Duration(days: 7);
      case SubscriptionPlan.monthly:
        return const Duration(days: 30);
      case SubscriptionPlan.quarterly:
        return const Duration(days: 90);
      case SubscriptionPlan.yearly:
        return const Duration(days: 365);
      case SubscriptionPlan.free:
        return Duration.zero;
    }
  }

  Future<Map<SubscriptionPlan, ProductDetails>> initialize() async {
    if (!supportsGooglePlayBilling) {
      return const <SubscriptionPlan, ProductDetails>{};
    }

    debugPrint(
      'PlayBillingService.initialize: package subscription ids=${_productIds.toList(growable: false)..sort()}',
    );

    if (!_initialized) {
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: dispose,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            'PlayBillingService.purchaseStreamError: error=$error\n$stackTrace',
          );
          _notifyPurchaseFailure(
            const PlayBillingPurchaseFailure(
              code: PlayBillingFailureCode.error,
              message:
                  'Google Play purchase updates are unavailable right now.',
            ),
            source: 'purchase-stream-error',
          );
        },
      );
      _initialized = true;
    }

    return loadProducts();
  }

  Future<Map<SubscriptionPlan, ProductDetails>> loadProducts() async {
    _productsByPlan.clear();
    _lastDiagnosticsMessage = null;

    if (_productIds.isEmpty) {
      onPurchaseError?.call(_missingProductsMessage);
      debugPrint('PlayBillingService.loadProducts: no product ids configured.');
      return const <SubscriptionPlan, ProductDetails>{};
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      onPurchaseError?.call('Google Play is unavailable on this device.');
      debugPrint(
          'PlayBillingService.loadProducts: Google Play is unavailable.');
      return const <SubscriptionPlan, ProductDetails>{};
    }

    final queryResult = await _queryProductsWithRetry();
    if (queryResult == null) {
      onPurchaseError?.call(
        'Google Play subscriptions are unavailable for this installation.',
      );
      return const <SubscriptionPlan, ProductDetails>{};
    }
    final response = queryResult.response;

    _lastDiagnosticsMessage = await _buildDiagnosticsMessage(
      isAvailable: isAvailable,
      queryResult: queryResult,
    );
    debugPrint('PlayBillingService.loadProducts: $_lastDiagnosticsMessage');

    if (response.error != null) {
      onPurchaseError?.call(
        response.error!.message.isNotEmpty
            ? response.error!.message
            : 'Subscription products could not be loaded. Verify Play Console configuration and tester installation.',
      );
    }

    for (final product in response.productDetails) {
      final plan = planForProductId(product.id);
      if (plan != null && !_productsByPlan.containsKey(plan)) {
        _productsByPlan[plan] = product;
        _logProductDetails(plan, product);
      }
    }

    _logPlanAvailability(response);

    if (_productsByPlan.isEmpty) {
      onPurchaseError?.call(
        response.notFoundIDs.isNotEmpty
            ? 'Subscription products could not be loaded. Verify Play Console configuration and tester installation.'
            : 'Google Play subscriptions are unavailable for this installation.',
      );
    }

    return Map<SubscriptionPlan, ProductDetails>.unmodifiable(_productsByPlan);
  }

  Future<void> purchasePlan(SubscriptionPlan plan) async {
    if (_purchaseFlowActive) {
      debugPrint(
        'PlayBillingService.purchasePlan: ignored duplicate launch '
        'requestedPlan=${plan.name} activePlan=${_activePurchasePlan?.name ?? 'none'}',
      );
      return;
    }

    var product = _productsByPlan[plan];
    if (product == null) {
      final products = await loadProducts();
      product = products[plan];
    }

    if (product == null) {
      _notifyPurchaseFailure(
        const PlayBillingPurchaseFailure(
          code: PlayBillingFailureCode.error,
          message:
              'This subscription plan is not available in Google Play yet.',
        ),
        source: 'product-missing',
      );
      return;
    }

    final offerToken = _offerTokenForProduct(product);
    debugPrint(
      'PlayBillingService.purchasePlan: plan=$plan product=${product.id} '
      'price=${product.price} currency=${product.currencyCode} '
      'offerToken=${offerToken ?? 'null'} '
      'runtimeType=${product.runtimeType}',
    );

    if (offerToken == null || offerToken.isEmpty) {
      _notifyPurchaseFailure(
        PlayBillingPurchaseFailure(
          code: PlayBillingFailureCode.error,
          message:
              'Google Play subscription offer details are missing for ${product.id}.',
        ),
        source: 'offer-token-missing',
      );
      return;
    }

    _beginPurchaseFlow(plan, source: 'launch-started');

    final purchaseParam = GooglePlayPurchaseParam(
      productDetails: product,
      offerToken: offerToken,
    );
    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint(
        'PlayBillingService.purchasePlan: launchResult started=$started plan=$plan',
      );

      if (!started) {
        _notifyPurchaseFailure(
          const PlayBillingPurchaseFailure(
            code: PlayBillingFailureCode.error,
            message: 'Could not start the Google Play purchase flow.',
          ),
          source: 'launch-not-started',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'PlayBillingService.purchasePlan: launch failed with $error\n$stackTrace',
      );
      _notifyPurchaseFailure(
        PlayBillingPurchaseFailure(
          code: PlayBillingFailureCode.error,
          message: 'Could not start the Google Play purchase flow. $error',
        ),
        source: 'launch-exception',
      );
    }
  }

  bool recoverInterruptedPurchaseSession({
    String source = 'resume-check',
  }) {
    if (!_purchaseFlowActive) {
      return false;
    }

    debugPrint(
      'PlayBillingService.recoverInterruptedPurchaseSession: '
      'source=$source activePlan=${_activePurchasePlan?.name ?? 'none'} '
      'pendingUpdate=$_hasPendingPurchaseUpdate',
    );

    if (_hasPendingPurchaseUpdate) {
      return false;
    }

    _notifyPurchaseFailure(
      const PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.userCanceled,
        message: 'Google Play purchase was canceled.',
      ),
      source: source,
    );
    return true;
  }

  bool canPurchasePlan(SubscriptionPlan plan) {
    final product = _productsByPlan[plan];
    if (product == null) {
      return false;
    }

    return _offerTokenForProduct(product)?.isNotEmpty ?? false;
  }

  ProductDetails? productDetailsForPlan(SubscriptionPlan plan) {
    return _productsByPlan[plan];
  }

  String? offerTokenForPlan(SubscriptionPlan plan) {
    return _offerTokenForProduct(_productsByPlan[plan]);
  }

  String? _offerTokenForProduct(ProductDetails? product) {
    if (product == null) {
      return null;
    }

    if (product is GooglePlayProductDetails) {
      final offerToken = product.offerToken;
      if (offerToken != null && offerToken.isNotEmpty) {
        return offerToken;
      }
    }

    try {
      final dynamic googlePlayProduct = product;
      final List<dynamic>? subscriptionOfferDetails = googlePlayProduct
          .productDetails?.subscriptionOfferDetails as List<dynamic>?;
      if (subscriptionOfferDetails == null) {
        return null;
      }

      for (final dynamic offerDetail in subscriptionOfferDetails) {
        final String? offerToken = offerDetail.offerIdToken as String?;
        if (offerToken != null && offerToken.isNotEmpty) {
          return offerToken;
        }
      }
    } catch (_) {
      // Fallback to null if the runtime type does not expose Play fields.
    }

    return null;
  }

  void _logProductDetails(SubscriptionPlan plan, ProductDetails product) {
    debugPrint(
      'PlayBillingService.loadProducts: plan=$plan id=${product.id} '
      'title=${product.title} price=${product.price} currency=${product.currencyCode} '
      'offerToken=${_offerTokenForProduct(product) ?? 'null'} '
      'basePlans=${_subscriptionBasePlanIds(product)} '
      'runtimeType=${product.runtimeType}',
    );
  }

  Future<_ProductQueryResult?> _queryProductsWithRetry() async {
    try {
      final firstResult = await _querySubscriptionProducts();
      if (firstResult.response.productDetails.isNotEmpty ||
          firstResult.response.error != null) {
        return firstResult;
      }

      debugPrint(
        'PlayBillingService.loadProducts: empty first response, retrying once after a short delay.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final secondResult = await _querySubscriptionProducts();
      return secondResult;
    } catch (error, stackTrace) {
      debugPrint(
        'PlayBillingService.loadProducts: query failed with $error\n$stackTrace',
      );
      _lastDiagnosticsMessage =
          'available=true queryFailed error=${error.runtimeType}: $error';
      return null;
    }
  }

  Future<_ProductQueryResult> _querySubscriptionProducts() async {
    final platform = InAppPurchasePlatform.instance;
    if (defaultTargetPlatform == TargetPlatform.android &&
        platform is InAppPurchaseAndroidPlatform) {
      final queryIds = _productIds.toList(growable: false)..sort();
      // ignore: invalid_use_of_visible_for_testing_member
      final wrapper = await platform.billingClientManager.runWithClient(
        (client) => client.queryProductDetails(
          productList: queryIds
              .map(
                (productId) => ProductWrapper(
                  productId: productId,
                  productType: ProductType.subs,
                ),
              )
              .toList(growable: false),
        ),
      );
      final productDetails = wrapper.productDetailsList
          .expand(GooglePlayProductDetails.fromProductDetails)
          .toList(growable: false);
      final returnedIds = productDetails.map((product) => product.id).toSet();
      final notFoundIds = queryIds
          .where((productId) => !returnedIds.contains(productId))
          .toList(growable: false);
      final error = wrapper.billingResult.responseCode == BillingResponse.ok
          ? null
          : IAPError(
              source: 'google_play',
              code: wrapper.billingResult.responseCode.name,
              message: wrapper.billingResult.debugMessage ?? '',
            );

      return _ProductQueryResult(
        response: ProductDetailsResponse(
          productDetails: productDetails,
          notFoundIDs: notFoundIds,
          error: error,
        ),
        queryType: 'BillingClient.queryProductDetailsAsync(ProductType.subs)',
        androidBillingResult: wrapper.billingResult,
      );
    }

    return _ProductQueryResult(
      response: await _inAppPurchase.queryProductDetails(_productIds),
      queryType: 'InAppPurchase.queryProductDetails',
    );
  }

  Future<String> _buildDiagnosticsMessage({
    required bool isAvailable,
    required _ProductQueryResult queryResult,
  }) async {
    final response = queryResult.response;
    final requestedIds = _productIds.toList(growable: false)..sort();
    final returnedIds = response.productDetails
        .map((product) => product.id)
        .toList(growable: false)
      ..sort();
    final notFoundIds = response.notFoundIDs.toList(growable: false)..sort();
    final connectionReady = isAvailable;
    final responseCode = queryResult.androidBillingResult?.responseCode.name ??
        response.error?.code ??
        'ok';
    final debugMessage = queryResult.androidBillingResult?.debugMessage ??
        response.error?.message ??
        'none';
    final returnedCount = response.productDetails.length;

    return 'query=${queryResult.queryType} '
        'available=$isAvailable ready=$connectionReady '
        'responseCode=$responseCode '
        'debugMessage=$debugMessage '
        'returnedCount=$returnedCount '
        'requested=$requestedIds returned=$returnedIds notFound=$notFoundIds '
        'planAvailability=${_planAvailabilitySummary(response)} '
        'basePlans=${response.productDetails.map(_subscriptionBasePlanIds).toList(growable: false)}';
  }

  void _logPlanAvailability(ProductDetailsResponse response) {
    debugPrint(
      'PlayBillingService.loadProducts: planAvailability=${_planAvailabilitySummary(response)}',
    );
  }

  Map<String, String> _planAvailabilitySummary(
      ProductDetailsResponse response) {
    final returnedIds =
        response.productDetails.map((product) => product.id).toSet();
    return <String, String>{
      for (final plan in SubscriptionPlan.values)
        if (plan != SubscriptionPlan.free)
          plan.name: () {
            final productId = productIdForPlan(plan);
            if (productId == null || productId.isEmpty) {
              return 'missing-config';
            }
            if (!returnedIds.contains(productId)) {
              return 'missing-product id=$productId';
            }
            final product = response.productDetails.firstWhere(
              (product) => product.id == productId,
            );
            final offerToken = _offerTokenForProduct(product);
            if (offerToken == null || offerToken.isEmpty) {
              return 'missing-offer-token id=$productId';
            }
            return 'ready id=$productId';
          }(),
    };
  }

  List<String> _subscriptionBasePlanIds(ProductDetails product) {
    try {
      final dynamic googlePlayProduct = product;
      final List<dynamic>? offerDetails = googlePlayProduct
          .productDetails.subscriptionOfferDetails as List<dynamic>?;
      if (offerDetails == null || offerDetails.isEmpty) {
        return const <String>[];
      }

      return offerDetails.map((dynamic offerDetail) {
        try {
          final String? basePlanId = offerDetail.basePlanId as String?;
          final String? offerToken = offerDetail.offerIdToken as String?;
          if ((basePlanId ?? '').isEmpty && (offerToken ?? '').isEmpty) {
            return 'unknown';
          }
          return [
            if (basePlanId != null && basePlanId.isNotEmpty)
              'basePlan=$basePlanId',
            if (offerToken != null && offerToken.isNotEmpty)
              'offerToken=$offerToken',
          ].join(' ');
        } catch (_) {
          return 'unknown';
        }
      }).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> restorePurchases() async {
    if (!supportsGooglePlayBilling) {
      return;
    }

    debugPrint(
        'PlayBillingService.restorePurchases: requesting Google Play restore.');
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    debugPrint(
      'PlayBillingService.purchaseUpdateBatch: count=${purchaseDetailsList.length} '
      'activePlan=${_activePurchasePlan?.name ?? 'none'} active=$_purchaseFlowActive',
    );

    for (final purchase in purchaseDetailsList) {
      final plan = planForProductId(purchase.productID);
      if (plan == null) {
        continue;
      }

      final errorCode = purchase.error?.code ?? 'none';
      debugPrint(
        'PlayBillingService.purchaseUpdate: status=${purchase.status.name} '
        'product=${purchase.productID} plan=${plan.name} '
        'errorCode=$errorCode pendingComplete=${purchase.pendingCompletePurchase}',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _hasPendingPurchaseUpdate = true;
          _beginPurchaseFlow(plan, source: 'purchase-update-pending');
          break;
        case PurchaseStatus.error:
          final failure = _mapPurchaseError(purchase.error);
          if (failure.code == PlayBillingFailureCode.itemAlreadyOwned) {
            _notifyPurchaseFailure(failure,
                source: 'purchase-update-already-owned');
            await restorePurchases();
            break;
          }
          _notifyPurchaseFailure(failure, source: 'purchase-update-error');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_isValidCompletedPurchase(purchase, plan)) {
            _notifyPurchaseFailure(
              const PlayBillingPurchaseFailure(
                code: PlayBillingFailureCode.error,
                message:
                    'Google Play purchase details were incomplete. Please restore your purchase again.',
              ),
              source: 'purchase-update-invalid-${purchase.status.name}',
            );
            break;
          }
          _endPurchaseFlow(source: 'purchase-update-${purchase.status.name}');
          onPurchaseSuccess?.call(purchase, plan);
          break;
        case PurchaseStatus.canceled:
          _notifyPurchaseFailure(
            const PlayBillingPurchaseFailure(
              code: PlayBillingFailureCode.userCanceled,
              message: 'Google Play purchase was canceled.',
            ),
            source: 'purchase-update-canceled',
          );
          break;
      }

      if (purchase.pendingCompletePurchase) {
        debugPrint(
          'PlayBillingService.completePurchase: '
          'product=${purchase.productID} status=${purchase.status.name} '
          'source=${purchase is GooglePlayPurchaseDetails ? 'google-play' : 'generic'}',
        );
        try {
          await _inAppPurchase.completePurchase(purchase);
          debugPrint(
            'PlayBillingService.completePurchase: success '
            'product=${purchase.productID} status=${purchase.status.name}',
          );
        } catch (error, stackTrace) {
          debugPrint(
            'PlayBillingService.completePurchase: failed '
            'product=${purchase.productID} error=$error\n$stackTrace',
          );
          _notifyPurchaseFailure(
            PlayBillingPurchaseFailure(
              code: PlayBillingFailureCode.error,
              message:
                  'Google Play confirmed the payment but the purchase could not be acknowledged. Please retry restore purchases.',
              rawCode: error.toString(),
            ),
            source: 'complete-purchase-failed',
          );
        }
      }
    }
  }

  bool _isValidCompletedPurchase(
    PurchaseDetails purchase,
    SubscriptionPlan plan,
  ) {
    if (purchase is! GooglePlayPurchaseDetails) {
      final hasToken =
          purchase.verificationData.serverVerificationData.trim().isNotEmpty;
      debugPrint(
        'PlayBillingService.purchaseValidation: '
        'plan=${plan.name} product=${purchase.productID} '
        'status=${purchase.status.name} hasToken=$hasToken '
        'runtimeType=${purchase.runtimeType}',
      );
      return hasToken;
    }

    final billingPurchase = purchase.billingClientPurchase;
    final purchaseToken =
        purchase.verificationData.serverVerificationData.trim();
    final isPurchasedState =
        billingPurchase.purchaseState == PurchaseStateWrapper.purchased;
    debugPrint(
      'PlayBillingService.purchaseValidation: '
      'plan=${plan.name} product=${purchase.productID} '
      'status=${purchase.status.name} orderId=${billingPurchase.orderId} '
      'tokenPresent=${purchaseToken.isNotEmpty} '
      'acknowledged=${billingPurchase.isAcknowledged} '
      'autoRenewing=${billingPurchase.isAutoRenewing} '
      'purchaseState=${billingPurchase.purchaseState.name} '
      'purchaseTime=${billingPurchase.purchaseTime}',
    );

    return isPurchasedState && purchaseToken.isNotEmpty;
  }

  String _errorMessage(IAPError? error) {
    if (error == null) {
      return 'Google Play could not complete the purchase.';
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Google Play could not complete the purchase.';
  }

  PlayBillingPurchaseFailure _mapPurchaseError(IAPError? error) {
    final rawCode = error?.code.trim() ?? '';
    final normalizedCode = rawCode.toLowerCase();
    final message = _errorMessage(error);

    if (normalizedCode.contains('already') &&
        normalizedCode.contains('owned')) {
      return PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.itemAlreadyOwned,
        message:
            'This Google Play subscription is already owned. Checking your existing subscription...',
        rawCode: rawCode,
      );
    }
    if (normalizedCode.contains('user') && normalizedCode.contains('cancel') ||
        normalizedCode.contains('canceled') ||
        normalizedCode.contains('cancelled')) {
      return PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.userCanceled,
        message: 'Google Play purchase was canceled.',
        rawCode: rawCode,
      );
    }
    if (normalizedCode.contains('service') &&
        normalizedCode.contains('disconnect')) {
      return PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.serviceDisconnected,
        message: 'Unable to connect to Google Play. Please try again.',
        rawCode: rawCode,
      );
    }
    if (normalizedCode.contains('service') &&
        normalizedCode.contains('unavailable')) {
      return PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.serviceUnavailable,
        message: 'Google Play is unavailable right now. Please try again.',
        rawCode: rawCode,
      );
    }
    if (normalizedCode.contains('network')) {
      return PlayBillingPurchaseFailure(
        code: PlayBillingFailureCode.networkError,
        message:
            'Network error while connecting to Google Play. Please try again.',
        rawCode: rawCode,
      );
    }

    return PlayBillingPurchaseFailure(
      code: PlayBillingFailureCode.error,
      message: message,
      rawCode: rawCode,
    );
  }

  void _beginPurchaseFlow(SubscriptionPlan plan, {required String source}) {
    _purchaseFlowActive = true;
    _activePurchasePlan = plan;
    debugPrint(
      'PlayBillingService.purchaseFlowState: pending=true '
      'plan=${plan.name} source=$source',
    );
    onPendingStateChanged?.call(true);
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(_purchaseTimeout, () {
      _notifyPurchaseFailure(
        const PlayBillingPurchaseFailure(
          code: PlayBillingFailureCode.timeout,
          message: 'Unable to connect to Google Play. Please try again.',
        ),
        source: 'purchase-timeout',
      );
    });
  }

  void _endPurchaseFlow({required String source}) {
    final previousPlan = _activePurchasePlan?.name ?? 'none';
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
    _purchaseFlowActive = false;
    _hasPendingPurchaseUpdate = false;
    _activePurchasePlan = null;
    debugPrint(
      'PlayBillingService.purchaseFlowState: pending=false '
      'plan=$previousPlan source=$source',
    );
    onPendingStateChanged?.call(false);
  }

  void _notifyPurchaseFailure(
    PlayBillingPurchaseFailure failure, {
    required String source,
  }) {
    debugPrint(
      'PlayBillingService.purchaseFailure: source=$source '
      'code=${failure.code.name} rawCode=${failure.rawCode ?? 'none'} '
      'message=${failure.message}',
    );
    _endPurchaseFlow(source: source);
    onPurchaseFailure?.call(failure);
  }

  void dispose() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _initialized = false;
    _purchaseFlowActive = false;
    _hasPendingPurchaseUpdate = false;
    _activePurchasePlan = null;
  }
}

enum PlayBillingFailureCode {
  userCanceled,
  error,
  serviceDisconnected,
  serviceUnavailable,
  networkError,
  itemAlreadyOwned,
  timeout,
  unknown,
}

class PlayBillingPurchaseFailure {
  const PlayBillingPurchaseFailure({
    required this.code,
    required this.message,
    this.rawCode,
  });

  final PlayBillingFailureCode code;
  final String message;
  final String? rawCode;
}

class _ProductQueryResult {
  const _ProductQueryResult({
    required this.response,
    required this.queryType,
    this.androidBillingResult,
  });

  final ProductDetailsResponse response;
  final String queryType;
  final BillingResultWrapper? androidBillingResult;
}
