import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/currency_service.dart';
import '../widgets/upi_payment_widget.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  final String? sourceFeature;

  const PremiumUpgradeScreen({super.key, this.sourceFeature});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'yearly';

  @override
  void initState() {
    super.initState();
    // Track premium screen view
    // Analytics disabled in this build
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get unlimited access to all templates, AI features, and more!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Features List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium Features',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: const [
                            _FeatureItem(
                              icon: Icons.design_services,
                              title: 'All 6 Professional Templates',
                              subtitle:
                                  'Classic, Modern, Minimal, Professional, Creative, One-Page',
                            ),
                            _FeatureItem(
                              icon: Icons.cloud_sync,
                              title: 'Unlimited Cloud Storage',
                              subtitle:
                                  'Save unlimited resumes with real-time sync across devices',
                            ),
                            _FeatureItem(
                              icon: Icons.smart_toy,
                              title: 'AI-Powered Content Generation',
                              subtitle:
                                  'Generate bullet points, optimize for ATS, and get writing tips',
                            ),
                            _FeatureItem(
                              icon: Icons.file_download,
                              title: 'Multiple Export Formats',
                              subtitle:
                                  'Export as PDF, DOCX, and TXT without watermarks',
                            ),
                            _FeatureItem(
                              icon: Icons.palette,
                              title: 'Custom Branding & Themes',
                              subtitle:
                                  'Personalize colors, fonts, and add your company logo',
                            ),
                            _FeatureItem(
                              icon: Icons.support_agent,
                              title: 'Priority Support',
                              subtitle:
                                  'Get help when you need it with premium customer support',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pricing Cards
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Monthly Plan
                        Expanded(
                          child: _PricingCard(
                            title: 'Monthly',
                            price: CurrencyService.formatPrice('monthly'),
                            period: '/month',
                            isPopular: false,
                            isSelected: _selectedPlan == 'monthly',
                            isLoading: _isLoading,
                            onTap: _isLoading
                                ? null
                                : () =>
                                      setState(() => _selectedPlan = 'monthly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Yearly Plan
                        Expanded(
                          child: _PricingCard(
                            title: 'Yearly',
                            price: CurrencyService.formatPrice('yearly'),
                            period: '/year',
                            discount: 'Save 58%',
                            isPopular: true,
                            isSelected: _selectedPlan == 'yearly',
                            isLoading: _isLoading,
                            onTap: _isLoading
                                ? null
                                : () =>
                                      setState(() => _selectedPlan = 'yearly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Lifetime Plan
                        Expanded(
                          child: _PricingCard(
                            title: 'Lifetime',
                            price: CurrencyService.formatPrice('lifetime'),
                            period: 'one-time',
                            discount: 'Best Value',
                            isPopular: false,
                            isSelected: _selectedPlan == 'lifetime',
                            isLoading: _isLoading,
                            onTap: _isLoading
                                ? null
                                : () => setState(
                                    () => _selectedPlan = 'lifetime',
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _purchasePlan(context, _selectedPlan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Purchase ${_selectedPlan.toUpperCase()} Plan',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      CurrencyService.getSubscriptionTerms(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Terms
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'Cancel anytime. 7-day free trial for new users.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchasePlan(BuildContext context, String planType) async {
    setState(() => _isLoading = true);

    // Show UPI payment dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upgrade to Premium - ${planType.toUpperCase()}'),
          content: SizedBox(
            width: double.maxFinite,
            child: UpiPaymentWidget(
              planType: planType,
              amount: _getPlanAmount(planType),
              onPaymentStart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment started...')),
                );
              },
              onPaymentSuccess: (result) async {
                Navigator.of(context).pop(); // Close payment dialog
                Navigator.of(context).pop(); // Close upgrade screen

                await PremiumService.upgradeToPremium();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 Welcome to Premium! All features unlocked!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onPaymentError: (error) {
                Navigator.of(context).pop(); // Close payment dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment failed: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    setState(() => _isLoading = false);
  }

  double _getPlanAmount(String planType) {
    switch (planType) {
      case 'monthly':
        return 299.0;
      case 'yearly':
        return 1999.0;
      case 'lifetime':
        return 4999.0;
      default:
        return 299.0;
    }
  }

  void _oldPurchaseMethod() async {
    setState(() => _isLoading = true);

    try {
      // Old stub method
      final success = await PremiumService.purchasePremium(_selectedPlan);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to Premium! All features unlocked!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? discount;
  final bool isPopular;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.discount,
    required this.isPopular,
    required this.isSelected,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple
                : (isPopular
                      ? Colors.deepPurple.withOpacity(0.5)
                      : Colors.grey.shade300),
            width: isSelected ? 3 : (isPopular ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(height: 8),
            ],
            if (discount != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discount!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPopular ? Colors.deepPurple : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              Text(
                price,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPopular ? Colors.deepPurple : Colors.black87,
                ),
              ),
              Text(
                period,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
