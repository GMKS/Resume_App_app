import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:io';  // TODO: Restore when cloud services are working
// import '../services/cloud_storage_service.dart';
// import '../services/cloud_resume_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';

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
  String? _cloudUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Check if initialBase64 is actually a URL
    if (widget.initialBase64 != null) {
      if (widget.initialBase64!.startsWith('http')) {
        _cloudUrl = widget.initialBase64;
      } else {
        _base64 = widget.initialBase64;
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;

    // For now, fall back to base64 until cloud services are fixed
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() {
      _base64 = b64;
      _cloudUrl = null;
      _isUploading = false;
    });
    widget.onChanged(b64);

    /* TODO: Restore cloud upload when Firebase services are working
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload photos')),
      );
      return;
    }

    try {
      // Show loading indicator
      setState(() => _isUploading = true);

      // Upload to cloud storage
      final downloadUrl = await CloudStorageService.uploadProfilePhoto(
        File(file.path),
      );

      if (downloadUrl != null) {
        // Save profile photo URL to user profile
        await CloudResumeService.instance.updateProfilePhoto(downloadUrl);

        setState(() {
          _base64 = null; // Clear base64 data
          _cloudUrl = downloadUrl; // Store cloud URL instead
          _isUploading = false;
        });
        widget.onChanged(downloadUrl); // Pass cloud URL to parent
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    }
    */
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
            if (_base64 != null || _cloudUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _base64 = null;
                    _cloudUrl = null;
                  });
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

    // Handle cloud URL
    if (_cloudUrl != null) {
      img = NetworkImage(_cloudUrl!);
    }
    // Handle base64 data (fallback for existing data)
    else if (_base64 != null) {
      try {
        img = MemoryImage(base64Decode(_base64!));
      } catch (_) {}
    }

    return InkWell(
      onTap: _isUploading ? null : _showOptions,
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
              child: _isUploading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
