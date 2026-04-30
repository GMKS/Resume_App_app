import '../../features/ai/screens/raoe2_screen.dart';
// RAOE2 (Resume Auto-Optimization Engine 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/dashboard/main_dashboard.dart';
import '../../features/editor/screens/resume_editor_screen.dart';
import '../../features/editor/screens/personal_info_screen.dart';
import '../../features/editor/screens/education_screen.dart';
import '../../features/editor/screens/experience_screen.dart';
import '../../features/editor/screens/skills_screen.dart';
import '../../features/editor/screens/projects_screen.dart';
import '../../features/editor/screens/certifications_screen.dart';
import '../../features/editor/screens/custom_section_screen.dart';
import '../../features/editor/screens/user_custom_section_screen.dart';
import '../../features/editor/screens/languages_screen.dart';
import '../../features/editor/screens/summary_screen.dart';
import '../../features/templates/screens/template_selection_screen.dart';
import '../../features/preview/screens/preview_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/ai/screens/ai_assistant_screen.dart';
import '../../features/ai/screens/ai_resume_generator_screen.dart';
import '../../features/ai/screens/ai_job_tailor_screen.dart';
import '../../features/ai/screens/ai_content_enhancer_screen.dart';
import '../../features/ai/screens/ai_resume_rewrite_screen.dart';
import '../../features/ai/screens/linkedin_import_screen.dart';
import '../../features/ats/screens/ats_optimization_screen.dart';
import '../../features/career_tools/screens/job_tracker_screen.dart';
import '../../features/career_tools/screens/cover_letter_screen.dart';
import '../../features/career_tools/screens/interview_prep_screen.dart';
import '../../features/career_tools/screens/skill_analyzer_screen.dart';
import '../../features/career_tools/screens/career_path_screen.dart';
import '../../features/career_tools/screens/job_search_screen.dart';
import '../../features/career_tools/screens/career_articles_screen.dart';
import '../../features/ai/screens/ai_bullet_generator_screen.dart';
import '../../features/ai/screens/roast_resume_screen.dart';
import '../../features/tools/screens/resume_style_converter_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../features/auth/screens/twilio_login_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/privacy_security_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/terms_conditions_screen.dart';
import '../../features/profile/screens/about_screen.dart';

// Onboarding completion provider
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/raoe2',
        name: 'raoe2',
        pageBuilder: (context, state) {
          final resumeId = state.uri.queryParameters['resumeId'];
          final resumeText = state.uri.queryParameters['resumeText'] ?? '';
          final jobDescription = state.uri.queryParameters['jobDescription'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: RAOE2Screen(
              resumeId: resumeId,
              resumeText: resumeText,
              jobDescription: jobDescription,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TwilioLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Dashboard (Main App)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainDashboard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Legacy Home Route (redirects to dashboard)
      GoRoute(
        path: '/home',
        name: 'home',
        redirect: (context, state) => '/dashboard',
      ),

      // Resume Editor
      GoRoute(
        path: '/editor/:resumeId',
        name: 'editor',
        builder: (context, state) => ResumeEditorScreen(
          resumeId: state.pathParameters['resumeId']!,
        ),
        routes: [
          GoRoute(
            path: 'personal',
            name: 'personal-info',
            pageBuilder: (context, state) => _slideTransition(
              state,
              PersonalInfoScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'summary',
            name: 'summary',
            pageBuilder: (context, state) => _slideTransition(
              state,
              SummaryScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'education',
            name: 'education',
            pageBuilder: (context, state) => _slideTransition(
              state,
              EducationScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'experience',
            name: 'experience',
            pageBuilder: (context, state) => _slideTransition(
              state,
              ExperienceScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'skills',
            name: 'skills',
            pageBuilder: (context, state) => _slideTransition(
              state,
              SkillsScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'projects',
            name: 'projects',
            pageBuilder: (context, state) => _slideTransition(
              state,
              ProjectsScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'certifications',
            name: 'certifications',
            pageBuilder: (context, state) => _slideTransition(
              state,
              CertificationsScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'languages',
            name: 'languages',
            pageBuilder: (context, state) => _slideTransition(
              state,
              LanguagesScreen(resumeId: state.pathParameters['resumeId']!),
            ),
          ),
          GoRoute(
            path: 'custom/:sectionId',
            name: 'custom-section',
            pageBuilder: (context, state) => _slideTransition(
              state,
              CustomSectionScreen(
                resumeId: state.pathParameters['resumeId']!,
                sectionId: state.pathParameters['sectionId']!,
              ),
            ),
          ),
          GoRoute(
            path: 'user-custom/:sectionId',
            name: 'user-custom-section',
            pageBuilder: (context, state) => _slideTransition(
              state,
              UserCustomSectionScreen(
                resumeId: state.pathParameters['resumeId']!,
                sectionId: state.pathParameters['sectionId']!,
              ),
            ),
          ),
        ],
      ),

      // Template Selection
      GoRoute(
        path: '/templates/:resumeId',
        name: 'templates',
        pageBuilder: (context, state) => _slideTransition(
          state,
          TemplateSelectionScreen(
            resumeId: state.pathParameters['resumeId']!,
            isNewResume: state.uri.queryParameters['isNew'] == 'true',
          ),
        ),
      ),

      // Preview
      GoRoute(
        path: '/preview/:resumeId',
        name: 'preview',
        pageBuilder: (context, state) => _slideTransition(
          state,
          PreviewScreen(resumeId: state.pathParameters['resumeId']!),
        ),
      ),

      // AI Features
      GoRoute(
        path: '/ai-assistant',
        name: 'ai-assistant',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const AIAssistantScreen(),
        ),
      ),

      GoRoute(
        path: '/ai-resume-generator',
        name: 'ai-resume-generator',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const AIResumeGeneratorScreen(),
        ),
      ),

      GoRoute(
        path: '/linkedin-import',
        name: 'linkedin-import',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const LinkedInImportScreen(),
        ),
      ),

      GoRoute(
        path: '/ai-job-tailor',
        name: 'ai-job-tailor',
        pageBuilder: (context, state) => _slideTransition(
          state,
          AiJobTailorScreen(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),

      GoRoute(
        path: '/ai-content-enhancer',
        name: 'ai-content-enhancer',
        pageBuilder: (context, state) => _slideTransition(
          state,
          AiContentEnhancerScreen(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),

      GoRoute(
        path: '/ai-resume-rewrite',
        name: 'ai-resume-rewrite',
        pageBuilder: (context, state) => _slideTransition(
          state,
          AiResumeRewriteScreen(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),

      // ATS Optimization
      GoRoute(
        path: '/ats/:resumeId',
        name: 'ats',
        pageBuilder: (context, state) => _slideTransition(
          state,
          ATSOptimizationScreen(resumeId: state.pathParameters['resumeId']!),
        ),
      ),

      // Career Tools
      GoRoute(
        path: '/job-tracker',
        name: 'job-tracker',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const JobTrackerScreen(),
        ),
      ),

      GoRoute(
        path: '/cover-letter',
        name: 'cover-letter',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const CoverLetterScreen(),
        ),
      ),

      GoRoute(
        path: '/interview-prep',
        name: 'interview-prep',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const InterviewPrepScreen(),
        ),
      ),

      GoRoute(
        path: '/skill-analyzer',
        name: 'skill-analyzer',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const SkillAnalyzerScreen(),
        ),
      ),

      GoRoute(
        path: '/career-path',
        name: 'career-path',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const CareerPathScreen(),
        ),
      ),

      GoRoute(
        path: '/job-search',
        name: 'job-search',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const JobSearchScreen(),
        ),
      ),

      GoRoute(
        path: '/career-articles',
        name: 'career-articles',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const CareerArticlesScreen(),
        ),
      ),

      GoRoute(
        path: '/ai-bullet-generator',
        name: 'ai-bullet-generator',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const AIBulletGeneratorScreen(),
        ),
      ),

      GoRoute(
        path: '/roast-resume',
        name: 'roast-resume',
        pageBuilder: (context, state) => _slideTransition(
          state,
          RoastResumeScreen(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),

      GoRoute(
        path: '/style-converter',
        name: 'style-converter',
        pageBuilder: (context, state) => _slideTransition(
          state,
          ResumeStyleConverterScreen(
            resumeId: state.uri.queryParameters['resumeId'],
          ),
        ),
      ),

      // Subscription
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const SubscriptionScreen(),
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const SettingsScreen(),
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const NotificationsScreen(),
        ),
      ),

      // Privacy & Security
      GoRoute(
        path: '/privacy-security',
        name: 'privacy-security',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const PrivacySecurityScreen(),
        ),
      ),

      // Help & Support
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const HelpSupportScreen(),
        ),
      ),

      // Terms & Conditions
      GoRoute(
        path: '/terms-conditions',
        name: 'terms-conditions',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const TermsConditionsScreen(),
        ),
      ),

      // About
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const AboutScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
