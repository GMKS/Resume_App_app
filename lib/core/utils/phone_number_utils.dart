import 'package:flutter/services.dart';

class PhoneNumberUtils {
  PhoneNumberUtils._();

  static const int localNumberLength = 10;

  static final List<TextInputFormatter> localNumberInputFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(localNumberLength),
  ];

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String normalizeLocalNumber(String value) {
    final digits = digitsOnly(value);
    if (digits.length <= localNumberLength) {
      return digits;
    }
    return digits.substring(0, localNumberLength);
  }

  static bool isValidLocalNumber(String value) {
    return digitsOnly(value).length == localNumberLength;
  }

  static String? validateLocalNumber(
    String? value, {
    bool required = false,
  }) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) {
      return required ? 'Please enter a valid 10-digit phone number' : null;
    }
    if (digits.length != localNumberLength) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String formatInternational(
    String countryCode,
    String localNumber, {
    bool includeSpace = false,
  }) {
    final codeDigits = digitsOnly(countryCode);
    final normalizedLocal = normalizeLocalNumber(localNumber);
    if (codeDigits.isEmpty) {
      return normalizedLocal;
    }
    final separator = includeSpace && normalizedLocal.isNotEmpty ? ' ' : '';
    return '+$codeDigits$separator$normalizedLocal';
  }

  static bool isValidInternationalNumber(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('+')) {
      return false;
    }

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
    final digits = digitsOnly(normalized);
    if (digits.length <= localNumberLength) {
      return false;
    }

    final localDigits = digits.substring(digits.length - localNumberLength);
    final countryDigits = digits.substring(0, digits.length - localNumberLength);
    return countryDigits.isNotEmpty &&
        countryDigits.length <= 4 &&
        localDigits.length == localNumberLength;
  }
}