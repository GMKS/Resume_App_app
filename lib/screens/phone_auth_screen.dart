import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:pinput/pinput.dart';
import '../services/firebase_auth_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _countryCode = '+1';
  String _verificationId = '';
  bool _isLoading = false;
  bool _isOtpSent = false;
  int? _resendToken;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isOtpSent) ...[
              _buildPhoneInputSection(),
            ] else ...[
              _buildOtpInputSection(),
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      children: [
        const Icon(Icons.phone_android, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'Enter your phone number',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will send you a verification code',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Production info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 SMS Verification Active',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Enter your real phone number to receive SMS',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
              Text(
                'Standard SMS rates may apply',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone number input with country picker
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CountryCodePicker(
                onChanged: (country) {
                  setState(() {
                    _countryCode = country.dialCode!;
                  });
                },
                initialSelection: 'US',
                favorite: const ['+1', 'US'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send OTP', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection() {
    return Column(
      children: [
        const Icon(Icons.sms, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'Enter verification code',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to $_countryCode ${_phoneController.text}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),

        // OTP input
        Pinput(
          controller: _otpController,
          length: 6,
          showCursor: true,
          onCompleted: (pin) => _verifyOtp(),
          defaultPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: const TextStyle(
              fontSize: 20,
              color: Color.fromRGBO(30, 60, 87, 1),
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: const TextStyle(
              fontSize: 20,
              color: Color.fromRGBO(30, 60, 87, 1),
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
          ),
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text('Resend OTP'),
        ),

        TextButton(
          onPressed: () {
            setState(() {
              _isOtpSent = false;
              _errorMessage = '';
              _otpController.clear();
            });
          },
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final phoneNumber = _countryCode + _phoneController.text.trim();

    try {
      await FirebaseAuthService.sendPhoneOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          try {
            final result = await FirebaseAuth.instance.signInWithCredential(
              credential,
            );
            if (result.user != null && mounted) {
              Navigator.of(context).pop(true); // Return success
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Auto-verification failed: $e';
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            if (e.code == 'billing-not-enabled' ||
                e.message?.contains('BILLING_NOT_ENABLED') == true) {
              _errorMessage = '''
Phone verification requires a paid Firebase plan.
Please try:
• Email/Password sign in instead
• Contact support for assistance
• Enable billing in Firebase Console''';
            } else {
              _errorMessage = 'Verification failed: ${e.message}';
            }
            _isLoading = false;
          });

          // Show dialog for billing issues
          if (e.code == 'billing-not-enabled' ||
              e.message?.contains('BILLING_NOT_ENABLED') == true) {
            _showBillingErrorDialog();
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FirebaseAuthService.verifyPhoneOTP(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      if (result?.user != null && mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isLoading = false;
      });
    }
  }

  void _showBillingErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Phone Authentication Unavailable'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone verification requires a paid Firebase plan.'),
              SizedBox(height: 16),
              Text('Alternative options:'),
              SizedBox(height: 8),
              Text('• Use Email/Password authentication'),
              Text('• Enable billing in Firebase Console'),
              Text('• Use Firebase emulator for testing'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Use Email Sign-In'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
