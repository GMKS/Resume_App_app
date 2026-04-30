import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OTPVerificationWidget extends StatefulWidget {
  final Color cardColor;
  final String phone;
  final Function(String) onSubmit;
  final Function() onResend;
  final Function() onBack;
  final bool isDarkMode;

  const OTPVerificationWidget({
    super.key,
    required this.cardColor,
    required this.phone,
    required this.onSubmit,
    required this.onResend,
    required this.onBack,
    required this.isDarkMode,
  });

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _fadeAnimation;
  final int _resendCountdown = 60;
  late int _secondsRemaining;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _fadeAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _secondsRemaining = _resendCountdown;
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _fadeAnimation.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
        });
        if (_secondsRemaining > 0) {
          _startResendCountdown();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _handleOTPInput(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[0];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit if all fields are filled
    if (_isOTPComplete()) {
      _submitOTP();
    }
  }

  bool _isOTPComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getOTP() {
    return _controllers.map((c) => c.text).join();
  }

  void _submitOTP() {
    if (_isOTPComplete()) {
      widget.onSubmit(_getOTP());
    }
  }

  void _handleResend() {
    if (_canResend) {
      // Clear OTP fields
      for (var controller in _controllers) {
        controller.clear();
      }
      setState(() {
        _canResend = false;
        _secondsRemaining = _resendCountdown;
      });
      _focusNodes[0].requestFocus();
      widget.onResend();
      _startResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 390 ? 16.0 : 24.0;

    return FadeTransition(
      opacity: _fadeAnimation.drive(
        Tween<double>(begin: 0, end: 1),
      ),
      child: Card(
        elevation: 8,
        color: widget.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify OTP',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          'Sent to ${widget.phone}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // OTP Input Fields
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = constraints.maxWidth < 300 ? 4.0 : 8.0;
                  final rawWidth = (constraints.maxWidth - (spacing * 5)) / 6;
                  final fieldWidth = rawWidth.clamp(38.0, 48.0);
                  final fieldHeight = constraints.maxWidth < 300 ? 52.0 : 56.0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == 5 ? 0 : spacing,
                        ),
                        child: _buildOTPField(
                          index,
                          width: fieldWidth,
                          height: fieldHeight,
                        ),
                      );
                    }),
                  );
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: const Duration(milliseconds: 600),
                  ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isOTPComplete() ? _submitOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Verify OTP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _isOTPComplete()
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ).animate().slideY(
                  begin: 0.2, duration: const Duration(milliseconds: 600)),

              const SizedBox(height: 16),

              // Resend Section
              Center(
                child: Column(
                  children: [
                    if (!_canResend) ...[
                      Text(
                        'Didn\'t receive? Resend in',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          '${_secondsRemaining}s',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ] else
                      GestureDetector(
                        onTap: _handleResend,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Didn\'t receive the code? ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            Text(
                              'Resend it',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                          ),
                  ],
                ),
              ).animate().slideY(
                  begin: 0.15, duration: const Duration(milliseconds: 700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(
    int index, {
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == _controllers.length - 1
            ? TextInputAction.done
            : TextInputAction.next,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.blue.shade600,
              width: 2,
            ),
          ),
          filled: true,
          fillColor:
              widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        onChanged: (value) => _handleOTPInput(index, value),
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 600),
        )
        .then()
        .scale(
            duration: const Duration(milliseconds: 300),
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0));
  }
}
