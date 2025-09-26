import 'dart:io';
import 'package:flutter/material.dart';
import '../services/premium_service.dart';

/// Video resume service for premium users
/// Lightweight implementation to minimize APK size
class VideoResumeService {
  static final VideoResumeService _instance = VideoResumeService._internal();
  factory VideoResumeService() => _instance;
  VideoResumeService._internal();

  // Maximum video duration in seconds
  static const int maxVideoDurationSeconds = 180; // 3 minutes
  static const int maxVideoSizeMB = 50;

  /// Check if video resume feature is available
  static bool get isAvailable => PremiumService.hasVideoResumeFeature;

  /// Supported video formats
  static const List<String> supportedFormats = ['mp4', 'mov', 'avi'];

  /// Record video resume (placeholder for camera integration)
  static Future<File?> recordVideoResume(BuildContext context) async {
    if (!isAvailable) {
      _showPremiumRequiredDialog(context);
      return null;
    }

    // This would integrate with camera plugin in production
    // For now, return null to reduce APK size
    return null;
  }

  /// Pick video from gallery
  static Future<File?> pickVideoFromGallery() async {
    if (!isAvailable) {
      throw Exception('Video resume is a premium feature');
    }

    // This would integrate with file picker for video selection
    // Placeholder implementation to reduce APK size
    return null;
  }

  /// Validate video file
  static Future<bool> validateVideoFile(File videoFile) async {
    try {
      // Check file size
      int fileSize = await videoFile.length();
      if (fileSize > (maxVideoSizeMB * 1024 * 1024)) {
        return false;
      }

      // Check file format
      String extension = videoFile.path.split('.').last.toLowerCase();
      if (!supportedFormats.contains(extension)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get video duration (placeholder)
  static Future<Duration> getVideoDuration(File videoFile) async {
    // This would use video_player or similar plugin
    // For now, return placeholder duration
    return const Duration(seconds: 60);
  }

  /// Generate video thumbnail (placeholder)
  static Future<File?> generateThumbnail(File videoFile) async {
    // This would generate a thumbnail from the video
    // Placeholder implementation
    return null;
  }

  /// Compress video if too large
  static Future<File?> compressVideo(File videoFile) async {
    // This would use video compression
    // Placeholder implementation to reduce APK size
    return videoFile;
  }

  /// Show premium required dialog
  static void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.video_camera_back, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Video Resume'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video Resume is a Premium feature.'),
            SizedBox(height: 16),
            Text(
              'Premium Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Record professional video resumes'),
            Text('• Upload videos from gallery'),
            Text('• Video compression and optimization'),
            Text('• Share video resumes directly'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium upgrade
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

/// Video resume widget for display
class VideoResumeWidget extends StatelessWidget {
  final File? videoFile;
  final VoidCallback? onTap;
  final bool showControls;

  const VideoResumeWidget({
    super.key,
    this.videoFile,
    this.onTap,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: videoFile != null
          ? _buildVideoPlayer()
          : _buildPlaceholder(context),
    );
  }

  Widget _buildVideoPlayer() {
    // This would integrate with video_player plugin
    // Placeholder implementation
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
        if (showControls)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '1:30',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(
            'Add Video Resume',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Premium Feature',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
