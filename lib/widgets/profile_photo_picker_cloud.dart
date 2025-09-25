import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloud_storage_service.dart';
import '../services/cloud_resume_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef PhotoChanged = void Function(String? photoUrl);

/// Enhanced ProfilePhotoPicker that automatically uploads photos to Firebase Cloud Storage
/// and saves the photo URL to the user's Firestore profile.
class ProfilePhotoPickerCloud extends StatefulWidget {
  final String? initialPhotoUrl;
  final PhotoChanged onChanged;
  final double size;
  final bool autoLoadFromCloud;

  const ProfilePhotoPickerCloud({
    super.key,
    this.initialPhotoUrl,
    required this.onChanged,
    this.size = 90,
    this.autoLoadFromCloud = true,
  });

  @override
  State<ProfilePhotoPickerCloud> createState() =>
      _ProfilePhotoPickerCloudState();
}

class _ProfilePhotoPickerCloudState extends State<ProfilePhotoPickerCloud> {
  String? _base64;
  String? _cloudUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePhoto();
  }

  Future<void> _initializePhoto() async {
    if (widget.autoLoadFromCloud) {
      setState(() => _isLoading = true);
      try {
        final photoUrl = await CloudResumeService.instance.getProfilePhotoUrl();
        if (mounted && photoUrl != null) {
          setState(() => _cloudUrl = photoUrl);
          widget.onChanged(photoUrl);
        }
      } catch (e) {
        print('Error loading profile photo: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    // Handle initial data
    if (widget.initialPhotoUrl != null) {
      if (widget.initialPhotoUrl!.startsWith('http')) {
        _cloudUrl = widget.initialPhotoUrl;
      } else {
        _base64 = widget.initialPhotoUrl;
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload photos')),
        );
      }
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

        if (mounted) {
          setState(() {
            _base64 = null; // Clear base64 data
            _cloudUrl = downloadUrl; // Store cloud URL instead
            _isUploading = false;
          });
          widget.onChanged(downloadUrl); // Pass cloud URL to parent
        }
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    }
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
      onTap: (_isUploading || _isLoading) ? null : _showOptions,
      borderRadius: BorderRadius.circular(widget.size),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: img,
            child: img == null
                ? (_isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white70,
                        ))
                : null,
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: (_isUploading || _isLoading)
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
