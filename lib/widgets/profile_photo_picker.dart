import 'dart:convert';
import 'package:flutter/material.dart';

/// Minimal profile photo picker that stores image as base64 string.
class ProfilePhotoPicker extends StatefulWidget {
  final String? initialBase64;
  final ValueChanged<String?> onChanged;
  // Visual diameter of the avatar in logical pixels. Default ~80 (radius 40)
  final double size;

  const ProfilePhotoPicker({
    super.key,
    this.initialBase64,
    required this.onChanged,
    this.size = 80,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  String? _b64;

  @override
  void initState() {
    super.initState();
    _b64 = widget.initialBase64;
  }

  Future<void> _pickImage() async {
    // Simple placeholder: show dialog to clear or keep; no file picker dependency.
    // Extend later with image_picker package if needed.
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Use sample avatar'),
              onTap: () => Navigator.pop(ctx, 'sample'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'remove') {
      setState(() => _b64 = null);
      widget.onChanged(null);
    } else if (choice == 'sample') {
      // Generate a tiny transparent PNG placeholder
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAA' // 1x1 transparent PNG
        'AAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      );
      final b64 = base64Encode(bytes);
      setState(() => _b64 = b64);
      widget.onChanged(b64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double radius = (widget.size <= 0) ? 40 : widget.size / 2;
    Widget avatar;
    if (_b64 != null && _b64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_b64!);
        avatar = CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        avatar = CircleAvatar(radius: radius, child: const Icon(Icons.person));
      }
    } else {
      avatar = CircleAvatar(radius: radius, child: const Icon(Icons.person));
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt, size: 16),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }
}
