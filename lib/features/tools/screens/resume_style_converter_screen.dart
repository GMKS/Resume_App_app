import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_api_key_storage_service.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/storage_service.dart';

class ResumeStyleConverterScreen extends ConsumerStatefulWidget {
  final String? resumeId;
  const ResumeStyleConverterScreen({super.key, this.resumeId});

  @override
  ConsumerState<ResumeStyleConverterScreen> createState() =>
      _ResumeStyleConverterScreenState();
}

class _ResumeStyleConverterScreenState
    extends ConsumerState<ResumeStyleConverterScreen> {
  static const _countries = [
    {'name': 'USA', 'flag': '🇺🇸', 'subtitle': 'Clean, 1-page, no photo'},
    {'name': 'UK', 'flag': '🇬🇧', 'subtitle': 'CV format, 2 pages OK'},
    {'name': 'Germany', 'flag': '🇩🇪', 'subtitle': 'Lebenslauf, photo common'},
    {'name': 'Canada', 'flag': '🇨🇦', 'subtitle': 'Similar to USA, bilingual'},
    {'name': 'Australia', 'flag': '🇦🇺', 'subtitle': '2-3 pages, referee list'},
    {'name': 'France', 'flag': '🇫🇷', 'subtitle': 'CV, photo recommended'},
    {'name': 'Japan', 'flag': '🇯🇵', 'subtitle': 'Rirekisho, strict format'},
    {'name': 'India', 'flag': '🇮🇳', 'subtitle': 'Detailed, 2-3 pages'},
    {'name': 'UAE', 'flag': '🇦🇪', 'subtitle': 'Photo, nationality listed'},
    {'name': 'Singapore', 'flag': '🇸🇬', 'subtitle': '2 pages, NRIC optional'},
  ];

  String? _selectedCountry;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  static Map<String, dynamic> _buildResumeMap(dynamic r) {
    return {
      'name': r.personalInfo.fullName,
      'title': r.personalInfo.jobTitle ?? '',
      'summary': r.objective ?? '',
      'experience': (r.experience as List)
          .map((e) => '${e.position} at ${e.company}: ${e.description}')
          .toList(),
      'education': (r.education as List)
          .map((e) => '${e.degree} in ${e.fieldOfStudy} at ${e.institution}')
          .toList(),
      'skills': (r.skills as List).map((s) => s.name).toList(),
      'certifications': (r.certifications as List).map((c) => c.name).toList(),
    };
  }

  Future<void> _convert() async {
    if (_selectedCountry == null) {
      setState(() => _errorMessage = 'Please select a target country.');
      return;
    }
    if (widget.resumeId == null) {
      setState(() => _errorMessage = 'No resume selected.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final resume = StorageService.getResume(widget.resumeId!);
      if (resume == null) {
        setState(() => _errorMessage = 'Resume not found.');
        return;
      }

      final apiKey = await AiApiKeyStorageService.read();

      final resumeJson = _buildResumeMap(resume);
      final result = await AiResumeService.convertResumeStyle(
        apiKey: apiKey,
        resumeJson: resumeJson,
        targetCountry: _selectedCountry!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Style Converter'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                    child: const Icon(Iconsax.global,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Global Resume Converter',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          'Adapt your resume to meet standards in any country.',
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

            Text('Select Target Country',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            // Country grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: _countries.length,
              itemBuilder: (context, i) {
                final c = _countries[i];
                final selected = _selectedCountry == c['name'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCountry = c['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c['flag']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c['name']!,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: selected
                                        ? AppColors.primary
                                        : null),
                              ),
                              Text(
                                c['subtitle']!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Iconsax.tick_circle,
                              color: AppColors.primary, size: 16),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: ((i * 40) + 120).ms).scale(
                    begin: const Offset(0.95, 0.95));
              },
            ),

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.info_circle,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13))),
                      ],
                    ),
                    if (_errorMessage!.contains('API key'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Iconsax.key, size: 16,
                                color: Colors.red),
                            label: const Text('Configure API Key in Settings',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
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
                onPressed: _isLoading ? null : _convert,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Iconsax.global, size: 20),
                label: Text(_isLoading
                    ? 'Adapting...'
                    : 'Convert for ${_selectedCountry ?? 'Selected Country'}'),
              ),
            ).animate().fadeIn(delay: 200.ms),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 28),
              ..._buildResults(_result!),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(Map<String, dynamic> r) {
    final keyDifferences = (r['keyDifferences'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final adaptedSummary = r['adaptedSummary'] as String? ?? '';
    final formatTips = (r['formatTips'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final doList = (r['doList'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final dontList = (r['dontList'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return [
      // Summary
      _sectionCard(
        title: 'Adapted Summary',
        icon: Iconsax.document_text,
        color: AppColors.primary,
        delay: 0,
        child: Text(adaptedSummary,
            style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
      const SizedBox(height: 12),

      // Key Differences
      _sectionCard(
        title: 'Key Differences',
        icon: Iconsax.info_circle,
        color: AppColors.info,
        delay: 80,
        child: Column(
          children: keyDifferences
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.info),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(d,
                                style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 12),

      // Format Tips
      _sectionCard(
        title: 'Format Tips',
        icon: Iconsax.format_circle,
        color: const Color(0xFF8B5CF6),
        delay: 160,
        child: Column(
          children: formatTips
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Iconsax.tick_circle,
                              color: Color(0xFF8B5CF6), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(t,
                                style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 12),

      // DOs and DON'Ts
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _sectionCard(
              title: 'DO',
              icon: Iconsax.tick_circle,
              color: const Color(0xFF10B981),
              delay: 240,
              child: Column(
                children: doList
                    .map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Iconsax.tick_circle,
                                  color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(d,
                                      style: const TextStyle(
                                          fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _sectionCard(
              title: "DON'T",
              icon: Iconsax.close_circle,
              color: const Color(0xFFEF4444),
              delay: 320,
              child: Column(
                children: dontList
                    .map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Iconsax.close_circle,
                                  color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(d,
                                      style: const TextStyle(
                                          fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 240.ms),
      const SizedBox(height: 80),
    ];
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    required int delay,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.08, end: 0);
  }
}
