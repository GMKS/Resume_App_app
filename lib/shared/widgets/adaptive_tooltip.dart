import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _showsMaterialTooltip {
  if (kIsWeb) {
    return true;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return false;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
  }
}

class AdaptiveTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool button;

  const AdaptiveTooltip({
    super.key,
    required this.message,
    required this.child,
    this.button = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _showsMaterialTooltip
        ? Tooltip(
            message: message,
            excludeFromSemantics: true,
            child: child,
          )
        : child;

    return Semantics(
      label: message,
      button: button,
      child: content,
    );
  }
}