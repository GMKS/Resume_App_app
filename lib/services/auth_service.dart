import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _loggedInKey = 'logged_in_email';
  String? _email;

  String? get currentUser => _email;
  bool get isLoggedIn => _email != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_loggedInKey); // null on fresh install
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, email);
    _email = email;
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    _email = null;
  }
}
