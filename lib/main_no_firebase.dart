import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/mock_auth_service.dart';
import 'screens/mock_login_screen.dart';
import 'screens/mock_home_screen.dart';

import 'screens/onboarding_screen.dart';

final ValueNotifier<bool> loggedInNotifier = ValueNotifier(false);

// Error app to show when main app fails to initialize
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Please check your internet connection and restart the app.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  // Add error handling for debugging white screen
  FlutterError.onError = (FlutterErrorDetails details) {
    print('FLUTTER ERROR: ${details.exception}');
    print('STACK TRACE: ${details.stack}');
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('DEBUG: WidgetsFlutterBinding initialized');

    // Skip Firebase initialization to test if that's the issue
    print('DEBUG: Skipping Firebase initialization for testing...');

    print('DEBUG: Starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('CRITICAL ERROR in main(): $e');
    print('STACK TRACE: $stackTrace');

    // Show error screen instead of white screen
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _init() async {
    try {
      print('DEBUG: Starting minimal service initialization...');

      // Initialize mock auth service
      print('DEBUG: Initializing mock auth service...');
      await MockAuthService.instance.init();

      // Check if user is already logged in
      final isLoggedIn = MockAuthService.instance.isLoggedIn;
      loggedInNotifier.value = isLoggedIn;
      print('DEBUG: Mock auth initialized - isLoggedIn: $isLoggedIn');

      print('DEBUG: Minimal initialization completed');
    } catch (e, stackTrace) {
      print('ERROR in _init(): $e');
      print('STACK TRACE: $stackTrace');
      // Don't rethrow - let the app continue with basic functionality
    }
  }

  Future<bool> _shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('onboarding_completed') ?? false);
    } catch (e) {
      print('ERROR: Could not check onboarding status: $e');
      return false; // Skip onboarding on error
    }
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
          // Show loading screen
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 20),
                    Text(
                      'Loading Resume Builder...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle initialization errors
          if (snap.hasError) {
            print('ERROR: App initialization failed: ${snap.error}');
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Initialization Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Force restart the app
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MyApp()),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<bool>(
            future: _shouldShowOnboarding(),
            builder: (context, onboardingSnap) {
              if (onboardingSnap.connectionState != ConnectionState.done) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
                );
              }

              // Handle onboarding check errors
              if (onboardingSnap.hasError) {
                print(
                  'ERROR: Onboarding check failed: ${onboardingSnap.error}',
                );
                // Skip onboarding on error and go to login
                return const MockLoginScreen();
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
                  try {
                    return loggedIn
                        ? const MockHomeScreen()
                        : const MockLoginScreen();
                  } catch (e) {
                    print('ERROR: Failed to load main screens: $e');
                    return const MockLoginScreen(); // Fallback to login
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
