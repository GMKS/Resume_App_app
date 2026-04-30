import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/razorpay_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionPlan? _selectedPlan;
  final RazorpayService _razorpayService = RazorpayService();
  bool _isProcessingPayment = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'plan': SubscriptionPlan.weekly,
      'name': 'Weekly Pro',
      'price': '₹499',
      'period': '/week',
      'savePercent': null,
      'features': [
        'All premium templates',
        'Unlimited resumes',
        'Unlimited PDF export without watermark',
        'Premium sections and layouts',
        'AI tools and ATS optimisation',
        'Cover letter builder',
      ],
    },
    {
      'plan': SubscriptionPlan.monthly,
      'name': 'Monthly Pro',
      'price': '₹849',
      'period': '/month',
      'savePercent': null,
      'popular': true,
      'features': [
        'Everything in Weekly',
        'DOCX and TXT exports',
        'Photo and signature support',
        'Cloud sync across devices',
        'Priority Support',
        'Premium media support',
      ],
    },
    {
      'plan': SubscriptionPlan.quarterly,
      'name': 'Quarterly Pro',
      'price': '₹2,099',
      'period': '/3 months',
      'savePercent': '16%',
      'features': [
        'Everything in Monthly',
        'Interview preparation tools',
        'Skill analysis and career tools',
        'Extended premium support',
        'Better long-term value',
      ],
    },
    {
      'plan': SubscriptionPlan.yearly,
      'name': 'Yearly Pro',
      'price': '₹6,699',
      'period': '/year',
      'savePercent': '33%',
      'bestValue': true,
      'features': [
        'Everything in Quarterly',
        'Priority support all year',
        'Best annual savings',
        'All future premium unlocks',
        'Complete pro toolkit',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlan = SubscriptionPlan.monthly;
    _razorpayService.initialize();
    _razorpayService.onSuccess = _onPaymentSuccess;
    _razorpayService.onFailure = _onPaymentFailure;
    _razorpayService.onExternalWallet = _onExternalWallet;
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay:100.ms).scale(),

                  const SizedBox(height: 24),

                  // Current Plan Status
                  if (currentSubscription.isPremium())
                    Card(
                      color: AppColors.success.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Iconsax.tick_circle, color: AppColors.success),
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
                                  if (currentSubscription.expiryDate != null)
                                    Text(
                                      'Expires: ${_formatDate(currentSubscription.expiryDate!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                  if (currentSubscription.isPremium()) const SizedBox(height: 16),

                  // Pricing Cards
                  ...List.generate(_plans.length, (index) {
                    final plan = _plans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PricingCard(
                        plan: plan['plan'] as SubscriptionPlan,
                        name: plan['name'] as String,
                        price: plan['price'] as String,
                        period: plan['period'] as String,
                        savePercent: plan['savePercent'] as String?,
                        features: plan['features'] as List<String>,
                        isPopular: plan['popular'] == true,
                        isBestValue: plan['bestValue'] == true,
                        isSelected: _selectedPlan == plan['plan'],
                        onTap: () => setState(() => _selectedPlan = plan['plan'] as SubscriptionPlan),
                      ),
                    ).animate().fadeIn(delay: (300 + index * 100).ms).slideX(begin: -0.1, end: 0);
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
                    onPressed: (_selectedPlan == null || _isProcessingPayment)
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
                        : const Icon(Iconsax.card),
                    label: Text(_isProcessingPayment
                        ? 'Opening Payment...'
                        : 'Subscribe Now'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://razorpay.com/favicon.ico',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.lock, size: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by Razorpay • Cancel anytime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
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
                  const Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(feature, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ))
        .toList();
  }

  String _getPlanName(SubscriptionPlan plan) {
    final planData = _plans.firstWhere((p) => p['plan'] == plan);
    return planData['name'] as String;
  }

  String _getPlanPrice(SubscriptionPlan plan) {
    final planData = _plans.firstWhere((p) => p['plan'] == plan);
    return '${planData['price']}${planData['period']}';
  }

  void _handleUpgrade() {
    if (_selectedPlan == null) return;
    setState(() => _isProcessingPayment = true);

    if (!RazorpayService.supportsNativeCheckout) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        _showWebCheckoutFallback();
      }
      return;
    }

    // Load saved phone from SharedPreferences (set during login)
    SharedPreferences.getInstance().then((prefs) {
      final phone = prefs.getString('saved_phone') ?? '';
      _razorpayService.openCheckout(
        plan: _selectedPlan!,
        userPhone: phone,
      );
      if (mounted) setState(() => _isProcessingPayment = false);
    });
  }

  Future<void> _activateSelectedPlan({String? paymentId}) async {
    if (_selectedPlan == null) return;

    ref.read(subscriptionProvider.notifier).upgradeToPlan(_selectedPlan!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', _selectedPlan!.name);
    await prefs.setString(
      'subscription_expiry',
      DateTime.now()
          .add(_planDuration(_selectedPlan!))
          .millisecondsSinceEpoch
          .toString(),
    );

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
              'Payment Successful!',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              '${_getPlanName(_selectedPlan!)} activated',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Payment ID: ${paymentId ?? "test-web-checkout"}',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontFamily: 'monospace',
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
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              RazorpayService.isTestMode
                  ? 'This Chrome build does not support the native Razorpay checkout used by the app. Since you are using a Razorpay test key, you can continue with a test activation to verify the premium flow.'
                  : 'This Chrome build does not support the native Razorpay checkout used by the app yet. Use Android/iOS for live checkout or wire a dedicated web Razorpay Checkout.js integration.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            if (RazorpayService.isTestMode)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _activateSelectedPlan(paymentId: 'test-web-checkout');
                  },
                  icon: const Icon(Iconsax.tick_circle),
                  label: const Text('Continue With Test Activation'),
                ),
              ),
            if (RazorpayService.isTestMode) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(RazorpayService.isTestMode ? 'Cancel' : 'OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _activateSelectedPlan(paymentId: response.paymentId);
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

class _PricingCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String name;
  final String price;
  final String period;
  final String? savePercent;
  final List<String> features;
  final bool isPopular;
  final bool isBestValue;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.plan,
    required this.name,
    required this.price,
    required this.period,
    this.savePercent,
    required this.features,
    this.isPopular = false,
    this.isBestValue = false,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                ),
                                Text(
                                  period,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.tick_circle5,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...features
                      .map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Iconsax.tick_circle,
                                    size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
            if (isPopular || isBestValue || savePercent != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    savePercent != null
                        ? 'Save $savePercent'
                        : isPopular
                            ? 'POPULAR'
                            : 'BEST VALUE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
