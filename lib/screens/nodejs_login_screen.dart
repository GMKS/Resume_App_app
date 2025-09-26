import 'package:flutter/material.dart';
import '../services/hybrid_auth_service.dart';
import 'simple_home_screen.dart';

class NodeJSLoginScreen extends StatefulWidget {
  const NodeJSLoginScreen({super.key});

  @override
  State<NodeJSLoginScreen> createState() => _NodeJSLoginScreenState();
}

class _NodeJSLoginScreenState extends State<NodeJSLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _isOTPMode = false;
  String _statusMessage = '';
  String _otpIdentifier = '';

  final HybridAuthService _authService = HybridAuthService();

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.init();
    await _authService.switchProvider(AuthProvider.nodejs);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final result = await _authService.loginWithNodeJS(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SimpleHomeScreen()),
        );
      } else {
        setState(() {
          _statusMessage = result['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final result = await _authService.registerWithNodeJS(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _statusMessage = 'Registration successful! Please verify your email.';
        });
        // Auto-switch to login mode after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isRegisterMode = false;
              _statusMessage = 'Please login with your credentials';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage = result['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email or phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final result = await _authService.sendOTP(
        identifier: _emailController.text.trim(),
        type: 'login',
      );

      if (result['success'] == true) {
        setState(() {
          _isOTPMode = true;
          _otpIdentifier = _emailController.text.trim();
          _statusMessage =
              'OTP sent successfully! Check your ${_emailController.text.contains('@') ? 'email' : 'phone'}.';
        });
      } else {
        setState(() {
          _statusMessage = result['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() {
        _statusMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final result = await _authService.verifyOTP(
        identifier: _otpIdentifier,
        otp: _otpController.text.trim(),
      );

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SimpleHomeScreen()),
        );
      } else {
        setState(() {
          _statusMessage = result['message'] ?? 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo and Title
                const Icon(Icons.description, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  'Resume Builder',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isOTPMode
                      ? 'Verify OTP'
                      : (_isRegisterMode ? 'Create Account' : 'Welcome Back'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Status Message
                if (_statusMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _statusMessage.contains('successful') ||
                              _statusMessage.contains('sent')
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _statusMessage.contains('successful') ||
                                _statusMessage.contains('sent')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color:
                            _statusMessage.contains('successful') ||
                                _statusMessage.contains('sent')
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // OTP Mode
                if (_isOTPMode) ...[
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '6-digit code',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'Please enter a valid 6-digit OTP';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify OTP'),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isOTPMode = false;
                        _otpController.clear();
                        _statusMessage = '';
                      });
                    },
                    child: const Text('Back to Login'),
                  ),
                ]
                // Register Mode
                else if (_isRegisterMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'your@email.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: '+919876543210',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account'),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = false;
                        _statusMessage = '';
                      });
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ]
                // Login Mode
                else ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email or Phone',
                      hintText: 'your@email.com or +919876543210',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or phone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Login with OTP'),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = true;
                        _statusMessage = '';
                      });
                    },
                    child: const Text('Don\'t have an account? Register'),
                  ),
                ],

                const SizedBox(height: 40),

                // Backend Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🚀 Powered by Node.js Backend\n📧 Email & 📱 SMS verification supported',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
