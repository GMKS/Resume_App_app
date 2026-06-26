import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> enableTwoFactorAuth(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('2fa_enabled', enabled);
  }
}
