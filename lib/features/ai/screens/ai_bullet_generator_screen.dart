import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../editor/screens/resume_editor_screen.dart'
    show currentResumeProvider;
import '../../home/screens/home_screen.dart' show resumesProvider;
import '../widgets/ai_bullet_results_panel.dart';

class AIBulletGeneratorScreen extends ConsumerStatefulWidget {
  final String? resumeId;

  const AIBulletGeneratorScreen({super.key, this.resumeId});

  @override
  ConsumerState<AIBulletGeneratorScreen> createState() =>
      _AIBulletGeneratorScreenState();
}

class _AIBulletGeneratorScreenState
    extends ConsumerState<AIBulletGeneratorScreen> {
  final _jobTitleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<String> _bullets = [];
  final Set<int> _copiedIndex = {};
  final Set<int> _selectedBulletIndexes = {};
  List<ResumeModel> _allResumes = [];
  ResumeModel? _selectedResume;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  @override
  void dispose() {
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _loadResumes() {
    final resumes = StorageService.getAllResumes();
    ResumeModel? selectedResume;

    if (widget.resumeId != null) {
      for (final resume in resumes) {
        if (resume.id == widget.resumeId) {
          selectedResume = resume;
          break;
        }
      }
    }

    selectedResume ??= resumes.length == 1 ? resumes.first : null;

    if (mounted) {
      setState(() {
        _allResumes = resumes;
        _selectedResume = selectedResume;
      });
    }
  }

  List<String> get _selectedBullets {
    final indexes = _selectedBulletIndexes.toList()..sort();
    return indexes.map((index) => _bullets[index]).toList();
  }

  void _toggleBulletSelection(int index) {
    setState(() {
      if (_selectedBulletIndexes.contains(index)) {
        _selectedBulletIndexes.remove(index);
      } else {
        _selectedBulletIndexes.add(index);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedBulletIndexes.length == _bullets.length) {
        _selectedBulletIndexes.clear();
      } else {
        _selectedBulletIndexes
          ..clear()
          ..addAll(List<int>.generate(_bullets.length, (index) => index));
      }
    });
  }

  void _setSelectedResume(String? resumeId) {
    if (resumeId == null) {
      setState(() => _selectedResume = null);
      return;
    }

    ResumeModel? selectedResume;
    for (final resume in _allResumes) {
      if (resume.id == resumeId) {
        selectedResume = resume;
        break;
      }
    }

    setState(() => _selectedResume = selectedResume);
  }

  List<String> _dedupeBullets(List<String> bullets) {
    final seen = <String>{};
    final deduped = <String>[];

    for (final bullet in bullets) {
      final normalized = bullet.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        deduped.add(normalized);
      }
    }

    return deduped;
  }

  Future<void> _generate() async {
    final jobTitle = _jobTitleCtrl.text.trim();
    final company = _companyCtrl.text.trim();
    final industry = _industryCtrl.text.trim();

    if (jobTitle.isEmpty) {
      setState(() => _errorMessage = 'Please enter a job title.');
      return;
    }
    if (industry.isEmpty) {
      setState(() => _errorMessage = 'Please enter the industry.');
      return;
    }
    if (!FreePlanService.canUseAiSuggestion) {
      showUpgradePromptSheet(
        context,
        featureName: 'ai_assistant',
        message: FreePlanService.aiLimitMessage,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bullets = [];
      _selectedBulletIndexes.clear();
      _copiedIndex.clear();
    });

    try {
      final result = await AiResumeService.generateBulletPoints(
        jobTitle: jobTitle,
        company: company.isEmpty ? 'a company' : company,
        industry: industry,
        existingDescription: _descCtrl.text.trim(),
      );

      final bullets = (result['bullets'] as List?)
              ?.map(
                (b) =>
                    b.toString().replaceFirst(RegExp(r'^[\-•\s]+'), '').trim(),
              )
              .where((bullet) => bullet.isNotEmpty)
              .toList() ??
          [];

      setState(() => _bullets = bullets);
      await FreePlanService.consumeAiSuggestion();
    } on AiConfigException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
          () => _errorMessage = AiResumeService.describeUnexpectedError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyBullet(int index) {
    Clipboard.setData(ClipboardData(text: _bullets[index]));
    setState(() => _copiedIndex.add(index));
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _copiedIndex.remove(index)) : null);
  }

  void _copyAll() {
    final text = _bullets.map((b) => '• $b').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All bullets copied to clipboard'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _copySelected() {
    if (_selectedBulletIndexes.isEmpty) {
      return;
    }

    final text = _selectedBullets.map((bullet) => '• $bullet').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedBulletIndexes.length} selected bullet${_selectedBulletIndexes.length == 1 ? '' : 's'} copied to clipboard',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _addSelectedToResume() async {
    if (_selectedBulletIndexes.isEmpty) {
      return;
    }
    if (_selectedResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a target resume first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final latestResume = StorageService.getResume(_selectedResume!.id);
    if (latestResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected resume could not be loaded.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedBullets = _selectedBullets;
    final updatedAt = DateTime.now();
    ResumeModel updatedResume;

    if (latestResume.experience.isNotEmpty) {
      final firstExperience = latestResume.experience.first;
      final mergedAchievements = _dedupeBullets([
        ...firstExperience.achievements,
        ...selectedBullets,
      ]);

      final updatedExperience = firstExperience.copyWith(
        company: firstExperience.company.isEmpty
            ? _companyCtrl.text.trim()
            : firstExperience.company,
        position: firstExperience.position.isEmpty
            ? _jobTitleCtrl.text.trim()
            : firstExperience.position,
        achievements: mergedAchievements,
      );

      updatedResume = latestResume.copyWith(
        experience: [updatedExperience, ...latestResume.experience.skip(1)],
        updatedAt: updatedAt,
      );
    } else {
      final newExperience = Experience(
        id: const Uuid().v4(),
        company: _companyCtrl.text.trim(),
        position: _jobTitleCtrl.text.trim(),
        location: '',
        startDate: updatedAt,
        isCurrentlyWorking: true,
        description: _descCtrl.text.trim(),
        achievements: selectedBullets,
      );

      updatedResume = latestResume.copyWith(
        experience: [newExperience],
        updatedAt: updatedAt,
      );
    }

    await StorageService.saveResume(updatedResume);
    ref.invalidate(resumesProvider);
    ref.invalidate(currentResumeProvider(updatedResume.id));

    if (!mounted) {
      return;
    }

    setState(() => _selectedResume = updatedResume);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${selectedBullets.length} bullet${selectedBullets.length == 1 ? '' : 's'} to "${updatedResume.title}".',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bullet Generator'),
        actions: [
          if (_bullets.isNotEmpty)
            TextButton.icon(
              onPressed: _copyAll,
              icon: const Icon(Iconsax.copy, size: 16),
              label: const Text('Copy All'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.magic_star,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Bullet Generator',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          'Generate powerful, ATS-optimised bullet points for your work experience.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Form
            Text('Job Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            TextField(
              controller: _jobTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                hintText: 'e.g. Software Engineer',
                prefixIcon: Icon(Iconsax.briefcase, size: 20),
              ),
            ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0),

            const SizedBox(height: 12),

            TextField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Company (optional)',
                hintText: 'e.g. Google',
                prefixIcon: Icon(Iconsax.buildings_2, size: 20),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),

            const SizedBox(height: 12),

            TextField(
              controller: _industryCtrl,
              decoration: const InputDecoration(
                labelText: 'Industry *',
                hintText: 'e.g. Technology, Healthcare, Finance',
                prefixIcon: Icon(Iconsax.chart_21, size: 20),
              ),
            ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05, end: 0),

            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Existing description (optional)',
                hintText: 'Paste your current job description to improve it...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Iconsax.document_text, size: 20),
                ),
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05, end: 0),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.info_circle,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Iconsax.magic_star, size: 20),
                label: Text(_isLoading ? 'Generating...' : 'Generate Bullets'),
              ),
            ).animate().fadeIn(delay: 350.ms),

            // Results
            if (_bullets.isNotEmpty) ...[
              const SizedBox(height: 28),
              AiBulletResultsPanel(
                bullets: _bullets,
                selectedIndexes: _selectedBulletIndexes,
                copiedIndexes: _copiedIndex,
                resumes: _allResumes,
                selectedResumeId: _selectedResume?.id,
                onResumeChanged: _setSelectedResume,
                onToggleSelection: _toggleBulletSelection,
                onCopyBullet: _copyBullet,
                onToggleSelectAll: _toggleSelectAll,
                onCopySelected:
                    _selectedBulletIndexes.isEmpty ? null : _copySelected,
                onAddSelectedToResume: _selectedBulletIndexes.isEmpty
                    ? null
                    : _addSelectedToResume,
              ).animate().fadeIn(),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}
