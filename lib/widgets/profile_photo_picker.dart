import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef PhotoChanged = void Function(String? base64Data);

class ProfilePhotoPicker extends StatefulWidget {
  final String? initialBase64;
  final PhotoChanged onChanged;
  final double size;
  const ProfilePhotoPicker({
    super.key,
    this.initialBase64,
    required this.onChanged,
    this.size = 90,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  String? _base64;

  @override
  void initState() {
    super.initState();
    _base64 = widget.initialBase64;
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() => _base64 = b64);
    widget.onChanged(b64);
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            if (_base64 != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _base64 = null);
                  widget.onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (_base64 != null) {
      try {
        img = MemoryImage(base64Decode(_base64!));
      } catch (_) {}
    }
    return InkWell(
      onTap: _showOptions,
      borderRadius: BorderRadius.circular(widget.size),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: img,
            child: img == null
                ? const Icon(Icons.person, size: 40, color: Colors.white70)
                : null,
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
