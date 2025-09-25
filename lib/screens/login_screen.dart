import 'package:flutter/material.dart';
import 'package:linkedin_login/linkedin_login.dart';
import '../services/auth_service.dart';
import '../widgets/mobile_login_widgets.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;
  int _selectedTab = 0; // 0 for email, 1 for mobile

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('remember_email');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _email.text = saved;
        _rememberMe = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final ok = await AuthService.instance.login(
      _email.text.trim(),
      _pass.text.trim(),
    );
    setState(() => _loading = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remember_email', _email.text.trim());
    } else {
      await prefs.remove('remember_email');
    }
    loggedInNotifier.value = true;
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text('Password recovery is not configured.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Up'),
        content: const Text('Sign up flow not implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFirebaseAuth() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (context) => const AuthScreen()));

    if (result == true) {
      loggedInNotifier.value = true;
    }
  }

  Widget _gradientField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FF), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87, fontSize: 13.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _socialIconButton({
    required Color color,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // NEW vibrant pink/purple layered background (replaces old indigo gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF35C9F), // top-left pink
                  Color(0xFF8E46FF), // mid violet
                  Color(0xFF5B2DE1), // deep purple bottom-right
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative radial glow
          Positioned(
            top: -140,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x33FFFFFF),
                    Color(0x11FFFFFF),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22FFFFFF), Colors.transparent],
                  radius: 0.9,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // NEW BRAND HEADER (ResuMate + caption)
                      Column(
                        children: [
                          // Logo placeholder circle
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFCFE3), Color(0xFFE7B4FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.insert_drive_file_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'ResuMate',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Build • Polish • Share',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: .4,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      // Optional welcome line (kept subtle)
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tab selector for Email/Mobile login
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: _selectedTab == 0
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                  ),
                                  child: const Text(
                                    'Email Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: _selectedTab == 1
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                  ),
                                  child: const Text(
                                    'Mobile Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Login form content based on selected tab
                      if (_selectedTab == 0) ...[
                        // Email login form
                        _gradientField(
                          controller: _email,
                          label: 'Username / Email',
                          keyboard: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _gradientField(
                          controller: _pass,
                          label: 'Password',
                          obscure: true,
                          validator: (v) => (v == null || v.length < 3)
                              ? 'Min 3 chars'
                              : null,
                        ),
                        const SizedBox(height: 26),
                        // UPDATED LOGIN BUTTON (new color / subtle gradient)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5F11E8), Color(0xFF8E3DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .8,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                visualDensity: VisualDensity.compact,
                                activeColor: const Color(0xFF8E3DFF),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _forgotPassword,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFFFFE4FF),
                                    fontSize: 12.5,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile login form
                        MobileLoginForm(
                          onLoginSuccess: () {
                            loggedInNotifier.value = true;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: .55,
                        child: Row(
                          children: const [
                            Expanded(child: Divider(color: Colors.white54)),
                            SizedBox(width: 28),
                            Expanded(child: Divider(color: Colors.white54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialIconButton(
                            tooltip: 'Login with Facebook',
                            color: const Color(0xFF1877F2),
                            icon: Icons.facebook,
                            onTap: () async {
                              final ok = await AuthService.instance
                                  .signInWithFacebook();
                              if (!ok) {
                                _toast('Facebook login failed');
                              } else {
                                loggedInNotifier.value = true;
                              }
                            },
                          ),
                          const SizedBox(width: 18),
                          _socialIconButton(
                            tooltip: 'Login with Google',
                            color: const Color(0xFFDB4437),
                            icon: Icons
                                .g_mobiledata, // You could use a custom G icon asset
                            onTap: () async {
                              final ok = await AuthService.instance
                                  .signInWithGoogle();
                              if (!ok) {
                                _toast('Google login failed');
                              } else {
                                loggedInNotifier.value = true;
                              }
                            },
                          ),
                          const SizedBox(width: 18),
                          _socialIconButton(
                            tooltip: 'Login with LinkedIn',
                            color: const Color(0xFF0A66C2),
                            icon: Icons
                                .link, // replace with custom LinkedIn icon asset if desired
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LinkedInUserWidget(
                                    destroySession: true,
                                    redirectUrl:
                                        'https://YOUR_REDIRECT_URL', // TODO: set real redirect URL
                                    clientId:
                                        'YOUR_LINKEDIN_CLIENT_ID', // TODO: set real client id
                                    clientSecret:
                                        'YOUR_LINKEDIN_CLIENT_SECRET', // TODO: set real client secret
                                    onGetUserProfile:
                                        (UserSucceededAction action) {
                                          final profile = action.user;
                                          final email =
                                              profile
                                                  .email
                                                  ?.elements
                                                  ?.first
                                                  .handleDeep
                                                  ?.emailAddress ??
                                              '${profile.userId}@linkedin.local';
                                          AuthService.instance
                                              .completeLinkedInLogin(email)
                                              .then((_) {
                                                if (Navigator.canPop(context)) {
                                                  Navigator.pop(context);
                                                }
                                                loggedInNotifier.value = true;
                                              });
                                        },
                                    onError: (UserFailedAction err) {
                                      _toast('LinkedIn login failed');
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Firebase Authentication Option
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _openFirebaseAuth,
                          icon: const Icon(Icons.security, size: 20),
                          label: const Text(
                            'Sign in with Firebase',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an Account?  ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          InkWell(
                            onTap: _signup,
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
