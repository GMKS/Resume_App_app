import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../config/app_config.dart';

/// Standalone testing screen for premium features
/// Only shows in testing mode
class PremiumTestingScreen extends StatefulWidget {
  const PremiumTestingScreen({super.key});

  @override
  State<PremiumTestingScreen> createState() => _PremiumTestingScreenState();
}

class _PremiumTestingScreenState extends State<PremiumTestingScreen> {
  bool _isPremium = false;
  String _premiumStatus = '';

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
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
        title: const Text('Premium Testing'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Testing Mode Only',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen is only visible in development mode.\nRemove before production release.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Current Status
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
                          'Current Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isPremium
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        border: Border.all(
                          color: _isPremium ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                                  : 'Free Version Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isPremium ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_premiumStatus.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _premiumStatus,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Testing Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Controls',
                      style: Theme.of(context).textTheme.titleLarge,
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Feature Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feature Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      'Templates',
                      '${PremiumService.availableTemplates.length}/6',
                      PremiumService.availableTemplates.join(', '),
                      PremiumService.availableTemplates.length == 6,
                    ),
                    _buildFeatureRow(
                      'Max Resumes',
                      '${PremiumService.maxResumes}',
                      PremiumService.maxResumes == 999
                          ? 'Unlimited'
                          : 'Limited to ${PremiumService.maxResumes}',
                      PremiumService.maxResumes == 999,
                    ),
                    _buildFeatureRow(
                      'Export Formats',
                      '${PremiumService.availableExportFormats.length}',
                      PremiumService.availableExportFormats.join(', '),
                      PremiumService.availableExportFormats.length > 1,
                    ),
                    _buildFeatureRow(
                      'AI Features',
                      PremiumService.hasAIFeatures ? 'Yes' : 'No',
                      PremiumService.hasAIFeatures
                          ? 'Content generation available'
                          : 'AI features locked',
                      PremiumService.hasAIFeatures,
                    ),
                    _buildFeatureRow(
                      'Cloud Sync',
                      PremiumService.hasCloudSync ? 'Yes' : 'No',
                      PremiumService.hasCloudSync
                          ? 'Cloud storage available'
                          : 'Local storage only',
                      PremiumService.hasCloudSync,
                    ),
                    _buildFeatureRow(
                      'Watermark',
                      PremiumService.hasWatermark ? 'Yes' : 'No',
                      PremiumService.hasWatermark
                          ? 'Watermark on exports'
                          : 'Clean exports',
                      !PremiumService.hasWatermark,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Configuration Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildConfigRow(
                      'Testing Mode',
                      AppConfig.enableTestingMode,
                    ),
                    _buildConfigRow(
                      'Bypass Premium Restrictions',
                      AppConfig.bypassPremiumRestrictions,
                    ),
                    _buildConfigRow('Show Debug Info', AppConfig.showDebugInfo),
                    _buildConfigRow(
                      'Cloud Features',
                      AppConfig.enableCloudFeatures,
                    ),
                    _buildConfigRow(
                      'Firebase Emulator',
                      AppConfig.useFirebaseEmulator,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    String title,
    String value,
    String description,
    bool isEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        color: isEnabled ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String title, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? Colors.blue : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value ? 'ON' : 'OFF',
            style: TextStyle(
              color: value ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
