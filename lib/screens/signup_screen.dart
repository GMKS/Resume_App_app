import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;
  bool _forgotChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient and shapes
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE1006A), Color(0xFF7F00FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Top curved shape
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                height: 180,
                color: Colors.white.withOpacity(0.15),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Logo placeholder
                    const FlutterLogo(size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      "LOGO",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "Lorem ipsum dolor sit",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 140),
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.pink[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Welcome text
                    const Text(
                      "Welcome",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      "Your Account",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Card with fields
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 22,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _userController,
                              decoration: const InputDecoration(
                                labelText: 'User Name / ID',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _staySignedIn,
                                  onChanged: (v) =>
                                      setState(() => _staySignedIn = v!),
                                  activeColor: Colors.pink,
                                ),
                                const Text("Stay signed in"),
                                const Spacer(),
                                Checkbox(
                                  value: _forgotChecked,
                                  onChanged: (v) =>
                                      setState(() => _forgotChecked = v!),
                                  activeColor: Colors.pink,
                                ),
                                const Text("Forgot User ID or Password?"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  // Handle login
                                },
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Not registered yet
                          },
                          child: const Text(
                            "Not registered yet?",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Create your account
                          },
                          child: const Text(
                            "Create your account",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for the top curve
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
