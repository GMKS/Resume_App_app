import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/services/user_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persistPhoneSession stores inferred India country code', () async {
    final prefs = await SharedPreferences.getInstance();

    await UserSessionService.persistPhoneSession(prefs, '+919876543210');

    expect(UserSessionService.readStoredCountryCode(prefs), 'IN');
    expect(UserSessionService.readStoredContact(prefs), contains('+91'));
  });

  test('readStoredCountryCode can infer country from masked legacy contact', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_contact', '+91 •••• 3210');

    expect(UserSessionService.readStoredCountryCode(prefs), 'IN');
  });
}