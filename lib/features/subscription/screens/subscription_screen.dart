import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:iconsax/iconsax.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/models/subscription_pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/services/play_billing_service.dart';
import '../../../core/services/pricing_region_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/subscription_pricing_service.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../core/services/user_session_service.dart';
import '../widgets/subscription_pricing_card.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionPlan? _selectedPlan;
  final RazorpayService _razorpayService = RazorpayService();
  final PlayBillingService _playBillingService = PlayBillingService();
  final PricingRegionService _pricingRegionService = PricingRegionService();
  bool _isProcessingPayment = false;
  bool _isStoreLoading = false;
  String? _storeMessage;
  late PricingRegion _pricingRegion;
  Map<SubscriptionPlan, ProductDetails> _playProducts =
      <SubscriptionPlan, ProductDetails>{};

  List<SubscriptionPricingOption> get _plans =>
      SubscriptionPricingService.plansForRegion(_pricingRegion);

  bool get _usesGooglePlayBilling =>
      PlayBillingService.supportsGooglePlayBilling;

  bool get _canUseGooglePlayTestFallback =>
      PlayBillingService.canUseTestPurchaseFallback;

  bool get _canUseDummyPaymentFallback =>
      AppConfigService.readBool('ENABLE_DUMMY_PAYMENTS');

  bool get _shouldUseLiveGooglePlayPricesOnly =>
      _usesGooglePlayBilling && !_canUseGooglePlayTestFallback;

  List<SubscriptionPricingOption> get _visiblePlans {
    if (_shouldUseLiveGooglePlayPricesOnly) {
      return _plans
          .where((plan) => _playProducts.containsKey(plan.plan))
          .toList(growable: false);
    }

    return _plans;
  }

  @override
  void initState() {
    super.initState();
    _pricingRegion = SubscriptionPricingService.regionFromCountryCode(
      WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );
    _selectedPlan = SubscriptionPlan.monthly;
    _resolvePricingRegion();

    if (_usesGooglePlayBilling) {
      _playBillingService.onPurchaseSuccess = _onGooglePlayPurchaseSuccess;
      _playBillingService.onPurchaseError = _onStoreError;
      _playBillingService.onPendingStateChanged = (isPending) {
        if (mounted) {
          setState(() => _isProcessingPayment = isPending);
        }
      };
      _initializeGooglePlayStore();
    } else {
      if (RazorpayService.isConfigured) {
        _razorpayService.initialize();
        _razorpayService.onSuccess = _onPaymentSuccess;
        _razorpayService.onFailure = _onPaymentFailure;
        _razorpayService.onExternalWallet = _onExternalWallet;
      } else if (_canUseDummyPaymentFallback) {
        setState(() {
          _storeMessage =
              'Dummy card payments are enabled for this test build. No real charge will be made.';
        });
      } else {
        setState(() {
          _storeMessage =
              'Payments are not configured for this build yet. Please check Razorpay configuration.';
        });
      }
    }
  }

  @override
  void dispose() {
    if (_usesGooglePlayBilling) {
      _playBillingService.dispose();
    } else {
      _razorpayService.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeGooglePlayStore() async {
    setState(() {
      _isStoreLoading = true;
      _storeMessage = 'Loading Google Play subscriptions...';
    });

    final products = await _playBillingService.initialize();
    if (!mounted) {
      return;
    }

    setState(() {
      _playProducts = products;
      _isStoreLoading = false;
      _storeMessage = _buildGooglePlayStoreMessage(products);
      if (!_canUseGooglePlayTestFallback &&
          _selectedPlan != null &&
          !_playProducts.containsKey(_selectedPlan)) {
        _selectedPlan = _playProducts.containsKey(SubscriptionPlan.monthly)
            ? SubscriptionPlan.monthly
            : _playProducts.containsKey(SubscriptionPlan.yearly)
                ? SubscriptionPlan.yearly
                : null;
      }
    });
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
                                  if (currentSubscription.isStoreManaged)
                                    Text(
                                      'Managed in Google Play',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    )
                                  else if (currentSubscription.expiryDate !=
                                      null)
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

                  if (_usesGooglePlayBilling)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _playProducts.isEmpty
                            ? AppColors.warning.withValues(alpha: 0.08)
                            : AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _playProducts.isEmpty
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _playProducts.isEmpty
                                ? Iconsax.warning_2
                                : Iconsax.shield_security,
                            size: 18,
                            color: _playProducts.isEmpty
                                ? AppColors.warning
                                : AppColors.info,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isStoreLoading
                                  ? 'Loading Google Play subscriptions...'
                                  : _storeMessage ??
                                      'Subscriptions on Android are managed securely through Google Play.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: _playProducts.isEmpty
                                    ? AppColors.warning
                                    : AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                  if (_usesGooglePlayBilling) const SizedBox(height: 16),

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

                  const SizedBox(height: 16),

                  // Pricing Cards
                  if (_shouldUseLiveGooglePlayPricesOnly &&
                      _visiblePlans.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.warning_2,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No Google Play subscriptions are available for this install yet.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Install the app from your Play testing track, sign in with an enrolled tester account, and verify that the subscription products and base plans are active for this application ID.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms)
                  else
                    ...List.generate(_visiblePlans.length, (index) {
                      final plan = _visiblePlans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SubscriptionPricingCard(
                          pricing: plan,
                          currentPrice: _priceForPlan(plan.plan),
                          originalPrice: plan.price.formatOriginal(),
                          isSelected: _selectedPlan == plan.plan,
                          isEnabled: !_usesGooglePlayBilling ||
                              _playProducts.containsKey(plan.plan) ||
                              _canUseGooglePlayTestFallback,
                          availabilityLabel:
                              _availabilityLabelForPlan(plan.plan),
                          onTap: () =>
                              setState(() => _selectedPlan = plan.plan),
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
                    onPressed: (_selectedPlan == null ||
                            _isProcessingPayment ||
                            (_usesGooglePlayBilling && _isStoreLoading) ||
                            (_usesGooglePlayBilling &&
                                !_playProducts.containsKey(_selectedPlan) &&
                                !_canUseGooglePlayTestFallback))
                        ? null
                        : _handleUpgrade,
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
                            _usesGooglePlayBilling
                                ? Iconsax.shop
                                : _canUseDummyPaymentFallback &&
                                        !RazorpayService.isConfigured
                                    ? Iconsax.card_tick
                                    : Iconsax.card,
                          ),
                    label: Text(_isProcessingPayment
                        ? (_usesGooglePlayBilling
                            ? 'Connecting to Google Play...'
                            : _canUseDummyPaymentFallback &&
                                    !RazorpayService.isConfigured
                                ? 'Opening Test Checkout...'
                                : 'Opening Payment...')
                        : (_usesGooglePlayBilling
                            ? 'Subscribe with Google Play'
                            : _canUseDummyPaymentFallback &&
                                    !RazorpayService.isConfigured
                                ? 'Pay with Test Card'
                                : 'Subscribe Now')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _usesGooglePlayBilling
                            ? Iconsax.shield_security
                            : Icons.lock,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _usesGooglePlayBilling
                            ? 'Managed securely by Google Play • Cancel anytime'
                            : _canUseDummyPaymentFallback &&
                                    !RazorpayService.isConfigured
                                ? 'Local dummy checkout • No real charge'
                                : 'Secured by Razorpay • Cancel anytime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                  if (_usesGooglePlayBilling) ...[
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
    if (_usesGooglePlayBilling) {
      if (_shouldUseLiveGooglePlayPricesOnly) {
        if (_isStoreLoading) {
          return 'Loading...';
        }
        return _playProducts[plan]?.price ?? 'Unavailable';
      }
      return _playProducts[plan]?.price ?? pricing.price.formatCurrent();
    }
    return pricing.price.formatCurrent();
  }

  String _getPlanPrice(SubscriptionPlan plan) {
    final pricing = _pricingForPlan(plan);
    final price = _priceForPlan(plan);
    if (price == 'Loading...') {
      return 'Loading Google Play price...';
    }
    if (price == 'Unavailable') {
      return 'Unavailable on this install';
    }
    return '$price${pricing.periodLabel}';
  }

  String _availabilityLabelForPlan(SubscriptionPlan plan) {
    if (!_usesGooglePlayBilling) {
      return 'Cancel anytime';
    }
    if (_isStoreLoading) {
      return 'Loading Google Play pricing...';
    }
    if (_playProducts.containsKey(plan)) {
      return 'Managed by Google Play • Cancel anytime';
    }
    if (_canUseGooglePlayTestFallback) {
      return 'Local test activation available • Use Internal Testing for real billing';
    }
    return 'Available when this Google Play plan is configured';
  }

  String _buildGooglePlayStoreMessage(
    Map<SubscriptionPlan, ProductDetails> products,
  ) {
    if (products.isEmpty) {
      if (_canUseGooglePlayTestFallback) {
        return 'Google Play products are unavailable in this local build. Install from Play Internal Testing for real billing, or continue with debug test activation to validate the premium flow.';
      }
      return 'No Google Play subscriptions were returned for this install. This usually means the app was sideloaded, the current account is not enrolled as a tester, or the Play subscriptions/base plans are not active for this package yet.';
    }

    final missingPlans = _plans
        .where((plan) => !products.containsKey(plan.plan))
        .map((plan) => plan.name)
        .toList(growable: false);
    if (missingPlans.isEmpty) {
      return 'Subscriptions on Android are managed securely through Google Play.';
    }

    return 'Google Play is active for ${products.length} plan${products.length == 1 ? '' : 's'}. Still configure: ${missingPlans.join(', ')}.';
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
    setState(() => _isProcessingPayment = true);

    if (_usesGooglePlayBilling) {
      if (!_playProducts.containsKey(_selectedPlan)) {
        if (_canUseGooglePlayTestFallback) {
          setState(() => _isProcessingPayment = false);
          _showGooglePlayDebugFallback();
          return;
        }

        setState(() => _isProcessingPayment = false);
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

    if (!RazorpayService.isConfigured) {
      if (_canUseDummyPaymentFallback) {
        if (mounted) {
          setState(() => _isProcessingPayment = false);
          _showDummyPaymentSheet();
        }
        return;
      }

      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Payments are not configured for this build yet.',
            ),
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
        setState(() => _isProcessingPayment = false);
        _showWebCheckoutFallback();
      }
      return;
    }

    // Load the current stored contact for prefill if available.
    final prefs = await SharedPreferences.getInstance();
    final phone = UserSessionService.readStoredContact(prefs);
    final opened = _razorpayService.openCheckout(
      plan: _selectedPlan!,
      pricing: _pricingForPlan(_selectedPlan!),
      userPhone: phone,
    );
    if (!opened && mounted) {
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
    }
    if (mounted) setState(() => _isProcessingPayment = false);
  }

  void _showDummyPaymentSheet() {
    final cardNumberController =
        TextEditingController(text: '4111111111111111');
    final cardholderController = TextEditingController(text: 'Test User');
    final expiryController = TextEditingController(text: '12/30');
    final cvvController = TextEditingController(text: '123');
    String? errorMessage;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.card_tick,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Test Card Checkout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This build accepts dummy card details for testing only. No real payment will be processed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '4111111111111111',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardholderController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final cardNumber = cardNumberController.text
                        .replaceAll(RegExp(r'\s+'), '');
                    final cardholder = cardholderController.text.trim();
                    final expiry = expiryController.text.trim();
                    final cvv = cvvController.text.trim();

                    final isCardValid =
                        RegExp(r'^\d{16}$').hasMatch(cardNumber);
                    final isExpiryValid =
                        RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(expiry);
                    final isCvvValid = RegExp(r'^\d{3,4}$').hasMatch(cvv);

                    if (!isCardValid ||
                        cardholder.isEmpty ||
                        !isExpiryValid ||
                        !isCvvValid) {
                      setModalState(() {
                        errorMessage =
                            'Enter dummy test details in valid card format to continue.';
                      });
                      return;
                    }

                    Navigator.pop(ctx);
                    _activateSelectedPlan(
                      plan: _selectedPlan!,
                      billingProvider: BillingProvider.local,
                      paymentId:
                          'dummy-card-${cardNumber.substring(cardNumber.length - 4)}',
                    );
                  },
                  icon: const Icon(Iconsax.card_tick),
                  label: const Text('Complete Test Payment'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      cardNumberController.dispose();
      cardholderController.dispose();
      expiryController.dispose();
      cvvController.dispose();
    });
  }

  void _showGooglePlayDebugFallback() {
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
                    Iconsax.shop,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Google Play Test Fallback',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This local Android build cannot load Play subscription products yet. Use an Internal Testing install from Play Console to validate real billing, or continue with a debug-only test activation to verify the premium unlock flow.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _activateSelectedPlan(
                    plan: _selectedPlan!,
                    billingProvider: BillingProvider.local,
                    paymentId: 'debug-google-play-fallback',
                  );
                },
                icon: const Icon(Iconsax.tick_circle),
                label: const Text('Continue With Test Activation'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateSelectedPlan({
    required SubscriptionPlan plan,
    required BillingProvider billingProvider,
    String? paymentId,
  }) async {
    final expiryDate = billingProvider == BillingProvider.googlePlay
        ? null
        : DateTime.now().add(_planDuration(plan));
    ref.read(subscriptionProvider.notifier).upgradeToPlan(
          plan,
          expiryDate: expiryDate,
          billingProvider: billingProvider,
        );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan.name);
    await prefs.setString('subscription_provider', billingProvider.name);
    await prefs.setBool('subscription_active', true);
    if (expiryDate != null) {
      await prefs.setString(
        'subscription_expiry',
        expiryDate.millisecondsSinceEpoch.toString(),
      );
    } else {
      await prefs.remove('subscription_expiry');
    }
    await prefs.setBool('subscription_cancel_at_period_end', false);

    if (!mounted) return;
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
              billingProvider == BillingProvider.googlePlay
                  ? 'Subscription Active!'
                  : 'Payment Successful!',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              '${_getPlanName(plan)} activated',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              billingProvider == BillingProvider.googlePlay
                  ? 'Managed in Google Play'
                  : 'Payment ID: ${paymentId ?? "test-web-checkout"}',
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
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Using Premium',
                  style: TextStyle(
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
              RazorpayService.canUseTestActivationFallback
                  ? 'This Chrome build does not support the native Razorpay checkout used by the app. Since you are using a Razorpay test key, you can continue with a test activation to verify the premium flow.'
                  : 'This Chrome build does not support the native Razorpay checkout used by the app yet. Use Android/iOS for live checkout or wire a dedicated web Razorpay Checkout.js integration.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            if (RazorpayService.canUseTestActivationFallback)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _activateSelectedPlan(
                      plan: _selectedPlan!,
                      billingProvider: BillingProvider.local,
                      paymentId: 'test-web-checkout',
                    );
                  },
                  icon: const Icon(Iconsax.tick_circle),
                  label: const Text('Continue With Test Activation'),
                ),
              ),
            if (RazorpayService.canUseTestActivationFallback)
              const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  RazorpayService.canUseTestActivationFallback
                      ? 'Cancel'
                      : 'OK',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _activateSelectedPlan(
      plan: _selectedPlan!,
      billingProvider: BillingProvider.local,
      paymentId: response.paymentId,
    );
  }

  void _onGooglePlayPurchaseSuccess(
    PurchaseDetails purchase,
    SubscriptionPlan plan,
  ) {
    _activateSelectedPlan(
      plan: plan,
      billingProvider: BillingProvider.googlePlay,
      paymentId: purchase.purchaseID ?? purchase.productID,
    );
  }

  void _onStoreError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingPayment = false;
      _storeMessage = message;
    });
  }

  void _onPaymentFailure(PaymentFailureResponse response) {
    if (!mounted) return;
    final message = RazorpayService.getErrorMessage(response.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing via ${response.walletName}...'),
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
    setState(() => _isProcessingPayment = true);
    await _playBillingService.restorePurchases();
    if (!mounted) {
      return;
    }
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking Google Play for previous purchases...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
}
