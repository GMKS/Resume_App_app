import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hybrid_auth_service.dart';
import '../services/node_api_service.dart';
import 'simple_home_screen.dart';
import 'nodejs_login_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize hybrid auth service
      await HybridAuthService().init();

      // Check if user is already logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        // Verify token with backend
        final isValid = await ApiService.verifyToken(token);
        if (isValid) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing Resume Builder...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text('Error: $_error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Navigate based on login status
    if (_isLoggedIn) {
      return const SimpleHomeScreen();
    } else {
      return const NodeJSLoginScreen();
    }
  }
}
