import 'dart:io';
import 'package:flutter/widgets.dart';

/// Simple drag & drop placeholders for platforms that support it; no-ops on others.
class DragDropService {
  static Future<File?> pickFile() async {
    // Not implemented; return null to indicate no file.
    return null;
  }
}

typedef FileDropHandler = Future<void> Function(File file);

class DragDropZone extends StatelessWidget {
  final Widget child;
  final FileDropHandler onFileDropped;

  const DragDropZone({
    super.key,
    required this.child,
    required this.onFileDropped,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: just render child; real drag-drop requires desktop web
    return child;
  }
}
