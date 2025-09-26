import 'package:flutter/material.dart';
import '../services/premium_service.dart';

class PremiumTestScreen extends StatefulWidget {
  const PremiumTestScreen({super.key});

  @override
  State<PremiumTestScreen> createState() => _PremiumTestScreenState();
}

class _PremiumTestScreenState extends State<PremiumTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Test Controls'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          PremiumService.isPremium
                              ? Icons.workspace_premium
                              : Icons.free_breakfast,
                          color: PremiumService.isPremium
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          PremiumService.isPremium
                              ? 'Premium User'
                              : 'Free User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PremiumService.isPremium
                                ? Colors.deepPurple
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Features',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _FeatureRow(
                      'Templates',
                      '${PremiumService.availableTemplates.length}/6',
                    ),
                    _FeatureRow('Max Resumes', '${PremiumService.maxResumes}'),
                    _FeatureRow(
                      'Export Formats',
                      PremiumService.availableExportFormats.join(', '),
                    ),
                    _FeatureRow(
                      'AI Features',
                      PremiumService.hasAIFeatures ? 'Enabled' : 'Disabled',
                    ),
                    _FeatureRow(
                      'Cloud Sync',
                      PremiumService.hasCloudSync ? 'Enabled' : 'Disabled',
                    ),
                    _FeatureRow(
                      'Watermark',
                      PremiumService.hasWatermark ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          PremiumService.isPremium
                              ? Icons.free_breakfast
                              : Icons.workspace_premium,
                        ),
                        label: Text(
                          PremiumService.isPremium
                              ? 'Switch to Free'
                              : 'Switch to Premium',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumService.isPremium
                              ? Colors.grey
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (PremiumService.isPremium) {
                            // Simulate downgrade (for testing only)
                            await PremiumService.downgradeTesting();
                          } else {
                            await PremiumService.upgradeToPremium();
                          }
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                PremiumService.isPremium
                                    ? '🎉 Upgraded to Premium!'
                                    : '⬇️ Switched to Free Plan',
                              ),
                              backgroundColor: PremiumService.isPremium
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock),
                        label: const Text('Test Premium Dialog'),
                        onPressed: () {
                          PremiumService.showUpgradeDialog(
                            context,
                            'Test Feature',
                          );
                        },
                      ),
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

  Widget _FeatureRow(String feature, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature),
          Text(
            status,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
