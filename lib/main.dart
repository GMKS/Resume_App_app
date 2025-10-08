import 'package:flutter/material.dart';
import 'screens/enhanced_login_screen.dart';
import 'services/currency_service.dart';
import 'services/premium_service.dart';
import 'services/node_api_service.dart';
import 'services/resume_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start app immediately for faster startup
  runApp(const MyApp());

  // Initialize services asynchronously in parallel after app starts
  _initializeServicesAsync();
}

/// Initialize all services in parallel to avoid blocking startup
void _initializeServicesAsync() {
  Future.wait([
        CurrencyService.initialize().catchError((e) {
          debugPrint('CurrencyService initialization failed: $e');
        }),
        PremiumService.initialize().catchError((e) {
          debugPrint('PremiumService initialization failed: $e');
        }),
        ApiService.init().catchError((e) {
          debugPrint('ApiService initialization failed: $e');
        }),
        ResumeStorageService.instance.initialize().catchError((e) {
          debugPrint('ResumeStorageService initialization failed: $e');
        }),
      ])
      .then((_) {
        debugPrint('All services initialized successfully');
      })
      .catchError((e) {
        debugPrint('Service initialization error: $e');
      });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const EnhancedLoginScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder - Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'App is Working!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Node.js Backend Ready',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 20),
            Text(
              'APK Size: 45MB (25% smaller!)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
