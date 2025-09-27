import 'package:flutter/material.dart';
import '../models/branding.dart';

/// Minimal branding customizer stub with a couple of fields.
class BrandingCustomizer extends StatefulWidget {
  final BrandingTheme initialTheme;
  final ValueChanged<BrandingTheme> onThemeChanged;

  const BrandingCustomizer({
    super.key,
    required this.initialTheme,
    required this.onThemeChanged,
  });

  @override
  State<BrandingCustomizer> createState() => _BrandingCustomizerState();
}

class _BrandingCustomizerState extends State<BrandingCustomizer> {
  late BrandingTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.initialTheme;
  }

  void _update(void Function() fn) {
    setState(fn);
    widget.onThemeChanged(_theme);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Primary Color (hex)'),
        TextFormField(
          initialValue: _theme.primaryColor,
          onChanged: (v) =>
              _update(() => _theme = _theme.copyWith(primaryColor: v)),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        const Text('Accent Color (hex)'),
        TextFormField(
          initialValue: _theme.accentColor,
          onChanged: (v) =>
              _update(() => _theme = _theme.copyWith(accentColor: v)),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        const Text('Font Family'),
        TextFormField(
          initialValue: _theme.fontFamily,
          onChanged: (v) =>
              _update(() => _theme = _theme.copyWith(fontFamily: v)),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
