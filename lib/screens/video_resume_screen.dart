import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../services/premium_service.dart';
import '../services/video_resume_service.dart';
import '../services/resume_storage_service.dart';
import '../models/saved_resume.dart';

class VideoResumeScreen extends StatefulWidget {
  const VideoResumeScreen({super.key});

  @override
  State<VideoResumeScreen> createState() => _VideoResumeScreenState();
}

class _VideoResumeScreenState extends State<VideoResumeScreen> {
  final _videoResumeService = VideoResumeService();

  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  File? _videoFile;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Video player state
  bool _isPlaying = false;
  int _playbackPosition = 0;
  Timer? _playbackTimer;
  VideoPlayerController? _controller;

  final List<String> _prompts = [
    "Tell me about yourself and your professional background",
    "What are your key strengths and achievements?",
    "Why are you interested in this position?",
    "Describe a challenging project you've worked on",
    "What are your career goals for the next 5 years?",
    "How do you handle difficult situations at work?",
  ];

  int _currentPromptIndex = 0;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PremiumService.hasVideoResumeFeature) {
      return _buildUpgradeScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Resume'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTips,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Card
            Card(
              color: Colors.purple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Create Your Video Resume',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stand out with a professional video resume. Record yourself answering common interview questions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recording Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recording Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Camera Preview/Recording Area
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _hasRecording
                          ? _buildVideoPlayer()
                          : _buildCameraPreview(),
                    ),

                    const SizedBox(height: 16),

                    // Recording Controls
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (!_hasRecording) ...[
                          ElevatedButton.icon(
                            onPressed: _isRecording
                                ? _stopRecording
                                : () async {
                                    // Try real capture via service; fall back to simulation if null
                                    final file =
                                        await VideoResumeService.recordVideoResume(
                                          context,
                                        );
                                    if (file != null) {
                                      final dur =
                                          await VideoResumeService.getVideoDuration(
                                            file,
                                          );
                                      setState(() {
                                        _videoFile = file;
                                        _hasRecording = true;
                                        _recordingSeconds = dur.inSeconds;
                                        _recordingPath = file.path;
                                      });
                                      // Initialize player for immediate playback
                                      await _initializeController(file);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Video captured successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      _startRecording();
                                    }
                                  },
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.videocam,
                            ),
                            label: Text(
                              _isRecording
                                  ? 'Stop Recording'
                                  : 'Start Recording',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? Colors.red
                                  : Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: _retakeVideo,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retake'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveVideo,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _shareVideo,
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_hasRecording)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final file =
                                  await VideoResumeService.pickVideoFromGallery(
                                    context,
                                  );
                              if (file != null) {
                                final dur =
                                    await VideoResumeService.getVideoDuration(
                                      file,
                                    );
                                setState(() {
                                  _videoFile = file;
                                  _hasRecording = true;
                                  _recordingSeconds = dur.inSeconds;
                                  _recordingPath = file.path;
                                });
                                // Initialize player for immediate playback
                                await _initializeController(file);
                              }
                            },
                            icon: const Icon(Icons.video_library),
                            label: const Text('Pick from Gallery'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Prompt Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interview Prompts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use these prompts to practice your responses',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Current Prompt
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.question_answer,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Question ${_currentPromptIndex + 1} of ${_prompts.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _prompts[_currentPromptIndex],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Prompt Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _currentPromptIndex > 0
                              ? _previousPrompt
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _currentPromptIndex < _prompts.length - 1
                              ? _nextPrompt
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tips Card
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Recording Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('• Keep responses under 2 minutes'),
                    Text('• Maintain eye contact with the camera'),
                    Text('• Speak clearly and at a moderate pace'),
                    Text('• Use good lighting and a clean background'),
                    Text('• Practice before recording'),
                    Text('• Be authentic and professional'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Resume'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Video Resume',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create professional video resumes to stand out from other candidates. Record yourself answering common interview questions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Video Resume is a premium feature',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => PremiumService.showUpgradeDialog(
                  context,
                  'Video Resume Feature',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _isRecording ? Icons.videocam : Icons.videocam_off,
              size: 64,
              color: _isRecording ? Colors.red : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'Recording in Progress...' : 'Ready to Record',
            style: TextStyle(
              fontSize: 18,
              color: _isRecording ? Colors.red : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Press "Stop Recording" when finished',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Camera simulation mode',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio == 0
              ? 16 / 9
              : _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        VideoProgressIndicator(
          _controller!,
          allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: Colors.purple),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: FloatingActionButton.small(
            onPressed: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
                setState(() => _isPlaying = false);
              } else {
                _controller!.play();
                setState(() => _isPlaying = true);
              }
            },
            backgroundColor: Colors.white,
            child: Icon(
              _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    // Start timer to track recording duration
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });

    // Show improved camera simulation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera simulation started. Recording in progress...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _recordingPath =
          _videoFile?.path ??
          'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    });

    // Initialize controller for playback if file exists
    if (_videoFile != null) {
      _initializeController(_videoFile!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Video recording completed successfully! Duration: ${_formatDuration(_recordingSeconds)}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _retakeVideo() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingSeconds = 0;
      _controller?.dispose();
      _controller = null;
      _videoFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to record again'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _initializeController(File file) async {
    _controller?.dispose();
    final c = VideoPlayerController.file(file);
    _controller = c;
    await c.initialize();
    setState(() {
      _recordingSeconds = c.value.duration.inSeconds;
    });
  }

  Future<void> _shareVideo() async {
    if (_videoFile == null) return;
    try {
      await Share.shareXFiles([
        XFile(_videoFile!.path, mimeType: 'video/mp4'),
      ], text: 'My Video Resume');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  void _saveVideo() async {
    // Save video to user's video resume collection
    try {
      final videoResume = SavedResume(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Video Resume ${DateTime.now().toString().split(' ')[0]}',
        template: 'Video',
        data: {
          'videoPath': _recordingPath ?? '',
          'promptAnswered': _prompts[_currentPromptIndex],
          'duration': _recordingSeconds,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ResumeStorageService.instance.saveOrUpdate(videoResume);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video resume saved to My Resumes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playVideo() {
    setState(() {
      _isPlaying = false;
      _playbackPosition = 0;
    });

    // Improved video player dialog with simulation
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.play_circle_filled, color: Colors.green),
              SizedBox(width: 8),
              Text('Video Player'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Video simulation content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.videocam : Icons.videocam_off,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isPlaying
                                ? 'Playing Video Resume'
                                : 'Video Resume Ready',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Duration: ${_formatDuration(_recordingSeconds)}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play overlay when paused
                    if (!_isPlaying)
                      Center(
                        child: GestureDetector(
                          onTap: () => _startPlayback(setDialogState),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Progress bar
              LinearProgressIndicator(
                value: _recordingSeconds > 0
                    ? _playbackPosition / _recordingSeconds
                    : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 8),
              Text(
                '${_formatDuration(_playbackPosition)} / ${_formatDuration(_recordingSeconds)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _rewind(setDialogState),
                    icon: Icon(Icons.replay_10),
                    tooltip: 'Rewind 10s',
                  ),
                  IconButton(
                    onPressed: () => _togglePlayback(setDialogState),
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 32,
                    ),
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    onPressed: () => _fastForward(setDialogState),
                    icon: Icon(Icons.forward_10),
                    tooltip: 'Forward 10s',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _stopPlayback();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _startPlayback(StateSetter setDialogState) {
    setDialogState(() {
      _isPlaying = true;
    });

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setDialogState(() {
        _playbackPosition++;
        if (_playbackPosition >= _recordingSeconds) {
          _playbackPosition = _recordingSeconds;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _togglePlayback(StateSetter setDialogState) {
    if (_isPlaying) {
      _pausePlayback(setDialogState);
    } else {
      _startPlayback(setDialogState);
    }
  }

  void _pausePlayback(StateSetter setDialogState) {
    _playbackTimer?.cancel();
    setDialogState(() {
      _isPlaying = false;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _playbackPosition = 0;
    });
  }

  void _rewind(StateSetter setDialogState) {
    setDialogState(() {
      _playbackPosition = (_playbackPosition - 10).clamp(0, _recordingSeconds);
    });
  }

  void _fastForward(StateSetter setDialogState) {
    setDialogState(() {
      _playbackPosition = (_playbackPosition + 10).clamp(0, _recordingSeconds);
    });
  }

  void _previousPrompt() {
    if (_currentPromptIndex > 0) {
      setState(() {
        _currentPromptIndex--;
      });
    }
  }

  void _nextPrompt() {
    if (_currentPromptIndex < _prompts.length - 1) {
      setState(() {
        _currentPromptIndex++;
      });
    }
  }

  void _showTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange),
            SizedBox(width: 8),
            Text('Video Resume Tips'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before Recording:'),
            Text('• Test your camera and audio'),
            Text('• Find a quiet, well-lit space'),
            Text('• Practice your responses'),
            SizedBox(height: 12),
            Text('During Recording:'),
            Text('• Look directly at the camera'),
            Text('• Speak clearly and confidently'),
            Text('• Keep responses concise'),
            SizedBox(height: 12),
            Text('After Recording:'),
            Text('• Review before saving'),
            Text('• Retake if needed'),
            Text('• Add to your resume package'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
