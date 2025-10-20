import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/hybrid_auth_service.dart';
import '../services/currency_service.dart';
import '../config/app_config.dart';
import '../widgets/upi_payment_widget.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;
  String _premiumStatus = '';
  late final HybridAuthService _auth;
  bool _authInitialized = false;
  String _selectedPlan = 'yearly'; // Default to yearly (best value)

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _auth = HybridAuthService();
    // Ensure auth is initialized so we can show current user if available
    _auth.init().then((_) {
      if (mounted) {
        setState(() {
          _authInitialized = true;
        });
      }
    });
  }

  void _loadPremiumStatus() {
    setState(() {
      _isPremium = PremiumService.isPremium;
      _premiumStatus = PremiumService.premiumStatusDebug;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Account Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_authInitialized) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_auth.isLoggedIn) ...[
                    // Name
                    _InfoRow(
                      label: 'Name',
                      value:
                          (_auth.currentUser?['name'] as String?)
                                  ?.trim()
                                  .isNotEmpty ==
                              true
                          ? (_auth.currentUser?['name'] as String)
                          : (_auth.userName?.isNotEmpty == true
                                ? _auth.userName!
                                : (_auth.userEmail ?? '—')),
                    ),
                    const SizedBox(height: 6),
                    // Email
                    _InfoRow(
                      label: 'Email',
                      value:
                          _auth.userEmail ??
                          (_auth.currentUser?['email'] as String? ?? '—'),
                    ),
                    const SizedBox(height: 6),
                    // Phone
                    _InfoRow(
                      label: 'Phone',
                      value:
                          (_auth.currentUser?['phone'] as String?)
                                  ?.trim()
                                  .isNotEmpty ==
                              true
                          ? (_auth.currentUser?['phone'] as String)
                          : '—',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.deepPurple),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.vpn_key,
                                size: 16,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Provider: ${_auth.currentProvider.toString().split('.').last.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Status: Logged In',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text('Not signed in'),
                  ],
                ],
              ),
            ),
          ),

          // Pricing & Upgrade Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Pricing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Responsive pricing chips; Wrap prevents horizontal overflow on small screens
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedPlan = 'monthly'),
                        child: SizedBox(
                          width: 280,
                          child: _priceChip(
                            'Monthly',
                            CurrencyService.formatPrice('monthly'),
                            '/mo',
                            selected: _selectedPlan == 'monthly',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedPlan = 'yearly'),
                        child: SizedBox(
                          width: 280,
                          child: _priceChip(
                            'Yearly',
                            CurrencyService.formatPrice('yearly'),
                            '/yr',
                            highlight: true,
                            note: 'Save 58%',
                            selected: _selectedPlan == 'yearly',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedPlan = 'lifetime'),
                        child: SizedBox(
                          width: 280,
                          child: _priceChip(
                            'Lifetime',
                            CurrencyService.formatPrice('lifetime'),
                            'one-time',
                            selected: _selectedPlan == 'lifetime',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyService.getSubscriptionTerms(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPremium
                          ? null
                          : () {
                              // Show payment gateway dialog
                              _showPaymentDialog(context);
                            },
                      icon: const Icon(Icons.upgrade),
                      label: Text(
                        _isPremium ? 'Premium Active' : 'Upgrade to Premium',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Premium Status Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isPremium
                            ? Icons.workspace_premium
                            : Icons.star_border,
                        color: _isPremium ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? Colors.amber.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isPremium ? Colors.amber : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPremium ? Icons.check_circle : Icons.cancel,
                          color: _isPremium ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isPremium
                                ? 'Premium Access Active'
                                : 'Free Version',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isPremium ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AppConfig.showDebugInfo && _premiumStatus.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _premiumStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Testing Controls (only show in testing mode)
          if (AppConfig.enableTestingMode) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Controls',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Development Mode - Remove in Production',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isPremium
                                ? null
                                : () async {
                                    await PremiumService.enablePremiumForTesting();
                                    _loadPremiumStatus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Premium access enabled for testing',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.star),
                            label: const Text('Enable Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !_isPremium
                                ? null
                                : () async {
                                    await PremiumService.disablePremiumForTesting();
                                    _loadPremiumStatus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Premium access disabled',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.star_border),
                            label: const Text('Disable Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Premium Features Available:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• All 6 Templates: ${PremiumService.availableTemplates.join(", ")}',
                    ),
                    Text('• Max Resumes: ${PremiumService.maxResumes}'),
                    Text(
                      '• Export Formats: ${PremiumService.availableExportFormats.join(", ")}',
                    ),
                    Text(
                      '• AI Features: ${PremiumService.hasAIFeatures ? "Yes" : "No"}',
                    ),
                    Text(
                      '• Cloud Sync: ${PremiumService.hasCloudSync ? "Yes" : "No"}',
                    ),
                    Text(
                      '• Watermark: ${PremiumService.hasWatermark ? "Yes" : "No"}',
                    ),
                  ],
                ),
              ),
            ),
          ],

          // App Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Version: 1.0.0'),
                  const Text('Build: Testing'),
                  if (AppConfig.showDebugInfo) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Debug Mode: Active',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Sign Out Button
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _auth.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final planName = _selectedPlan == 'monthly'
        ? 'Monthly'
        : _selectedPlan == 'yearly'
        ? 'Yearly'
        : 'Lifetime';
    final amount = CurrencyService.formatPrice(_selectedPlan);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.payment, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Upgrade to Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Plan: $planName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: $amount',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your payment method:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              dialogContext,
              icon: Icons.credit_card,
              title: 'UPI Payment',
              subtitle: 'PhonePe, Google Pay, Paytm',
              onTap: () {
                Navigator.pop(dialogContext);
                _processUPIPayment(dialogContext, _selectedPlan, amount);
              },
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              dialogContext,
              icon: Icons.account_balance_wallet,
              title: 'Razorpay',
              subtitle: 'Cards, UPI, Wallets, NetBanking',
              onTap: () {
                Navigator.pop(dialogContext);
                _processRazorpayPayment(dialogContext, _selectedPlan, amount);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _processUPIPayment(BuildContext context, String plan, String amount) {
    // Extract numeric amount from formatted string
    final numericAmount =
        double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    // Show UPI payment widget in a dialog
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text(
                    'UPI Payment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              UpiPaymentWidget(
                planType: plan,
                amount: numericAmount,
                onPaymentStart: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting UPI payment...')),
                  );
                },
                onPaymentSuccess: (response) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh premium status
                  setState(() {
                    _loadPremiumStatus();
                  });
                },
                onPaymentError: (error) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processRazorpayPayment(
    BuildContext context,
    String plan,
    String amount,
  ) {
    // Extract numeric amount from formatted string
    final numericAmount =
        double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    // Initialize Razorpay
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      razorpay.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! ID: ${response.paymentId}'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh premium status
      setState(() {
        _loadPremiumStatus();
      });
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      razorpay.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
      ExternalWalletResponse response,
    ) {
      razorpay.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    });

    // Prepare payment options
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Use your Razorpay key
      'amount': (numericAmount * 100).toInt(), // Amount in paise
      'name': 'Resume Builder',
      'description': '$plan Plan Subscription',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#6C5CE7'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      razorpay.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Widget _priceChip(
  String title,
  String price,
  String period, {
  bool highlight = false,
  String? note,
  bool selected = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: selected
          ? Colors.deepPurple.withOpacity(0.15)
          : (highlight
                ? Colors.deepPurple.withOpacity(0.08)
                : Colors.grey.withOpacity(0.08)),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected
            ? Colors.deepPurple
            : (highlight ? Colors.deepPurple : Colors.grey.shade300),
        width: selected ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + optional note badge + selected indicator
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected || highlight
                    ? Colors.deepPurple
                    : Colors.black87,
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.deepPurple,
              ),
            if (note != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected || highlight ? Colors.deepPurple : Colors.black87,
          ),
        ),
        Text(period, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    ),
  );
}
