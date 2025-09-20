import 'package:flutter/material.dart';
import '../widgets/glassmorphic_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicPage(
      title: "Login",
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              hintText: "User Name / ID",
              prefixIcon: Icon(Icons.person, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: Icon(Icons.lock, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text("LOGIN")),
        ],
      ),
    );
  }
}
