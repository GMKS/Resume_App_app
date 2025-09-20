import 'package:flutter/material.dart';

class GlassmorphicPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showButton;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const GlassmorphicPage({
    super.key,
    required this.title,
    required this.child,
    this.showButton = false,
    this.buttonText = '',
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // App Icon or Logo
              Center(
                child: Icon(
                  Icons.home,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Glassmorphic Card
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
              if (showButton)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A82FB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: onButtonPressed,
                      child: Text(buttonText),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(),
    );
  }
}

// Example bottom navigation bar
class _GlassNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home, color: Colors.white, size: 28),
          Icon(Icons.settings, color: Colors.white54, size: 28),
          Icon(Icons.person, color: Colors.white54, size: 28),
          Icon(Icons.notifications, color: Colors.white54, size: 28),
        ],
      ),
    );
  }
}
