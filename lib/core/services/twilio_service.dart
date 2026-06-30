import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'app_config_service.dart';

class TwilioService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String otpDebugCode = AppConfigService.read('OTP_DEBUG_CODE');
  String? _verificationId;
  int? _forceResendingToken;
  String? _pendingPhoneNumber;
  String? _activeOtpProvider;

  bool get _hasDebugOtp => !kReleaseMode && otpDebugCode.isNotEmpty;

  bool get _hasBackendOtp => _otpSendUrl.isNotEmpty && _otpVerifyUrl.isNotEmpty;

  String get _otpBaseUrl => AppConfigService.read('OTP_BASE_URL');

  String get _otpSendUrl =>
      _readOtpUrl(explicitKey: 'OTP_SEND_URL', fallbackPath: 'send-otp');

  String get _otpVerifyUrl =>
      _readOtpUrl(explicitKey: 'OTP_VERIFY_URL', fallbackPath: 'verify-otp');

  bool get supportsWebOtp => !kIsWeb || _hasDebugOtp || _hasBackendOtp;

  void _logOtpContext(String stage, {Object? error, StackTrace? stackTrace}) {
    final packageName = AppConfigService.read('PACKAGE_NAME');
    final packageSha1 = AppConfigService.read('PACKAGE_SHA1');
    final packageSha256 = AppConfigService.read('PACKAGE_SHA256');
    final firebaseCerts = AppConfigService.read(
      'FIREBASE_ANDROID_CERTIFICATE_HASHES',
    );

    debugPrint(
      '[OTP][$stage] package=$packageName '
      'sha1=${packageSha1.isEmpty ? 'n/a' : packageSha1} '
      'sha256=${packageSha256.isEmpty ? 'n/a' : packageSha256} '
      'firebaseCerts=${firebaseCerts.isEmpty ? 'n/a' : firebaseCerts}',
    );

    if (error != null) {
      debugPrint('[OTP][$stage] error=$error');
    }

    if (stackTrace != null) {
      debugPrint('[OTP][$stage] stack=$stackTrace');
    }
  }

  /// Sends a verification code using Firebase Phone Auth on mobile first,
  /// then falls back to the configured backend when available.
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    if (_hasDebugOtp) {
      return {
        'success': true,
        'message':
            'Debug OTP is enabled for this build. Use the configured local test code to continue.',
        'status': 'pending',
      };
    }

    final formattedPhone = _formatPhoneNumber(phoneNumber);

    if (!kIsWeb) {
      final firebaseResult = await _sendOtpViaFirebase(formattedPhone);
      if (firebaseResult['success'] == true ||
          !_hasBackendOtp ||
          !_shouldFallbackToBackend(firebaseResult)) {
        return firebaseResult;
      }

      final backendResult = await _sendOtpViaBackend(formattedPhone);
      if (backendResult['success'] == true) {
        return backendResult;
      }
      return _mergeOtpFailures(
        primary: firebaseResult,
        fallback: backendResult,
      );
    }

    if (_hasBackendOtp) {
      return _sendOtpViaBackend(formattedPhone);
    }

    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'Phone verification is available only in the mobile app for this build.',
      };
    }

    return {
      'success': false,
      'message': 'Could not start phone verification. Please try again.',
    };
  }

  /// Verify OTP entered by user
  Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otpCode,
  ) async {
    if (_hasDebugOtp) {
      final isVerified = otpCode == otpDebugCode;
      return {
        'success': isVerified,
        'message': isVerified
            ? 'Debug OTP verified successfully.'
            : 'Invalid debug OTP. Please try again.',
        'status': isVerified ? 'approved' : 'pending',
      };
    }

    final formattedPhone = _formatPhoneNumber(phoneNumber);

    if (_activeOtpProvider == 'backend') {
      if (_pendingPhoneNumber != null &&
          _pendingPhoneNumber != formattedPhone) {
        return {
          'success': false,
          'message': 'Please request a new OTP and try again.',
        };
      }

      return _verifyOtpViaBackend(formattedPhone, otpCode);
    }

    if (!kIsWeb) {
      final hasFirebaseSession =
          _verificationId != null && _pendingPhoneNumber == formattedPhone;
      if (_activeOtpProvider == 'firebase' ||
          hasFirebaseSession ||
          !_hasBackendOtp) {
        return _verifyOtpViaFirebase(formattedPhone, otpCode);
      }
    }

    if (_hasBackendOtp) {
      if (_pendingPhoneNumber != null &&
          _pendingPhoneNumber != formattedPhone) {
        return {
          'success': false,
          'message': 'Please request a new OTP and try again.',
        };
      }

      return _verifyOtpViaBackend(formattedPhone, otpCode);
    }

    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'Phone verification is available only in the mobile app for this build.',
      };
    }

    return _verifyOtpViaFirebase(formattedPhone, otpCode);
  }

  /// Format phone number to E.164 format (+CountryCodeNumber)
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('00')) {
        cleaned = '+${cleaned.substring(2)}';
      } else {
        cleaned = '+$cleaned';
      }
    }

    return cleaned;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Resend OTP (request new code)
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    return sendOTP(phoneNumber);
  }

  Future<Map<String, dynamic>> _sendOtpViaFirebase(String phoneNumber) async {
    final completer = Completer<Map<String, dynamic>>();
    var completed = false;

    try {
      _logOtpContext('firebase-send-start');
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken:
            _pendingPhoneNumber == phoneNumber ? _forceResendingToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (completed) {
            return;
          }

          try {
            await _auth.signInWithCredential(credential);
            _activeOtpProvider = 'firebase';
            _clearPendingVerification();
            completed = true;
            completer.complete(<String, dynamic>{
              'success': true,
              'message': 'Phone number verified automatically.',
              'status': 'approved',
            });
          } on FirebaseAuthException catch (error) {
            completed = true;
            completer.complete(<String, dynamic>{
              'success': false,
              'message': _parseFirebaseAuthError(error),
              'errorCode': error.code,
              'provider': 'firebase',
            });
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          if (completed) {
            return;
          }

          completed = true;
          _logOtpContext('firebase-verification-failed', error: error);
          completer.complete(<String, dynamic>{
            'success': false,
            'message': _parseFirebaseAuthError(error),
            'errorCode': error.code,
            'provider': 'firebase',
          });
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          _pendingPhoneNumber = phoneNumber;
          _activeOtpProvider = 'firebase';

          if (completed) {
            return;
          }

          completed = true;
          completer.complete(<String, dynamic>{
            'success': true,
            'message': 'OTP sent successfully.',
            'status': 'pending',
            'provider': 'firebase',
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return completer.future.timeout(
        const Duration(seconds: 75),
        onTimeout: () => <String, dynamic>{
          'success': false,
          'message': 'Timed out while sending OTP. Please try again.',
          'errorCode': 'timeout',
          'provider': 'firebase',
        },
      );
    } on FirebaseAuthException catch (error) {
      _logOtpContext('firebase-send-exception', error: error);
      return {
        'success': false,
        'message': _parseFirebaseAuthError(error),
        'errorCode': error.code,
        'provider': 'firebase',
      };
    } catch (error, stackTrace) {
      _logOtpContext(
        'firebase-send-unknown-exception',
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        'Failed to start Firebase phone verification',
        name: 'TwilioService',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'success': false,
        'message': 'Could not start phone verification. Please try again.',
        'errorCode': 'firebase_start_failed',
        'provider': 'firebase',
      };
    }
  }

  Future<Map<String, dynamic>> _verifyOtpViaFirebase(
    String phoneNumber,
    String otpCode,
  ) async {
    final verificationId = _verificationId;
    if (verificationId == null || _pendingPhoneNumber != phoneNumber) {
      return {
        'success': false,
        'message': 'Please request a new OTP and try again.',
      };
    }

    try {
      _logOtpContext('firebase-verify-start');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);
      _clearPendingVerification();

      return {
        'success': true,
        'message': 'OTP verified successfully.',
        'status': 'approved',
      };
    } on FirebaseAuthException catch (error) {
      _logOtpContext('firebase-verify-failed', error: error);
      return {
        'success': false,
        'message': _parseFirebaseAuthError(error),
        'errorCode': error.code,
        'provider': 'firebase',
      };
    } catch (error, stackTrace) {
      _logOtpContext(
        'firebase-verify-unknown-exception',
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        'Failed to verify Firebase OTP',
        name: 'TwilioService',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'success': false,
        'message': 'Could not verify OTP. Please try again.',
        'errorCode': 'firebase_verify_failed',
        'provider': 'firebase',
      };
    }
  }

  Future<Map<String, dynamic>> _sendOtpViaBackend(String phoneNumber) async {
    try {
      _logOtpContext('backend-send-start');
      final response = await http
          .post(
            Uri.parse(_otpSendUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, String>{'phoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));

      final result = _parseBackendResult(
        response,
        fallbackMessage: 'Could not send OTP. Please try again.',
      );

      if (result['success'] == true) {
        _verificationId = null;
        _forceResendingToken = null;
        _pendingPhoneNumber = phoneNumber;
        _activeOtpProvider = 'backend';
      }

      return result;
    } catch (error, stackTrace) {
      _logOtpContext(
        'backend-send-exception',
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        'Failed to reach OTP send service',
        name: 'TwilioService',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'success': false,
        'message':
            'Could not reach the OTP service. Check your internet connection and try again in a moment.',
        'errorCode': 'backend_unreachable',
        'provider': 'backend',
      };
    }
  }

  Future<Map<String, dynamic>> _verifyOtpViaBackend(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      _logOtpContext('backend-verify-start');
      final response = await http
          .post(
            Uri.parse(_otpVerifyUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'phoneNumber': phoneNumber,
              'code': otpCode.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      final result = _parseBackendResult(
        response,
        fallbackMessage: 'Could not verify OTP. Please try again.',
      );

      if (result['success'] == true) {
        _clearPendingVerification();
      }

      return result;
    } catch (error, stackTrace) {
      _logOtpContext(
        'backend-verify-exception',
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        'Failed to reach OTP verify service',
        name: 'TwilioService',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'success': false,
        'message':
            'Could not reach the OTP service. Check your internet connection and try again in a moment.',
        'errorCode': 'backend_unreachable',
        'provider': 'backend',
      };
    }
  }

  Map<String, dynamic> _parseBackendResult(
    http.Response response, {
    required String fallbackMessage,
  }) {
    Map<String, dynamic> body = <String, dynamic>{};
    final rawBody = response.body.trim();

    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else if (decoded is Map) {
          body = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        // Fall back to the HTTP status and generic message below.
      }
    }

    final success = body['success'] == true ||
        (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            body['success'] != false);
    final message = body['message']?.toString().trim();
    final status = body['status']?.toString().trim();

    return {
      'success': success,
      'message':
          message != null && message.isNotEmpty ? message : fallbackMessage,
      'provider': 'backend',
      if (status != null && status.isNotEmpty) 'status': status,
    };
  }

  String _readOtpUrl({
    required String explicitKey,
    required String fallbackPath,
  }) {
    final explicit = AppConfigService.read(explicitKey).trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final base = _otpBaseUrl.trim();
    if (base.isEmpty) {
      return '';
    }

    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$normalizedBase/$fallbackPath';
  }

  bool _shouldFallbackToBackend(Map<String, dynamic> firebaseResult) {
    final errorCode = (firebaseResult['errorCode']?.toString() ?? '').trim();
    switch (errorCode) {
      case 'operation-not-allowed':
      case 'app-not-authorized':
      case 'captcha-check-failed':
      case 'internal-error':
      case 'firebase_start_failed':
      case 'timeout':
        return true;
      default:
        return false;
    }
  }

  Map<String, dynamic> _mergeOtpFailures({
    required Map<String, dynamic> primary,
    required Map<String, dynamic> fallback,
  }) {
    final primaryMessage = (primary['message']?.toString() ?? '').trim();
    final fallbackMessage = (fallback['message']?.toString() ?? '').trim();

    if (fallback['success'] == true) {
      return fallback;
    }

    if (fallback['errorCode'] == 'backend_unreachable' &&
        primaryMessage.isNotEmpty) {
      return primary;
    }

    if (primaryMessage.isEmpty) {
      return fallback;
    }

    if (fallbackMessage.isEmpty || fallbackMessage == primaryMessage) {
      return primary;
    }

    return <String, dynamic>{
      ...primary,
      'message':
          '$primaryMessage\n\nFallback OTP service response: $fallbackMessage',
    };
  }

  void _clearPendingVerification() {
    _verificationId = null;
    _forceResendingToken = null;
    _pendingPhoneNumber = null;
    _activeOtpProvider = null;
  }

  String _parseFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'missing-phone-number':
        return 'Please enter a phone number.';
      case 'quota-exceeded':
        return 'Firebase phone verification quota has been exceeded. Please try again later.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit before trying again.';
      case 'session-expired':
        return 'The OTP has expired. Please request a new code.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new OTP.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'captcha-check-failed':
        return 'Phone verification could not be completed. Please try again.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in Firebase Authentication.';
      default:
        return (error.message ?? 'Phone verification failed.').trim();
    }
  }
}
