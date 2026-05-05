import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config_service.dart';
import 'user_session_service.dart';

/// Result object returned by every social sign-in method.
class SocialAuthResult {
  final bool success;
  final String? message;
  final User? user;

  const SocialAuthResult({
    required this.success,
    this.message,
    this.user,
  });
}

/// Handles Google, Facebook, Twitter/X and LinkedIn sign-in via Firebase Auth.
class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool get isFacebookSignInEnabled =>
      AppConfigService.readBool('ENABLE_FACEBOOK_AUTH');

  static const String facebookDisabledMessage =
      'Facebook sign-in is disabled for this build until the Android Facebook App ID and client token are configured and ENABLE_FACEBOOK_AUTH=true is passed at build time.';

  // ──────────────────────────────────────────────────────────────────
  // Google Sign-In
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: Firebase popup flow
        final provider = GoogleAuthProvider()
          ..addScope('profile')
          ..addScope('email');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // Mobile: google_sign_in package → credential
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return const SocialAuthResult(
              success: false, message: 'Google sign-in cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      await _persistSession(userCredential.user, 'google');
      return SocialAuthResult(success: true, user: userCredential.user);
    } catch (e) {
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Facebook Sign-In
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithFacebook() async {
    if (!isFacebookSignInEnabled) {
      return const SocialAuthResult(
        success: false,
        message: facebookDisabledMessage,
      );
    }

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = FacebookAuthProvider()..addScope('email');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final result =
            await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);

        if (result.status == LoginStatus.cancelled) {
          return const SocialAuthResult(
              success: false, message: 'Facebook sign-in cancelled.');
        }
        if (result.status != LoginStatus.success) {
          // Map known SDK error messages to friendly text.
          final msg = result.message ?? '';
          if (msg.toLowerCase().contains('invalid app id') ||
              msg.toLowerCase().contains('invalid_app_id')) {
            return const SocialAuthResult(
              success: false,
              message: 'Facebook login is not configured yet.\n'
                  'Please replace YOUR_FACEBOOK_APP_ID in\n'
                  'android/app/src/main/res/values/strings.xml\n'
                  'with your real Facebook App ID from developers.facebook.com.',
            );
          }
          return SocialAuthResult(
              success: false,
              message: msg.isNotEmpty ? msg : 'Facebook sign-in failed.');
        }

        final credential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        userCredential = await _auth.signInWithCredential(credential);
      }

      await _persistSession(userCredential.user, 'facebook');
      return SocialAuthResult(success: true, user: userCredential.user);
    } catch (e) {
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Twitter / X Sign-In
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithTwitter() async {
    try {
      final provider = TwitterAuthProvider();
      late UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        userCredential = await _auth.signInWithProvider(provider);
      }

      await _persistSession(userCredential.user, 'twitter');
      return SocialAuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        return const SocialAuthResult(
          success: false,
          message: 'Twitter/X sign-in is not enabled yet.\n'
              'To enable it:\n'
              '1. Go to Firebase Console -> Authentication -> Sign-in method\n'
              '2. Enable Twitter and enter your Twitter API Key & Secret\n'
              '   (Get them from developer.twitter.com)',
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    } catch (e) {
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // LinkedIn Sign-In  (Firebase generic OAuth provider)
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithLinkedIn() async {
    try {
      final provider = OAuthProvider('linkedin.com')
        ..addScope('r_emailaddress')
        ..addScope('r_liteprofile');

      late UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        userCredential = await _auth.signInWithProvider(provider);
      }

      await _persistSession(userCredential.user, 'linkedin');
      return SocialAuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        return const SocialAuthResult(
          success: false,
          message: 'LinkedIn sign-in is not enabled yet.\n'
              'To enable it:\n'
              '1. Go to Firebase Console -> Authentication -> Sign-in method\n'
              '2. Add LinkedIn as a custom OAuth provider\n'
              '   (Get Client ID & Secret from linkedin.com/developers)',
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    } catch (e) {
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  Future<void> _persistSession(User? user, String provider) async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await UserSessionService.persistSocialContact(prefs, user.email ?? user.uid);
    await prefs.setString('auth_provider', provider);
    await prefs.setString('display_name', user.displayName ?? '');
    await prefs.setString('photo_url', user.photoURL ?? '');
  }

  String _parseError(dynamic e) {
    // ── FirebaseAuthException ──────────────────────────────────────
    if (e is FirebaseAuthException) {
      final msg = e.message ?? '';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'popup-blocked':
          return 'Pop-up blocked. Please allow pop-ups and try again.';
        case 'cancelled-popup-request':
        case 'popup-closed-by-user':
          return 'Sign-in was cancelled.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'operation-not-allowed':
          return 'This sign-in provider is not enabled in Firebase Console.\n'
              'Go to Authentication -> Sign-in method and enable it.';
        case 'internal-error':
          // INVALID_APP_ID  → provider not yet enabled in Firebase Console.
          if (msg.contains('INVALID_APP_ID') || msg.contains('invalid_app_id')) {
            return 'This sign-in provider is not configured in Firebase Console yet.\n'
                'Enable it under Authentication -> Sign-in method.';
          }
          return 'An internal error occurred. Please try again.';
        default:
          return msg.isNotEmpty ? msg : 'An error occurred. Please try again.';
      }
    }

    // ── PlatformException (google_sign_in native SDK) ─────────────
    if (e is PlatformException) {
      final code   = e.code;
      final detail = e.details?.toString() ?? e.message ?? '';

      if (code == 'sign_in_failed') {
        // ApiException: 10  → DEVELOPER_ERROR
        // The debug/release SHA-1 fingerprint is not registered in Firebase
        // Console or Google Cloud OAuth client.
        if (detail.contains('ApiException: 10') || detail.contains('10:')) {
          return 'Google Sign-In is not fully configured.\n'
              'Add your debug SHA-1 fingerprint\n'
              'B1:25:67:8C:A9:3C:37:20:5F:DA:60:58:20:E4:33:C3:98:40:01:57\n'
              'to Firebase Console → Project Settings → Your Android App → SHA certificate fingerprints.';
        }
        if (detail.contains('ApiException: 7')) {
          return 'No internet connection. Please try again.';
        }
        if (detail.contains('ApiException: 12501') || detail.contains('12501')) {
          return 'Google sign-in was cancelled.';
        }
        return 'Google sign-in failed. Please check your internet connection and try again.';
      }

      if (code == 'sign_in_cancelled') {
        return 'Google sign-in was cancelled.';
      }

      if (code == 'network_error') {
        return 'No internet connection. Please try again.';
      }

      return detail.isNotEmpty ? detail : 'Sign-in failed. Please try again.';
    }

    final raw = e.toString();
    if (raw.contains('INVALID_APP_ID')) {
      return 'This sign-in provider is not configured in Firebase Console yet.\n'
          'Enable it under Authentication → Sign-in method.';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
