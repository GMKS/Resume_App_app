import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.alignment = Alignment.topCenter,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}