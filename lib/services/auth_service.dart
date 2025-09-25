import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_otp_service.dart';
import 'otp_service.dart';
// NOTE: For LinkedIn we will just store email from result; configure keys in LinkedIn dev portal.

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _loggedInKey = 'logged_in_email';
  static const _loggedInMobileKey = 'logged_in_mobile';
  static const _loginTypeKey = 'login_type';

  String? _email;
  String? _mobileNumber;
  String? _loginType; // 'email', 'mobile', 'google', 'facebook', 'linkedin'

  String? get currentUser => _email ?? _mobileNumber;
  String? get currentEmail => _email;
  String? get currentMobile => _mobileNumber;
  String? get loginType => _loginType;
  bool get isLoggedIn => _email != null || _mobileNumber != null;

  // Initialize auth service and restore login state
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

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, email);
    await prefs.setString(_loginTypeKey, 'email');
    await prefs.remove(_loggedInMobileKey);
    _email = email;
    _mobileNumber = null;
    _loginType = 'email';
    return true;
  }

  // Mobile login with Firebase OTP verification
  Future<bool> sendMobileOtp(
    String countryCode,
    String mobileNumber, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    if (mobileNumber.isEmpty || mobileNumber.length < 7) return false;

    // Use Firebase for real SMS delivery
    return await FirebaseOtpService.sendMobileOtp(
      countryCode: countryCode,
      mobileNumber: mobileNumber,
      onCodeSent: (message) {
        onSuccess?.call(message);
      },
      onError: (error) {
        onError?.call(error);
      },
      onAutoVerify: (credential) async {
        // Handle auto-verification (Android only)
        await _handleFirebasePhoneAuth(credential, countryCode, mobileNumber);
      },
    );
  }

  Future<bool> verifyMobileOtp(
    String countryCode,
    String mobileNumber,
    String otp,
  ) async {
    try {
      // First try Firebase verification
      final credential = await FirebaseOtpService.verifyOtp(otp);
      if (credential != null) {
        return await _handleFirebasePhoneAuth(
          credential,
          countryCode,
          mobileNumber,
        );
      }

      // Fallback to local OTP verification (for testing)
      if (!OtpService.verifyMobileOtp(countryCode, mobileNumber, otp)) {
        return false;
      }

      return await _setMobileLogin(countryCode, mobileNumber);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _handleFirebasePhoneAuth(
    PhoneAuthCredential credential,
    String countryCode,
    String mobileNumber,
  ) async {
    try {
      final userCredential = await FirebaseOtpService.signInWithPhoneCredential(
        credential,
      );
      if (userCredential != null) {
        return await _setMobileLogin(countryCode, mobileNumber);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _setMobileLogin(String countryCode, String mobileNumber) async {
    final fullNumber = OtpService.formatMobileNumber(countryCode, mobileNumber);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInMobileKey, fullNumber);
    await prefs.setString(_loginTypeKey, 'mobile');
    await prefs.remove(_loggedInKey);

    _mobileNumber = fullNumber;
    _email = null;
    _loginType = 'mobile';

    // Clear the OTP after successful verification
    OtpService.clearMobileOtp(countryCode, mobileNumber);

    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_loggedInMobileKey);
    await prefs.remove(_loginTypeKey);
    _email = null;
    _mobileNumber = null;
    _loginType = null;

    // Sign out from all social providers
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Google sign out error: $e');
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('Facebook sign out error: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Firebase sign out error: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final g = GoogleSignIn(scopes: ['email']);
      final acct = await g.signIn();
      if (acct == null) return false;
      final prefs = await SharedPreferences.getInstance();
      _email = acct.email;
      _mobileNumber = null;
      _loginType = 'google';
      await prefs.setString(_loggedInKey, _email!);
      await prefs.setString(_loginTypeKey, 'google');
      await prefs.remove(_loggedInMobileKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: ['email']);
      if (result.status != LoginStatus.success) return false;
      final data = await FacebookAuth.instance.getUserData(
        fields: "email,name",
      );
      final email = data['email'] ?? '${data['id']}@facebook.local';
      final prefs = await SharedPreferences.getInstance();
      _email = email;
      _mobileNumber = null;
      _loginType = 'facebook';
      await prefs.setString(_loggedInKey, _email!);
      await prefs.setString(_loginTypeKey, 'facebook');
      await prefs.remove(_loggedInMobileKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  // LinkedIn uses an external screen; just helper to store email once retrieved.
  Future<void> completeLinkedInLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _email = email;
    _mobileNumber = null;
    _loginType = 'linkedin';
    await prefs.setString(_loggedInKey, _email!);
    await prefs.setString(_loginTypeKey, 'linkedin');
    await prefs.remove(_loggedInMobileKey);
  }
}
