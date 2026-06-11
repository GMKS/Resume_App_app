import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/utils/shareable_export_file.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/reading_mode_text.dart';

class CoverLetterScreen extends ConsumerStatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  ConsumerState<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends ConsumerState<CoverLetterScreen> {
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedTone = 'Professional';
  String _selectedLength = 'Medium';
  bool _isGenerating = false;
  bool _isExporting = false;
  String? _generatedLetter;

  final List<String> _tones = [
    'Professional',
    'Enthusiastic',
    'Formal',
    'Creative'
  ];
  final List<String> _lengths = ['Short', 'Medium', 'Long'];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _jobDescriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: SubscriptionFeatures.coverLetterGenerator,
      child: Scaffold(
        appBar: AppBar(
          leading: AdaptiveTooltip(
            message: 'Back',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left),
            ),
          ),
          title: const Text('Cover Letter Generator'),
          actions: [
            if (_generatedLetter != null)
              AdaptiveTooltip(
                message: 'Export',
                button: true,
                child: IconButton(
                  onPressed: _isExporting ? null : _exportLetter,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.document_download),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Iconsax.magic_star, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI-powered cover letter tailored to your job application',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Input Form
              Text(
                'Job Details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _jobTitleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'e.g. Senior Software Engineer',
                  prefixIcon: Icon(Iconsax.briefcase),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'e.g. Google Inc.',
                  prefixIcon: Icon(Iconsax.building),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _jobDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  hintText: 'Paste the job description here...',
                  prefixIcon: Icon(Iconsax.document_text),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. John Doe',
                  prefixIcon: Icon(Iconsax.user),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),

              // Customization Options
              Text(
                'Customization',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Tone Selection
              Text(
                'Tone',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tones.map((tone) {
                  final isSelected = _selectedTone == tone;
                  return ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedTone = tone);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Length Selection
              Text(
                'Length',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _lengths.map((length) {
                  final isSelected = _selectedLength == length;
                  return ChoiceChip(
                    label: Text(length),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedLength = length);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Generate Button
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateLetter,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Iconsax.magic_star),
                label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Cover Letter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),

              if (_generatedLetter != null) ...[
                const SizedBox(height: 24),

                // Generated Letter
                Text(
                  'Generated Cover Letter',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ReadingModeText(
                          text: _generatedLetter!,
                          fullScreenTitle: 'Cover Letter',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Iconsax.copy),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isExporting ? null : _exportLetter,
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(Iconsax.document_download),
                                label: Text(
                                    _isExporting ? 'Exporting...' : 'Export'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _generateLetter() {
    if (_jobTitleController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill in job title, company name, and your name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    // Simulate AI generation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _generatedLetter = _generateSampleLetter();
      });
    });
  }

  String _generateSampleLetter() {
    final jobTitle = _jobTitleController.text;
    final company = _companyController.text;
    final name = _nameController.text.trim();

    return '''Dear Hiring Manager,

I am writing to express my strong interest in the $jobTitle position at $company. With my proven track record and passion for innovation, I am confident that I would be a valuable addition to your team.

Throughout my career, I have developed expertise in areas that align perfectly with your requirements. My experience has equipped me with the skills necessary to excel in this role and contribute meaningfully to $company's continued success.

What particularly excites me about this opportunity is the chance to work with a team that values excellence and innovation. I am impressed by $company's commitment to pushing boundaries and would be thrilled to contribute to your mission.

I have attached my resume for your review and would welcome the opportunity to discuss how my background, skills, and enthusiasm can benefit $company. Thank you for considering my application.

I look forward to the possibility of contributing to your team.

Sincerely,
$name''';
  }

  Future<void> _copyToClipboard() async {
    if (_generatedLetter != null) {
      await Clipboard.setData(ClipboardData(text: _generatedLetter!));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.tick_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Copied to clipboard'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportLetter() async {
    final letter = _generatedLetter?.trim();
    if (letter == null || letter.isEmpty) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final file = await buildShareableExportFile(
        bytes: Uint8List.fromList(utf8.encode(letter)),
        fileName: _buildExportFileName(),
        mimeType: 'text/plain',
      );
      await Share.shareXFiles(
        [file],
        subject: _buildExportSubject(),
        text: 'Cover letter export from ${AppInfo.appName}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting cover letter: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildExportFileName() {
    final parts = <String>[
      if (_companyController.text.trim().isNotEmpty)
        _sanitizeFilePart(_companyController.text),
      if (_jobTitleController.text.trim().isNotEmpty)
        _sanitizeFilePart(_jobTitleController.text),
      'cover_letter',
    ];
    return '${parts.join('_')}.txt';
  }

  String _buildExportSubject() {
    final company = _companyController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    if (company.isEmpty && jobTitle.isEmpty) {
      return 'Cover Letter';
    }
    return 'Cover Letter${jobTitle.isNotEmpty ? ' - $jobTitle' : ''}${company.isNotEmpty ? ' at $company' : ''}';
  }

  String _sanitizeFilePart(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    return normalized.isEmpty ? 'cover_letter' : normalized;
  }
}
