class UserSessionService {
  const UserSessionService._();

  static const String _contactKey = 'user_contact';
  static const String _countryCodeKey = 'user_country_code';
  static const String _legacySavedPhoneKey = 'saved_phone';

  static String readStoredContact(dynamic prefs) {
    final contact = prefs.getString(_contactKey)?.trim() ?? '';
    if (contact.isNotEmpty) {
      return contact;
    }
    return prefs.getString(_legacySavedPhoneKey)?.trim() ?? '';
  }

  static Future<void> persistPhoneSession(
    dynamic prefs,
    String phone,
  ) async {
    await prefs.setBool('is_logged_in', true);
    await prefs.setString(_contactKey, maskPhoneNumber(phone));
    final countryCode = inferCountryCodeFromContact(phone);
    if (countryCode == null) {
      await prefs.remove(_countryCodeKey);
    } else {
      await prefs.setString(_countryCodeKey, countryCode);
    }
    await prefs.remove(_legacySavedPhoneKey);
  }

  static Future<void> persistSocialContact(
    dynamic prefs,
    String contact,
  ) async {
    final trimmed = contact.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_contactKey);
    } else {
      await prefs.setString(_contactKey, trimmed);
    }
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_legacySavedPhoneKey);
  }

  static Future<void> clearStoredContact(dynamic prefs) async {
    await prefs.remove(_contactKey);
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_legacySavedPhoneKey);
  }

  static String? readStoredCountryCode(dynamic prefs) {
    final stored = prefs.getString(_countryCodeKey)?.trim().toUpperCase();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    return inferCountryCodeFromContact(readStoredContact(prefs));
  }

  static String formatContactForDisplay(String contact) {
    final trimmed = contact.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.contains('@') || trimmed.contains('•')) {
      return trimmed;
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return trimmed;
    }
    return maskPhoneNumber(trimmed);
  }

  static String maskPhoneNumber(String phone) {
    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Phone verified';
    }

    final visible =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final countryCodeDigits = digits.length > 10 ? digits.substring(0, digits.length - 10) : '';
    final prefix = trimmed.startsWith('+') && countryCodeDigits.isNotEmpty
        ? '+$countryCodeDigits'
        : 'Phone';

    return '$prefix •••• $visible';
  }

  static String? inferCountryCodeFromContact(String contact) {
    final trimmed = contact.trim();
    if (trimmed.isEmpty || trimmed.contains('@')) {
      return null;
    }

    if (trimmed.startsWith('+971')) {
      return 'AE';
    }
    if (trimmed.startsWith('+91')) {
      return 'IN';
    }
    if (trimmed.startsWith('+81')) {
      return 'JP';
    }
    if (trimmed.startsWith('+65')) {
      return 'SG';
    }
    if (trimmed.startsWith('+61')) {
      return 'AU';
    }
    if (trimmed.startsWith('+49')) {
      return 'DE';
    }
    if (trimmed.startsWith('+44')) {
      return 'GB';
    }
    if (trimmed.startsWith('+33')) {
      return 'FR';
    }
    if (trimmed.startsWith('+1')) {
      return 'US';
    }

    return null;
  }
}