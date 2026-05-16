import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfigService {
  const AppConfigService._();

  static const MethodChannel _channel = MethodChannel('resume_builder/app_config');
  static final Map<String, String> _runtimeValues = <String, String>{};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final config = await _channel.invokeMapMethod<String, dynamic>('getConfig');
        if (config != null) {
          for (final entry in config.entries) {
            final value = _normalizeForKey(entry.key, entry.value?.toString() ?? '');
            if (value.isNotEmpty) {
              _runtimeValues[entry.key] = value;
            }
          }
        }
      }
    } catch (_) {
      // Keep using compile-time defines when Android runtime config is unavailable.
    } finally {
      _initialized = true;
    }
  }

  static String read(String key) {
    final compileTimeOtpBaseUrl =
        _normalize(const String.fromEnvironment('OTP_BASE_URL'));
    final runtimeOtpBaseUrl = _normalize(_runtimeValues['OTP_BASE_URL'] ?? '');

    final compileTimeValue = switch (key) {
      'OTP_SEND_URL' => _readOtpUrl(
          explicitValue: const String.fromEnvironment('OTP_SEND_URL'),
          otpBaseUrl: compileTimeOtpBaseUrl,
          path: 'send-otp',
        ),
      'OTP_VERIFY_URL' => _readOtpUrl(
          explicitValue: const String.fromEnvironment('OTP_VERIFY_URL'),
          otpBaseUrl: compileTimeOtpBaseUrl,
          path: 'verify-otp',
        ),
      'OTP_DEBUG_CODE' => const String.fromEnvironment('OTP_DEBUG_CODE'),
      'PLAY_WEEKLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_WEEKLY_PRODUCT_ID',
          defaultValue: 'resumix_ai_weekly',
        ),
      'PLAY_MONTHLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_MONTHLY_PRODUCT_ID',
          defaultValue: 'resumix_ai_monthly',
        ),
      'PLAY_QUARTERLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_QUARTERLY_PRODUCT_ID',
          defaultValue: 'resumix_ai_quarterly',
        ),
      'PLAY_YEARLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_YEARLY_PRODUCT_ID',
          defaultValue: 'resumix_ai_yearly',
        ),
      'RAZORPAY_KEY_ID' => const String.fromEnvironment('RAZORPAY_KEY_ID'),
      'ENABLE_DUMMY_PAYMENTS' =>
          const String.fromEnvironment('ENABLE_DUMMY_PAYMENTS'),
      'DISABLE_GOOGLE_PLAY_BILLING' =>
          const String.fromEnvironment('DISABLE_GOOGLE_PLAY_BILLING'),
      'ENABLE_FACEBOOK_AUTH' =>
          const String.fromEnvironment('ENABLE_FACEBOOK_AUTH'),
      'FACEBOOK_APP_ID' => const String.fromEnvironment('FACEBOOK_APP_ID'),
      'FACEBOOK_CLIENT_TOKEN' =>
          const String.fromEnvironment('FACEBOOK_CLIENT_TOKEN'),
      'LINKEDIN_PROVIDER_ID' => const String.fromEnvironment(
          'LINKEDIN_PROVIDER_ID',
          defaultValue: 'oidc.linkedin',
        ),
      _ => '',
    };

    final normalizedCompileTime = _normalizeForKey(key, compileTimeValue);
    if (normalizedCompileTime.isNotEmpty) {
      return normalizedCompileTime;
    }

    final runtimeValue = switch (key) {
      'OTP_SEND_URL' => _readOtpUrl(
          explicitValue: _runtimeValues['OTP_SEND_URL'] ?? '',
          otpBaseUrl: runtimeOtpBaseUrl,
          path: 'send-otp',
        ),
      'OTP_VERIFY_URL' => _readOtpUrl(
          explicitValue: _runtimeValues['OTP_VERIFY_URL'] ?? '',
          otpBaseUrl: runtimeOtpBaseUrl,
          path: 'verify-otp',
        ),
      _ => _runtimeValues[key] ?? '',
    };

    return _normalizeForKey(key, runtimeValue);
  }

  static String _readOtpUrl({
    required String explicitValue,
    required String otpBaseUrl,
    required String path,
  }) {
    final normalizedExplicit = _normalize(explicitValue);
    if (normalizedExplicit.isNotEmpty) {
      return normalizedExplicit;
    }

    if (otpBaseUrl.isEmpty) {
      return '';
    }

    return _joinUrl(otpBaseUrl, path);
  }

  static bool readBool(String key, {bool defaultValue = false}) {
    final value = read(key);
    if (value.isEmpty) {
      return defaultValue;
    }

    switch (value.toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return defaultValue;
    }
  }

  static String _normalize(String value) {
    var normalized = value.trim();
    if (normalized.endsWith(';')) {
      normalized = normalized.substring(0, normalized.length - 1).trimRight();
    }
    if (normalized.length >= 2 &&
        ((normalized.startsWith("'") && normalized.endsWith("'")) ||
            (normalized.startsWith('"') && normalized.endsWith('"')))) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    return normalized;
  }

  static String _normalizeForKey(String key, String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) {
      return '';
    }

    return switch (key) {
      'FACEBOOK_APP_ID' || 'FACEBOOK_CLIENT_TOKEN' =>
        normalized.startsWith('YOUR_FACEBOOK_') ? '' : normalized,
      'LINKEDIN_PROVIDER_ID' => _normalizeLinkedInProviderId(normalized),
      _ => normalized,
    };
  }

  static String _normalizeLinkedInProviderId(String value) {
    if (value.startsWith('oidc.')) {
      return value;
    }

    if (value.contains('.')) {
      return value;
    }

    return 'oidc.$value';
  }

  static String _joinUrl(String baseUrl, String path) {
    final trimmedBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final trimmedPath = path.trim().replaceFirst(RegExp(r'^/+'), '');
    if (trimmedBase.isEmpty) {
      return trimmedPath;
    }
    if (trimmedPath.isEmpty) {
      return trimmedBase;
    }
    return '$trimmedBase/$trimmedPath';
  }
}