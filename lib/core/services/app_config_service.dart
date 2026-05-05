class AppConfigService {
  const AppConfigService._();

  static String read(String key) {
    final value = switch (key) {
      'OTP_SEND_URL' => const String.fromEnvironment('OTP_SEND_URL'),
      'OTP_VERIFY_URL' => const String.fromEnvironment('OTP_VERIFY_URL'),
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