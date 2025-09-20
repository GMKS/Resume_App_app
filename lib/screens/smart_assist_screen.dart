import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class SmartAssistScreen extends StatefulWidget {
  const SmartAssistScreen({super.key});

  @override
  State<SmartAssistScreen> createState() => _SmartAssistScreenState();
}

class _SmartAssistScreenState extends State<SmartAssistScreen> {
  final TextEditingController _resumeController = TextEditingController();
  String? _tips;
  bool _loading = false;

  Future<void> _getTips() async {
    setState(() {
      _loading = true;
      _tips = null;
    });
    final tips = await getResumeTips(_resumeController.text);
    setState(() {
      _tips = tips;
      _loading = false;
    });
  }

  void _copyResume() {
    Clipboard.setData(ClipboardData(text: _resumeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume copied to clipboard!')),
    );
  }

  void _copyTips() {
    if (_tips != null && _tips!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _tips!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tips copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Smart Assist')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste your resume content below to get instant tips:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resumeController,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Paste your resume content here...',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _copyResume,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Resume'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _getTips,
                icon: const Icon(Icons.smart_toy),
                label: const Text('Analyze & Get Tips'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_tips != null)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tips!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _copyTips,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Tips'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
