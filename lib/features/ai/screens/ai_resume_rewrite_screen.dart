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
import '../../../core/services/resume_json.dart';
import '../../../core/services/resume_version_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/ai_review_notice.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;

/// Accent color used for the rewrite feature
const _kRewriteColor = Color(0xFF8B5CF6); // violet

/// Screen that rewrites an entire resume using AI for maximum impact
class AiResumeRewriteScreen extends ConsumerStatefulWidget {
  /// If passed, a specific resume is pre-selected
  final String? resumeId;

  const AiResumeRewriteScreen({super.key, this.resumeId});

  @override
  ConsumerState<AiResumeRewriteScreen> createState() =>
      _AiResumeRewriteScreenState();
}

class _AiResumeRewriteScreenState extends ConsumerState<AiResumeRewriteScreen> {
  final _targetJobTitleController = TextEditingController();

  bool _isRewriting = false;
  bool _showResult = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  String? _selectedResumeId;
  String _apiKey = '';
  List<ResumeModel> _allResumes = [];

  /// Available writing tones
  static const List<_ToneOption> _tones = [
    _ToneOption('Professional', Iconsax.briefcase, AppColors.primary),
    _ToneOption('Executive', Iconsax.crown_1, Color(0xFF8B5CF6)),
    _ToneOption('Creative', Iconsax.brush_2, AppColors.secondary),
    _ToneOption('Modern', Iconsax.flash, AppColors.info),
  ];

  int _selectedToneIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadResumes();
    _selectedResumeId = widget.resumeId;
  }

  void _loadResumes() {
    final resumes = StorageService.getAllResumes();
    setState(() {
      _allResumes = resumes;
      if (widget.resumeId != null) {
        _selectedResumeId = widget.resumeId;
        try {
          final selected = resumes.firstWhere((r) => r.id == widget.resumeId);
          if (_targetJobTitleController.text.isEmpty) {
            _targetJobTitleController.text = selected.personalInfo.jobTitle ?? '';
          }
        } catch (_) {
          // Resume not found, will show empty list
        }
      } else if (_selectedResumeId == null && resumes.isNotEmpty) {
        _selectedResumeId = resumes.first.id;
        if (_targetJobTitleController.text.isEmpty) {
          _targetJobTitleController.text = resumes.first.personalInfo.jobTitle ?? '';
        }
      }
    });
  }

  @override
  void dispose() {
    _targetJobTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await AiApiKeyStorageService.read();
    setState(() => _apiKey = apiKey);
  }

  Future<void> _rewriteResume(List<ResumeModel> allResumes) async {
    if (!FreePlanService.isPremium) {
      showUpgradePromptSheet(
        context,
        featureName: 'ai_assistant',
        message: FreePlanService.premiumAiToolMessage,
      );
      return;
    }

    final selectedResume = _selectedResumeId != null
        ? allResumes.firstWhere((r) => r.id == _selectedResumeId,
            orElse: () => allResumes.first)
        : allResumes.isNotEmpty
            ? allResumes.first
            : null;
    if (selectedResume == null) {
      setState(() => _errorMessage = 'Please select a resume first.');
      return;
    }
    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isRewriting = true;
      _errorMessage = null;
      _showResult = false;
    });

    try {
      // Auto-save version before rewriting
      await ResumeVersionService.saveVersion(
        resume: selectedResume,
        changeType: 'ai_rewrite',
        description: 'Before AI full rewrite',
      );

      final resumeMap = ResumeJson.toMap(selectedResume);
      final tone = _tones[_selectedToneIndex].label;
      final targetTitle = _targetJobTitleController.text.trim();

      final result = await AiResumeService.rewriteFullResume(
        apiKey: _apiKey,
        resumeJson: resumeMap,
        tone: tone,
        targetJobTitle: targetTitle.isNotEmpty ? targetTitle : null,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _showResult = true;
        _isRewriting = false;
      });

    } on AiUsageLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isRewriting = false;
      });
    } on AiConfigException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRewriting = false;
        _errorMessage = e.message;
      });
      _showApiKeyDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isRewriting = false;
      });
    }
  }

  void _applyToResume(List<ResumeModel> allResumes) {
    if (_result == null) return;
    final resume = _selectedResumeId != null
        ? allResumes.firstWhere((r) => r.id == _selectedResumeId,
            orElse: () => allResumes.first)
        : allResumes.isNotEmpty
            ? allResumes.first
            : null;
    if (resume == null) return;
    final rewrittenSummary = _result!['rewrittenSummary'] as String? ?? '';
    final rewrittenExp = _result!['rewrittenExperience'] as List? ?? [];
    final rewrittenSkillNames = _result!['rewrittenSkills'] as List? ?? [];

    // Update objective/summary
    ResumeModel updated = resume.copyWith(
      objective: rewrittenSummary.isNotEmpty ? rewrittenSummary : resume.objective,
      updatedAt: DateTime.now(),
    );

    // Update experience descriptions – match by index
    if (rewrittenExp.isNotEmpty && updated.experience.isNotEmpty) {
      final updatedExperiences = updated.experience.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        if (i < rewrittenExp.length) {
          final rewritten = rewrittenExp[i] as Map<String, dynamic>? ?? {};
          final newDesc = rewritten['description'] as String?;
          final newPos = rewritten['position'] as String?;
          return exp.copyWith(
            description: newDesc?.isNotEmpty == true ? newDesc! : exp.description,
            position: newPos?.isNotEmpty == true ? newPos! : exp.position,
          );
        }
        return exp;
      }).toList();
      updated = updated.copyWith(experience: updatedExperiences);
    }

    // Update skills – replace names while preserving other fields (level, category)
    if (rewrittenSkillNames.isNotEmpty) {
      final newSkills = rewrittenSkillNames
          .take(12)
          .toList()
          .asMap()
          .entries
          .map((entry) {
        final i = entry.key;
        final newName = entry.value.toString().trim();
        if (i < updated.skills.length) {
          return updated.skills[i].copyWith(name: newName);
        }
        // New skill not in original list
        return Skill(id: const Uuid().v4(), name: newName);
      }).toList();
      updated = updated.copyWith(skills: newSkills);
    }

    StorageService.saveResume(updated);
    ref.invalidate(resumesProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Resume rewritten & saved!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        action: SnackBarAction(
          label: 'Edit',
          textColor: Colors.white,
          onPressed: () => context.push('/editor/${resume.id}'),
        ),
      ),
    );

    setState(() {
      _showResult = false;
      _result = null;
    });
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.key, color: _kRewriteColor),
            SizedBox(width: 10),
            Text('Groq API Key (Free)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI features require a free Groq API key. No credit card needed!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Visit: console.groq.com → Sign up → API Keys → Create key',
                    ),
                  ),
                );
              },
              child: const Text(
                'Get FREE key → console.groq.com',
                style: TextStyle(
                  color: _kRewriteColor,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Paste API Key',
                prefixIcon: const Icon(Iconsax.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
        title: const Text('AI Resume Rewrite'),
        actions: [
          AdaptiveTooltip(
            message: _apiKey.isNotEmpty
                ? 'API Key configured'
                : 'Add API Key',
            button: true,
            child: IconButton(
              onPressed: _showApiKeyDialog,
              icon: Icon(
                Iconsax.key,
                color: _apiKey.isNotEmpty
                    ? AppColors.success
                    : AppColors.warning,
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
            // ── Header banner ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kRewriteColor.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _kRewriteColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kRewriteColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.refresh_2,
                      color: _kRewriteColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Resume Rewrite',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AI rewrites your summary, experience bullets and skills with stronger language, metrics and ATS keywords.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 20),

            // ── Resume selector ──────────────────────────────────────
            Text(
              'Select Resume',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_allResumes.isEmpty)
              _EmptyResumeTile()
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedResumeId ?? _allResumes.first.id,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.document_text_1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                items: _allResumes
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          r.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final picked =
                      _allResumes.firstWhere((r) => r.id == id);
                  setState(() {
                    _selectedResumeId = picked.id;
                    _targetJobTitleController.text =
                        picked.personalInfo.jobTitle ?? '';
                    _showResult = false;
                    _result = null;
                  });
                },
              ),

            const SizedBox(height: 20),

            // ── Target job title (optional) ──────────────────────────
            Text(
              'Target Job Title (optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetJobTitleController,
              decoration: InputDecoration(
                hintText: 'e.g. Senior Product Manager, Full-Stack Engineer…',
                prefixIcon: const Icon(Iconsax.briefcase),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tone selector ────────────────────────────────────────
            Text(
              'Writing Tone',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_tones.length, (i) {
                final tone = _tones[i];
                final selected = _selectedToneIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedToneIndex = i),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: EdgeInsets.only(right: i < _tones.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? tone.color.withValues(alpha: 0.12)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? tone.color.withValues(alpha: 0.5)
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tone.icon,
                            color: selected ? tone.color : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tone.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? tone.color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            // ── Error message ────────────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Rewrite button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed:
                    (_isRewriting || _allResumes.isEmpty) ? null : () => _rewriteResume(_allResumes),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRewriteColor,
                  disabledBackgroundColor:
                      _kRewriteColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _isRewriting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.magic_star, color: Colors.white),
                label: Text(
                  _isRewriting
                      ? 'Rewriting your resume…'
                      : 'Rewrite Resume with AI',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 50.ms),

            // ── Results ──────────────────────────────────────────────
            if (_showResult && _result != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _buildResultsSection(_allResumes),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Results section ────────────────────────────────────────────────

  Widget _buildResultsSection(List<ResumeModel> allResumes) {
    final rewrittenSummary = _result!['rewrittenSummary'] as String? ?? '';
    final rewrittenExp = _result!['rewrittenExperience'] as List? ?? [];
    final rewrittenSkills = _result!['rewrittenSkills'] as List? ?? [];
    final improvements = _result!['improvements'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Iconsax.magic_star, color: _kRewriteColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Rewrite Results',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kRewriteColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _kRewriteColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _tones[_selectedToneIndex].label,
                style: const TextStyle(
                  color: _kRewriteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(),

        const SizedBox(height: 16),
        const AiReviewNotice(),
        const SizedBox(height: 16),

        // Rewritten summary
        if (rewrittenSummary.isNotEmpty)
          _buildCard(
            icon: Iconsax.document_text_1,
            title: 'Rewritten Summary',
            color: AppColors.primary,
            child: Text(
              rewrittenSummary,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Rewritten experience
        if (rewrittenExp.isNotEmpty)
          _buildCard(
            icon: Iconsax.briefcase,
            title: 'Rewritten Experience (${rewrittenExp.length} entries)',
            color: _kRewriteColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rewrittenExp.map<Widget>((e) {
                final entry = e as Map<String, dynamic>? ?? {};
                final pos = entry['position'] as String? ?? '';
                final company = entry['company'] as String? ?? '';
                final desc = entry['description'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pos.isNotEmpty || company.isNotEmpty)
                        Text(
                          [pos, company]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const Divider(height: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Rewritten skills
        if (rewrittenSkills.isNotEmpty)
          _buildCard(
            icon: Iconsax.code,
            title: 'Refined Skills (${rewrittenSkills.length})',
            color: AppColors.secondary,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rewrittenSkills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 12),

        // What was improved
        if (improvements.isNotEmpty)
          _buildCard(
            icon: Iconsax.lamp_charge,
            title: 'Improvements Made',
            color: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: improvements
                  .map(
                    (imp) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              imp.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 20),

        // Apply button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _applyToResume(_allResumes),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Iconsax.tick_circle, color: Colors.white),
            label: const Text(
              'Apply Rewrite to Resume',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),

        Center(
          child: Text(
            'Previous version saved automatically before rewrite',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _EmptyResumeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Iconsax.document_text, color: AppColors.textTertiary),
          SizedBox(width: 12),
          Text(
            'No resumes yet. Create one first.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────

class _ToneOption {
  final String label;
  final IconData icon;
  final Color color;

  const _ToneOption(this.label, this.icon, this.color);
}
