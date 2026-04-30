import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resume_builder/core/services/twilio_service.dart';
import '../widgets/otp_verification_widget.dart';
import '../widgets/phone_entry_widget.dart';
import '../widgets/loading_animation_widget.dart';
import '../widgets/social_login_buttons.dart';

class TwilioLoginScreen extends StatefulWidget {
  const TwilioLoginScreen({super.key});

  @override
  State<TwilioLoginScreen> createState() => _TwilioLoginScreenState();
}

class _TwilioLoginScreenState extends State<TwilioLoginScreen> with SingleTickerProviderStateMixin {
  final TwilioService _twilioService = TwilioService();
  late AnimationController _fadeController;

  String _phone = '';
  bool _isPhoneEntered = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isFlashLoading = false;
  String _savedPhone = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final phone = prefs.getString('saved_phone') ?? '';
    if (!mounted) return;
    if (isLoggedIn && phone.isNotEmpty) {
      setState(() {
        _isFlashLoading = true;
        _savedPhone = phone;
      });
      // Brief flash, then navigate
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneSubmit(String phone) async {
    if (!_twilioService.isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _twilioService.sendOTP(phone);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _phone = phone;
        _isPhoneEntered = true;
        _isLoading = false;
      });

      _fadeController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent to your phone'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _handleOTPSubmit(String otp) async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _twilioService.verifyOTP(_phone, otp);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      // Play success animation
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Login successful!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );

        // Save login session for flash login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('saved_phone', _phone);

        // Navigate to dashboard after success
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _twilioService.resendOTP(_phone);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New OTP sent to your phone'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _handleBackToPhone() {
    _fadeController.reverse().then((_) {
      setState(() {
        _isPhoneEntered = false;
        _phone = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final backgroundColor = isDarkMode ? Colors.black87 : Colors.grey.shade100;

    // Flash login: auto-navigate if session exists
    if (_isFlashLoading) {
      return _buildFlashScreen(isDarkMode);
    }

    // On web, show a skip-to-dashboard option since SMS OTP requires mobile
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Card(
                elevation: 8,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_android, size: 64, color: Colors.blue.shade600),
                      const SizedBox(height: 20),
                      Text(
                        'Mobile App Required',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SMS OTP login requires the mobile app.\nYou are currently on web preview.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Continue to Dashboard (Web Preview)',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo/Title Animation
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(duration: const Duration(milliseconds: 2000), begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05))
                        .then()
                        .scale(duration: const Duration(milliseconds: 2000), begin: const Offset(1.05, 1.05), end: const Offset(0.95, 0.95)),
                    const SizedBox(height: 24),
                    Text(
                      'Secure Login',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(duration: const Duration(milliseconds: 600)),
                    const SizedBox(height: 8),
                    Text(
                      _isPhoneEntered
                          ? 'Enter verification code'
                          : 'Enter your phone number',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ).animate().fadeIn(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 600),
                        ),
                  ],
                ),

                const SizedBox(height: 48),

                // Card Container with Animation
                if (_isSuccess)
                  _buildSuccessCard(isDarkMode)
                else if (_isLoading)
                  _buildLoadingCard()
                else if (!_isPhoneEntered)
                  PhoneEntryWidget(
                    cardColor: cardColor,
                    onSubmit: _handlePhoneSubmit,
                    isDarkMode: isDarkMode,
                  )
                else
                  ScaleTransition(
                    scale: _fadeController.view,
                    child: FadeTransition(
                      opacity: _fadeController.view,
                      child: OTPVerificationWidget(
                        cardColor: cardColor,
                        phone: _phone,
                        onSubmit: _handleOTPSubmit,
                        onResend: _handleResendOTP,
                        onBack: _handleBackToPhone,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // ── Social Login ────────────────────────────────
                if (!_isPhoneEntered && !_isLoading && !_isSuccess)
                  SocialLoginButtons(
                    onResult: ({required bool success, String? errorMsg}) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Login successful!'),
                              ],
                            ),
                            backgroundColor: Colors.green.shade600,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) context.go('/dashboard');
                        });
                      } else if (errorMsg != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMsg,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 6),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  ),

                const SizedBox(height: 24),

                // Footer
                if (!_isSuccess && !_isLoading)
                  Column(
                    children: [
                      Text(
                        'Your data is encrypted and secure',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 600),
                          ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'End-to-End Encrypted',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 600),
                          ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashScreen(bool isDarkMode) {
    // Mask phone: +91XXXXX5678 → +91 ••••• 5678
    final masked = _savedPhone.length > 4
        ? '${_savedPhone.substring(0, 3)} ••••• ${_savedPhone.substring(_savedPhone.length - 4)}'
        : _savedPhone;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated shield icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 52),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: const Duration(milliseconds: 900),
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.08, 1.08),
                    curve: Curves.easeInOut,
                  )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400)),

              const SizedBox(height: 32),

              const Text(
                'Welcome Back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, duration: 500.ms),

              const SizedBox(height: 12),

              Text(
                masked,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 48),

              // Glowing progress bar
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 20),

              Text(
                'Signing you in securely...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingAnimationWidget(),
            const SizedBox(height: 24),
            Text(
              _isPhoneEntered ? 'Verifying OTP...' : 'Sending OTP...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          duration: const Duration(milliseconds: 600),
        );
  }

  Widget _buildSuccessCard(bool isDarkMode) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ).animate().scale(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            Text(
              'Login Successful!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 600),
                ),
            const SizedBox(height: 8),
            Text(
              'Redirecting to your resume...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                  ),
            ).animate().fadeIn(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 600),
                ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.2,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuad,
        );
  }
}
