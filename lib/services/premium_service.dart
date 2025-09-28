import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/premium_upgrade_screen.dart';
import '../config/app_config.dart';

// Premium Feature Control Service
class PremiumService {
  static bool _isPremium = false;
  static SharedPreferences? _prefs;
  // IAP disabled in this build; using local prefs toggle only

  static bool get isPremium =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  // Template Access Control
  static List<String> get availableTemplates {
    if (_isPremium || AppConfig.bypassPremiumRestrictions) {
      return [
        'Classic',
        'Modern',
        'Minimal',
        'Professional',
        'Creative',
        'OnePage',
        'TwoPage', // New AI-powered template with document import
      ];
    }
    return ['Classic', 'Minimal']; // Free templates only
  }

  // Premium Feature Access Control
  static bool get hasCopyPasteFeature =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  static bool get hasDragDropFeature => true; // Available for all users

  static bool get hasDocumentImport =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  static bool get hasCoverLetterFeature =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  static bool get hasVideoResumeFeature =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  static bool get hasPrewrittenContent => true; // Available for all users

  static bool get hasGuidedCreation => true; // Available for all users

  // Resume Limit Control
  static int get maxResumes =>
      (_isPremium || AppConfig.bypassPremiumRestrictions) ? 999 : 3;

  // Export Format Control
  static List<String> get availableExportFormats {
    if (_isPremium || AppConfig.bypassPremiumRestrictions) {
      return ['PDF', 'DOCX', 'TXT'];
    }
    return ['PDF']; // Free: PDF only
  }

  // AI Features Control
  static bool get hasAIFeatures =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  // Cloud Features Control
  static bool get hasCloudSync =>
      _isPremium || AppConfig.bypassPremiumRestrictions;

  // Watermark Control
  static bool get hasWatermark =>
      !(_isPremium || AppConfig.bypassPremiumRestrictions);

  // Feature Gate Helpers
  static bool canUseTemplate(String template) {
    return availableTemplates.contains(template);
  }

  static bool canCreateMoreResumes(int currentCount) {
    return currentCount < maxResumes;
  }

  static bool canExportFormat(String format) {
    return availableExportFormats.contains(format);
  }

  // Premium Upgrade Prompt
  static void showUpgradeDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$feature is available in Premium version.'),
            const SizedBox(height: 16),
            const Text(
              'Upgrade now for:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• All 6 professional templates'),
            const Text('• Unlimited cloud storage'),
            const Text('• AI-powered content generation'),
            const Text('• Multiple export formats'),
            const Text('• Watermark-free exports'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _navigateToUpgradeScreen(context);
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  static void _navigateToUpgradeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumUpgradeScreen()),
    );
  }

  // Initialization
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await checkSubscriptionStatus();
  }

  // Subscription Management
  static Future<bool> purchasePremium(String productId) async {
    // Stub: mark as premium locally
    _isPremium = true;
    await _prefs?.setBool('is_premium', true);
    return true;
  }

  static Future<void> upgradeToPremium() async {
    _isPremium = true;
    await _prefs?.setBool('is_premium', true);
  }

  static Future<void> checkSubscriptionStatus() async {
    try {
      // Check local storage first
      _isPremium = _prefs?.getBool('is_premium') ?? false;
    } catch (e) {
      // Fallback to local storage
      _isPremium = _prefs?.getBool('is_premium') ?? false;
    }
  }

  // Get product value for analytics
  static double _getProductValue(String productId) {
    // Static defaults
    return 0.0;
  }

  // Get user segment for analytics
  static Future<String> _getUserSegment() async {
    final resumeCount = _prefs?.getInt('resume_count') ?? 0;
    final daysActive = _prefs?.getInt('days_active') ?? 0;

    if (resumeCount == 0) return 'new_user';
    if (resumeCount <= 2 && daysActive <= 7) return 'trial_user';
    if (resumeCount >= 3 && daysActive >= 7) return 'engaged_user';
    return 'power_user';
  }

  // Testing helpers (remove in production)
  static Future<void> enablePremiumForTesting() async {
    _isPremium = true;
    await _prefs?.setBool('is_premium', true);
    await _prefs?.setBool('testing_premium_enabled', true);
  }

  static Future<void> disablePremiumForTesting() async {
    _isPremium = false;
    await _prefs?.setBool('is_premium', false);
    await _prefs?.setBool('testing_premium_enabled', false);
  }

  // Legacy method for backward compatibility
  static Future<void> downgradeTesting() async {
    await disablePremiumForTesting();
  }

  // Check if testing mode is active
  static bool get isTestingModeActive =>
      AppConfig.enableTestingMode && AppConfig.bypassPremiumRestrictions;

  // Get premium status description for debugging
  static String get premiumStatusDebug {
    if (!AppConfig.showDebugInfo) return '';

    String status = 'Premium Status: ';
    if (_isPremium && AppConfig.bypassPremiumRestrictions) {
      status += 'PREMIUM (Paid + Testing)';
    } else if (_isPremium) {
      status += 'PREMIUM (Paid)';
    } else if (AppConfig.bypassPremiumRestrictions) {
      status += 'PREMIUM (Testing Only)';
    } else {
      status += 'FREE';
    }

    if (isTestingModeActive) {
      status += ' | Testing Mode: ACTIVE';
    }

    return status;
  }
}
