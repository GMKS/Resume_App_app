import 'package:flutter/material.dart';
import '../widgets/glassmorphic_page.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicPage(
      title: "SMART HOME\nMobile App",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
      showButton: true,
      buttonText: "GET STARTED",
      onButtonPressed: () {
        // Navigate to next page
      },
    );
  }
}
