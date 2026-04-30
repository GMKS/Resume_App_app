import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ATSAnalyzerScreen extends ConsumerStatefulWidget {
  final String resumeId;
  const ATSAnalyzerScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ATSAnalyzerScreen> createState() => _ATSAnalyzerScreenState();
}

class _ATSAnalyzerScreenState extends ConsumerState<ATSAnalyzerScreen> {
  final TextEditingController _jobDescController = TextEditingController();
  String _analysisResult = '';

  @override
  void dispose() {
    _jobDescController.dispose();
    super.dispose();
  }

  void _analyzeATS() {
    // TODO: Implement keyword extraction and matching logic
    setState(() {
      _analysisResult = 'ATS analysis will appear here.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ATS Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste Job Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _jobDescController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste the job description here...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyzeATS,
              child: const Text('Analyze Resume'),
            ),
            const SizedBox(height: 24),
            Text(_analysisResult),
          ],
        ),
      ),
    );
  }
}
