import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();
  DateTime? _startTime;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    AnalyticsService.trackOnboardingStep('welcome', 1, 5);
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      pages: _buildPages(),
      onDone: () => _onOnboardingComplete(),
      onSkip: () => _onOnboardingSkipped(),
      showSkipButton: true,
      showNextButton: true,
      showDoneButton: true,
      next: const Icon(Icons.arrow_forward),
      done: const Text(
        'Get Started',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      skip: const Text('Skip'),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey,
        activeSize: const Size(22.0, 10.0),
        activeColor: Colors.deepPurple,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      onChange: (index) {
        setState(() => _currentStep = index);
        AnalyticsService.trackOnboardingStep(_getStepName(index), index + 1, 5);
      },
      globalBackgroundColor: Colors.white,
    );
  }

  List<PageViewModel> _buildPages() {
    return [
      // Welcome Page
      PageViewModel(
        title: "Welcome to Resume Builder! 👋",
        body:
            "Create professional resumes in minutes with our easy-to-use templates and AI-powered suggestions.",
        image: _buildImage('assets/onboarding/welcome.png', Icons.work),
        decoration: _getPageDecoration(),
      ),

      // Templates Page
      PageViewModel(
        title: "Choose from 6 Professional Templates 📄",
        body:
            "Start with our Classic and Minimal templates for free, or upgrade to Premium for all 6 professional designs.",
        image: _buildImage(
          'assets/onboarding/templates.png',
          Icons.design_services,
        ),
        decoration: _getPageDecoration(),
        footer: _buildFeatureComparison(),
      ),

      // AI Features Page
      PageViewModel(
        title: "AI-Powered Content Generation 🤖",
        body:
            "Let our AI help you write compelling bullet points, optimize for ATS systems, and create cover letters.",
        image: _buildImage('assets/onboarding/ai.png', Icons.smart_toy),
        decoration: _getPageDecoration(),
        footer: _buildPremiumBadge("AI features available in Premium"),
      ),

      // Export Options Page
      PageViewModel(
        title: "Export in Multiple Formats 📎",
        body:
            "Export your resume as PDF, DOCX, or TXT. Premium users get watermark-free exports.",
        image: _buildImage('assets/onboarding/export.png', Icons.file_download),
        decoration: _getPageDecoration(),
        footer: _buildExportComparison(),
      ),

      // Cloud Sync Page
      PageViewModel(
        title: "Sync Across All Your Devices ☁️",
        body:
            "Access your resumes anywhere with cloud synchronization. Premium users get unlimited storage.",
        image: _buildImage('assets/onboarding/cloud.png', Icons.cloud_sync),
        decoration: _getPageDecoration(),
        footer: _buildStorageComparison(),
      ),
    ];
  }

  Widget _buildImage(String assetPath, IconData fallback) {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Icon(fallback, size: 80, color: Colors.deepPurple),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.deepPurple,
      ),
      bodyTextStyle: TextStyle(fontSize: 16.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildPlanCard(
              'Free Plan',
              ['2 Templates', '3 Resumes', 'PDF Export*'],
              Colors.orange,
              false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPlanCard(
              'Premium',
              ['6 Templates', 'Unlimited', 'All Formats'],
              Colors.deepPurple,
              true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    List<String> features,
    Color color,
    bool isPremium,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: isPremium ? 2 : 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                feature,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (isPremium) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumBadge(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.workspace_premium,
            color: Colors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildComparisonRow(
            'PDF Export',
            true,
            true,
            'With watermark',
            'Watermark-free',
          ),
          _buildComparisonRow('DOCX Export', false, true, '✗', '✓'),
          _buildComparisonRow('TXT Export', false, true, '✗', '✓'),
        ],
      ),
    );
  }

  Widget _buildStorageComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildComparisonRow(
            'Resume Storage',
            true,
            true,
            '3 resumes',
            'Unlimited',
          ),
          _buildComparisonRow('Cloud Sync', false, true, '✗', '✓'),
          _buildComparisonRow(
            'Device Access',
            true,
            true,
            'Single device',
            'All devices',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    bool freeHas,
    bool premiumHas,
    String freeValue,
    String premiumValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: freeHas ? Colors.orange : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              premiumValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: premiumHas ? Colors.deepPurple : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepName(int index) {
    switch (index) {
      case 0:
        return 'welcome';
      case 1:
        return 'templates';
      case 2:
        return 'ai_features';
      case 3:
        return 'export_options';
      case 4:
        return 'cloud_sync';
      default:
        return 'unknown';
    }
  }

  void _onOnboardingComplete() {
    final totalTime = DateTime.now().difference(_startTime!).inSeconds;
    AnalyticsService.trackOnboardingCompleted(totalTime);

    _completeOnboarding();
  }

  void _onOnboardingSkipped() {
    AnalyticsService.trackEvent('onboarding_skipped', {
      'step_when_skipped': _currentStep + 1,
      'total_time_seconds': DateTime.now().difference(_startTime!).inSeconds,
    });

    _completeOnboarding();
  }

  void _completeOnboarding() async {
    print('DEBUG: Completing onboarding');

    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    print('DEBUG: Onboarding marked as completed');

    // Navigate back to main app flow which will show login screen
    // since user is not logged in yet
    if (mounted) {
      print('DEBUG: Navigating back to main app flow');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

class OnboardingGuideWidget extends StatelessWidget {
  final Widget child;
  final String feature;
  final String description;
  final bool showOnce;

  const OnboardingGuideWidget({
    super.key,
    required this.child,
    required this.feature,
    required this.description,
    this.showOnce = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowGuide(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Stack(
            children: [
              child,
              Positioned.fill(
                child: _FeatureHighlight(
                  feature: feature,
                  description: description,
                  onDismiss: () => _markAsSeen(),
                ),
              ),
            ],
          );
        }
        return child;
      },
    );
  }

  Future<bool> _shouldShowGuide() async {
    if (!showOnce) return false;

    // Check if user has seen this guide before
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('guide_seen_$feature') ?? false);
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_seen_$feature', true);

    AnalyticsService.trackEvent('feature_guide_seen', {
      'feature': feature,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

class _FeatureHighlight extends StatelessWidget {
  final String feature;
  final String description;
  final VoidCallback onDismiss;

  const _FeatureHighlight({
    required this.feature,
    required this.description,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                feature,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Got it!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
