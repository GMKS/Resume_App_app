import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/services/ai_api_key_storage_service.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/resume_version_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../editor/screens/resume_editor_screen.dart'
    show currentResumeProvider;
import '../../home/screens/home_screen.dart' show resumesProvider;
import '../services/raoe2_service.dart';
import '../services/raoe2_version_service.dart';

/// RAOE 2: AI-assisted resume optimization against a job description.
class RAOE2Screen extends ConsumerStatefulWidget {
  final String resumeText;
  final String jobDescription;
  final String? resumeId;
  final void Function(String optimizedResume)? onSave;

  const RAOE2Screen({
    super.key,
    required this.resumeText,
    required this.jobDescription,
    this.resumeId,
    this.onSave,
  });

  @override
  ConsumerState<RAOE2Screen> createState() => _RAOE2ScreenState();
}

class _RAOE2ScreenState extends ConsumerState<RAOE2Screen> {
  static const String _manualSourceValue = '__manual__';
  static const List<String> _tones = <String>[
    'Professional',
    'Executive',
    'Modern',
    'Concise',
  ];

  late final TextEditingController _resumeController;
  late final TextEditingController _jobDescController;

  final List<ResumeModel> _allResumes = <ResumeModel>[];

  ResumeModel? _selectedResume;
  Set<String> _missingKeywords = <String>{};
  RAOE2OptimizationResult? _result;
  String _apiKey = '';
  String _selectedTone = _tones.first;
  String _manualResumeDraft = '';
  String? _errorMessage;
  bool _isOptimizing = false;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _resumeController = TextEditingController(text: widget.resumeText);
    _jobDescController = TextEditingController(text: widget.jobDescription);
    _manualResumeDraft = widget.resumeText;
    _resumeController.addListener(_handleInputChanged);
    _jobDescController.addListener(_handleInputChanged);
    _loadApiKey();
    _loadResumes();
    _refreshKeywordAnalysis();
  }

  @override
  void dispose() {
    _resumeController.dispose();
    _jobDescController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await AiApiKeyStorageService.read();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiKey = apiKey;
    });
  }

  void _loadResumes({String? preferredResumeId}) {
    final resumes = StorageService.getAllResumes()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    _allResumes
      ..clear()
      ..addAll(resumes);

    final shouldDefaultToSavedResume =
        widget.resumeText.trim().isEmpty && resumes.isNotEmpty;
    final targetId = preferredResumeId ?? widget.resumeId;

    if (targetId != null) {
      final matched = resumes.where((resume) => resume.id == targetId).toList();
      if (matched.isNotEmpty) {
        _applyResumeSource(matched.first, updateState: true);
        return;
      }
    }

    if (shouldDefaultToSavedResume) {
      _applyResumeSource(resumes.first, updateState: true);
      return;
    }

    if (mounted) {
      setState(() {
        _selectedResume = null;
      });
    }
  }

  void _handleInputChanged() {
    if (_selectedResume == null) {
      _manualResumeDraft = _resumeController.text;
    }
    setState(() {
      _result = null;
      _errorMessage = null;
      _refreshKeywordAnalysis();
    });
  }

  void _refreshKeywordAnalysis() {
    _missingKeywords = RAOE2KeywordAnalyzer.findMissingKeywords(
      resumeText: _resumeController.text,
      jobDescription: _jobDescController.text,
    );
  }

  void _handleResumeSourceChanged(String? value) {
    if (value == null || value == _manualSourceValue) {
      if (_selectedResume != null) {
        _setControllerText(_manualResumeDraft);
      }
      setState(() {
        _selectedResume = null;
        _result = null;
        _errorMessage = null;
      });
      return;
    }

    final matches = _allResumes.where((resume) => resume.id == value).toList();
    if (matches.isEmpty) {
      return;
    }
    _applyResumeSource(matches.first, updateState: true);
  }

  void _applyResumeSource(ResumeModel resume, {required bool updateState}) {
    if (_selectedResume == null) {
      _manualResumeDraft = _resumeController.text;
    }
    _setControllerText(RAOE2Service.buildEditableResumeText(resume));

    if (!updateState || !mounted) {
      _selectedResume = resume;
      return;
    }

    setState(() {
      _selectedResume = resume;
      _result = null;
      _errorMessage = null;
    });
  }

  void _setControllerText(String value) {
    _resumeController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _optimizeResume() async {
    final resumeText = _resumeController.text.trim();
    final jobDescription = _jobDescController.text.trim();

    if (resumeText.length < 50) {
      setState(() {
        _errorMessage = 'Add more resume content before optimizing.';
      });
      return;
    }
    if (jobDescription.length < 50) {
      setState(() {
        _errorMessage = 'Paste a fuller job description before optimizing.';
      });
      return;
    }
    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isOptimizing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await RAOE2Service.optimize(
        apiKey: _apiKey,
        resumeText: resumeText,
        jobDescription: jobDescription,
        resume: _selectedResume,
        tone: _selectedTone,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isOptimizing = false;
      });
    } on AiConfigException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isOptimizing = false;
      });
      _showApiKeyDialog();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isOptimizing = false;
      });
    }
  }

  Future<void> _saveOptimizedVersion() async {
    final result = _result;
    if (result == null) {
      return;
    }

    final resumeId =
        _selectedResume?.id ?? _resumeController.text.hashCode.toString();
    await RAOE2VersionService.saveOptimizedVersion(
      resumeId: resumeId,
      optimizedText: result.optimizedResumeText,
    );

    widget.onSave?.call(result.optimizedResumeText);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Optimized draft saved for later.')),
    );
  }

  Future<void> _applyToResume() async {
    final result = _result;
    final resume = _selectedResume;
    if (result == null || resume == null || !result.hasStructuredResumeUpdate) {
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      await ResumeVersionService.saveVersion(
        resume: resume,
        changeType: 'raoe2_optimize',
        description: 'Before RAOE2 optimization',
      );

      final updatedResume = RAOE2Service.applyToResume(
        resume: resume,
        result: result,
      );

      await StorageService.saveResume(updatedResume);
      await RAOE2VersionService.saveOptimizedVersion(
        resumeId: updatedResume.id,
        optimizedText: result.optimizedResumeText,
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(resumesProvider);
      ref.invalidate(currentResumeProvider(updatedResume.id));

      _loadResumes(preferredResumeId: updatedResume.id);
      _setControllerText(RAOE2Service.buildEditableResumeText(updatedResume));

      setState(() {
        _selectedResume = updatedResume;
        _result = null;
        _isApplying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Optimizations applied to the selected resume.'),
          action: SnackBarAction(
            label: 'Preview',
            onPressed: () => context.push('/preview/${updatedResume.id}'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Could not apply the optimized result. ${error.toString()}';
        _isApplying = false;
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.cpu, color: AppColors.primary),
            SizedBox(width: 10),
            Text('AI Service'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI access is managed by the app. You do not need to create or paste a personal API key.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              'If AI is unavailable right now, the app configuration is missing or temporarily unavailable. Please try again later.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Resume Auto-Optimization (RAOE 2)'),
        actions: [
          IconButton(
            onPressed: _showApiKeyDialog,
            icon: Icon(
              Iconsax.key,
              color: _apiKey.isNotEmpty ? AppColors.success : AppColors.warning,
            ),
            tooltip: _apiKey.isNotEmpty
                ? 'AI service ready'
                : 'AI service unavailable',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(theme),
            const SizedBox(height: 16),
            _buildResumeSourcePicker(theme),
            const SizedBox(height: 16),
            _buildResumeInput(theme),
            const SizedBox(height: 16),
            _buildJobDescriptionInput(theme),
            const SizedBox(height: 16),
            _buildToneSelector(theme),
            const SizedBox(height: 20),
            _buildKeywordPanel(theme),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isOptimizing ? null : _optimizeResume,
                  icon: _isOptimizing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.magic_star),
                  label: Text(
                      _isOptimizing ? 'Optimizing...' : 'Optimize with AI'),
                ),
                if (result != null)
                  OutlinedButton.icon(
                    onPressed: _saveOptimizedVersion,
                    icon: const Icon(Iconsax.archive_2),
                    label: const Text('Save Optimized Draft'),
                  ),
                if (result != null && _selectedResume != null)
                  FilledButton.tonalIcon(
                    onPressed: _isApplying ? null : _applyToResume,
                    icon: _isApplying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.document_upload),
                    label:
                        Text(_isApplying ? 'Applying...' : 'Apply to Resume'),
                  ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 24),
              _buildResultMetrics(theme, result),
              if (result.overallRationale.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCalloutCard(
                  title: 'Why These Changes',
                  body: result.overallRationale,
                  color: AppColors.info,
                ),
              ],
              if (result.actionableSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSuggestionsCard(theme, result),
              ],
              if (result.sectionRewrites.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Section Rewrites', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...result.sectionRewrites.map((section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSectionRewriteCard(theme, section),
                    )),
              ],
              const SizedBox(height: 16),
              Text('Preview Diff', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildPreviewPane(
                theme,
                label: 'Before',
                color: Colors.grey.shade100,
                text: result.originalResumeText,
              ),
              const SizedBox(height: 12),
              _buildPreviewPane(
                theme,
                label: 'After',
                color: Colors.green.shade50,
                text: result.optimizedResumeText,
              ),
              const SizedBox(height: 12),
              Text(
                'Engine: ${result.engineId} (${result.engineVersion})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target a real job posting', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            _selectedResume != null
                ? 'RAOE2 will rewrite the selected resume using AI, show section-level diffs, then let you apply the result back into the resume so PreviewScreen reflects the changes.'
                : 'Use manual mode to optimize raw resume text, or choose a saved resume to push AI rewrites back into the app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSourcePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume Source', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedResume?.id ?? _manualSourceValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          selectedItemBuilder: (context) => [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manual text entry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ..._allResumes.map(
              (resume) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          items: [
            const DropdownMenuItem<String>(
              value: _manualSourceValue,
              child: Text(
                'Manual text entry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ..._allResumes.map(
              (resume) => DropdownMenuItem<String>(
                value: resume.id,
                child: Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _handleResumeSourceChanged,
        ),
      ],
    );
  }

  Widget _buildResumeInput(ThemeData theme) {
    final isReadOnly = _selectedResume != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume Text', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (isReadOnly)
          Text(
            'This text is generated from the selected saved resume. Switch to Manual text entry if you want to paste a custom draft instead.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _resumeController,
          readOnly: isReadOnly,
          minLines: 8,
          maxLines: 16,
          decoration: InputDecoration(
            hintText: 'Paste your resume text here',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            fillColor: isReadOnly ? Colors.grey.shade50 : null,
            filled: isReadOnly,
          ),
        ),
      ],
    );
  }

  Widget _buildJobDescriptionInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Description', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _jobDescController,
          minLines: 6,
          maxLines: 14,
          decoration: const InputDecoration(
            hintText: 'Paste the target job description here',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildToneSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rewrite Tone', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tones.map((tone) {
            final selected = tone == _selectedTone;
            return ChoiceChip(
              label: Text(tone),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedTone = tone;
                  _result = null;
                });
              },
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildKeywordPanel(ThemeData theme) {
    final sortedKeywords = _missingKeywords.toList(growable: false)..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Missing Keywords', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            sortedKeywords.isEmpty
                ? 'No missing keywords were detected yet. Add a fuller job description or optimize to see AI-guided changes.'
                : '${sortedKeywords.length} target keywords are missing from the current resume draft.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (sortedKeywords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedKeywords
                  .map((keyword) => Chip(label: Text(keyword)))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultMetrics(
    ThemeData theme,
    RAOE2OptimizationResult result,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricCard(
          theme,
          label: 'Keywords Added',
          value: '${result.keywordsAdded.length}',
          color: AppColors.primary,
        ),
        _buildMetricCard(
          theme,
          label: 'Keywords Addressed',
          value: '${result.missingKeywordsAddressed.length}',
          color: AppColors.success,
        ),
        _buildMetricCard(
          theme,
          label: 'Sections Rewritten',
          value: '${result.sectionRewrites.length}',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCalloutCard({
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(
    ThemeData theme,
    RAOE2OptimizationResult result,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actionable Suggestions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.actionableSuggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Iconsax.tick_circle, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(suggestion)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRewriteCard(
    ThemeData theme,
    RAOE2SectionRewrite section,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(section.label, style: theme.textTheme.titleSmall),
              ),
              if (section.keywordsAdded.isNotEmpty)
                Text(
                  '${section.keywordsAdded.length} keywords',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (section.rationale.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              section.rationale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (section.keywordsAdded.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: section.keywordsAdded
                  .map((keyword) => Chip(label: Text(keyword)))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          _buildPreviewPane(
            theme,
            label: 'Original',
            color: Colors.grey.shade100,
            text: section.originalText,
            dense: true,
          ),
          const SizedBox(height: 10),
          _buildPreviewPane(
            theme,
            label: 'Optimized',
            color: Colors.green.shade50,
            text: section.optimizedText,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPane(
    ThemeData theme, {
    required String label,
    required Color color,
    required String text,
    bool dense = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 12 : 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            text.trim().isEmpty ? 'No content available.' : text.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
