import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/reminder_service.dart';
import 'services/auth_service.dart';
import 'services/analytics_service.dart';
import 'services/premium_service.dart';
import 'services/retention_service.dart';
import 'services/currency_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'config/app_config.dart';

final ValueNotifier<bool> loggedInNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firebase emulators for development
  if (AppConfig.useFirebaseEmulator) {
    await _configureEmulators();
  }

  runApp(const MyApp());
}

Future<void> _configureEmulators() async {
  try {
    // Configure Auth Emulator
    await FirebaseAuth.instance.useAuthEmulator(
      AppConfig.emulatorHost,
      AppConfig.authEmulatorPort,
    );

    // Configure Firestore Emulator
    FirebaseFirestore.instance.useFirestoreEmulator(
      AppConfig.emulatorHost,
      AppConfig.firestoreEmulatorPort,
    );

    // Configure Storage Emulator
    await FirebaseStorage.instance.useStorageEmulator(
      AppConfig.emulatorHost,
      AppConfig.storageEmulatorPort,
    );

    print('Firebase emulators configured successfully');
  } catch (e) {
    print('Failed to configure Firebase emulators: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _init() async {
    // Initialize core services
    await CurrencyService.initialize();
    await AnalyticsService.initialize();
    await PremiumService.initialize();
    await RetentionService.initialize();
    await ReminderService.instance.init();

    // Track app launch
    AnalyticsService.trackEvent('app_launched', {
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
    });

    // Initialize auth service and check if user is already logged in
    await AuthService.instance.init();
    final isLoggedIn = AuthService.instance.isLoggedIn;
    loggedInNotifier.value = isLoggedIn;

    // Debug logging
    print('DEBUG: Auth initialized - isLoggedIn: $isLoggedIn');
    print('DEBUG: Current user: ${AuthService.instance.currentUser}');
  }

  Future<bool> _shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_completed') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: FutureBuilder(
        future: _init(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return FutureBuilder<bool>(
            future: _shouldShowOnboarding(),
            builder: (context, onboardingSnap) {
              if (onboardingSnap.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Show onboarding for first-time users
              if (onboardingSnap.data == true) {
                print('DEBUG: Showing onboarding screen');
                return const OnboardingScreen();
              }

              // Regular app flow
              return ValueListenableBuilder<bool>(
                valueListenable: loggedInNotifier,
                builder: (_, loggedIn, __) {
                  print('DEBUG: Main app - loggedIn: $loggedIn');
                  return loggedIn ? const HomeShell() : const LoginScreen();
                },
              );
            },
          );
        },
      ),
    );
  }
}
