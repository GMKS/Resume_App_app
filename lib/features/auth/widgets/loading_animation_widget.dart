import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingAnimationWidget extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingAnimationWidget({
    super.key,
    this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Colors.blue.shade600;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
          ),

          // Rotating gradient ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor,
                width: 3,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(milliseconds: 1500), begin: 0, end: 1),

          // Inner pulsing circle
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: const Duration(milliseconds: 1000),
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
              ),

          // Center pulse dot
          Container(
            width: size * 0.15,
            height: size * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: const Duration(milliseconds: 1200),
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.3, 1.3),
              )
              .then()
              .fadeOut(duration: const Duration(milliseconds: 100))
              .then()
              .fadeIn(duration: const Duration(milliseconds: 100)),
        ],
      ),
    );
  }
}

/// Alternative loading indicator with gradient effect
class GradientLoadingWidget extends StatelessWidget {
  final double size;

  const GradientLoadingWidget({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient rotating background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.purple.shade600,
                  Colors.blue.shade600,
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(milliseconds: 2000), begin: 0, end: 1),

          // Center loading text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_bottom,
                color: Colors.blue.shade600,
                size: size * 0.5,
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ).animate(onPlay: (controller) => controller.repeat())
                  .then(delay: const Duration(milliseconds: 500))
                  .fadeOut(duration: const Duration(milliseconds: 300))
                  .then()
                  .fadeIn(duration: const Duration(milliseconds: 300)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modern linear progress indicator with smooth animation
class ModernLoadingBar extends StatelessWidget {
  final double height;
  final Color? color;

  const ModernLoadingBar({
    super.key,
    this.height = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Colors.blue.shade600;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                primaryColor,
                Colors.transparent,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .slideX(
              duration: const Duration(milliseconds: 1500),
              begin: -2,
              end: 2,
            ),
      ),
    );
  }
}
