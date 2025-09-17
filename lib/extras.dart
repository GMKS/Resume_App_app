import 'package:flutter/material.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: const Center(child: Text('Pricing Screen Placeholder')),
    );
  }
}

class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.5,
        size.height,
      )
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.8, 0, size.height)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
