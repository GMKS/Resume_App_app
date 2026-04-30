import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/social_auth_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';

/// Displays the "Or continue with" divider and the four social brand icon buttons
/// (Facebook, Twitter/X, LinkedIn, Google).
class SocialLoginButtons extends StatefulWidget {
  /// Called with `true` on success, `false` + optional [errorMsg] on failure.
  final void Function({required bool success, String? errorMsg}) onResult;

  const SocialLoginButtons({super.key, required this.onResult});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  final SocialAuthService _service = SocialAuthService();
  bool _loading = false;
  String? _activeProvider; // which button shows a spinner

  Future<void> _handleSocial(
      String provider, Future<SocialAuthResult> Function() signIn) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _activeProvider = provider;
    });

    final result = await signIn();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _activeProvider = null;
    });

    widget.onResult(success: result.success, errorMsg: result.message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── "Or continue with" divider ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        // ── Four brand icon buttons ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialCircleButton(
              icon: FontAwesomeIcons.facebookF,
              color: const Color(0xFF1877F2),
              label: 'Facebook',
              loading: _activeProvider == 'facebook',
              onTap: () => _handleSocial(
                'facebook',
                _service.signInWithFacebook,
              ),
            ),
            const SizedBox(width: 16),
            _SocialCircleButton(
              icon: FontAwesomeIcons.xTwitter,
              color: const Color(0xFF000000),
              label: 'Twitter/X',
              loading: _activeProvider == 'twitter',
              onTap: () => _handleSocial(
                'twitter',
                _service.signInWithTwitter,
              ),
            ),
            const SizedBox(width: 16),
            _SocialCircleButton(
              icon: FontAwesomeIcons.linkedinIn,
              color: const Color(0xFF0A66C2),
              label: 'LinkedIn',
              loading: _activeProvider == 'linkedin',
              onTap: () => _handleSocial(
                'linkedin',
                _service.signInWithLinkedIn,
              ),
            ),
            const SizedBox(width: 16),
            _SocialCircleButton(
              icon: FontAwesomeIcons.googlePlusG,
              color: const Color(0xFFDD4B39),
              label: 'Google',
              loading: _activeProvider == 'google',
              onTap: () => _handleSocial(
                'google',
                _service.signInWithGoogle,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual circular brand button
// ─────────────────────────────────────────────────────────────────────────────
class _SocialCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _SocialCircleButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTooltip(
      message: label,
      button: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          onTap: loading ? null : onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : FaIcon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
