import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                      Icon(Icons.account_circle, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    AuthService.instance.currentUser != null
                        ? 'Email: ${AuthService.instance.currentUser}'
                        : 'Not signed in',
                  ),
                  SizedBox(height: 8),
                  if (AuthService.instance.isLoggedIn)
                    Text(
                      'Status: Logged In',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
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
                      SizedBox(width: 8),
                      Text(
                        'Premium Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
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
                        SizedBox(width: 8),
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
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
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
                        Icon(Icons.bug_report, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Testing Controls',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
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
                    SizedBox(height: 16),
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
                                      SnackBar(
                                        content: Text(
                                          'Premium access enabled for testing',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                            icon: Icon(Icons.star),
                            label: Text('Enable Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !_isPremium
                                ? null
                                : () async {
                                    await PremiumService.disablePremiumForTesting();
                                    _loadPremiumStatus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Premium access disabled',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                            icon: Icon(Icons.star_border),
                            label: Text('Disable Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Premium Features Available:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
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
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Version: 1.0.0'),
                  Text('Build: Testing'),
                  if (AppConfig.showDebugInfo) ...[
                    SizedBox(height: 8),
                    Text(
                      'Debug Mode: Active',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Sign Out Button
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Sign Out'),
                  content: Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService.instance.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
            icon: Icon(Icons.logout),
            label: Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
