import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Minimal profile photo picker that stores image as base64 string.
class ProfilePhotoPicker extends StatefulWidget {
  final String? initialBase64;
  final ValueChanged<String?> onChanged;
  // Visual diameter of the avatar in logical pixels. Default ~80 (radius 40)
  final double size;
  // When true, shows the Change Photo button below the avatar instead of inline
  final bool buttonBelow;

  const ProfilePhotoPicker({
    super.key,
    this.initialBase64,
    required this.onChanged,
    this.size = 80,
    this.buttonBelow = false,
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
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'camera' || choice == 'gallery') {
      final picker = ImagePicker();
      final source = choice == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;
      final picked = await picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        setState(() => _b64 = b64);
        widget.onChanged(b64);
      }
    } else if (choice == 'remove') {
      setState(() => _b64 = null);
      widget.onChanged(null);
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

    if (widget.buttonBelow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Change Photo'),
          ),
        ],
      );
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
