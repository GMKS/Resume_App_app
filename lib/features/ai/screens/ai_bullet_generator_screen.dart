import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_api_key_storage_service.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../shared/widgets/feature_gate.dart';

class AIBulletGeneratorScreen extends ConsumerStatefulWidget {
  const AIBulletGeneratorScreen({super.key});

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

  @override
  void dispose() {
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
    });

    try {
      final apiKey = await AiApiKeyStorageService.read();

      final result = await AiResumeService.generateBulletPoints(
        apiKey: apiKey,
        jobTitle: jobTitle,
        company: company.isEmpty ? 'a company' : company,
        industry: industry,
        existingDescription: _descCtrl.text.trim(),
      );

      final bullets = (result['bullets'] as List?)
          ?.map((b) => b.toString())
          .toList() ??
          [];

      setState(() => _bullets = bullets);
      await FreePlanService.consumeAiSuggestion();
    } on AiConfigException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
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
                    ?.copyWith(fontWeight: FontWeight.w600)).animate().fadeIn(delay: 100.ms),
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
                hintText:
                    'Paste your current job description to improve it...',
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
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.info_circle,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Generated Bullets',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${_bullets.length} bullets',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              ..._bullets.asMap().entries.map((entry) {
                final i = entry.key;
                final bullet = entry.value;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(
                                fontSize: 14, height: 1.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _copyBullet(i),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _copiedIndex.contains(i)
                                ? const Icon(Iconsax.tick_circle,
                                    key: ValueKey('done'),
                                    color: Color(0xFF10B981),
                                    size: 20)
                                : const Icon(Iconsax.copy,
                                    key: ValueKey('copy'),
                                    color: AppColors.textSecondary,
                                    size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (i * 80).ms)
                    .slideX(begin: 0.05, end: 0);
              }),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}
