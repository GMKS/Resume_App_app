import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/video_resume_service.dart';

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_hasRecording) ...[
                          ElevatedButton.icon(
                            onPressed: _isRecording
                                ? _stopRecording
                                : _startRecording,
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
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _saveVideo,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
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
          Icon(Icons.videocam, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'Recording...' : 'Camera Preview',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_filled, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Video Recorded Successfully',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _playVideo, child: const Text('Tap to Play')),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });

    // Simulate recording process
    Future.delayed(const Duration(seconds: 2), () {
      // In a real implementation, this would start the camera recording
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _recordingPath = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _retakeVideo() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });
  }

  void _saveVideo() {
    // Save video to user's video resume collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video resume saved to your collection'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _playVideo() {
    // Play the recorded video
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Player'),
        content: const Text(
          'Video player would appear here in a real implementation',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
