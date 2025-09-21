import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:linkedin_login/linkedin_login.dart'; // OAuth screen widget (LinkedIn)
// NOTE: For LinkedIn we will just store email from result; configure keys in LinkedIn dev portal.

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _loggedInKey = 'logged_in_email';
  String? _email;

  String? get currentUser => _email;
  bool get isLoggedIn => _email != null;

  // Always call with alwaysFresh: true to force showing Login
  Future<void> init({bool alwaysFresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (alwaysFresh) {
      await prefs.remove(_loggedInKey);
      _email = null;
      return;
    }
    _email = prefs.getString(_loggedInKey);
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || !email.contains('@') || password.length < 3)
      return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, email);
    _email = email;
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    _email = null;
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final g = GoogleSignIn(scopes: ['email']);
      final acct = await g.signIn();
      if (acct == null) return false;
      final prefs = await SharedPreferences.getInstance();
      _email = acct.email;
      await prefs.setString(_loggedInKey, _email!);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: ['email']);
      if (result.status != LoginStatus.success) return false;
      final data = await FacebookAuth.instance.getUserData(
        fields: "email,name",
      );
      final email = data['email'] ?? '${data['id']}@facebook.local';
      final prefs = await SharedPreferences.getInstance();
      _email = email;
      await prefs.setString(_loggedInKey, _email!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // LinkedIn uses an external screen; just helper to store email once retrieved.
  Future<void> completeLinkedInLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _email = email;
    await prefs.setString(_loggedInKey, _email!);
  }
}
