import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_info.dart';
import 'core/debug/store_screenshot_seed.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/app_config_service.dart';
import 'core/services/storage_service.dart';
import 'features/settings/screens/settings_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  var startupState = const AppStartupState();
  await runZonedGuarded(() async {
    startupState = await _bootstrapApp();
  }, (error, stackTrace) {
    _logStartup(
      'Unhandled zone error during startup',
      error: error,
      stackTrace: stackTrace,
    );
    startupState = startupState.copyWith(
      issues: [
        ...startupState.issues,
        AppStartupIssue(
          step: 'Unhandled startup error',
          message: error.toString(),
        ),
      ],
    );
  });

  runApp(ProviderScope(child: ResumeBuilderApp(startupState: startupState)));
}

Future<AppStartupState> _bootstrapApp() async {
  var firebaseReady = false;
  var storageReady = false;
  final issues = <AppStartupIssue>[];

  Future<void> guardStep(
    String step,
    Future<void> Function() action, {
    bool critical = false,
    VoidCallback? onSuccess,
  }) async {
    _logStartup('Starting $step');
    try {
      await action();
      onSuccess?.call();
      _logStartup('Completed $step');
    } catch (error, stackTrace) {
      issues.add(
        AppStartupIssue(
          step: step,
          message: error.toString(),
          critical: critical,
        ),
      );
      _reportStartupError(step, error, stackTrace);
    }
  }

  // Initialize Firebase — wrapped so a config error never white-screens the app.
  await guardStep('Firebase initialization', () async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }, onSuccess: () {
    firebaseReady = true;
  });

  await guardStep('Runtime app config initialization', () async {
    await AppConfigService.initialize();
  });

  await guardStep('Hive initialization', () async {
    await Hive.initFlutter();
  }, critical: true);

  await guardStep(
      'Local storage initialization',
      () async {
        await StorageService.init();
      },
      critical: true,
      onSuccess: () {
        storageReady = true;
      });

  if (storageReady) {
    await guardStep('Seed store screenshot data', () async {
      await ensureStoreScreenshotSeedData();
    });
  }

  await guardStep('System overlay configuration', () async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  });

  await guardStep('Preferred orientation configuration', () async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });

  return AppStartupState(
    firebaseReady: firebaseReady,
    storageReady: storageReady,
    issues: issues,
  );
}

class ResumeBuilderApp extends ConsumerWidget {
  const ResumeBuilderApp({
    super.key,
    required this.startupState,
  });

  final AppStartupState startupState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!startupState.canLaunchApp) {
      return MaterialApp(
        title: AppInfo.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: StartupRecoveryScreen(startupState: startupState),
      );
    }

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          return StartupRecoveryScreen(startupState: startupState);
        }
        return child;
      },
    );
  }
}

@immutable
class AppStartupState {
  const AppStartupState({
    this.firebaseReady = false,
    this.storageReady = false,
    this.issues = const <AppStartupIssue>[],
  });

  final bool firebaseReady;
  final bool storageReady;
  final List<AppStartupIssue> issues;

  bool get canLaunchApp => storageReady;

  AppStartupState copyWith({
    bool? firebaseReady,
    bool? storageReady,
    List<AppStartupIssue>? issues,
  }) {
    return AppStartupState(
      firebaseReady: firebaseReady ?? this.firebaseReady,
      storageReady: storageReady ?? this.storageReady,
      issues: issues ?? this.issues,
    );
  }
}

@immutable
class AppStartupIssue {
  const AppStartupIssue({
    required this.step,
    required this.message,
    this.critical = false,
  });

  final String step;
  final String message;
  final bool critical;
}

class StartupRecoveryScreen extends StatelessWidget {
  const StartupRecoveryScreen({
    super.key,
    required this.startupState,
  });

  final AppStartupState startupState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Resumix AI could not finish startup',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'The app stayed open instead of closing unexpectedly. Check the startup steps below and retry after fixing the failing configuration or storage issue.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: startupState.issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final issue = startupState.issues[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.step,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(issue.message),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: SystemNavigator.pop,
                  child: const Text('Close App'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logStartup(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _logStartup(
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  ErrorWidget.builder = (details) {
    _logStartup(
      'ErrorWidget fallback triggered',
      error: details.exception,
      stackTrace: details.stack,
    );
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong, but the app is still running.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
}

void _reportStartupError(String step, Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'main',
      context: ErrorDescription('while running startup step: $step'),
    ),
  );
}

void _logStartup(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: 'app.startup',
    error: error,
    stackTrace: stackTrace,
  );
}
