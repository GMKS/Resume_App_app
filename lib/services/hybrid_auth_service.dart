import 'package:shared_preferences/shared_preferences.dart';
import 'node_api_service.dart';

enum AuthProvider { firebase, nodejs }

class HybridAuthService {
  static const String _authProviderKey = 'auth_provider';
  static const String _userDataKey = 'user_data';

  AuthProvider _currentProvider = AuthProvider.nodejs; // Default to Node.js
  Map<String, dynamic>? _currentUser;

  // Singleton pattern
  static final HybridAuthService _instance = HybridAuthService._internal();
  factory HybridAuthService() => _instance;
  HybridAuthService._internal();

  // Initialize the service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final providerString = prefs.getString(_authProviderKey);

    if (providerString == 'firebase') {
      _currentProvider = AuthProvider.firebase;
    } else {
      _currentProvider = AuthProvider.nodejs;
    }

    // Initialize Node.js API service
    await ApiService.init();

    // Restore user data
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      _currentUser = Map<String, dynamic>.from(
        // Simple JSON decode simulation
        userData.split(',').fold<Map<String, dynamic>>({}, (map, item) {
          final parts = item.split(':');
          if (parts.length == 2) {
            map[parts[0].trim()] = parts[1].trim();
          }
          return map;
        }),
      );
    }
  }

  // Switch authentication provider
  Future<void> switchProvider(AuthProvider provider) async {
    _currentProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authProviderKey, provider.toString());
  }

  // Register with Node.js backend
  Future<Map<String, dynamic>> registerWithNodeJS({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    required String password,
  }) async {
    // ApiService.register expects: name, email, password, phone
    final result = await ApiService.register(
      name: ('$firstName $lastName').trim(),
      email: email,
      password: password,
      phone: phoneNumber ?? '',
    );

    if (result['success'] == true) {
      _currentUser = result['data']['user'];
      _currentProvider = AuthProvider.nodejs;
      await _saveUserData();
    }

    return result;
  }

  // Login with Node.js backend
  Future<Map<String, dynamic>> loginWithNodeJS({
    required String identifier,
    required String password,
  }) async {
    final result = await ApiService.login(
      identifier: identifier,
      password: password,
    );

    if (result['success'] == true) {
      _currentUser = result['data']['user'];
      _currentProvider = AuthProvider.nodejs;
      await _saveUserData();
    }

    return result;
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOTP({
    required String identifier,
    String type = 'login',
  }) async {
    return await ApiService.sendOTP(identifier: identifier, type: type);
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String identifier,
    required String otp,
  }) async {
    // Use the generic identifier version to support email or phone
    final result = await ApiService.verifyOTPByIdentifier(
      identifier: identifier,
      otp: otp,
    );

    if (result['success'] == true) {
      _currentUser = result['data']['user'];
      _currentProvider = AuthProvider.nodejs;
      await _saveUserData();
    }

    return result;
  }

  // Save user data to local storage
  Future<void> _saveUserData() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      // Simple serialization for demo
      final userData = _currentUser!.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_userDataKey, userData);
      await prefs.setString(_authProviderKey, _currentProvider.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await ApiService.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_authProviderKey);
  }

  // Getters
  bool get isLoggedIn => _currentUser != null && ApiService.isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  AuthProvider get currentProvider => _currentProvider;
  String? get userEmail => _currentUser?['email'];
  String? get userName =>
      '${_currentUser?['firstName'] ?? ''} ${_currentUser?['lastName'] ?? ''}'
          .trim();
  bool get isEmailVerified => _currentUser?['isEmailVerified'] ?? false;
  bool get isPhoneVerified => _currentUser?['isPhoneVerified'] ?? false;
}
