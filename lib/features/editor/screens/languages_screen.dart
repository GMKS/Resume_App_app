import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/free_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../../../core/services/resume_quality_service.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class LanguagesScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const LanguagesScreen({super.key, required this.resumeId});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedProficiency = 'Professional';
  String _searchQuery = '';
  String _selectedRegion = 'All';

  final List<String> _proficiencies = ['Native', 'Fluent', 'Professional', 'Intermediate', 'Beginner'];

  // ── 50+ world languages grouped by region ──────────────────────────────────
  static const Map<String, List<Map<String, String>>> _languagesByRegion = {
    'Popular': [
      {'name': 'English', 'flag': '🇬🇧'},
      {'name': 'Spanish', 'flag': '🇪🇸'},
      {'name': 'Mandarin Chinese', 'flag': '🇨🇳'},
      {'name': 'Arabic', 'flag': '🇸🇦'},
      {'name': 'French', 'flag': '🇫🇷'},
      {'name': 'Portuguese', 'flag': '🇧🇷'},
      {'name': 'Russian', 'flag': '🇷🇺'},
      {'name': 'Hindi', 'flag': '🇮🇳'},
      {'name': 'Japanese', 'flag': '🇯🇵'},
      {'name': 'German', 'flag': '🇩🇪'},
    ],
    'European': [
      {'name': 'Italian', 'flag': '🇮🇹'},
      {'name': 'Dutch', 'flag': '🇳🇱'},
      {'name': 'Polish', 'flag': '🇵🇱'},
      {'name': 'Swedish', 'flag': '🇸🇪'},
      {'name': 'Norwegian', 'flag': '🇳🇴'},
      {'name': 'Danish', 'flag': '🇩🇰'},
      {'name': 'Finnish', 'flag': '🇫🇮'},
      {'name': 'Greek', 'flag': '🇬🇷'},
      {'name': 'Czech', 'flag': '🇨🇿'},
      {'name': 'Romanian', 'flag': '🇷🇴'},
      {'name': 'Hungarian', 'flag': '🇭🇺'},
      {'name': 'Ukrainian', 'flag': '🇺🇦'},
      {'name': 'Turkish', 'flag': '🇹🇷'},
    ],
    'Asian': [
      {'name': 'Korean', 'flag': '🇰🇷'},
      {'name': 'Vietnamese', 'flag': '🇻🇳'},
      {'name': 'Thai', 'flag': '🇹🇭'},
      {'name': 'Indonesian', 'flag': '🇮🇩'},
      {'name': 'Malay', 'flag': '🇲🇾'},
      {'name': 'Bengali', 'flag': '🇧🇩'},
      {'name': 'Urdu', 'flag': '🇵🇰'},
      {'name': 'Tamil', 'flag': '🇱🇰'},
      {'name': 'Marathi', 'flag': '🇮🇳'},
      {'name': 'Punjabi', 'flag': '🇮🇳'},
      {'name': 'Tagalog', 'flag': '🇵🇭'},
      {'name': 'Burmese', 'flag': '🇲🇲'},
      {'name': 'Khmer', 'flag': '🇰🇭'},
    ],
    'Middle Eastern': [
      {'name': 'Hebrew', 'flag': '🇮🇱'},
      {'name': 'Persian (Farsi)', 'flag': '🇮🇷'},
      {'name': 'Kurdish', 'flag': '🏳'},
      {'name': 'Pashto', 'flag': '🇦🇫'},
    ],
    'African': [
      {'name': 'Swahili', 'flag': '🇰🇪'},
      {'name': 'Amharic', 'flag': '🇪🇹'},
      {'name': 'Yoruba', 'flag': '🇳🇬'},
      {'name': 'Hausa', 'flag': '🇳🇬'},
      {'name': 'Zulu', 'flag': '🇿🇦'},
      {'name': 'Somali', 'flag': '🇸🇴'},
    ],
    'Americas': [
      {'name': 'Catalan', 'flag': '🏴'},
      {'name': 'Quechua', 'flag': '🇵🇪'},
      {'name': 'Guaraní', 'flag': '🇵🇾'},
    ],
    'Other': [
      {'name': 'Sign Language (ASL)', 'flag': '🤟'},
      {'name': 'Latin', 'flag': '🏛'},
      {'name': 'Esperanto', 'flag': '🌍'},
    ],
  };

  List<Map<String, String>> get _filteredSuggestions {
    final allWithRegion = _selectedRegion == 'All'
        ? _languagesByRegion.values.expand((l) => l).toList()
        : _languagesByRegion[_selectedRegion] ?? [];

    if (_searchQuery.isEmpty) return allWithRegion;
    final q = _searchQuery.toLowerCase();
    return allWithRegion.where((l) => l['name']!.toLowerCase().contains(q)).toList();
  }

  String _normalizeLanguageName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _languageExists(ResumeModel resume, String name) {
    final normalizedName = _normalizeLanguageName(name);
    return resume.languages.any(
      (language) => _normalizeLanguageName(language.name) == normalizedName,
    );
  }

  void _showLanguageMessage(String message, {Color backgroundColor = AppColors.warning}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _addLanguage() {
    final languageName = _controller.text.trim();
    if (languageName.isEmpty) return;

    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    if (_languageExists(resume, languageName)) {
      _showLanguageMessage('$languageName is already added');
      return;
    }

    final lang = Language(
      id: const Uuid().v4(),
      name: languageName,
      proficiency: _selectedProficiency,
    );

    final updated = [...resume.languages, lang];
    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(resume.copyWith(languages: updated));
    _controller.clear();
  }

  void _addSuggestedLanguage(Map<String, String> language) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final languageName = language['name'];
    if (languageName == null || languageName.isEmpty) return;

    if (_languageExists(resume, languageName)) {
      _showLanguageMessage('$languageName is already added');
      return;
    }

    final updated = [
      ...resume.languages,
      Language(
        id: const Uuid().v4(),
        name: languageName,
        proficiency: 'Professional',
      ),
    ];
    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(languages: updated),
    );
  }

  void _deleteLanguage(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updated = resume.languages.where((l) => l.id != id).toList();
      ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(resume.copyWith(languages: updated));
    }
  }

  void _updateProficiency(String id, String proficiency) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updated = resume.languages.map((l) => l.id == id ? l.copyWith(proficiency: proficiency) : l).toList();
      ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(resume.copyWith(languages: updated));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FreePlanService.canEditSection('languages')) {
      return const Scaffold(
        body: SafeArea(
          child: UpgradePromptCard(
            featureName: 'premium_sections',
            message: 'Premium feature. Upgrade to edit this section.',
          ),
        ),
      );
    }

    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    
    if (resume == null) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Loading languages',
          message: 'Preparing your language proficiency details.',
        ),
      );
    }
    final qualityReport = ResumeQualityService.analyzeResume(resume);
    final fluentOrBetter = resume.languages
      .where((language) =>
        language.proficiency == 'Native' || language.proficiency == 'Fluent')
      .length;
    final professionalOrBetter = resume.languages
      .where((language) =>
        language.proficiency == 'Native' ||
        language.proficiency == 'Fluent' ||
        language.proficiency == 'Professional')
      .length;
    
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
        title: const Text('Languages'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EditorIntroCard(
            title: 'Global Readiness',
            subtitle:
                'Language coverage helps international applications, client-facing roles, and template completeness. Changes here save immediately and flow into preview output.',
            icon: Iconsax.translate,
            accentColor: const Color(0xFF64748B),
            stats: [
              EditorIntroStat(
                label: '${resume.languages.length} languages',
                icon: Iconsax.translate,
              ),
              EditorIntroStat(
                label: '$fluentOrBetter fluent+',
                icon: Iconsax.star1,
              ),
              EditorIntroStat(
                label: '$professionalOrBetter professional+',
                icon: Iconsax.award,
              ),
            ],
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 16),
          ResumeQualityPanel(
            report: qualityReport,
            title: 'Language Guidance',
            subtitle:
                'Language coverage strengthens preview completeness and makes international profiles easier to trust at a glance.',
            accentColor: const Color(0xFF64748B),
            maxSuggestions: 2,
          ).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 20),
          // Add Language Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF64748B).withValues(alpha: 0.1), const Color(0xFF64748B).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF64748B).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Iconsax.translate, color: Color(0xFF64748B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Add Language', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Language name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _addLanguage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addLanguage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Icon(Iconsax.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _proficiencies.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: _selectedProficiency == p,
                        onSelected: (s) => setState(() => _selectedProficiency = p),
                        selectedColor: const Color(0xFF64748B),
                        labelStyle: TextStyle(
                          color: _selectedProficiency == p ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Quick Add Language Browser
          if (resume.languages.length < 8) ...[
            Row(
              children: [
                const Icon(Iconsax.global, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text('Browse Languages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search languages…',
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? AdaptiveTooltip(
                        message: 'Clear language search',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Iconsax.close_circle, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 10),
            // Region filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', ..._languagesByRegion.keys].map((region) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(region),
                    selected: _selectedRegion == region,
                    onSelected: (_) => setState(() => _selectedRegion = region),
                    selectedColor: const Color(0xFF64748B),
                    labelStyle: TextStyle(
                      color: _selectedRegion == region ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredSuggestions
                  .where((l) => !_languageExists(resume, l['name'] ?? ''))
                  .take(20)
                  .map((lang) => ActionChip(
                        avatar: Text(
                          lang['flag'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(lang['name'] ?? ''),
                        labelStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onPressed: () => _addSuggestedLanguage(lang),
                      ))
                  .toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],

          // Languages List
          if (resume.languages.isNotEmpty) ...[
            Text('Your Languages (${resume.languages.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...resume.languages.asMap().entries.map((e) => _LanguageCard(
              language: e.value,
              onDelete: () => _deleteLanguage(e.value.id),
              onUpdateProficiency: (p) => _updateProficiency(e.value.id, p),
              proficiencies: _proficiencies,
            ).animate().fadeIn(delay: (300 + e.key * 100).ms).slideX(begin: 0.1, end: 0)),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language language;
  final VoidCallback onDelete;
  final Function(String) onUpdateProficiency;
  final List<String> proficiencies;

  const _LanguageCard({
    required this.language,
    required this.onDelete,
    required this.onUpdateProficiency,
    required this.proficiencies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _getColorForProficiency(language.proficiency).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                language.name.substring(0, min(2, language.name.length)).toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: _getColorForProficiency(language.proficiency)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                EditorStatPill(
                  label: language.proficiency,
                  icon: _getIconForProficiency(language.proficiency),
                  color: _getColorForProficiency(language.proficiency),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showProficiencyPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorForProficiency(language.proficiency).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(language.proficiency, style: TextStyle(fontSize: 12, color: _getColorForProficiency(language.proficiency), fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        Icon(Iconsax.arrow_down_1, size: 12, color: _getColorForProficiency(language.proficiency)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AdaptiveTooltip(
            message: 'Delete language',
            button: true,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Iconsax.trash, size: 20, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showProficiencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Proficiency', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...proficiencies.map((p) => ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _getColorForProficiency(p).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(_getIconForProficiency(p), color: _getColorForProficiency(p), size: 20),
              ),
              title: Text(p),
              trailing: language.proficiency == p ? const Icon(Iconsax.tick_circle, color: AppColors.success) : null,
              onTap: () {
                onUpdateProficiency(p);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getColorForProficiency(String p) {
    switch (p) {
      case 'Native': return const Color(0xFF22C55E);
      case 'Fluent': return const Color(0xFF3B82F6);
      case 'Professional': return const Color(0xFF8B5CF6);
      case 'Intermediate': return const Color(0xFFF59E0B);
      case 'Beginner': return const Color(0xFF64748B);
      default: return AppColors.primary;
    }
  }

  IconData _getIconForProficiency(String p) {
    switch (p) {
      case 'Native': return Iconsax.star1;
      case 'Fluent': return Iconsax.medal_star;
      case 'Professional': return Iconsax.award;
      case 'Intermediate': return Iconsax.chart;
      case 'Beginner': return Iconsax.book;
      default: return Iconsax.translate;
    }
  }

  int min(int a, int b) => a < b ? a : b;
}
