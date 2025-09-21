import 'package:flutter/material.dart';
import '../widgets/glassmorphic_page.dart';
import 'login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicPage(
      title: "SMART HOME\nMobile App",
      showButton: true,
      buttonText: "GET STARTED",
      onButtonPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            "Create your perfect resume, showcase your skills, and land your dream job.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
