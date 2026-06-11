import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'app_config_service.dart';
import 'storage_service.dart';
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
  static const String _facebookPackageName = 'com.seenaigmk.resumebuilderai';
  static const String _facebookActivityName =
      'com.seenaigmk.resumebuilderai.MainActivity';
  static const String _linkedInIssuer = 'https://www.linkedin.com/oauth';

  static Set<String> get _firebaseAndroidCertificateHashes =>
    _readCertificateSet('FIREBASE_ANDROID_CERTIFICATE_HASHES');

  static Set<String> get _packageSha1Values => _readCertificateSet('PACKAGE_SHA1');

  static Set<String> get _packageSha256Values =>
    _readCertificateSet('PACKAGE_SHA256');

  static List<String> get _facebookKeyHashes =>
    _readConfigList('FACEBOOK_KEY_HASH');

  static bool get _hasFacebookNativeConfig =>
      AppConfigService.read('FACEBOOK_APP_ID').isNotEmpty &&
      AppConfigService.read('FACEBOOK_CLIENT_TOKEN').isNotEmpty;

  static String get _linkedInProviderId {
    final configured = AppConfigService.read('LINKEDIN_PROVIDER_ID');
    return configured.isNotEmpty ? configured : 'oidc.linkedin';
  }

  static bool get isFacebookSignInEnabled =>
      AppConfigService.readBool(
        'ENABLE_FACEBOOK_AUTH',
        defaultValue: !kIsWeb || _hasFacebookNativeConfig,
      );

  static bool get canAttemptFacebookSignIn => true;

  static bool get canAttemptGoogleSignIn => true;

  static bool get canAttemptTwitterSignIn => true;

  static bool get canAttemptLinkedInSignIn => true;

  static const String facebookDisabledMessage =
      'Facebook sign-in is disabled for this build until the Android Facebook App ID and client token are configured.';

    static String get googleDisabledMessage =>
      _firebaseFingerprintMismatchMessage('Google');

    static String get twitterDisabledMessage =>
      _firebaseFingerprintMismatchMessage('Twitter/X');

    static String get linkedInDisabledMessage =>
      _firebaseFingerprintMismatchMessage('LinkedIn');

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
      if (_isFirebaseFingerprintError(e.toString())) {
        return SocialAuthResult(
          success: false,
          message: _firebaseFingerprintMismatchMessage('Google'),
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Facebook Sign-In
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithFacebook() async {
    if (kIsWeb && !isFacebookSignInEnabled) {
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
        final result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
          loginBehavior: LoginBehavior.webOnly,
        );

        if (result.status == LoginStatus.cancelled) {
          return const SocialAuthResult(
              success: false, message: 'Facebook sign-in cancelled.');
        }
        if (result.status != LoginStatus.success) {
          // Map known SDK error messages to friendly text.
          final msg = result.message ?? '';
          if (_isFacebookPackageHashError(msg)) {
            return SocialAuthResult(
              success: false,
              message: _facebookPackageHashMessage(),
            );
          }
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
          if (_isFacebookInactiveAppError(msg)) {
            return const SocialAuthResult(
              success: false,
              message: 'Facebook sign-in is blocked because the Meta app is inactive.\n'
                  'In Meta Developers, switch the app to Live mode or add your Facebook account as a Developer/Tester for this app, then try again.',
            );
          }
          if (_isFacebookNativePlatformError(msg)) {
            return const SocialAuthResult(
              success: false,
              message: 'Facebook sign-in is misconfigured in Meta Developers.\n'
                  'Add an Android platform for package com.seenaigmk.resumebuilderai, set the default activity to com.seenaigmk.resumebuilderai.MainActivity, and register the app signing key hashes in the Facebook app settings.',
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
      if (_isFacebookPackageHashError(e.toString())) {
        return SocialAuthResult(
          success: false,
          message: _facebookPackageHashMessage(),
        );
      }
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
      if (_isFirebaseFingerprintError(e.message ?? '')) {
        return SocialAuthResult(
          success: false,
          message: _firebaseFingerprintMismatchMessage('Twitter/X'),
        );
      }
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
      if (_isFirebaseFingerprintError(e.toString())) {
        return SocialAuthResult(
          success: false,
          message: _firebaseFingerprintMismatchMessage('Twitter/X'),
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // LinkedIn Sign-In  (Firebase generic OAuth provider)
  // ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithLinkedIn() async {
    try {
      final provider = OAuthProvider(_linkedInProviderId)
        // Keep LinkedIn mobile sign-in on the minimum OIDC scope. Some
        // LinkedIn app setups reject the optional profile/email scopes with
        // invalid_scope_error even though the app can tolerate missing claims.
        ..addScope('openid');

      late UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        userCredential = await _auth.signInWithProvider(provider);
      }

      await _persistSession(userCredential.user, 'linkedin');
      return SocialAuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (_isFirebaseFingerprintError(e.message ?? '')) {
        return SocialAuthResult(
          success: false,
          message: _firebaseFingerprintMismatchMessage('LinkedIn'),
        );
      }
      if (e.code == 'operation-not-allowed') {
        return SocialAuthResult(
          success: false,
          message: 'LinkedIn sign-in is not available for provider "$_linkedInProviderId".\n'
              'In Firebase Console -> Authentication -> Sign-in method, confirm the LinkedIn OIDC provider ID matches exactly, then rebuild the app if you changed it.',
        );
      }
      if (_isLinkedInIssuerError(e.message ?? '')) {
        return SocialAuthResult(
          success: false,
          message: _linkedInIssuerMessage(e.message ?? ''),
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    } catch (e) {
      if (_isFirebaseFingerprintError(e.toString())) {
        return SocialAuthResult(
          success: false,
          message: _firebaseFingerprintMismatchMessage('LinkedIn'),
        );
      }
      if (_isLinkedInIssuerError(e.toString())) {
        return SocialAuthResult(
          success: false,
          message: _linkedInIssuerMessage(e.toString()),
        );
      }
      return SocialAuthResult(success: false, message: _parseError(e));
    }
  }

  static Set<String> _readCertificateSet(String key) {
    return _readConfigList(key)
        .map(_normalizeCertificateHash)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static List<String> _readConfigList(String key) {
    return AppConfigService.read(key)
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static String _normalizeCertificateHash(String value) {
    return value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toLowerCase();
  }

  static bool _isFirebaseFingerprintError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('package certificate hash') ||
        normalized.contains('apiexception: 10') ||
        normalized.contains('developer_error');
  }

  static bool _isFacebookPackageHashError(String message) {
    return message.toLowerCase().contains('package certificate hash');
  }

  static String _firebaseFingerprintMismatchMessage(String providerLabel) {
    final currentSha1 = _formatCertificateHashes(_packageSha1Values);
    final currentSha256 = _formatCertificateHashes(_packageSha256Values);
    final expected = _formatCertificateHashes(_firebaseAndroidCertificateHashes);

    return '$providerLabel sign-in is blocked on this Android install because the app signing fingerprints do not match Firebase for package\n'
        '$_facebookPackageName.\n\n'
        'Current install SHA-1: $currentSha1\n'
        'Current install SHA-256: $currentSha256\n'
        'Configured in google-services.json: $expected\n\n'
        'Add the current SHA-1/SHA-256 in Firebase Console -> Project Settings -> Your Android app, then download a fresh android/app/google-services.json and reinstall the app.';
  }

  static String _facebookPackageHashMessage() {
    final currentSha1 = _formatCertificateHashes(_packageSha1Values);
    final keyHashes = _facebookKeyHashes.isEmpty
        ? 'Unavailable from this install'
        : _facebookKeyHashes.join(', ');

    return 'Facebook sign-in could not validate this Android app signature.\n\n'
        'Package: $_facebookPackageName\n'
        'Activity: $_facebookActivityName\n'
        'Current SHA-1: $currentSha1\n'
        'Current Facebook key hash: $keyHashes\n\n'
        'In Meta Developers, add the Android platform for this package/activity and register the current key hash, then reinstall the app.';
  }

  static String _formatCertificateHashes(Set<String> values) {
    if (values.isEmpty) {
      return 'Unavailable';
    }

    return values.map(_prettyPrintCertificateHash).join(', ');
  }

  static String _prettyPrintCertificateHash(String value) {
    if (value.length.isOdd) {
      return value.toUpperCase();
    }

    final parts = <String>[];
    for (var index = 0; index < value.length; index += 2) {
      parts.add(value.substring(index, index + 2).toUpperCase());
    }
    return parts.join(':');
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  Future<void> _persistSession(User? user, String provider) async {
    if (user == null) return;
    final prefs = StorageService.prefs;
    await prefs.setBool('is_logged_in', true);
    await UserSessionService.persistSocialContact(prefs, user.email ?? user.uid);
    await prefs.setString('auth_provider', provider);
    await prefs.setString('display_name', user.displayName ?? '');
    await prefs.setString('photo_url', user.photoURL ?? '');
  }

  bool _isLinkedInIssuerError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('error connecting to the given credential\'s issuer') ||
        (normalized.contains('auth/invalid-credential') &&
            normalized.contains('issuer'));
  }

  bool _isLinkedInInvalidScopeError(String message) {
    final normalized = message.toLowerCase();
    final oauthError = _readOAuthQueryField(message, 'error').toLowerCase();
    final oauthDescription =
        _readOAuthQueryField(message, 'error_description').toLowerCase();
    return normalized.contains('invalid_scope_error') ||
        normalized.contains('requested permission scope is not valid') ||
        oauthError == 'invalid_scope_error' ||
        oauthDescription.contains('requested permission scope is not valid');
  }

  String _linkedInInvalidScopeMessage() {
    return 'LinkedIn sign-in is misconfigured outside the app.\n'
        'LinkedIn is rejecting the requested OIDC scope for provider "$_linkedInProviderId".\n\n'
        'Fix this in configuration:\n'
        '1. LinkedIn Developer Portal -> Products -> enable "Sign In with LinkedIn using OpenID Connect" for the LinkedIn app.\n'
        '2. LinkedIn Developer Portal -> Auth -> add the redirect URL https://resumeapplatest.firebaseapp.com/__/auth/handler.\n'
        '3. Firebase Console -> Authentication -> Sign-in method -> OpenID Connect provider "$_linkedInProviderId" -> issuer must be $_linkedInIssuer, and the LinkedIn client ID / secret must match the same LinkedIn app.\n'
        '4. Rebuild and reinstall the app after saving those provider changes.';
  }

  String _linkedInIssuerMessage([String technicalDetail = '']) {
    final buffer = StringBuffer()
      ..writeln(
        'LinkedIn sign-in is misconfigured outside the app for provider "$_linkedInProviderId".',
      )
      ..writeln()
      ..writeln('Verify these values together:')
      ..writeln(
        '1. Firebase Console -> Authentication -> Sign-in method -> OpenID Connect provider "$_linkedInProviderId"',
      )
      ..writeln('   Issuer: $_linkedInIssuer')
      ..writeln(
        '   Client ID and Client secret: must match the same LinkedIn app',
      )
      ..writeln(
        '2. LinkedIn Developer Portal -> Products -> enable "Sign In with LinkedIn using OpenID Connect"',
      )
      ..writeln(
        '3. LinkedIn Developer Portal -> Auth -> add redirect URL https://resumeapplatest.firebaseapp.com/__/auth/handler',
      )
      ..write('4. Rebuild and reinstall the app after saving those provider changes.');

    final normalizedDetail = technicalDetail.trim();
    if (normalizedDetail.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write('Technical details: $normalizedDetail');
    }

    return buffer.toString();
  }

  String _readOAuthQueryField(String message, String field) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final candidates = <String>[];
    final queryIndex = trimmed.indexOf('?');
    if (queryIndex >= 0 && queryIndex + 1 < trimmed.length) {
      candidates.add(trimmed.substring(queryIndex + 1));
    }
    candidates.add(trimmed);

    for (final candidate in candidates) {
      if (!candidate.contains('$field=')) {
        continue;
      }
      try {
        final parsed = Uri.splitQueryString(candidate);
        final value = parsed[field];
        if (value != null && value.isNotEmpty) {
          return value;
        }
      } catch (_) {
        // Fall through to the regex-based extraction below.
      }

      final match = RegExp('(?:^|[?&])${RegExp.escape(field)}=([^&]+)')
          .firstMatch(candidate);
      if (match != null) {
        return Uri.decodeQueryComponent(match.group(1)!);
      }
    }

    return '';
  }

  bool _isFacebookInactiveAppError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('app not active') ||
        normalized.contains('this app is not accessible right now') ||
        (normalized.contains('app is inactive') &&
            normalized.contains('facebook'));
  }

  bool _isFacebookNativePlatformError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('given url is not allowed by the application configuration') ||
        normalized.contains('add a valid native platform') ||
        (normalized.contains('not allowed by the app\'s settings') &&
            normalized.contains('facebook'));
  }

  String _parseError(dynamic e) {
    // ── FirebaseAuthException ──────────────────────────────────────
    if (e is FirebaseAuthException) {
      final msg = e.message ?? '';
      if (_isLinkedInIssuerError(msg)) {
        return _linkedInIssuerMessage(msg);
      }
      if (_isLinkedInInvalidScopeError(msg)) {
        return _linkedInInvalidScopeMessage();
      }
      if (_isFacebookInactiveAppError(msg)) {
        return 'Facebook sign-in is blocked because the Meta app is inactive.\n'
            'In Meta Developers, switch the app to Live mode or add your Facebook account as a Developer/Tester for this app, then try again.';
      }
      if (_isFacebookNativePlatformError(msg)) {
        return 'Facebook sign-in is misconfigured in Meta Developers.\n'
            'Add an Android platform for package $_facebookPackageName, set the default activity to $_facebookActivityName, and register the app signing key hashes in the Facebook app settings.';
      }
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

      if (_isLinkedInIssuerError(detail)) {
        return _linkedInIssuerMessage(detail);
      }
      if (_isLinkedInInvalidScopeError(detail)) {
        return _linkedInInvalidScopeMessage();
      }

      if (_isFacebookInactiveAppError(detail)) {
        return 'Facebook sign-in is blocked because the Meta app is inactive.\n'
        'In Meta Developers, switch the app to Live mode or add your Facebook account as a Developer/Tester for this app, then try again.';
      }

      if (_isFacebookPackageHashError(detail)) {
        return _facebookPackageHashMessage();
      }

      if (_isFirebaseFingerprintError(detail)) {
        return _firebaseFingerprintMismatchMessage('Google');
      }

      if (_isFacebookNativePlatformError(detail)) {
        return 'Facebook sign-in is misconfigured in Meta Developers.\n'
            'Add an Android platform for package $_facebookPackageName, set the default activity to $_facebookActivityName, and register the app signing key hashes in the Facebook app settings.';
      }

      if (code == 'sign_in_failed') {
        // ApiException: 10  → DEVELOPER_ERROR
        // The debug/release SHA-1 fingerprint is not registered in Firebase
        // Console or Google Cloud OAuth client.
        if (detail.contains('ApiException: 10') || detail.contains('10:')) {
          return _firebaseFingerprintMismatchMessage('Google');
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
    if (_isFacebookPackageHashError(raw)) {
      return _facebookPackageHashMessage();
    }
    if (_isFirebaseFingerprintError(raw)) {
      return _firebaseFingerprintMismatchMessage('Google');
    }
    if (_isLinkedInIssuerError(raw)) {
      return _linkedInIssuerMessage(raw);
    }
    if (_isLinkedInInvalidScopeError(raw)) {
      return _linkedInInvalidScopeMessage();
    }
    if (_isFacebookInactiveAppError(raw)) {
      return 'Facebook sign-in is blocked because the Meta app is inactive.\n'
          'In Meta Developers, switch the app to Live mode or add your Facebook account as a Developer/Tester for this app, then try again.';
    }
    if (_isFacebookNativePlatformError(raw)) {
      return 'Facebook sign-in is misconfigured in Meta Developers.\n'
          'Add an Android platform for package $_facebookPackageName, set the default activity to $_facebookActivityName, and register the app signing key hashes in the Facebook app settings.';
    }
    if (raw.contains('INVALID_APP_ID')) {
      return 'This sign-in provider is not configured in Firebase Console yet.\n'
          'Enable it under Authentication → Sign-in method.';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
