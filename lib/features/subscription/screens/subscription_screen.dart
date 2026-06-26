// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:iconsax/iconsax.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/models/subscription_pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/services/payment_verification_service.dart';
import '../../../core/services/play_billing_service.dart';
import '../../../core/services/pricing_region_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/subscription_pricing_service.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../core/services/user_session_service.dart';
import '../widgets/subscription_pricing_card.dart';

enum _CheckoutProvider {
  googlePlay,
  razorpay,
  unavailable,
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with WidgetsBindingObserver {
  static const String _pendingPaymentProviderKey = 'pending_payment_provider';
  static const String _pendingPaymentPlanKey = 'pending_payment_plan';
  static const String _pendingPaymentOrderIdKey = 'pending_payment_order_id';
  static const String _pendingPaymentStartedAtKey =
      'pending_payment_started_at';
  static const String _lastSubscriptionPopupEventKey =
      'subscription_last_popup_event';

  SubscriptionPlan? _selectedPlan;
  final RazorpayService _razorpayService = RazorpayService();
  final PlayBillingService _playBillingService = PlayBillingService();
  final PaymentVerificationService _paymentVerificationService =
      PaymentVerificationService();
  final PricingRegionService _pricingRegionService = PricingRegionService();
  bool _isProcessingPayment = false;
  bool _isStoreLoading = false;
  bool _isRazorpayReady = false;
  bool _razorpayInitialized = false;
  Timer? _googlePlayResumeRecoveryTimer;
  Timer? _razorpayVerificationTimeoutTimer;
  bool _awaitingRazorpayExternalReturn = false;
  String? _pendingRazorpayWalletName;
  late PricingRegion _pricingRegion;
  Map<SubscriptionPlan, ProductDetails> _playProducts =
      <SubscriptionPlan, ProductDetails>{};
  Map<SubscriptionPlan, String> _playOfferTokens = <SubscriptionPlan, String>{};
  DateTime? _storePurchaseDate;
  DateTime? _storeRenewalDate;
  bool? _storeAutoRenewing;
  String? _storeOrderId;
  String? _storeStatus;
  String? _googlePlayUnavailableReason;
  String? _razorpayUnavailableReason;
  SubscriptionPlan? _pendingRazorpayPlan;
  String? _pendingRazorpayOrderId;
  bool _googlePlayRestoreRequestedByUser = false;

  List<SubscriptionPricingOption> get _plans =>
      SubscriptionPricingService.plansForRegion(_pricingRegion);

  bool get _supportsGooglePlayBilling =>
      PlayBillingService.supportsGooglePlayBilling;

  _CheckoutProvider get _selectedCheckoutProvider {
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      return _CheckoutProvider.unavailable;
    }
    return _checkoutProviderForPlan(selectedPlan);
  }

  List<SubscriptionPricingOption> get _visiblePlans => _plans;

  bool get _canPurchaseSelectedPlan {
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      return false;
    }

    if (_isProcessingPayment) {
      return false;
    }

    if (_selectedCheckoutProvider == _CheckoutProvider.unavailable) {
      return false;
    }

    final currentSubscription = ref.read(subscriptionProvider);
    if (currentSubscription.isPremium() &&
        currentSubscription.plan == selectedPlan &&
        currentSubscription.billingProvider != BillingProvider.local) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pricingRegion = SubscriptionPricingService.regionFromCountryCode(
      WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );
    _selectedPlan = SubscriptionPlan.monthly;
    _resolvePricingRegion();
    _loadGooglePlaySubscriptionState();
    _recoverPendingPaymentState();
    _initializeRazorpayCheckout();

    if (_supportsGooglePlayBilling) {
      _playBillingService.onPurchaseSuccess = _onGooglePlayPurchaseSuccess;
      _playBillingService.onPurchaseFailure = _onGooglePlayPurchaseFailure;
      _playBillingService.onPurchaseError = _onStoreError;
      _playBillingService.onPendingStateChanged = (isPending) {
        _setProcessingPayment(
          isPending,
          reason: 'google-play-pending-state-callback',
        );
      };
      _initializeGooglePlayStore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _googlePlayResumeRecoveryTimer?.cancel();
    _cancelRazorpayVerificationTimeout(reason: 'screen-disposed');
    if (_supportsGooglePlayBilling) {
      _playBillingService.dispose();
    }
    if (_razorpayInitialized) {
      _razorpayService.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
      'SubscriptionScreen.lifecycle: state=${state.name} '
      'processing=$_isProcessingPayment activePlaySession=${_playBillingService.hasActivePurchaseSession} '
      'pendingRazorpayOrder=${_pendingRazorpayOrderId ?? 'none'} '
      'awaitingRazorpayReturn=$_awaitingRazorpayExternalReturn',
    );

    switch (state) {
      case AppLifecycleState.resumed:
        if (_supportsGooglePlayBilling) {
          _scheduleGooglePlayResumeRecovery();
        }
        _handleRazorpayResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _googlePlayResumeRecoveryTimer?.cancel();
        if (_pendingRazorpayOrderId != null && _isProcessingPayment) {
          _awaitingRazorpayExternalReturn = true;
          debugPrint(
            'SubscriptionScreen.razorpayLifecycle: user-left-app '
            'orderId=${_pendingRazorpayOrderId ?? 'none'}',
          );
        }
        break;
    }
  }

  void _initializeRazorpayCheckout() {
    if (!RazorpayService.isConfigured) {
      _razorpayUnavailableReason = 'Razorpay Key ID is not configured.';
      debugPrint(
        'SubscriptionScreen.razorpayStatus: ready=false '
        'reason=$_razorpayUnavailableReason ${RazorpayService.diagnosticsSummary}',
      );
      return;
    }
    if (!PaymentVerificationService.isRazorpayBackendConfigured) {
      _razorpayUnavailableReason =
          'Secure Razorpay verification backend is not configured.';
      debugPrint(
        'SubscriptionScreen.razorpayStatus: ready=false '
        'reason=$_razorpayUnavailableReason '
        '${PaymentVerificationService.diagnosticsSummary}',
      );
      return;
    }
    if (!RazorpayService.supportsNativeCheckout) {
      _razorpayUnavailableReason =
          'Native Razorpay checkout is unavailable on this platform.';
      debugPrint(
        'SubscriptionScreen.razorpayStatus: ready=false '
        'reason=$_razorpayUnavailableReason ${RazorpayService.diagnosticsSummary}',
      );
      return;
    }

    try {
      _razorpayService.initialize();
      _razorpayService.onSuccess = _onPaymentSuccess;
      _razorpayService.onFailure = _onPaymentFailure;
      _razorpayService.onExternalWallet = _onExternalWallet;
      _isRazorpayReady = true;
      _razorpayInitialized = true;
      _razorpayUnavailableReason = null;
      debugPrint(
        'SubscriptionScreen.razorpayStatus: ready=true '
        '${RazorpayService.diagnosticsSummary} '
        '${PaymentVerificationService.diagnosticsSummary}',
      );
    } catch (error, stackTrace) {
      _isRazorpayReady = false;
      _razorpayUnavailableReason = error.toString();
      debugPrint(
        'SubscriptionScreen.razorpayStatus: ready=false '
        'reason=$_razorpayUnavailableReason\n$stackTrace',
      );
    }
  }

  Future<void> _initializeGooglePlayStore() async {
    setState(() {
      _isStoreLoading = true;
    });

    Map<SubscriptionPlan, ProductDetails> products =
        const <SubscriptionPlan, ProductDetails>{};
    try {
      products = await _playBillingService.initialize();
    } catch (error, stackTrace) {
      debugPrint(
        'SubscriptionScreen.initializeGooglePlayStore: failed with $error\n$stackTrace',
      );
      if (mounted) {
        setState(() {
          _playProducts = const <SubscriptionPlan, ProductDetails>{};
          _playOfferTokens = const <SubscriptionPlan, String>{};
          _isStoreLoading = false;
          _googlePlayUnavailableReason = error.toString();
        });
      }
      _logCheckoutProviderSelection('google-play-init-failed');
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _playProducts = products;
      _playOfferTokens = <SubscriptionPlan, String>{
        for (final entry in products.entries)
          if (_playBillingService.offerTokenForPlan(entry.key) != null)
            entry.key: _playBillingService.offerTokenForPlan(entry.key)!,
      };
      _isStoreLoading = false;
      _googlePlayUnavailableReason =
          _googlePlayBlockingReasonForPlan(_selectedPlan) ??
              _playBillingService.lastDiagnosticsMessage;
      if (_selectedPlan != null &&
          _playProducts.isNotEmpty &&
          !_playProducts.containsKey(_selectedPlan)) {
        _selectedPlan = _playProducts.containsKey(SubscriptionPlan.monthly)
            ? SubscriptionPlan.monthly
            : _playProducts.containsKey(SubscriptionPlan.yearly)
                ? SubscriptionPlan.yearly
                : _playProducts.keys.first;
      }
    });
    _logCheckoutProviderSelection('google-play-init-complete');
    debugPrint(
      'SubscriptionScreen.googlePlayRestore: source=store-init started=true',
    );
    await _playBillingService.restorePurchases();
    await _loadGooglePlaySubscriptionState();
  }

  _CheckoutProvider _checkoutProviderForPlan(SubscriptionPlan plan) {
    if (_supportsGooglePlayBilling) {
      final product = _playProducts[plan];
      final offerToken =
          _playOfferTokens[plan] ?? _playBillingService.offerTokenForPlan(plan);
      if (product != null && offerToken != null && offerToken.isNotEmpty) {
        return _CheckoutProvider.googlePlay;
      }
    }

    if (_isRazorpayReady) {
      return _CheckoutProvider.razorpay;
    }

    return _CheckoutProvider.unavailable;
  }

  String? _googlePlayBlockingReasonForPlan(SubscriptionPlan? plan) {
    if (!_supportsGooglePlayBilling) {
      return 'Google Play Billing is unavailable on this build.';
    }
    if (_isStoreLoading) {
      return 'Google Play Billing is still initializing.';
    }
    if (plan == null) {
      return _googlePlayUnavailableReason ??
          _playBillingService.lastDiagnosticsMessage;
    }

    final configuredProductId = PlayBillingService.productIdForPlan(plan);
    if (configuredProductId == null || configuredProductId.isEmpty) {
      return 'No Google Play product ID is configured for ${plan.name}.';
    }

    final product = _playProducts[plan];
    if (product == null) {
      return _playBillingService.lastDiagnosticsMessage ??
          'Google Play returned no ProductDetails for ${plan.name} '
              '(productId=$configuredProductId).';
    }

    final offerToken =
        _playOfferTokens[plan] ?? _playBillingService.offerTokenForPlan(plan);
    if (offerToken == null || offerToken.isEmpty) {
      return _playBillingService.lastDiagnosticsMessage ??
          'Google Play returned ProductDetails without a valid offer token '
              'for ${plan.name} (productId=$configuredProductId).';
    }

    return null;
  }

  void _logCheckoutProviderSelection(String source) {
    final selectedPlan = _selectedPlan;
    final provider = selectedPlan == null
        ? _CheckoutProvider.unavailable
        : _checkoutProviderForPlan(selectedPlan);
    final googlePlayReason = _googlePlayBlockingReasonForPlan(selectedPlan);
    debugPrint(
      'SubscriptionScreen.checkoutProvider: source=$source '
      'selectedPlan=${selectedPlan?.name ?? 'none'} provider=${provider.name} '
      'googlePlaySupported=$_supportsGooglePlayBilling '
      'googlePlayReason=${googlePlayReason ?? 'ready'} '
      'razorpayReady=$_isRazorpayReady '
      'razorpayReason=${_razorpayUnavailableReason ?? 'ready'}',
    );
  }

  void _setProcessingPayment(bool value, {required String reason}) {
    if (!mounted) {
      return;
    }
    if (_isProcessingPayment == value) {
      debugPrint(
        'SubscriptionScreen.processingState: unchanged value=$value reason=$reason',
      );
      return;
    }

    debugPrint(
      'SubscriptionScreen.processingState: $_isProcessingPayment -> $value '
      'reason=$reason provider=${_selectedCheckoutProvider.name}',
    );
    setState(() => _isProcessingPayment = value);
  }

  void _scheduleGooglePlayResumeRecovery() {
    _googlePlayResumeRecoveryTimer?.cancel();
    if (!_playBillingService.hasActivePurchaseSession &&
        !_isProcessingPayment) {
      return;
    }

    _googlePlayResumeRecoveryTimer =
        Timer(const Duration(seconds: 2), () async {
      if (!mounted) {
        return;
      }

      debugPrint(
        'SubscriptionScreen.googlePlayResumeRecovery: '
        'processing=$_isProcessingPayment activeSession=${_playBillingService.hasActivePurchaseSession}',
      );

      debugPrint(
        'SubscriptionScreen.googlePlayRestore: source=screen-resume started=true',
      );
      await _playBillingService.restorePurchases();
      await _loadGooglePlaySubscriptionState();
      _playBillingService.recoverInterruptedPurchaseSession(
        source: 'screen-resumed-after-google-play',
      );
    });
  }

  void _handleRazorpayResume() {
    if (_pendingRazorpayOrderId == null || !_isProcessingPayment) {
      _awaitingRazorpayExternalReturn = false;
      return;
    }

    debugPrint(
      'SubscriptionScreen.razorpayLifecycle: user-returned '
      'orderId=${_pendingRazorpayOrderId ?? 'none'} '
      'awaitingExternalReturn=$_awaitingRazorpayExternalReturn '
      'wallet=${_pendingRazorpayWalletName ?? 'unknown'}',
    );

    if (_awaitingRazorpayExternalReturn) {
      unawaited(
        _reconcilePendingRazorpayPayment(
          reason: 'user-returned-from-upi-app',
          allowTimeoutFallback: true,
        ),
      );
    }
  }

  void _startRazorpayVerificationTimeout({required String reason}) {
    _cancelRazorpayVerificationTimeout(reason: 'restart-$reason');
    debugPrint(
      'SubscriptionScreen.razorpayVerificationTimeout: started '
      'orderId=${_pendingRazorpayOrderId ?? 'none'} reason=$reason',
    );
    _razorpayVerificationTimeoutTimer = Timer(
      const Duration(seconds: 12),
      () async {
        debugPrint(
          'SubscriptionScreen.razorpayVerificationTimeout: elapsed '
          'orderId=${_pendingRazorpayOrderId ?? 'none'}',
        );
        await _handleRazorpayVerificationTimeout();
      },
    );
  }

  void _cancelRazorpayVerificationTimeout({required String reason}) {
    if (_razorpayVerificationTimeoutTimer == null) {
      return;
    }
    debugPrint(
      'SubscriptionScreen.razorpayVerificationTimeout: cancelled '
      'orderId=${_pendingRazorpayOrderId ?? 'none'} reason=$reason',
    );
    _razorpayVerificationTimeoutTimer?.cancel();
    _razorpayVerificationTimeoutTimer = null;
  }

  Future<void> _handleRazorpayVerificationTimeout() async {
    _razorpayVerificationTimeoutTimer = null;
    await _reconcilePendingRazorpayPayment(
      reason: 'verification-timeout-elapsed',
      allowTimeoutFallback: false,
    );
  }

  Future<void> _reconcilePendingRazorpayPayment({
    required String reason,
    required bool allowTimeoutFallback,
  }) async {
    final orderId = _pendingRazorpayOrderId;
    final plan = _pendingRazorpayPlan ?? _selectedPlan;
    if (orderId == null || plan == null) {
      return;
    }

    debugPrint(
      'SubscriptionScreen.razorpayStatusCheck: started '
      'reason=$reason plan=${plan.name} orderId=$orderId '
      'wallet=${_pendingRazorpayWalletName ?? 'unknown'}',
    );

    final result = await _paymentVerificationService.checkRazorpayOrderStatus(
      plan: plan,
      orderId: orderId,
    );

    debugPrint(
      'SubscriptionScreen.razorpayStatusCheck: completed '
      'reason=$reason verified=${result.verified} pending=${result.pending} '
      'cancelled=${result.cancelled} orderStatus=${result.orderStatus ?? 'null'} '
      'paymentStatus=${result.paymentStatus ?? 'null'} '
      'paymentId=${result.paymentId ?? 'null'} message=${result.message}',
    );

    if (result.verified) {
      await _clearPendingPaymentState();
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'razorpay-order-status-verified',
      );
      await _activateSelectedPlan(
        plan: plan,
        billingProvider: BillingProvider.razorpay,
        paymentId: result.paymentId,
        orderId: result.orderId ?? orderId,
        verified: true,
        verificationStatus: result.paymentStatus ?? result.orderStatus,
      );
      return;
    }

    if (result.cancelled) {
      await _handleRazorpayCancellation(
        message: result.message,
        reason: 'razorpay-order-status-cancelled',
      );
      return;
    }

    if (result.pending && allowTimeoutFallback) {
      _startRazorpayVerificationTimeout(
          reason: 'razorpay-order-status-pending');
      return;
    }

    await _handleRazorpayCancellation(
      message: result.message,
      reason: 'razorpay-order-status-unresolved',
    );
  }

  Future<void> _handleRazorpayCancellation({
    required String message,
    required String reason,
  }) async {
    debugPrint(
      'SubscriptionScreen.razorpayCancellation: reason=$reason '
      'orderId=${_pendingRazorpayOrderId ?? 'none'} '
      'wallet=${_pendingRazorpayWalletName ?? 'unknown'} message=$message',
    );
    await _clearPendingPaymentState();
    if (!mounted) {
      return;
    }
    _setProcessingPayment(false, reason: reason);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadGooglePlaySubscriptionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    DateTime? parseTimestamp(String key) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final millis = int.tryParse(raw);
      if (millis == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }

    setState(() {
      _storePurchaseDate = parseTimestamp('subscription_purchase_date');
      _storeRenewalDate = parseTimestamp('subscription_renewal_date');
      _storeAutoRenewing = prefs.getBool('subscription_auto_renewing');
      _storeOrderId = prefs.getString('subscription_store_order_id');
      _storeStatus = prefs.getString('subscription_status');
    });
  }

  Future<void> _recoverPendingPaymentState() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_pendingPaymentProviderKey);
    if (provider != BillingProvider.razorpay.name) {
      return;
    }

    final pendingPlan = SubscriptionPlan.values.firstWhere(
      (value) => value.name == prefs.getString(_pendingPaymentPlanKey),
      orElse: () => SubscriptionPlan.free,
    );
    final pendingOrderId = prefs.getString(_pendingPaymentOrderIdKey);
    debugPrint(
      'SubscriptionScreen.pendingPaymentRecovered: provider=$provider '
      'plan=${pendingPlan.name} orderId=${pendingOrderId ?? 'null'} '
      'status=recovering',
    );

    if (!mounted ||
        pendingPlan == SubscriptionPlan.free ||
        pendingOrderId == null ||
        pendingOrderId.isEmpty) {
      await _clearPendingPaymentState(prefs: prefs);
      return;
    }

    setState(() {
      _selectedPlan = pendingPlan;
      _pendingRazorpayPlan = pendingPlan;
      _pendingRazorpayOrderId = pendingOrderId;
      _isProcessingPayment = true;
    });

    await _reconcilePendingRazorpayPayment(
      reason: 'screen-open-pending-recovery',
      allowTimeoutFallback: false,
    );
  }

  Future<void> _persistPendingRazorpayPayment({
    required SubscriptionPlan plan,
    required String orderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pendingPaymentProviderKey, BillingProvider.razorpay.name);
    await prefs.setString(_pendingPaymentPlanKey, plan.name);
    await prefs.setString(_pendingPaymentOrderIdKey, orderId);
    await prefs.setString(
      _pendingPaymentStartedAtKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _pendingRazorpayPlan = plan;
    _pendingRazorpayOrderId = orderId;
    _pendingRazorpayWalletName = null;
    _awaitingRazorpayExternalReturn = false;
    debugPrint(
      'SubscriptionScreen.razorpayPaymentState: initiated '
      'plan=${plan.name} orderId=$orderId',
    );
  }

  Future<void> _clearPendingPaymentState({SharedPreferences? prefs}) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    _cancelRazorpayVerificationTimeout(reason: 'pending-state-cleared');
    await preferences.remove(_pendingPaymentProviderKey);
    await preferences.remove(_pendingPaymentPlanKey);
    await preferences.remove(_pendingPaymentOrderIdKey);
    await preferences.remove(_pendingPaymentStartedAtKey);
    _pendingRazorpayPlan = null;
    _pendingRazorpayOrderId = null;
    _pendingRazorpayWalletName = null;
    _awaitingRazorpayExternalReturn = false;
  }

  Future<void> _resolvePricingRegion() async {
    final region =
        await _pricingRegionService.resolveRegion(forceRefresh: true);
    if (!mounted) {
      return;
    }

    setState(() {
      _pricingRegion = region;
      if (_selectedPlan != null &&
          !_visiblePlans.any((plan) => plan.plan == _selectedPlan)) {
        _selectedPlan = _visiblePlans.isEmpty ? null : _visiblePlans.first.plan;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSubscription = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Upgrade to Pro'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Iconsax.crown_15,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock Your Career Potential',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Access AI-powered tools, premium templates, and career coaching',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).scale(),

                  const SizedBox(height: 24),

                  // Current Plan Status
                  if (currentSubscription.isPremium())
                    Card(
                      color: AppColors.success.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Iconsax.tick_circle,
                                color: AppColors.success),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Plan: ${currentSubscription.displayName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${_storeStatusLabel(currentSubscription)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  if (_storePurchaseDate != null)
                                    Text(
                                      'Purchase date: ${_formatDate(_storePurchaseDate!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  if (currentSubscription.isStoreManaged) ...[
                                    Text(
                                      _storeRenewalDate != null
                                          ? 'Renewal/expiry: ${_formatDate(_storeRenewalDate!)}'
                                          : 'Renewal: Managed by Google Play',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      _storeAutoRenewing == false
                                          ? 'Auto-renewal: Off'
                                          : 'Auto-renewal: Managed by Google Play',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                    if (_storeOrderId != null &&
                                        _storeOrderId!.isNotEmpty)
                                      Text(
                                        'Store reference: $_storeOrderId',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                  ] else if (currentSubscription.expiryDate !=
                                      null) ...[
                                    Text(
                                      currentSubscription.cancelAtPeriodEnd
                                          ? 'Cancels: ${_formatDate(currentSubscription.expiryDate!)}'
                                          : 'Expires: ${_formatDate(currentSubscription.expiryDate!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'Remaining validity: ${_remainingValidity(currentSubscription.expiryDate!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  ],
                                  if (currentSubscription.cancelAtPeriodEnd)
                                    Text(
                                      'Cancellation is scheduled. Premium stays active until the end of this billing period.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.warning),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                  if (currentSubscription.isPremium())
                    const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildOfferChip(
                        '🔥 Limited Time Offer',
                        backgroundColor:
                            AppColors.warning.withValues(alpha: 0.14),
                        foregroundColor: AppColors.warning,
                      ),
                      _buildOfferChip(
                        'Intro Pricing',
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                      ),
                      _buildOfferChip(
                        _pricingRegion == PricingRegion.india
                            ? 'India pricing in INR'
                            : 'Global pricing in USD',
                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                        foregroundColor: AppColors.info,
                      ),
                    ],
                  ).animate().fadeIn(delay: 275.ms),

                  // Pricing Cards
                  ...List.generate(_visiblePlans.length, (index) {
                    final plan = _visiblePlans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SubscriptionPricingCard(
                        pricing: plan,
                        currentPrice: _priceForPlan(plan.plan),
                        originalPrice: plan.price.formatOriginal(),
                        isSelected: _selectedPlan == plan.plan,
                        isEnabled: _checkoutProviderForPlan(plan.plan) !=
                            _CheckoutProvider.unavailable,
                        availabilityLabel: _availabilityLabelForPlan(plan.plan),
                        onTap: () {
                          final provider = _checkoutProviderForPlan(plan.plan);
                          debugPrint(
                            'SubscriptionScreen.planSelected: plan=${plan.plan} '
                            'provider=${provider.name} '
                            'googlePlayReason=${_googlePlayBlockingReasonForPlan(plan.plan) ?? 'ready'}',
                          );
                          setState(() => _selectedPlan = plan.plan);
                          _logCheckoutProviderSelection('plan-selected');
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (300 + index * 100).ms)
                        .slideX(begin: -0.1, end: 0);
                  }),

                  const SizedBox(height: 16),

                  // Features List
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why Upgrade?',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ..._buildFeaturesList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedPlan != null)
                    Text(
                      '${_getPlanName(_selectedPlan!)} - ${_getPlanPrice(_selectedPlan!)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _canPurchaseSelectedPlan ? _handleUpgrade : null,
                    icon: _isProcessingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _selectedCheckoutProvider ==
                                    _CheckoutProvider.googlePlay
                                ? Iconsax.shop
                                : Iconsax.card,
                          ),
                    label: Text(_isProcessingPayment
                        ? (_selectedCheckoutProvider ==
                                _CheckoutProvider.googlePlay
                            ? 'Connecting to Google Play...'
                            : 'Opening Payment...')
                        : (_selectedCheckoutProvider ==
                                _CheckoutProvider.googlePlay
                            ? 'Subscribe with Google Play'
                            : _selectedCheckoutProvider ==
                                    _CheckoutProvider.razorpay
                                ? 'Subscribe with Razorpay'
                                : 'Subscription Unavailable')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedCheckoutProvider ==
                                _CheckoutProvider.googlePlay
                            ? Iconsax.shield_security
                            : Icons.lock,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCheckoutProvider ==
                                _CheckoutProvider.googlePlay
                            ? 'Managed securely by Google Play • Cancel anytime'
                            : 'Secured by Razorpay • Cancel anytime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                  if (_supportsGooglePlayBilling) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _isProcessingPayment
                          ? null
                          : _restoreGooglePlayPurchases,
                      child: const Text('Restore Google Play Purchases'),
                    ),
                  ],
                  if (currentSubscription.isPremium()) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: currentSubscription.isStoreManaged
                          ? TextButton(
                              onPressed: _openGooglePlaySubscriptionManager,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                'Manage Subscription',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                              ),
                            )
                          : TextButton(
                              onPressed: currentSubscription.cancelAtPeriodEnd
                                  ? _keepSubscription
                                  : _confirmCancellation,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    currentSubscription.cancelAtPeriodEnd
                                        ? AppColors.primary
                                        : AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                currentSubscription.cancelAtPeriodEnd
                                    ? 'Keep Subscription'
                                    : 'Cancel Subscription',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          currentSubscription.cancelAtPeriodEnd
                                              ? AppColors.primary
                                              : AppColors.error,
                                    ),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      'Unlimited resume creation',
      'All premium templates and creative designs',
      'Unlimited PDF downloads with no watermark',
      'High-resolution export access',
      'Premium sections including projects, certifications, achievements and languages',
      'AI summary, bullet, rewrite and ATS optimisation tools',
      'Cover letter generator',
      'Photo upload and signature support',
      'Cloud sync across devices',
      'DOCX and TXT export access when available',
      'Priority customer support',
    ];

    return features
        .map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Iconsax.tick_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(feature,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ))
        .toList();
  }

  String _getPlanName(SubscriptionPlan plan) {
    return _pricingForPlan(plan).name;
  }

  SubscriptionPricingOption _pricingForPlan(SubscriptionPlan plan) {
    return SubscriptionPricingService.planFor(_pricingRegion, plan);
  }

  String _priceForPlan(SubscriptionPlan plan) {
    final pricing = _pricingForPlan(plan);
    if (_supportsGooglePlayBilling) {
      if (_isStoreLoading) {
        return 'Loading...';
      }
      final livePrice = _playProducts[plan]?.price;
      if (livePrice != null && livePrice.isNotEmpty) {
        return livePrice;
      }
      return pricing.price.formatCurrent();
    }
    return pricing.price.formatCurrent();
  }

  String _getPlanPrice(SubscriptionPlan plan) {
    final pricing = _pricingForPlan(plan);
    final price = _priceForPlan(plan);
    if (price == 'Loading...') {
      return 'Loading Google Play price...';
    }
    return '$price${pricing.periodLabel}';
  }

  String _availabilityLabelForPlan(SubscriptionPlan plan) {
    final provider = _checkoutProviderForPlan(plan);
    if (provider == _CheckoutProvider.googlePlay) {
      return 'Managed by Google Play • Cancel anytime';
    }
    if (provider == _CheckoutProvider.razorpay) {
      if (_supportsGooglePlayBilling) {
        return 'Google Play unavailable, checkout via Razorpay';
      }
      return 'Secured by Razorpay • Cancel anytime';
    }
    if (_supportsGooglePlayBilling && _isStoreLoading) {
      return 'Google Play Billing is still initializing.';
    }
    if (_supportsGooglePlayBilling) {
      return 'Play product pending for this plan';
    }
    return 'Payment unavailable for this plan';
  }

  Widget _buildOfferChip(
    String label, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    if (_selectedPlan == null) return;

    debugPrint(
      'SubscriptionScreen.purchaseRequested: plan=$_selectedPlan '
      'provider=$_selectedCheckoutProvider '
      'available=$_canPurchaseSelectedPlan '
      'product=${_playProducts[_selectedPlan!]?.id ?? 'null'} '
      'offerToken=${_playOfferTokens[_selectedPlan!] ?? _playBillingService.offerTokenForPlan(_selectedPlan!) ?? 'null'} '
      'googlePlayReason=${_googlePlayBlockingReasonForPlan(_selectedPlan) ?? 'ready'} '
      'razorpayReason=${_razorpayUnavailableReason ?? 'ready'}',
    );

    if (_selectedCheckoutProvider == _CheckoutProvider.googlePlay &&
        ref.read(subscriptionProvider).isPremium() &&
        ref.read(subscriptionProvider).plan == _selectedPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Google Play subscription is already active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _setProcessingPayment(
      true,
      reason: 'purchase-requested',
    );

    if (_selectedCheckoutProvider == _CheckoutProvider.googlePlay) {
      if (!_playProducts.containsKey(_selectedPlan)) {
        _setProcessingPayment(
          false,
          reason: 'google-play-product-missing',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'This Google Play subscription is not available for this build yet.',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      await _playBillingService.purchasePlan(_selectedPlan!);
      return;
    }

    if (_selectedCheckoutProvider == _CheckoutProvider.unavailable) {
      _setProcessingPayment(
        false,
        reason: 'checkout-provider-unavailable',
      );
      final reason = _googlePlayBlockingReasonForPlan(_selectedPlan) ??
          _razorpayUnavailableReason ??
          'No payment provider is available for this plan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!RazorpayService.isConfigured) {
      if (mounted) {
        _setProcessingPayment(
          false,
          reason: 'razorpay-not-configured',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Razorpay is not configured for this build yet.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    if (!RazorpayService.supportsNativeCheckout) {
      if (mounted) {
        _setProcessingPayment(
          false,
          reason: 'razorpay-web-fallback',
        );
        _showWebCheckoutFallback();
      }
      return;
    }

    // Load the current stored contact for prefill if available.
    final prefs = await SharedPreferences.getInstance();
    final phone = UserSessionService.readStoredPhoneForCheckout(prefs);
    final email = UserSessionService.readStoredEmailForCheckout(prefs);
    final orderResult = await _paymentVerificationService.createRazorpayOrder(
      plan: _selectedPlan!,
      pricing: _pricingForPlan(_selectedPlan!),
    );
    if (!orderResult.success ||
        orderResult.orderId == null ||
        orderResult.orderId!.isEmpty) {
      if (mounted) {
        _setProcessingPayment(
          false,
          reason: 'razorpay-order-creation-failed',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderResult.message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }
    await _persistPendingRazorpayPayment(
      plan: _selectedPlan!,
      orderId: orderResult.orderId!,
    );
    debugPrint(
      'SubscriptionScreen.razorpayPurchase: plan=${_selectedPlan!.name} '
      'provider=${_selectedCheckoutProvider.name} '
      'orderId=${orderResult.orderId} '
      'selectedUpiApp=pending-user-choice '
      '${RazorpayService.diagnosticsSummary} '
      '${PaymentVerificationService.diagnosticsSummary}',
    );
    final opened = _razorpayService.openCheckout(
      plan: _selectedPlan!,
      pricing: _pricingForPlan(_selectedPlan!),
      orderId: orderResult.orderId!,
      userPhone: phone,
      userEmail: email,
    );
    if (!opened && mounted) {
      await _clearPendingPaymentState(prefs: prefs);
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'razorpay-checkout-open-failed',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to open the Razorpay checkout.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
  }

  Future<void> _activateSelectedPlan({
    required SubscriptionPlan plan,
    required BillingProvider billingProvider,
    String activationEventType = 'purchase',
    bool showSuccessPopup = true,
    bool closeSubscriptionScreenOnSuccess = true,
    String? paymentId,
    String? purchaseToken,
    String? orderId,
    String? signature,
    bool verified = false,
    String? verificationStatus,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    bool? autoRenewing,
  }) async {
    if (billingProvider == BillingProvider.razorpay && !verified) {
      debugPrint(
        'SubscriptionScreen.premiumActivationResult: blocked '
        'provider=${billingProvider.name} reason=unverified-payment',
      );
      return;
    }

    final resolvedPurchaseDate = purchaseDate ?? DateTime.now();
    final resolvedExpiryDate = expiryDate ??
        (billingProvider == BillingProvider.googlePlay
            ? null
            : resolvedPurchaseDate.add(_planDuration(plan)));
    ref.read(subscriptionProvider.notifier).upgradeToPlan(
          plan,
          expiryDate: resolvedExpiryDate,
          billingProvider: billingProvider,
        );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan.name);
    await prefs.setString('subscription_provider', billingProvider.name);
    await prefs.setBool('subscription_active', true);
    await prefs.setBool(
      'subscription_verified',
      billingProvider == BillingProvider.googlePlay ? true : verified,
    );
    await prefs.setString(
      'subscription_status',
      verificationStatus ?? 'active',
    );
    await prefs.setString(
      'subscription_purchase_date',
      resolvedPurchaseDate.millisecondsSinceEpoch.toString(),
    );
    await prefs.setString('subscription_purchase_token', purchaseToken ?? '');
    await prefs.setString(
      'subscription_store_order_id',
      orderId ?? paymentId ?? '',
    );
    await prefs.setString('subscription_payment_id', paymentId ?? '');
    await prefs.setString('subscription_order_id', orderId ?? '');
    await prefs.setString('subscription_signature', signature ?? '');
    await prefs.setString(
      'subscription_verification_status',
      verificationStatus ?? 'active',
    );
    await prefs.setBool(
      'subscription_auto_renewing',
      autoRenewing ?? (billingProvider == BillingProvider.googlePlay),
    );
    if (resolvedExpiryDate != null) {
      await prefs.setString(
        'subscription_expiry',
        resolvedExpiryDate.millisecondsSinceEpoch.toString(),
      );
      await prefs.setString(
        'subscription_renewal_date',
        resolvedExpiryDate.millisecondsSinceEpoch.toString(),
      );
    } else {
      await prefs.remove('subscription_expiry');
      await prefs.remove('subscription_renewal_date');
    }
    await prefs.setBool('subscription_cancel_at_period_end', false);
    await _clearPendingPaymentState(prefs: prefs);
    await _loadGooglePlaySubscriptionState();

    debugPrint(
      'SubscriptionScreen.premiumActivationResult: success '
      'plan=${plan.name} provider=${billingProvider.name} '
      'eventType=$activationEventType showPopup=$showSuccessPopup '
      'verified=$verified paymentId=${paymentId ?? 'null'} '
      'orderId=${orderId ?? 'null'} tokenPresent=${purchaseToken?.isNotEmpty ?? false} '
      'purchaseDate=${resolvedPurchaseDate.toIso8601String()} '
      'renewalDate=${resolvedExpiryDate?.toIso8601String() ?? 'null'} '
      'autoRenewing=${autoRenewing ?? (billingProvider == BillingProvider.googlePlay)}',
    );

    if (!mounted || !showSuccessPopup) return;

    final popupEventKey = _subscriptionPopupEventKey(
      provider: billingProvider,
      plan: plan,
      eventType: activationEventType,
      paymentId: paymentId,
      purchaseToken: purchaseToken,
      orderId: orderId,
    );
    final shouldShowPopup =
        await _markSubscriptionPopupEventIfNeeded(popupEventKey);
    if (!mounted || !shouldShowPopup) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 52),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              _subscriptionResultTitle(
                billingProvider: billingProvider,
                activationEventType: activationEventType,
              ),
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              _subscriptionResultSubtitle(
                plan: plan,
                activationEventType: activationEventType,
              ),
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              billingProvider == BillingProvider.googlePlay
                  ? 'Managed in Google Play'
                  : 'Payment ID: ${paymentId ?? 'unavailable'}',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontFamily: billingProvider == BillingProvider.googlePlay
                        ? null
                        : 'monospace',
                  ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (closeSubscriptionScreenOnSuccess && mounted) {
                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  activationEventType == 'restore'
                      ? 'View Current Plan'
                      : 'Start Using Premium',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  void _showWebCheckoutFallback() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Iconsax.monitor_mobbile,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Web Checkout Fallback',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This build does not support the native Razorpay checkout used by the app on the web. No premium access will be granted without a verified payment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) {
      return;
    }

    final plan = _pendingRazorpayPlan ?? _selectedPlan;
    final paymentId = response.paymentId?.trim();
    final orderId = response.orderId?.trim();
    final signature = response.signature?.trim();
    debugPrint(
      'SubscriptionScreen.razorpayCallback: status=success '
      'plan=${plan?.name ?? 'null'} paymentId=${paymentId ?? 'null'} '
      'orderId=${orderId ?? 'null'} signaturePresent=${signature?.isNotEmpty ?? false}',
    );
    _cancelRazorpayVerificationTimeout(reason: 'razorpay-success-callback');

    if (plan == null ||
        paymentId == null ||
        paymentId.isEmpty ||
        orderId == null ||
        orderId.isEmpty ||
        signature == null ||
        signature.isEmpty) {
      await _clearPendingPaymentState();
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'razorpay-success-response-incomplete',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment could not be verified because the Razorpay response was incomplete.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_pendingRazorpayOrderId != null && _pendingRazorpayOrderId != orderId) {
      debugPrint(
        'SubscriptionScreen.razorpayCallback: status=order-mismatch '
        'expected=$_pendingRazorpayOrderId actual=$orderId',
      );
      await _clearPendingPaymentState();
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'razorpay-order-mismatch',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Payment verification failed due to an order mismatch.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final verificationResult =
        await _paymentVerificationService.verifyRazorpayPayment(
      plan: plan,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
    debugPrint(
      'SubscriptionScreen.razorpayVerification: '
      'verified=${verificationResult.verified} '
      'signatureVerified=${verificationResult.signatureVerified} '
      'paymentStatus=${verificationResult.paymentStatus ?? 'null'} '
      'message=${verificationResult.message}',
    );

    if (!verificationResult.verified) {
      await _clearPendingPaymentState();
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'razorpay-verification-failed',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verificationResult.message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (mounted) {
      _setProcessingPayment(
        false,
        reason: 'razorpay-verification-succeeded',
      );
    }
    await _activateSelectedPlan(
      plan: plan,
      billingProvider: BillingProvider.razorpay,
      paymentId: verificationResult.paymentId ?? paymentId,
      orderId: verificationResult.orderId ?? orderId,
      signature: signature,
      verified: verificationResult.signatureVerified,
      verificationStatus: verificationResult.paymentStatus ?? 'verified',
    );
  }

  void _onGooglePlayPurchaseSuccess(
    PurchaseDetails purchase,
    SubscriptionPlan plan,
  ) {
    final googlePurchase =
        purchase is GooglePlayPurchaseDetails ? purchase : null;
    final purchaseToken =
        purchase.verificationData.serverVerificationData.trim();
    final billingPurchase = googlePurchase?.billingClientPurchase;
    final purchaseDate = _googlePlayPurchaseDate(purchase);
    final renewalDate = _googlePlayRenewalDate(
      plan,
      purchaseDate: purchaseDate,
      autoRenewing: billingPurchase?.isAutoRenewing ?? true,
    );
    debugPrint(
      'SubscriptionScreen.purchaseSuccess: plan=$plan product=${purchase.productID} '
      'status=${purchase.status.name} '
      'pendingComplete=${purchase.pendingCompletePurchase} '
      'purchaseTokenPresent=${purchaseToken.isNotEmpty} '
      'acknowledged=${billingPurchase?.isAcknowledged ?? 'unknown'} '
      'autoRenewing=${billingPurchase?.isAutoRenewing ?? 'unknown'} '
      'orderId=${billingPurchase?.orderId ?? purchase.purchaseID ?? 'null'} '
      'purchaseDate=${purchaseDate?.toIso8601String() ?? 'null'} '
      'renewalDate=${renewalDate?.toIso8601String() ?? 'null'}',
    );
    final isRestored = purchase.status == PurchaseStatus.restored;
    final activationEventType = isRestored ? 'restore' : 'purchase';
    final showSuccessPopup = !isRestored || _googlePlayRestoreRequestedByUser;
    final closeSubscriptionScreenOnSuccess = !isRestored;
    if (isRestored) {
      _googlePlayRestoreRequestedByUser = false;
    }
    _setProcessingPayment(
      false,
      reason: 'google-play-purchase-success',
    );
    unawaited(_activateSelectedPlan(
      plan: plan,
      billingProvider: BillingProvider.googlePlay,
      activationEventType: activationEventType,
      showSuccessPopup: showSuccessPopup,
      closeSubscriptionScreenOnSuccess: closeSubscriptionScreenOnSuccess,
      paymentId: purchase.purchaseID ?? purchase.productID,
      purchaseToken: purchaseToken,
      orderId: billingPurchase?.orderId ?? purchase.purchaseID,
      signature: billingPurchase?.signature,
      verified: purchaseToken.isNotEmpty,
      verificationStatus: purchase.status.name,
      purchaseDate: purchaseDate,
      expiryDate: renewalDate,
      autoRenewing: billingPurchase?.isAutoRenewing,
    ));
  }

  void _onGooglePlayPurchaseFailure(PlayBillingPurchaseFailure failure) {
    if (!mounted) {
      return;
    }

    debugPrint(
      'SubscriptionScreen.googlePlayFailure: code=${failure.code.name} '
      'rawCode=${failure.rawCode ?? 'none'} message=${failure.message}',
    );

    _setProcessingPayment(
      false,
      reason: 'google-play-failure-${failure.code.name}',
    );

    if (failure.code == PlayBillingFailureCode.itemAlreadyOwned) {
      unawaited(_loadGooglePlaySubscriptionState());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message),
        backgroundColor: failure.code == PlayBillingFailureCode.userCanceled
            ? Colors.orange.shade700
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onStoreError(String message) {
    if (!mounted) {
      return;
    }

    debugPrint('SubscriptionScreen.storeError: $message');

    _setProcessingPayment(
      false,
      reason: 'google-play-store-error',
    );
  }

  void _onPaymentFailure(PaymentFailureResponse response) async {
    debugPrint(
      'SubscriptionScreen.razorpayCallback: status=${RazorpayService.errorStatus(response.code)} '
      'code=${response.code} message=${response.message ?? 'none'}',
    );
    _cancelRazorpayVerificationTimeout(reason: 'razorpay-failure-callback');
    final message = response.code == Razorpay.PAYMENT_CANCELLED
        ? 'Payment was cancelled. No amount was charged.'
        : RazorpayService.getErrorMessage(response.code);
    await _handleRazorpayCancellation(
      message: message,
      reason: 'razorpay-payment-failure',
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _pendingRazorpayWalletName = response.walletName?.trim();
    _awaitingRazorpayExternalReturn = true;
    if (!mounted) return;
    debugPrint(
      'SubscriptionScreen.razorpayCallback: status=external_wallet '
      'wallet=${response.walletName ?? 'unknown'}',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continue the payment in ${response.walletName}...'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Cancel premium at the end of the current billing period? You will keep access until the expiry date shown above.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Plan'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Cancel Subscription'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(subscriptionProvider.notifier).scheduleCancellation();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Subscription will end at the close of the current billing period.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _keepSubscription() async {
    await ref.read(subscriptionProvider.notifier).keepSubscription();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Scheduled cancellation removed. Your subscription stays active.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restoreGooglePlayPurchases() async {
    _googlePlayRestoreRequestedByUser = true;
    _setProcessingPayment(
      true,
      reason: 'google-play-restore-started',
    );
    try {
      await _playBillingService.restorePurchases();
      await _loadGooglePlaySubscriptionState();
      if (!mounted) {
        return;
      }
      _setProcessingPayment(
        false,
        reason: 'google-play-restore-finished',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking Google Play for previous purchases...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _googlePlayRestoreRequestedByUser = false;
    }
  }

  String _subscriptionPopupEventKey({
    required BillingProvider provider,
    required SubscriptionPlan plan,
    required String eventType,
    String? paymentId,
    String? purchaseToken,
    String? orderId,
  }) {
    final eventId = [orderId, purchaseToken, paymentId, plan.name]
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join('|');
    return '${provider.name}:$eventType:$eventId';
  }

  Future<bool> _markSubscriptionPopupEventIfNeeded(String popupEventKey) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_lastSubscriptionPopupEventKey) ?? '';
    if (previous == popupEventKey) {
      debugPrint(
        'SubscriptionScreen.subscriptionPopup: skipped event=$popupEventKey',
      );
      return false;
    }

    await prefs.setString(_lastSubscriptionPopupEventKey, popupEventKey);
    debugPrint(
      'SubscriptionScreen.subscriptionPopup: recorded event=$popupEventKey',
    );
    return true;
  }

  String _subscriptionResultTitle({
    required BillingProvider billingProvider,
    required String activationEventType,
  }) {
    if (activationEventType == 'restore') {
      return 'Subscription Restored';
    }

    return billingProvider == BillingProvider.googlePlay
        ? 'Subscription Active!'
        : 'Payment Successful!';
  }

  String _subscriptionResultSubtitle({
    required SubscriptionPlan plan,
    required String activationEventType,
  }) {
    if (activationEventType == 'restore') {
      return '${_getPlanName(plan)} restored';
    }

    return '${_getPlanName(plan)} activated';
  }

  DateTime? _googlePlayPurchaseDate(PurchaseDetails purchase) {
    final rawTransactionDate = purchase.transactionDate;
    if (rawTransactionDate == null || rawTransactionDate.isEmpty) {
      return null;
    }

    final transactionMillis = int.tryParse(rawTransactionDate);
    if (transactionMillis == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(transactionMillis);
  }

  DateTime? _googlePlayRenewalDate(
    SubscriptionPlan plan, {
    required DateTime? purchaseDate,
    required bool autoRenewing,
  }) {
    if (purchaseDate == null) {
      return null;
    }

    var currentPeriodEnd = purchaseDate.add(_planDuration(plan));
    final now = DateTime.now();
    while (currentPeriodEnd.isBefore(now)) {
      currentPeriodEnd = currentPeriodEnd.add(_planDuration(plan));
    }

    if (!autoRenewing && currentPeriodEnd.isBefore(now)) {
      return now;
    }

    return currentPeriodEnd;
  }

  Future<void> _openGooglePlaySubscriptionManager() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=${AppInfo.playStorePackageId}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open Google Play subscription management.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Duration _planDuration(SubscriptionPlan plan) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _remainingValidity(DateTime expiryDate) {
    final remaining = expiryDate.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired';
    }

    final days = remaining.inDays;
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} left';
    }

    final hours = remaining.inHours;
    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} left';
    }

    final minutes = remaining.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} left';
  }

  String _storeStatusLabel(SubscriptionModel subscription) {
    if (subscription.isStoreManaged) {
      return _storeStatus == 'active' ? 'Active' : 'Active in Google Play';
    }
    if (!subscription.isPremium()) {
      return 'Inactive';
    }
    if (subscription.cancelAtPeriodEnd) {
      return 'Cancels at period end';
    }
    return 'Active';
  }
}
