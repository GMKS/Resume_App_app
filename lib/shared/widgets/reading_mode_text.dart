import 'package:flutter/material.dart';

class ReadingModeText extends StatelessWidget {
  final String text;
  final String fullScreenTitle;
  final TextStyle? style;

  const ReadingModeText({
    super.key,
    required this.text,
    required this.fullScreenTitle,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStyle = style ?? theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          text,
          style: resolvedStyle,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openReadingMode(context, resolvedStyle),
            icon: const Icon(Icons.open_in_full, size: 18),
            label: const Text('Reading mode'),
          ),
        ),
      ],
    );
  }

  void _openReadingMode(BuildContext context, TextStyle? resolvedStyle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(fullScreenTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                text,
                style: resolvedStyle?.copyWith(
                        height: resolvedStyle.height ?? 1.6) ??
                    const TextStyle(height: 1.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
