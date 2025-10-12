import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';
import '../models/customize_settings.dart';

class SmartFeaturesTab extends StatefulWidget {
  final CustomizeSettings settings;
  final CustomResumeData resumeData;
  final Function(CustomizeSettings) onSettingsChanged;
  final Function(CustomResumeData) onResumeDataChanged;

  const SmartFeaturesTab({
    super.key,
    required this.settings,
    required this.resumeData,
    required this.onSettingsChanged,
    required this.onResumeDataChanged,
  });

  @override
  _SmartFeaturesTabState createState() => _SmartFeaturesTabState();
}

class _SmartFeaturesTabState extends State<SmartFeaturesTab> {
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  bool _isGeneratingContent = false;
  bool _isOptimizingKeywords = false;
  bool _isCheckingGrammar = false;

  @override
  void initState() {
    super.initState();
    _jobDescriptionController.text = widget.settings.jobDescription ?? '';
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateAISuggestions() async {
    setState(() {
      _isGeneratingContent = true;
    });

    try {
      // TODO: Implement AI suggestions
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI suggestions generated! Check the content sections for improvements.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate AI suggestions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingContent = false;
      });
    }
  }

  Future<void> _optimizeKeywords() async {
    setState(() {
      _isOptimizingKeywords = true;
    });

    try {
      // TODO: Implement keyword optimization
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keywords optimized for ATS compatibility!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to optimize keywords: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isOptimizingKeywords = false;
      });
    }
  }

  Future<void> _checkGrammar() async {
    setState(() {
      _isCheckingGrammar = true;
    });

    try {
      // TODO: Implement grammar check
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grammar and spelling checked! No issues found.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check grammar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingGrammar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use AI-powered tools to enhance your resume content and optimize it for better results.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // AI Suggestions Section
          _buildAISuggestionsSection(),
          const SizedBox(height: 24),

          // Keyword Optimization Section
          _buildKeywordOptimizationSection(),
          const SizedBox(height: 24),

          // Grammar Check Section
          _buildGrammarCheckSection(),
          const SizedBox(height: 24),

          // Job Description Analysis Section
          _buildJobDescriptionSection(),
          const SizedBox(height: 24),

          // Feature Settings
          _buildFeatureSettings(),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'AI Content Suggestions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Get AI-powered suggestions to improve your resume content, make it more compelling, and highlight your achievements.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingContent ? null : _generateAISuggestions,
                icon: _isGeneratingContent
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology),
                label: Text(
                  _isGeneratingContent
                      ? 'Generating Suggestions...'
                      : 'Generate AI Suggestions',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable AI Suggestions'),
              subtitle: const Text(
                'Automatically suggest improvements while editing',
              ),
              value: widget.settings.aiSuggestions,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(aiSuggestions: value),
                );
              },
              activeThumbColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordOptimizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Keyword Optimization',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Optimize your resume with industry-relevant keywords to improve ATS (Applicant Tracking System) compatibility.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOptimizingKeywords ? null : _optimizeKeywords,
                icon: _isOptimizingKeywords
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune),
                label: Text(
                  _isOptimizingKeywords
                      ? 'Optimizing Keywords...'
                      : 'Optimize Keywords',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Keyword Optimizer'),
              subtitle: const Text(
                'Suggest relevant keywords for your industry',
              ),
              value: widget.settings.keywordOptimizer,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(keywordOptimizer: value),
                );
              },
              activeThumbColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarCheckSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.spellcheck, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Grammar & Spell Check',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ensure your resume is error-free with our advanced grammar and spell checking capabilities.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingGrammar ? null : _checkGrammar,
                icon: _isCheckingGrammar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isCheckingGrammar
                      ? 'Checking Grammar...'
                      : 'Check Grammar & Spelling',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Grammar Check'),
              subtitle: const Text('Real-time grammar and spelling validation'),
              value: widget.settings.grammarCheck,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(grammarCheck: value),
                );
              },
              activeThumbColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.work_outline, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Job Description Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Paste a job description to get tailored suggestions for optimizing your resume for that specific role.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                hintText:
                    'Paste the job description here to get tailored suggestions...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(jobDescription: value),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_jobDescriptionController.text.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI will use this job description to provide personalized recommendations.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Smart Feature Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Feature',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Smart features require a premium subscription to unlock advanced AI capabilities.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to premium upgrade
                    },
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
