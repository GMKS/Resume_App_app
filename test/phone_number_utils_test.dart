import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/utils/phone_number_utils.dart';

void main() {
  test('normalizes local phone numbers to 10 digits', () {
    expect(
      PhoneNumberUtils.normalizeLocalNumber('98765-43210'),
      '9876543210',
    );
    expect(
      PhoneNumberUtils.normalizeLocalNumber('9876543210123'),
      '9876543210',
    );
  });

  test('validates exact 10-digit local numbers', () {
    expect(PhoneNumberUtils.isValidLocalNumber('9876543210'), isTrue);
    expect(PhoneNumberUtils.isValidLocalNumber('987654321'), isFalse);
    expect(PhoneNumberUtils.isValidLocalNumber('98765432101'), isFalse);
  });

  test('formats and validates international numbers with country code', () {
    final formatted = PhoneNumberUtils.formatInternational('+91', '9876543210');

    expect(formatted, '+919876543210');
    expect(PhoneNumberUtils.isValidInternationalNumber(formatted), isTrue);
    expect(
      PhoneNumberUtils.isValidInternationalNumber('+91 9876543210'),
      isTrue,
    );
    expect(PhoneNumberUtils.isValidInternationalNumber('9876543210'), isFalse);
  });
}