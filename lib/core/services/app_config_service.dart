import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfigService {
  const AppConfigService._();

  static const MethodChannel _channel =
      MethodChannel('resume_builder/app_config');
  static Map<String, String> _runtimeConfig = <String, String>{};
  static Map<String, String> _dotenvConfig = <String, String>{};
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final rawDotEnv = await rootBundle.loadString('.env');
      _dotenvConfig = _parseDotEnv(rawDotEnv);
      _logConfig(
        'Loaded .env configuration',
        details: <String, Object?>{'dotenvKeys': _dotenvConfig.keys.length},
      );
    } catch (error, stackTrace) {
      _dotenvConfig = <String, String>{};
      _logConfig(
        'Unable to load .env configuration',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final config =
            await _channel.invokeMapMethod<String, dynamic>('getConfig');
        if (config != null) {
          _runtimeConfig = config.map(
            (key, value) => MapEntry(key, _normalize(value?.toString() ?? '')),
          );
        }
        _logConfig(
          'Loaded Android runtime configuration',
          details: <String, Object?>{'runtimeKeys': _runtimeConfig.keys.length},
        );
      } catch (error, stackTrace) {
        _runtimeConfig = <String, String>{};
        _logConfig(
          'Unable to load Android runtime configuration',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _validateAiConfiguration();

    _logConfig(
      'App configuration initialized',
      details: <String, Object?>{
        'aiBaseUrlSource': sourceOf('AI_BASE_URL'),
        'aiBackendConfigured': hasAiBackendConfigured,
        'aiEnvironment': read('AI_ENV'),
      },
    );

    _initialized = true;
  }

  static String read(String key) {
    final runtimeValue = _runtimeConfig[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }

    final dotenvValue = _dotenvConfig[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue;
    }

    final value = switch (key) {
      'OTP_BASE_URL' => const String.fromEnvironment('OTP_BASE_URL'),
      'OTP_SEND_URL' => const String.fromEnvironment('OTP_SEND_URL'),
      'OTP_VERIFY_URL' => const String.fromEnvironment('OTP_VERIFY_URL'),
      'OTP_DEBUG_CODE' => const String.fromEnvironment('OTP_DEBUG_CODE'),
      'FACEBOOK_APP_ID' => const String.fromEnvironment('FACEBOOK_APP_ID'),
      'FACEBOOK_CLIENT_TOKEN' =>
        const String.fromEnvironment('FACEBOOK_CLIENT_TOKEN'),
      'LINKEDIN_PROVIDER_ID' =>
        const String.fromEnvironment('LINKEDIN_PROVIDER_ID'),
      'FIREBASE_ANDROID_CERTIFICATE_HASHES' => const String.fromEnvironment(
          'FIREBASE_ANDROID_CERTIFICATE_HASHES',
        ),
      'PACKAGE_SHA1' => const String.fromEnvironment('PACKAGE_SHA1'),
      'PACKAGE_SHA256' => const String.fromEnvironment('PACKAGE_SHA256'),
      'FACEBOOK_KEY_HASH' => const String.fromEnvironment('FACEBOOK_KEY_HASH'),
      'PLAY_WEEKLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_WEEKLY_PRODUCT_ID',
          defaultValue: 'weekly_pro',
        ),
      'PLAY_MONTHLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_MONTHLY_PRODUCT_ID',
          defaultValue: 'monthly_pro',
        ),
      'PLAY_QUARTERLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_QUARTERLY_PRODUCT_ID',
          defaultValue: 'quarterly_pro',
        ),
      'PLAY_YEARLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_YEARLY_PRODUCT_ID',
          defaultValue: 'yearly_pro',
        ),
      'AI_BASE_URL' => const String.fromEnvironment('AI_BASE_URL'),
      'AI_ENV' => const String.fromEnvironment('AI_ENV'),
      'RAZORPAY_KEY_ID' => const String.fromEnvironment('RAZORPAY_KEY_ID'),
      'ENABLE_DUMMY_PAYMENTS' => const String.fromEnvironment(
          'ENABLE_DUMMY_PAYMENTS',
          defaultValue: 'false',
        ),
      'DISABLE_GOOGLE_PLAY_BILLING' => const String.fromEnvironment(
          'DISABLE_GOOGLE_PLAY_BILLING',
          defaultValue: 'false',
        ),
      'ENABLE_FACEBOOK_AUTH' => const String.fromEnvironment(
          'ENABLE_FACEBOOK_AUTH',
          defaultValue: 'false',
        ),
      _ => '',
    };

    return _normalize(value);
  }

  static String sourceOf(String key) {
    final runtimeValue = _runtimeConfig[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return 'android-runtime';
    }

    final dotenvValue = _dotenvConfig[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return '.env';
    }

    final compileTimeValue = _readCompileTimeValue(key);
    if (compileTimeValue.isNotEmpty) {
      return 'dart-define';
    }

    return 'missing';
  }

  static bool get hasAiBackendConfigured => read('AI_BASE_URL').isNotEmpty;

  static void _validateAiConfiguration() {
    final aiBaseUrl = read('AI_BASE_URL');
    if (aiBaseUrl.isEmpty) {
      _logConfig(
        'AI_BASE_URL is missing; AI Assistant backend will remain unavailable.',
        details: <String, Object?>{'source': sourceOf('AI_BASE_URL')},
      );
      return;
    }

    final uri = Uri.tryParse(aiBaseUrl);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
      _logConfig(
        'AI_BASE_URL is present but invalid; AI Assistant requests will be disabled.',
        details: <String, Object?>{
          'source': sourceOf('AI_BASE_URL'),
          'value': aiBaseUrl,
        },
      );
    }
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

  static String _readCompileTimeValue(String key) {
    final value = switch (key) {
      'OTP_BASE_URL' => const String.fromEnvironment('OTP_BASE_URL'),
      'OTP_SEND_URL' => const String.fromEnvironment('OTP_SEND_URL'),
      'OTP_VERIFY_URL' => const String.fromEnvironment('OTP_VERIFY_URL'),
      'OTP_DEBUG_CODE' => const String.fromEnvironment('OTP_DEBUG_CODE'),
      'FACEBOOK_APP_ID' => const String.fromEnvironment('FACEBOOK_APP_ID'),
      'FACEBOOK_CLIENT_TOKEN' =>
        const String.fromEnvironment('FACEBOOK_CLIENT_TOKEN'),
      'LINKEDIN_PROVIDER_ID' =>
        const String.fromEnvironment('LINKEDIN_PROVIDER_ID'),
      'FIREBASE_ANDROID_CERTIFICATE_HASHES' => const String.fromEnvironment(
          'FIREBASE_ANDROID_CERTIFICATE_HASHES',
        ),
      'PACKAGE_SHA1' => const String.fromEnvironment('PACKAGE_SHA1'),
      'PACKAGE_SHA256' => const String.fromEnvironment('PACKAGE_SHA256'),
      'FACEBOOK_KEY_HASH' => const String.fromEnvironment('FACEBOOK_KEY_HASH'),
      'PLAY_WEEKLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_WEEKLY_PRODUCT_ID',
          defaultValue: 'weekly_pro',
        ),
      'PLAY_MONTHLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_MONTHLY_PRODUCT_ID',
          defaultValue: 'monthly_pro',
        ),
      'PLAY_QUARTERLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_QUARTERLY_PRODUCT_ID',
          defaultValue: 'quarterly_pro',
        ),
      'PLAY_YEARLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_YEARLY_PRODUCT_ID',
          defaultValue: 'yearly_pro',
        ),
      'AI_BASE_URL' => const String.fromEnvironment('AI_BASE_URL'),
      'AI_ENV' => const String.fromEnvironment('AI_ENV'),
      'RAZORPAY_KEY_ID' => const String.fromEnvironment('RAZORPAY_KEY_ID'),
      'ENABLE_DUMMY_PAYMENTS' => const String.fromEnvironment(
          'ENABLE_DUMMY_PAYMENTS',
          defaultValue: 'false',
        ),
      'DISABLE_GOOGLE_PLAY_BILLING' => const String.fromEnvironment(
          'DISABLE_GOOGLE_PLAY_BILLING',
          defaultValue: 'false',
        ),
      'ENABLE_FACEBOOK_AUTH' => const String.fromEnvironment(
          'ENABLE_FACEBOOK_AUTH',
          defaultValue: 'false',
        ),
      _ => '',
    };

    return _normalize(value);
  }

  static void _logConfig(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    final suffix = details.isEmpty ? '' : ' | ${details.toString()}';
    developer.log(
      '$message$suffix',
      name: 'AppConfigService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Map<String, String> _parseDotEnv(String raw) {
    final values = <String, String>{};
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = trimmed.substring(0, separatorIndex).trim();
      final value = trimmed.substring(separatorIndex + 1);
      values[key] = _normalize(value);
    }
    return values;
  }
}
