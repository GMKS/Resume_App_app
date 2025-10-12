import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resume_template_selection_screen.dart';
import 'smart_assist_screen.dart';
import 'saved_resumes_screen.dart';
import 'settings_screen.dart';
import 'customize_screen.dart';
import 'cover_letter_form_screen.dart';
import 'video_resume_screen.dart';
import 'prewritten_content_screen.dart';
import '../services/premium_service.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF8B5FBF),
              Color(0xFFf093fb),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Modern Header
                  _buildModernHeader(context),

                  // Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: Column(
                          children: [
                            // Welcome Section
                            _buildWelcomeSection(),

                            // Features Section
                            Expanded(child: _buildFeaturesSection(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Builder',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Build your future today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;

        return Container(
          margin: EdgeInsets.fromLTRB(
            screenWidth * 0.04, // 4% of screen width
            16,
            screenWidth * 0.04,
            16,
          ),
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_emotions,
                      color: Colors.white,
                      size: isTablet ? 28 : 20,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          'Ready to create something amazing?',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : screenWidth * 0.035,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 20 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 12,
                  vertical: isTablet ? 12 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: isTablet ? 18 : 14,
                    ),
                    SizedBox(width: isTablet ? 10 : 6),
                    Expanded(
                      child: Text(
                        'AI-Powered • Professional • Modern',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 14 : screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final crossAxisCount = isTablet ? 3 : 2;
        final childAspectRatio = isTablet ? 1.1 : 0.85;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04,
                4,
                screenWidth * 0.04,
                12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard_customize,
                    color: const Color(0xFF667eea),
                    size: isTablet ? 26 : 20,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: isTablet ? 22 : screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2d3748),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isTablet ? 16 : 10,
                  mainAxisSpacing: isTablet ? 16 : 10,
                  childAspectRatio: childAspectRatio,
                  padding: EdgeInsets.only(bottom: isTablet ? 120 : 80),
                  children: [
                    _buildModernFeatureCard(
                      context,
                      'Smart Assist',
                      Icons.psychology,
                      const LinearGradient(
                        colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                      ),
                      'AI-powered suggestions', // Shortened
                      () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SmartAssistScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'Customize',
                      Icons.palette,
                      const LinearGradient(
                        colors: [Color(0xFFffb347), Color(0xFFffcc33)],
                      ),
                      'Personalize design', // Shortened
                      () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomizeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'My Resumes',
                      Icons.folder_open,
                      const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      'View & manage resumes', // Shortened
                      () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedResumesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'Analytics',
                      Icons.analytics_outlined,
                      const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                      ),
                      'Track performance', // Shortened
                      () {
                        HapticFeedback.mediumImpact();
                        // TODO: Navigate to analytics screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.analytics, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Analytics feature coming soon!',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF667eea),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'Cover Letter',
                      Icons.email,
                      const LinearGradient(
                        colors: [Color(0xFF26a69a), Color(0xFF00bcd4)],
                      ),
                      'Create compelling covers',
                      () {
                        HapticFeedback.mediumImpact();
                        if (!PremiumService.hasCoverLetterFeature) {
                          PremiumService.showUpgradeDialog(
                            context,
                            'Cover Letter Builder',
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoverLetterFormScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'Video Resume',
                      Icons.videocam,
                      const LinearGradient(
                        colors: [Color(0xFFe91e63), Color(0xFF9c27b0)],
                      ),
                      'Record video resumes',
                      () {
                        HapticFeedback.mediumImpact();
                        if (!PremiumService.hasVideoResumeFeature) {
                          PremiumService.showUpgradeDialog(
                            context,
                            'Video Resume',
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VideoResumeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      'Content Library',
                      Icons.library_books,
                      const LinearGradient(
                        colors: [Color(0xFF3f51b5), Color(0xFF5c6bc0)],
                      ),
                      'Prewritten content',
                      () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PrewrittenContentScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4facfe).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.heavyImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResumeTemplateSelectionScreen(),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        label: const Text(
          'Create Resume',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Gradient gradient,
    String description,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14), // Slightly reduced padding
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 24, // Reduced icon size
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10), // Reduced spacing
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // Ensure single line
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3), // Reduced spacing
                Flexible(
                  // Added Flexible to prevent overflow
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 10, // Further reduced font size
                      color: Colors.grey[600],
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
