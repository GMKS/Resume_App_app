import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppLoadingState extends StatelessWidget {
  final String title;
  final String? message;
  final String? semanticsLabel;

  const AppLoadingState({
    super.key,
    this.title = 'Loading',
    this.message,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel ?? [title, message].whereType<String>().join('. '),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(strokeWidth: 3.2),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}