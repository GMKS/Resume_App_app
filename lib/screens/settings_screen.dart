import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/hybrid_auth_service.dart';
import '../services/currency_service.dart';
import '../config/app_config.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _auth = HybridAuthService();
    // Ensure auth is initialized so we can show current user if available
    _auth.init().then((_) {
      if (mounted) setState(() {});
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
                  if (_auth.isLoggedIn) ...[
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
                  Row(
                    children: [
                      _priceChip(
                        'Monthly',
                        CurrencyService.formatPrice('monthly'),
                        '/mo',
                      ),
                      const SizedBox(width: 8),
                      _priceChip(
                        'Yearly',
                        CurrencyService.formatPrice('yearly'),
                        '/yr',
                        highlight: true,
                        note: 'Save 58%',
                      ),
                      const SizedBox(width: 8),
                      _priceChip(
                        'Lifetime',
                        CurrencyService.formatPrice('lifetime'),
                        'one-time',
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
                              PremiumService.showUpgradeDialog(
                                context,
                                'Premium Features',
                              );
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
}

Widget _priceChip(
  String title,
  String price,
  String period, {
  bool highlight = false,
  String? note,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.deepPurple.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? Colors.deepPurple : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: highlight ? Colors.deepPurple : Colors.black87,
                ),
              ),
              if (note != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.deepPurple : Colors.black87,
            ),
          ),
          Text(period, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    ),
  );
}
