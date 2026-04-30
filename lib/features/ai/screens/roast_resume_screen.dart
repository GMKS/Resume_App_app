import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';

class RoastResumeScreen extends ConsumerStatefulWidget {
  final String? resumeId;
  const RoastResumeScreen({super.key, this.resumeId});

  @override
  ConsumerState<RoastResumeScreen> createState() => _RoastResumeScreenState();
}

class _RoastResumeScreenState extends ConsumerState<RoastResumeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;
  List<ResumeModel> _allResumes = [];
  String? _selectedResumeId;

  @override
  void initState() {
    super.initState();
    _loadResumes();
    if (widget.resumeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _roast());
    }
  }

  void _loadResumes() {
    final resumes = StorageService.getAllResumes()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final defaultResumeId = widget.resumeId ?? (resumes.isNotEmpty ? resumes.first.id : null);

    setState(() {
      _allResumes = resumes;
      _selectedResumeId = defaultResumeId;
    });
  }

  ResumeModel? _selectedResume() {
    final targetId = widget.resumeId ?? _selectedResumeId;
    if (targetId == null) {
      return null;
    }

    for (final resume in _allResumes) {
      if (resume.id == targetId) {
        return resume;
      }
    }

    return StorageService.getResume(targetId);
  }

  static Map<String, dynamic> _buildResumeMap(dynamic r) {
    return {
      'name': r.personalInfo.fullName,
      'title': r.personalInfo.jobTitle ?? '',
      'email': r.personalInfo.email,
      'summary': r.objective ?? '',
      'experience': (r.experience as List)
          .map((e) => '${e.position} at ${e.company}: ${e.description}')
          .toList(),
      'education': (r.education as List)
          .map((e) => '${e.degree} in ${e.fieldOfStudy} at ${e.institution}')
          .toList(),
      'skills': (r.skills as List).map((s) => s.name).toList(),
      'certifications': (r.certifications as List).map((c) => c.name).toList(),
      'projects': (r.projects as List).map((p) => p.title).toList(),
      'languages': (r.languages as List)
          .map((l) => '${l.name} (${l.proficiency})')
          .toList(),
    };
  }

  Future<void> _roast() async {
    final targetResume = _selectedResume();
    if (targetResume == null) {
      setState(() {
        _errorMessage = _allResumes.isEmpty
            ? 'Create a resume first, then come back to roast it.'
            : 'Please select a resume to roast.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      if (!FreePlanService.isPremium) {
        showUpgradePromptSheet(
          context,
          featureName: 'ai_assistant',
          message: FreePlanService.premiumAiToolMessage,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key') ?? '';

      final resumeJson = _buildResumeMap(targetResume);
      final result = await AiResumeService.roastResume(
        apiKey: apiKey,
        resumeJson: resumeJson,
      );

      setState(() => _result = result);
    } on AiConfigException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
          () => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _gradeColor(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A':
        return const Color(0xFF10B981);
      case 'B':
        return const Color(0xFF3B82F6);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEF4444);
      case 'F':
        return const Color(0xFF991B1B);
      default:
        return AppColors.primary;
    }
  }

  Widget _scoreBar(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$score',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roast My Resume'),
        actions: [
          if (_result != null)
            AdaptiveTooltip(
              message: 'Re-roast',
              button: true,
              child: IconButton(
                icon: const Icon(Iconsax.refresh_2),
                onPressed: _roast,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _result != null
                  ? _buildResultView()
                  : _buildEmptyView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text('Preparing the roast...',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('🔥 This may take a moment',
              style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Roast My Resume',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get a brutally honest, AI-powered critique of your resume. We\'ll score it, roast it, and tell you exactly what to fix.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Warning: The AI will not sugarcoat. 😅',
              style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_allResumes.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resume to roast',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedResumeId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                isExpanded: true,
                items: _allResumes
                    .map(
                      (resume) => DropdownMenuItem<String>(
                        value: resume.id,
                        child: Text(
                          resume.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedResumeId = value;
                    _errorMessage = null;
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'No saved resumes found yet. Create one first to use this feature.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _allResumes.isEmpty ? null : _roast,
              icon: const Icon(Iconsax.magic_star, size: 20),
              label: const Text('Roast My Resume'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  minimumSize: const Size(200, 52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.info_circle, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            if (_errorMessage!.contains('API key'))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Iconsax.key, size: 16, color: Colors.red),
                  label: const Text('Configure API Key in Settings',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _roast,
              icon: const Icon(Iconsax.refresh_2, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final r = _result!;
    final grade = r['grade'] as String? ?? 'C';
    final overall = (r['overallScore'] as num?)?.toInt() ?? 50;
    final scores = r['scores'] as Map<String, dynamic>? ?? {};
    final roast = r['roast'] as String? ?? '';
    final improvements =
        (r['improvements'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final gradeColor = _gradeColor(grade);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: gradeColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        grade,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: gradeColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Score',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        Text('$overall / 100',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: gradeColor)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overall / 100,
                            minHeight: 8,
                            backgroundColor:
                                gradeColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(gradeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 16),

          // Roast Quote
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    roast,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Score Breakdown
          Text('Score Breakdown',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _scoreBar('Impact', (scores['impact'] as num?)?.toInt() ?? 50, const Color(0xFF10B981)),
                  _scoreBar('Clarity', (scores['clarity'] as num?)?.toInt() ?? 50, const Color(0xFF3B82F6)),
                  _scoreBar('Skills', (scores['skills'] as num?)?.toInt() ?? 50, const Color(0xFFF59E0B)),
                  _scoreBar('Formatting', (scores['formatting'] as num?)?.toInt() ?? 50, const Color(0xFF8B5CF6)),
                  _scoreBar('ATS Compatibility', (scores['atsCompatibility'] as num?)?.toInt() ?? 50, const Color(0xFFEC4899)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Improvements
          Text('Fix These First',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          ...improvements.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
                title: Text(item,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ).animate().fadeIn(delay: ((4 + i) * 80).ms).slideX(begin: 0.05, end: 0);
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
