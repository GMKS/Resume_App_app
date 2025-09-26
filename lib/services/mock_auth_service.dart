import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  static const _loggedInKey = 'logged_in_email';
  static const _loggedInMobileKey = 'logged_in_mobile';
  static const _loginTypeKey = 'login_type';

  String? _email;
  String? _mobileNumber;
  String? _loginType;

  String? get currentUser => _email ?? _mobileNumber;
  String? get currentEmail => _email;
  String? get currentMobile => _mobileNumber;
  String? get loginType => _loginType;
  bool get isLoggedIn => _email != null || _mobileNumber != null;

  // Initialize mock auth service
  Future<void> init({bool alwaysFresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (alwaysFresh) {
      await prefs.remove(_loggedInKey);
      await prefs.remove(_loggedInMobileKey);
      await prefs.remove(_loginTypeKey);
      _email = null;
      _mobileNumber = null;
      _loginType = null;
      return;
    }
    // Restore previous login state
    _email = prefs.getString(_loggedInKey);
    _mobileNumber = prefs.getString(_loggedInMobileKey);
    _loginType = prefs.getString(_loginTypeKey);
  }

  // Mock email login - accepts any email with password length > 3
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, email);
    await prefs.setString(_loginTypeKey, 'email');

    _email = email;
    _loginType = 'email';
    _mobileNumber = null;

    return true;
  }

  // Mock mobile login - accepts any mobile number
  Future<bool> loginWithMobile(String mobileNumber) async {
    if (mobileNumber.isEmpty || mobileNumber.length < 10) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInMobileKey, mobileNumber);
    await prefs.setString(_loginTypeKey, 'mobile');

    _mobileNumber = mobileNumber;
    _loginType = 'mobile';
    _email = null;

    return true;
  }

  // Mock OTP verification - always returns true
  Future<bool> verifyOTP(String otp) async {
    // Mock verification - accept any 6-digit OTP
    return otp.length == 6 && RegExp(r'^\d+$').hasMatch(otp);
  }

  // Mock send OTP - simulates sending OTP
  Future<bool> sendOTP(String mobileNumber) async {
    if (mobileNumber.isEmpty || mobileNumber.length < 10) {
      return false;
    }

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock success - in real app, this would send actual OTP
    print('MOCK: OTP sent to $mobileNumber (Use any 6-digit number to verify)');
    return true;
  }

  // Mock Google Sign-In
  Future<bool> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));

    const mockEmail = 'user@gmail.com';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, mockEmail);
    await prefs.setString(_loginTypeKey, 'google');

    _email = mockEmail;
    _loginType = 'google';
    _mobileNumber = null;

    return true;
  }

  // Mock Facebook Sign-In
  Future<bool> signInWithFacebook() async {
    await Future.delayed(const Duration(seconds: 1));

    const mockEmail = 'user@facebook.com';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, mockEmail);
    await prefs.setString(_loginTypeKey, 'facebook');

    _email = mockEmail;
    _loginType = 'facebook';
    _mobileNumber = null;

    return true;
  }

  // Mock LinkedIn Sign-In
  Future<bool> signInWithLinkedIn() async {
    await Future.delayed(const Duration(seconds: 1));

    const mockEmail = 'user@linkedin.com';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, mockEmail);
    await prefs.setString(_loginTypeKey, 'linkedin');

    _email = mockEmail;
    _loginType = 'linkedin';
    _mobileNumber = null;

    return true;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_loggedInMobileKey);
    await prefs.remove(_loginTypeKey);

    _email = null;
    _mobileNumber = null;
    _loginType = null;
  }

  // Register - mock implementation
  Future<bool> register(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      return false;
    }

    // Mock registration - just log in the user
    return await login(email, password);
  }

  // Reset password - mock implementation
  Future<bool> resetPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return false;
    }

    await Future.delayed(const Duration(seconds: 1));
    print('MOCK: Password reset email sent to $email');
    return true;
  }
}
