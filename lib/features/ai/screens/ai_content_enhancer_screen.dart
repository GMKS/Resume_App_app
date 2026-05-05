import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/ai_api_key_storage_service.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/skill_suggestions_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/ai_review_notice.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;
import '../../editor/screens/resume_editor_screen.dart' show currentResumeProvider;

/// Screen to generate AI-powered resume content
class AiContentEnhancerScreen extends ConsumerStatefulWidget {
  final String? resumeId;

  const AiContentEnhancerScreen({super.key, this.resumeId});

  @override
  ConsumerState<AiContentEnhancerScreen> createState() => _AiContentEnhancerScreenState();
}

class _AiContentEnhancerScreenState extends ConsumerState<AiContentEnhancerScreen> {
  static const String _createNewResumeValue = '__create_new_resume__';

  final _industryController = TextEditingController();
  final _existingDescController = TextEditingController();
  bool _isGenerating = false;
  bool _showResult = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;
  String _apiKey = '';

  // Form state
  String _selectedJobTitle = 'Software Engineer';
  int _experienceYears = 3;
  final List<String> _selectedSkills = [];

  List<ResumeModel> _allResumes = [];
  ResumeModel? _selectedResume;
  String? _newResumeTitle;
  int _resumeDropdownResetVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadResumes();
  }

  @override
  void dispose() {
    _industryController.dispose();
    _existingDescController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await AiApiKeyStorageService.read();
    setState(() => _apiKey = apiKey);
  }

  void _loadResumes() {
    final resumes = StorageService.getAllResumes();
    setState(() {
      _allResumes = resumes;
      if (widget.resumeId != null) {
        try {
          _selectedResume = resumes.firstWhere((r) => r.id == widget.resumeId);
        } catch (_) {
          _selectedResume = resumes.isNotEmpty ? resumes.first : null;
        }
      } else {
        _selectedResume = resumes.isNotEmpty ? resumes.first : null;
      }
      // Pre-fill job title and skills from selected resume
      _prefillFromResume();
    });
  }

  void _prefillFromResume() {
    if (_selectedResume == null) return;
    final resume = _selectedResume!;
    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty) {
      _selectedJobTitle = resume.personalInfo.jobTitle!;
    }
    if (resume.skills.isNotEmpty) {
      _selectedSkills.addAll(
        resume.skills.take(6).map((s) => s.name).where((n) => n.isNotEmpty),
      );
    }
  }

  List<String> get _suggestedSkills {
    return SkillSuggestionsService.getSkillsForRole(_selectedJobTitle);
  }

  String get _selectedResumeDropdownValue {
    return _selectedResume?.id ?? _createNewResumeValue;
  }

  String _formatSummaryAsBulletLines(String summary) {
    final cleaned = summary.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }

    final existingLines = cleaned
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (existingLines.length > 1) {
      return existingLines.join('\n');
    }

    final sentenceLines = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return sentenceLines.isEmpty ? cleaned : sentenceLines.join('\n');
  }

  Future<void> _generateContent() async {
    if (_selectedSkills.isEmpty) {
      setState(() => _errorMessage = 'Add at least one skill.');
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
    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _showResult = false;
    });

    try {
      final result = await AiResumeService.generateResumeContent(
        apiKey: _apiKey,
        jobTitle: _selectedJobTitle,
        experienceYears: _experienceYears,
        industry: _industryController.text.trim().isNotEmpty
            ? _industryController.text.trim()
            : 'Technology',
        skillsList: _selectedSkills,
        existingDescription: _existingDescController.text.trim().isNotEmpty
            ? _existingDescController.text.trim()
            : null,
      );

      result['professionalSummary'] = _formatSummaryAsBulletLines(
        (result['professionalSummary'] as String? ?? '').trim(),
      );

      setState(() {
        _result = result;
        _showResult = true;
        _isGenerating = false;
      });
      await FreePlanService.consumeAiSuggestion();
    } on AiUsageLimitException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isGenerating = false;
      });
    } on AiConfigException catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.message;
      });
      _showApiKeyDialog();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _applyToResume() async {
    if (_result == null) return;

    final summary = (_result!['professionalSummary'] as String? ?? '').trim();
    final bullets = (_result!['optimizedExperience'] as List? ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final keywords = (_result!['atsKeywordsUsed'] as List? ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_selectedResume != null) {
      ResumeModel updated = _selectedResume!;

      // 1. Apply professional summary to objective
      if (summary.isNotEmpty) {
        updated = updated.copyWith(objective: summary);
      }

      // 2. Apply all bullets as achievements to the first (most recent) experience entry
      if (bullets.isNotEmpty) {
        if (updated.experience.isNotEmpty) {
          // Apply all bullets as achievements to the first experience entry
          final updatedFirst = updated.experience.first.copyWith(achievements: bullets);
          final newExps = [updatedFirst, ...updated.experience.skip(1)];
          updated = updated.copyWith(experience: newExps);
        } else {
          // No experience entries — create one with all generated bullets as achievements
          final newExp = Experience(
            id: const Uuid().v4(),
            company: 'Your Company',
            position: _selectedJobTitle,
            startDate: DateTime.now().subtract(Duration(days: 365 * _experienceYears)),
            isCurrentlyWorking: true,
            description: '',
            achievements: bullets,
            location: '',
          );
          updated = updated.copyWith(experience: [newExp]);
        }
      }

      // 3. Add ATS keywords to skills (skip duplicates)
      if (keywords.isNotEmpty) {
        final existingNames = updated.skills.map((s) => s.name.toLowerCase()).toSet();
        final newSkills = List<Skill>.from(updated.skills);
        for (final kw in keywords) {
          if (!existingNames.contains(kw.toLowerCase())) {
            newSkills.add(Skill(
              id: const Uuid().v4(),
              name: kw,
              proficiency: 3,
              category: 'Technical',
            ));
            existingNames.add(kw.toLowerCase());
          }
        }
        updated = updated.copyWith(skills: newSkills);
      }

      // 4. Update timestamp
      updated = updated.copyWith(updatedAt: DateTime.now());

      await StorageService.saveResume(updated);
      ref.invalidate(resumesProvider);
      // Also invalidate the editor's per-resume provider so sub-screens (Summary, Experience) reload fresh data
      ref.invalidate(currentResumeProvider(updated.id));

      // Update local reference so snackbar action uses correct id
      setState(() => _selectedResume = updated);

      if (mounted) {
        _showApplySuccessDialog(
          resumeId: updated.id,
          resumeTitle: updated.title,
          isNew: false,
        );
      }
    } else {
      final resumeTitle = (_newResumeTitle?.trim().isNotEmpty ?? false)
          ? _newResumeTitle!.trim()
          : await _promptForNewResumeName(
              initialName: '$_selectedJobTitle Resume',
            );
      if (resumeTitle == null) {
        return;
      }

      // Create new resume with all generated content
      final bulletsText = bullets.map((b) => '• $b').join('\n');
      final exp = Experience(
        id: const Uuid().v4(),
        company: '',
        position: _selectedJobTitle,
        startDate: DateTime.now().subtract(Duration(days: 365 * _experienceYears)),
        isCurrentlyWorking: true,
        description: bulletsText,
        location: '',
      );

      // Merge selected skills + ATS keywords (no duplicates)
      final allSkillNames = {..._selectedSkills};
      for (final kw in keywords) {
        allSkillNames.add(kw);
      }

      final newResume = ResumeModel(
        id: const Uuid().v4(),
        title: resumeTitle,
        personalInfo: PersonalInfo(
          fullName: '',
          email: '',
          phone: '',
          address: '',
          jobTitle: _selectedJobTitle,
        ),
        objective: summary,
        experience: [exp],
        education: [],
        skills: allSkillNames.map((name) => Skill(
          id: const Uuid().v4(),
          name: name,
          proficiency: 3,
          category: 'Technical',
        )).toList(),
        projects: [],
        certifications: [],
        languages: [],
        hobbies: [],
        references: [],
        templateId: 'modern',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await StorageService.saveResume(newResume);
      ref.invalidate(resumesProvider);
      ref.invalidate(currentResumeProvider(newResume.id));

      if (mounted) {
        setState(() {
          _allResumes = [newResume, ..._allResumes];
          _selectedResume = newResume;
          _newResumeTitle = null;
        });
      }

      if (mounted) {
        _showApplySuccessDialog(
          resumeId: newResume.id,
          resumeTitle: newResume.title,
          isNew: true,
        );
      }
    }
  }

  Future<void> _handleResumeSelection(String? id) async {
    if (id == null) {
      return;
    }

    if (id == _createNewResumeValue) {
      final resumeTitle = await _promptForNewResumeName(
        initialName: (_newResumeTitle?.trim().isNotEmpty ?? false)
            ? _newResumeTitle!.trim()
            : '$_selectedJobTitle Resume',
      );
      if (!mounted) {
        return;
      }
      if (resumeTitle == null) {
        setState(() {
          _resumeDropdownResetVersion++;
        });
        return;
      }

      setState(() {
        _selectedResume = null;
        _newResumeTitle = resumeTitle;
        _showResult = false;
        _result = null;
      });
      return;
    }

    setState(() {
      _selectedResume = _allResumes.firstWhere((r) => r.id == id);
      _newResumeTitle = null;
      _showResult = false;
      _result = null;
      _selectedSkills.clear();
      _prefillFromResume();
    });
  }

  Future<String?> _promptForNewResumeName({String? initialName}) async {
    final nameController = TextEditingController(text: initialName ?? '');
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('New Resume'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Give your resume a name:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Software Engineer Resume',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _submitNewResumeName(
                  dialogContext: dialogContext,
                  nameController: nameController,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitNewResumeName(
                dialogContext: dialogContext,
                nameController: nameController,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
    }
  }

  void _submitNewResumeName({
    required BuildContext dialogContext,
    required TextEditingController nameController,
  }) {
    final trimmedName = nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resume name')),
      );
      return;
    }

    Navigator.pop(dialogContext, trimmedName);
  }

  void _showApplySuccessDialog({
    required String resumeId,
    required String resumeTitle,
    required bool isNew,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              isNew ? 'Resume Created!' : 'Content Applied!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isNew
                  ? 'A new resume "$resumeTitle" was created with your AI-generated content.'
                  : 'Summary, experience bullets & ATS keywords were saved to "$resumeTitle".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Primary button — View Summary
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/editor/$resumeId/summary');
                },
                icon: const Icon(Iconsax.document_text_1, color: Colors.white),
                label: const Text('View Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary button — View Experience
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/editor/$resumeId/experience');
                },
                icon: const Icon(Iconsax.briefcase, color: Colors.white),
                label: const Text('View Experience', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tertiary — Stay here
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Stay Here', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.key, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Groq API Key (Free)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get a completely FREE key at:\nconsole.groq.com → API Keys\n(No credit card required!)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Paste API Key',
                prefixIcon: const Icon(Iconsax.key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await AiApiKeyStorageService.save(key);
                setState(() => _apiKey = key);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveTooltip(
          message: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
        ),
        title: const Text('AI Content Enhancer'),
        actions: [
          AdaptiveTooltip(
            message: _apiKey.isNotEmpty ? 'API Key configured' : 'Add API Key',
            button: true,
            child: IconButton(
              onPressed: _showApiKeyDialog,
              icon: Icon(
                Iconsax.key,
                color:
                    _apiKey.isNotEmpty ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.magic_star, color: Color(0xFF8B5CF6), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Content Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text(
                          'Generate professional summaries, bullet points, and ATS keywords.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 20),

            // Apply to resume (optional)
            Text('Apply To (optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'resume-target-${_selectedResumeDropdownValue}_$_resumeDropdownResetVersion',
              ),
              initialValue: _selectedResumeDropdownValue,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.document_text_1),
                hintText: 'Select existing resume to update',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: _createNewResumeValue,
                  child: Text(
                    'Create new resume',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
                ..._allResumes.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.title, overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: _handleResumeSelection,
            ),
            if (_selectedResume == null && (_newResumeTitle?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                'New resume name: ${_newResumeTitle!.trim()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Job Title
            Text('Target Job Title',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: SkillSuggestionsService.allRoles.contains(_selectedJobTitle)
                  ? _selectedJobTitle
                  : SkillSuggestionsService.allRoles.first,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.briefcase),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: SkillSuggestionsService.allRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedJobTitle = v ?? _selectedJobTitle;
                _selectedSkills.clear();
                _showResult = false;
              }),
            ),

            const SizedBox(height: 16),

            // Industry
            Text('Industry / Company Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _industryController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.building_4),
                hintText: 'e.g. FinTech, Healthcare, E-Commerce...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Experience 
            Text('Years of Experience: $_experienceYears years',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Slider(
              value: _experienceYears.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              activeColor: AppColors.primary,
              label: '$_experienceYears yrs',
              onChanged: (v) => setState(() => _experienceYears = v.round()),
            ),

            const SizedBox(height: 16),

            // Skills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Skills (${_selectedSkills.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (_selectedSkills.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedSkills.clear()),
                    icon: const Icon(Iconsax.close_circle, size: 14),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedSkills.remove(skill);
                    } else {
                      _selectedSkills.add(skill);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Existing description (optional)
            Text('Existing Summary to Improve (optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _existingDescController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Paste your current summary for AI to improve...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isGenerating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Iconsax.magic_star, color: Colors.white),
                label: Text(
                  _isGenerating ? 'Generating content...' : 'Generate with AI',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                ),
              ),
            ),

            // Results
            if (_showResult && _result != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _buildResultsSection(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final summary = _result!['professionalSummary'] as String? ?? '';
    final bullets = _result!['optimizedExperience'] as List? ?? [];
    final metrics = _result!['suggestedMetrics'] as List? ?? [];
    final keywords = _result!['atsKeywordsUsed'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.magic_star, color: Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 8),
            Text('Generated Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ).animate().fadeIn(),
        const SizedBox(height: 16),
        const AiReviewNotice(),
        const SizedBox(height: 16),

        // Professional summary
        if (summary.isNotEmpty)
          _buildCard(
            icon: Iconsax.document_text_1,
            title: 'Professional Summary',
            color: AppColors.primary,
            child: Text(summary, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
          ),

        const SizedBox(height: 12),

        // Bullet points
        if (bullets.isNotEmpty)
          _buildCard(
            icon: Iconsax.edit_2,
            title: 'Optimized Experience Bullets',
            color: AppColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b.toString(), style: const TextStyle(fontSize: 13, height: 1.4))),
                  ],
                ),
              )).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // ATS keywords
        if (keywords.isNotEmpty)
          _buildCard(
            icon: Iconsax.tag,
            title: 'ATS Keywords',
            color: AppColors.info,
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: keywords.map((k) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(k.toString(), style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Suggested metrics
        if (metrics.isNotEmpty)
          _buildCard(
            icon: Iconsax.chart_1,
            title: 'Suggested Metrics to Add',
            color: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: metrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Iconsax.arrow_up_2, size: 14, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.toString(), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),

        const SizedBox(height: 20),

        // Apply button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _applyToResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Iconsax.document_download, color: Colors.white),
            label: Text(
              _selectedResume != null
                  ? 'Apply to "${_selectedResume!.title}"'
                  : ((_newResumeTitle?.trim().isNotEmpty ?? false)
                      ? 'Create "${_newResumeTitle!.trim()}"'
                      : 'Create New Resume'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildCard({required IconData icon, required String title, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}
