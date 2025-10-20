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
import 'analytics_dashboard_screen.dart';
import '../services/premium_service.dart';
import '../services/resume_storage_service.dart';
import '../models/saved_resume.dart';

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
  int _currentCarouselPage = 0;

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
              child: _buildFeaturesCarousel(context, isTablet, screenWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesCarousel(
    BuildContext context,
    bool isTablet,
    double screenWidth,
  ) {
    final PageController pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );

    // Listen to page changes
    pageController.addListener(() {
      if (pageController.page != null) {
        int page = pageController.page!.round();
        if (page != _currentCarouselPage) {
          setState(() {
            _currentCarouselPage = page;
          });
        }
      }
    });

    // Feature data list - Reordered: My Resumes, Smart Assist, Customize, Video Resume first
    final features = [
      {
        'title': 'My Resumes',
        'icon': Icons.folder_open,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        'description': 'View & manage',
        'action': () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedResumesScreen()),
          );
        },
      },
      {
        'title': 'Smart Assist',
        'icon': Icons.psychology,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        ),
        'description': 'AI suggestions',
        'action': () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SmartAssistScreen()),
          );
        },
      },
      {
        'title': 'Customize',
        'icon': Icons.palette,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFffb347), Color(0xFFffcc33)],
        ),
        'description': 'Personalize design',
        'action': () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomizeScreen()),
          );
        },
      },
      {
        'title': 'Video Resume',
        'icon': Icons.videocam,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFe91e63), Color(0xFF9c27b0)],
        ),
        'description': 'Record videos',
        'action': () {
          HapticFeedback.mediumImpact();
          if (!PremiumService.hasVideoResumeFeature) {
            PremiumService.showUpgradeDialog(context, 'Video Resume');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VideoResumeScreen()),
          );
        },
      },
      {
        'title': 'Analytics',
        'icon': Icons.analytics_outlined,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
        ),
        'description': 'Track performance',
        'action': () {
          HapticFeedback.mediumImpact();
          _openAnalyticsDashboard(context);
        },
      },
      {
        'title': 'Cover Letter',
        'icon': Icons.email,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26a69a), Color(0xFF00bcd4)],
        ),
        'description': 'Compelling covers',
        'action': () {
          HapticFeedback.mediumImpact();
          if (!PremiumService.hasCoverLetterFeature) {
            PremiumService.showUpgradeDialog(context, 'Cover Letter Builder');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CoverLetterFormScreen(),
            ),
          );
        },
      },
      {
        'title': 'Content Library',
        'icon': Icons.library_books,
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3f51b5), Color(0xFF5c6bc0)],
        ),
        'description': 'Prewritten content',
        'action': () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrewrittenContentScreen(),
            ),
          );
        },
      },
    ];

    // Group features into pages of 4
    final pageCount = (features.length / 4).ceil();

    return Column(
      children: [
        // Hero Layout Carousel with 4 widgets per page
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 4;
              final endIndex = (startIndex + 4).clamp(0, features.length);
              final pageFeatures = features.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: isTablet ? 1.1 : 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: pageFeatures.length,
                  itemBuilder: (context, index) {
                    return _buildCompactFeatureCard(
                      context,
                      pageFeatures[index]['title'] as String,
                      pageFeatures[index]['icon'] as IconData,
                      pageFeatures[index]['gradient'] as LinearGradient,
                      pageFeatures[index]['description'] as String,
                      pageFeatures[index]['action'] as VoidCallback,
                      isTablet,
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Page indicator
        const SizedBox(height: 12),
        _buildPageIndicator(pageCount),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    LinearGradient gradient,
    String description,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 16 : 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with glow effect
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: isTablet ? 32 : 28,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: isTablet ? 10 : 8),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isTablet ? 4 : 3),

                    // Description
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 10,
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentCarouselPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentCarouselPage
                ? const Color(0xFF667eea)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
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

  // Method to handle analytics dashboard navigation
  Future<void> _openAnalyticsDashboard(BuildContext context) async {
    try {
      // Get list of saved resumes
      final resumes = ResumeStorageService.instance.resumes.value;

      if (resumes.isEmpty) {
        // No resumes - show guidance
        _showNoResumesDialog(context);
        return;
      }

      if (resumes.length == 1) {
        // Single resume - open analytics directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AnalyticsDashboardScreen(resume: resumes.first),
          ),
        );
        return;
      }

      // Multiple resumes - show selection dialog
      _showResumeSelectionDialog(context, resumes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoResumesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.purple),
            SizedBox(width: 8),
            Text('Analytics Dashboard'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No resumes found for analysis.'),
            SizedBox(height: 12),
            Text('To use Analytics:'),
            Text('• Create a resume first'),
            Text('• Add content and sections'),
            Text('• Return here for insights'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResumeTemplateSelectionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Resume'),
          ),
        ],
      ),
    );
  }

  void _showResumeSelectionDialog(
    BuildContext context,
    List<SavedResume> resumes,
  ) {
    Set<String> selectedResumeIds = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Select Resume to Analyze',
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resumes.length > 1)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select multiple resumes for comparison',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...resumes.map((resume) {
                    final isSelected = selectedResumeIds.contains(resume.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedResumeIds.add(resume.id);
                            } else {
                              selectedResumeIds.remove(resume.id);
                            }
                          });
                        },
                        activeColor: Colors.purple,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? Colors.purple.shade100
                              : Colors.grey.shade200,
                          child: Text(
                            resume.template.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.purple.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          resume.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${resume.template} • ${_formatDate(resume.updatedAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedResumeIds.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      // If single selection, go to analytics directly
                      if (selectedResumeIds.length == 1) {
                        final selectedResume = resumes.firstWhere(
                          (r) => r.id == selectedResumeIds.first,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsDashboardScreen(
                              resume: selectedResume,
                            ),
                          ),
                        );
                      } else {
                        // Multiple selection - show comparison analytics
                        final selectedResumes = resumes
                            .where((r) => selectedResumeIds.contains(r.id))
                            .toList();
                        _showComparisonAnalytics(context, selectedResumes);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                selectedResumeIds.isEmpty
                    ? 'Select Resume'
                    : selectedResumeIds.length == 1
                    ? 'Analyze Resume'
                    : 'Compare ${selectedResumeIds.length} Resumes',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComparisonAnalytics(
    BuildContext context,
    List<SavedResume> resumes,
  ) {
    // For now, just show the first resume's analytics
    // In a full implementation, this would show comparison view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboardScreen(resume: resumes.first),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comparing ${resumes.length} resumes - showing ${resumes.first.title}',
        ),
        backgroundColor: Colors.purple,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
