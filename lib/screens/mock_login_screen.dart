import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mock_auth_service.dart';
import '../main_no_firebase.dart';
import 'mock_home_screen.dart';

class MockLoginScreen extends StatefulWidget {
  const MockLoginScreen({super.key});

  @override
  State<MockLoginScreen> createState() => _MockLoginScreenState();
}

class _MockLoginScreenState extends State<MockLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();

  bool _loading = false;
  bool _rememberMe = false;
  int _selectedTab = 0; // 0 for email, 1 for mobile
  bool _otpSent = false;

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

  Future<void> _submitEmail() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final success = await MockAuthService.instance.login(
      _email.text.trim(),
      _pass.text.trim(),
    );

    setState(() => _loading = false);

    if (success) {
      if (_rememberMe) {
        final p = await SharedPreferences.getInstance();
        await p.setString('remember_email', _email.text.trim());
      }

      // Update login state
      loggedInNotifier.value = true;

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MockHomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendOTP() async {
    if (_mobile.text.trim().isEmpty || _mobile.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final success = await MockAuthService.instance.sendOTP(_mobile.text.trim());

    setState(() {
      _loading = false;
      _otpSent = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP sent to ${_mobile.text.trim()}! Use any 6-digit number to verify.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otp.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final otpValid = await MockAuthService.instance.verifyOTP(_otp.text.trim());

    if (otpValid) {
      final success = await MockAuthService.instance.loginWithMobile(
        _mobile.text.trim(),
      );

      setState(() => _loading = false);

      if (success) {
        loggedInNotifier.value = true;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MockHomeScreen()),
          );
        }
      }
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _loading = true);

    bool success = false;
    switch (provider) {
      case 'google':
        success = await MockAuthService.instance.signInWithGoogle();
        break;
      case 'facebook':
        success = await MockAuthService.instance.signInWithFacebook();
        break;
      case 'linkedin':
        success = await MockAuthService.instance.signInWithLinkedIn();
        break;
    }

    setState(() => _loading = false);

    if (success) {
      loggedInNotifier.value = true;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MockHomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$provider login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login - Mock Mode'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Mock Mode Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'MOCK MODE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This is a test version. Use any email/password (min 4 chars) or mobile number to login.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Tab Selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? Colors.purple
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Email Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? Colors.purple
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mobile Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Email Login Tab
              if (_selectedTab == 0) ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.contains('@') != true ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v?.length ?? 0) < 4 ? 'Min 4 characters' : null,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  title: const Text('Remember me'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submitEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login with Email'),
                ),
              ],

              // Mobile Login Tab
              if (_selectedTab == 1) ...[
                TextFormField(
                  controller: _mobile,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading || _otpSent ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_otpSent ? 'OTP Sent' : 'Send OTP'),
                ),

                if (_otpSent) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _otp,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.sms),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify OTP & Login'),
                  ),
                ],
              ],

              const SizedBox(height: 30),

              // Social Login Options
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Or login with:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Google Login
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _socialLogin('google'),
                icon: const Icon(Icons.login),
                label: const Text('Login with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 10),

              // Facebook Login
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _socialLogin('facebook'),
                icon: const Icon(Icons.facebook),
                label: const Text('Login with Facebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 10),

              // LinkedIn Login
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _socialLogin('linkedin'),
                icon: const Icon(Icons.work),
                label: const Text('Login with LinkedIn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
