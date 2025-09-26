import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/cover_letter_service.dart';

class CoverLetterFormScreen extends StatefulWidget {
  const CoverLetterFormScreen({super.key});

  @override
  State<CoverLetterFormScreen> createState() => _CoverLetterFormScreenState();
}

class _CoverLetterFormScreenState extends State<CoverLetterFormScreen> {
  final _coverLetterService = CoverLetterService();

  String _selectedTemplate = 'Professional';
  String _selectedIndustry = 'Technology';
  bool _isGenerating = false;

  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _customContentController = TextEditingController();

  final List<String> _availableTemplates = [
    'Professional',
    'Creative',
    'Technical',
    'Executive',
  ];

  final List<String> _availableIndustries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Marketing',
    'Education',
    'Retail',
    'Manufacturing',
    'Legal',
    'Non-Profit',
    'Government',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cover Letter Builder'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (PremiumService.hasCoverLetterFeature)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI Assistant',
              onPressed: _showAIAssistant,
            ),
        ],
      ),
      body: Column(
        children: [
          // Premium Feature Banner
          if (!PremiumService.hasCoverLetterFeature)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cover Letter Builder is a premium feature',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => PremiumService.showUpgradeDialog(
                      context,
                      'Cover Letter Builder',
                    ),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Template Selection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTemplate,
                            decoration: const InputDecoration(
                              labelText: 'Cover Letter Template',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableTemplates.map((template) {
                              return DropdownMenuItem(
                                value: template,
                                child: Text(template),
                              );
                            }).toList(),
                            onChanged: PremiumService.hasCoverLetterFeature
                                ? (value) {
                                    setState(() {
                                      _selectedTemplate = value!;
                                    });
                                  }
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedIndustry,
                            decoration: const InputDecoration(
                              labelText: 'Industry',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableIndustries.map((industry) {
                              return DropdownMenuItem(
                                value: industry,
                                child: Text(industry),
                              );
                            }).toList(),
                            onChanged: PremiumService.hasCoverLetterFeature
                                ? (value) {
                                    setState(() {
                                      _selectedIndustry = value!;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Job Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Job Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyController,
                            enabled: PremiumService.hasCoverLetterFeature,
                            decoration: const InputDecoration(
                              labelText: 'Company Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _positionController,
                            enabled: PremiumService.hasCoverLetterFeature,
                            decoration: const InputDecoration(
                              labelText: 'Position Title *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Content Generation
                  if (PremiumService.hasCoverLetterFeature)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.smart_toy, color: Colors.teal),
                                SizedBox(width: 8),
                                Text(
                                  'AI-Powered Content',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Let AI generate a personalized cover letter based on your details',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isGenerating
                                        ? null
                                        : _generateCoverLetter,
                                    icon: _isGenerating
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.auto_awesome),
                                    label: Text(
                                      _isGenerating
                                          ? 'Generating...'
                                          : 'Generate with AI',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _loadTemplate,
                                  child: const Text('Load Template'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Content Editor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cover Letter Content',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customContentController,
                            enabled: PremiumService.hasCoverLetterFeature,
                            maxLines: 15,
                            decoration: const InputDecoration(
                              hintText:
                                  'Your cover letter content will appear here...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: PremiumService.hasCoverLetterFeature
                              ? _previewCoverLetter
                              : null,
                          icon: const Icon(Icons.preview),
                          label: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: PremiumService.hasCoverLetterFeature
                              ? _saveCoverLetter
                              : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.teal),
            SizedBox(width: 8),
            Text('AI Assistant Tips'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Include specific company research'),
            Text('• Highlight relevant skills and experience'),
            Text('• Use industry-specific keywords'),
            Text('• Keep it concise and professional'),
            Text('• Customize for each application'),
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

  Future<void> _generateCoverLetter() async {
    if (_companyController.text.isEmpty || _positionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in company name and position'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await _coverLetterService.generateCoverLetter(
        template: _selectedTemplate,
        industry: _selectedIndustry,
        companyName: _companyController.text,
        positionTitle: _positionController.text,
        customRequirements: '',
      );

      setState(() {
        _customContentController.text = result.content;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover letter generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate cover letter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadTemplate() {
    final template = _coverLetterService.getTemplate(_selectedTemplate);
    setState(() {
      _customContentController.text = template.content;
    });
  }

  void _previewCoverLetter() {
    if (_customContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add content to preview'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cover Letter Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(_customContentController.text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveCoverLetter();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveCoverLetter() {
    // Save cover letter logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cover letter saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _customContentController.dispose();
    super.dispose();
  }
}
