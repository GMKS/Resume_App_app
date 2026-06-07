import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfigService {
  const AppConfigService._();

  static const MethodChannel _channel =
      MethodChannel('resume_builder/app_config');
  static Map<String, String> _runtimeConfig = <String, String>{};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final config =
            await _channel.invokeMapMethod<String, dynamic>('getConfig');
        if (config != null) {
          _runtimeConfig = config.map(
            (key, value) => MapEntry(key, _normalize(value?.toString() ?? '')),
          );
        }
      } catch (_) {
        _runtimeConfig = <String, String>{};
      }
    }

    _initialized = true;
  }

  static String read(String key) {
    final runtimeValue = _runtimeConfig[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }

    final value = switch (key) {
      'OTP_SEND_URL' => const String.fromEnvironment('OTP_SEND_URL'),
      'OTP_VERIFY_URL' => const String.fromEnvironment('OTP_VERIFY_URL'),
      'OTP_DEBUG_CODE' => const String.fromEnvironment('OTP_DEBUG_CODE'),
      'PLAY_WEEKLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_WEEKLY_PRODUCT_ID',
        ),
      'PLAY_MONTHLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_MONTHLY_PRODUCT_ID',
        ),
      'PLAY_QUARTERLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_QUARTERLY_PRODUCT_ID',
        ),
      'PLAY_YEARLY_PRODUCT_ID' => const String.fromEnvironment(
          'PLAY_YEARLY_PRODUCT_ID',
        ),
      'GROQ_API_KEY' => const String.fromEnvironment('GROQ_API_KEY'),
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
}
