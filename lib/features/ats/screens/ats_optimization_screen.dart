import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../services/ats_service.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final _atsResultProvider =
    StateProvider.family<ATSResult?, String>((ref, resumeId) => null);

// ── Screen ─────────────────────────────────────────────────────────────────

class ATSOptimizationScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const ATSOptimizationScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ATSOptimizationScreen> createState() =>
      _ATSOptimizationScreenState();
}

class _ATSOptimizationScreenState
    extends ConsumerState<ATSOptimizationScreen> {
  final _jobDescController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _jobDescController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final resume = StorageService.getResume(widget.resumeId);
    if (resume == null) return;

    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final result = ATSService.analyse(resume, _jobDescController.text.trim());
    ref.read(_atsResultProvider(widget.resumeId).notifier).state = result;
    setState(() => _isAnalyzing = false);
  }

  void _resetAnalysis() {
    ref.read(_atsResultProvider(widget.resumeId).notifier).state = null;
    _jobDescController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_atsResultProvider(widget.resumeId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('ATS Analyzer'),
        actions: [
          if (result != null)
            TextButton.icon(
              onPressed: _resetAnalysis,
              icon: const Icon(Iconsax.refresh, size: 16),
              label: const Text('Re-analyze'),
            ),
        ],
      ),
      body: _isAnalyzing
          ? _buildLoadingView()
          : (result == null ? _buildInputView() : _buildResultView(result)),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 6),
          ),
          const SizedBox(height: 24),
          Text('Analyzing your resume…',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Checking keywords, structure & more',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn(),
    );
  }

  // ── Job Description Input ──────────────────────────────────────────────

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.info.withOpacity(0.12),
                AppColors.info.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.shield_tick,
                      color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How ATS Analysis Works',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Paste the job description to compare it with your resume keywords. '
                        'You can also run a general check without one.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          Text('What we check:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CheckChip(label: 'Keyword Match', icon: Iconsax.search_normal),
              _CheckChip(label: 'Contact Info', icon: Iconsax.user),
              _CheckChip(label: 'Section Structure', icon: Iconsax.document_text),
              _CheckChip(label: 'Action Verbs', icon: Iconsax.flash),
              _CheckChip(label: 'Summary', icon: Iconsax.note_text),
              _CheckChip(label: 'Formatting Tips', icon: Iconsax.tick_square),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 28),

          Text('Job Description (Optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _jobDescController,
            maxLines: 9,
            decoration: InputDecoration(
              hintText:
                  'Paste the job posting here to match keywords against your resume…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Iconsax.search_normal_1),
              label: const Text('Analyze My Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  // ── Result View ────────────────────────────────────────────────────────

  Widget _buildResultView(ATSResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreCard(result: result).animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          const SizedBox(height: 20),

          const _SectionHeader(title: 'Score Breakdown'),
          const SizedBox(height: 12),
          _ScoreBreakdownCard(result: result)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          const _SectionHeader(title: 'Keyword Analysis'),
          const SizedBox(height: 12),
          _KeywordCard(
                  matched: result.matchedKeywords,
                  missing: result.missingKeywords)
              .animate()
              .fadeIn(delay: 150.ms)
              .slideY(begin: 0.1, end: 0),

          if (result.formattingIssues.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
                title: 'Issues Found', count: result.formattingIssues.length),
            const SizedBox(height: 12),
            ...result.formattingIssues.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AtsIssueCard(issue: e.value)
                      .animate()
                      .fadeIn(delay: (200 + e.key * 60).ms)
                      .slideX(begin: -0.05, end: 0),
                )),
          ],

          if (result.weakVerbIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionHeader(
                title: 'Weak Phrases', count: result.weakVerbIssues.length),
            const SizedBox(height: 12),
            ...result.weakVerbIssues.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AtsIssueCard(issue: e.value)
                      .animate()
                      .fadeIn(delay: (250 + e.key * 60).ms)
                      .slideX(begin: -0.05, end: 0),
                )),
          ],

          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionHeader(
                title: 'Suggestions', count: result.suggestions.length),
            const SizedBox(height: 12),
            ...result.suggestions.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AtsSuggestionCard(suggestion: e.value)
                      .animate()
                      .fadeIn(delay: (300 + e.key * 80).ms)
                      .slideX(begin: -0.05, end: 0),
                )),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.edit),
              label: const Text('Go Back & Improve Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _CheckChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CheckChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

// ── Score Card ─────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final ATSResult result;

  const _ScoreCard({required this.result});

  Color _color(int s) {
    if (s >= 80) return AppColors.success;
    if (s >= 55) return AppColors.warning;
    return AppColors.error;
  }

  String _label(int s) {
    if (s >= 80) return 'Excellent — ATS Ready';
    if (s >= 65) return 'Good — Minor Improvements';
    if (s >= 45) return 'Fair — Several Issues Found';
    return 'Poor — Action Required';
  }

  IconData _icon(int s) {
    if (s >= 80) return Iconsax.tick_circle;
    if (s >= 55) return Iconsax.warning_2;
    return Iconsax.close_circle;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(result.score);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('ATS Score',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: result.score / 100,
                    strokeWidth: 14,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text('${result.score}',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold, color: color)),
                    Text('/ 100',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon(result.score), color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(_label(result.score),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score Breakdown ────────────────────────────────────────────────────────

class _ScoreBreakdownCard extends StatelessWidget {
  final ATSResult result;

  const _ScoreBreakdownCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Bar(label: 'Keyword Match', score: result.keywordScore, max: 40, color: AppColors.primary),
            _Bar(label: 'Contact Info', score: result.contactScore, max: 20, color: AppColors.secondary),
            _Bar(label: 'Section Structure', score: result.structureScore, max: 20, color: AppColors.info),
            _Bar(label: 'Action Verbs', score: result.verbScore, max: 10, color: AppColors.warning),
            _Bar(label: 'Summary', score: result.summaryScore, max: 10, color: AppColors.success, isLast: true),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int score, max;
  final Color color;
  final bool isLast;

  const _Bar({required this.label, required this.score, required this.max, required this.color, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (score / max).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              Text('$score / $max',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Keyword Card ───────────────────────────────────────────────────────────

class _KeywordCard extends StatefulWidget {
  final List<String> matched, missing;

  const _KeywordCard({required this.matched, required this.missing});

  @override
  State<_KeywordCard> createState() => _KeywordCardState();
}

class _KeywordCardState extends State<_KeywordCard> {
  bool _moreMatched = false, _moreMissing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.matched.isEmpty && widget.missing.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'No job description provided — keyword match not calculated.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary))),
            ],
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.matched.isNotEmpty) ...[
              Row(children: [
                const Icon(Iconsax.tick_circle,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text('Matched (${widget.matched.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (_moreMatched
                        ? widget.matched
                        : widget.matched.take(12).toList())
                    .map((k) => _Chip(keyword: k, matched: true))
                    .toList(),
              ),
              if (widget.matched.length > 12)
                TextButton(
                  onPressed: () =>
                      setState(() => _moreMatched = !_moreMatched),
                  child: Text(_moreMatched
                      ? 'Show less'
                      : '+${widget.matched.length - 12} more'),
                ),
            ],
            if (widget.missing.isNotEmpty) ...[
              if (widget.matched.isNotEmpty) const Divider(height: 24),
              Row(children: [
                const Icon(Iconsax.close_circle,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text('Missing (${widget.missing.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.error)),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (_moreMissing
                        ? widget.missing
                        : widget.missing.take(12).toList())
                    .map((k) => _Chip(keyword: k, matched: false))
                    .toList(),
              ),
              if (widget.missing.length > 12)
                TextButton(
                  onPressed: () =>
                      setState(() => _moreMissing = !_moreMissing),
                  child: Text(_moreMissing
                      ? 'Show less'
                      : '+${widget.missing.length - 12} more'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String keyword;
  final bool matched;

  const _Chip({required this.keyword, required this.matched});

  @override
  Widget build(BuildContext context) {
    final color = matched ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(keyword,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Issue Card ─────────────────────────────────────────────────────────────

class _AtsIssueCard extends StatelessWidget {
  final ATSIssue issue;

  const _AtsIssueCard({required this.issue});

  Color _c(ATSSeverity s) {
    switch (s) {
      case ATSSeverity.high:
        return AppColors.error;
      case ATSSeverity.medium:
        return AppColors.warning;
      case ATSSeverity.low:
        return AppColors.info;
    }
  }

  IconData _i(ATSSeverity s) {
    switch (s) {
      case ATSSeverity.high:
        return Iconsax.danger;
      case ATSSeverity.medium:
        return Iconsax.warning_2;
      case ATSSeverity.low:
        return Iconsax.info_circle;
    }
  }

  String _l(ATSSeverity s) {
    switch (s) {
      case ATSSeverity.high:
        return 'High';
      case ATSSeverity.medium:
        return 'Medium';
      case ATSSeverity.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _c(issue.severity);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_i(issue.severity), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(issue.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(_l(issue.severity),
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(issue.detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion Card ────────────────────────────────────────────────────────

class _AtsSuggestionCard extends StatelessWidget {
  final ATSSuggestion suggestion;

  const _AtsSuggestionCard({required this.suggestion});

  Color _color(ATSSeverity p) {
    switch (p) {
      case ATSSeverity.high:
        return AppColors.primary;
      case ATSSeverity.medium:
        return AppColors.secondary;
      case ATSSeverity.low:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(suggestion.priority);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Iconsax.lamp_charge, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(suggestion.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
