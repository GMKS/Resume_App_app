import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/resume_quality_service.dart';
import '../../../core/services/skill_suggestions_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

const List<String> _skillEmojis = [
  '💻', '🐍', '⚛️', '🐳', '☁️', '🔧', '🛡️', '📊', '🎨', '📱',
  '🤖', '🧪', '🔬', '📡', '🌐', '🗃️', '⚙️', '📐', '🎯', '🚀',
  '🧠', '🤝', '📢', '🎤', '✍️', '📝', '💡', '🏆', '🌍', '🔍',
];

String _normalizedSkillName(String value) {
  final trimmed = value.trim();
  for (final emoji in _skillEmojis) {
    if (trimmed == emoji) {
      return '';
    }

    if (trimmed.startsWith(emoji)) {
      return trimmed.substring(emoji.length).trimLeft();
    }
  }

  return trimmed;
}

String? _skillEmojiPrefix(String value) {
  final trimmed = value.trimLeft();
  for (final emoji in _skillEmojis) {
    if (trimmed == emoji || trimmed.startsWith(emoji)) {
      return emoji;
    }
  }

  return null;
}

class SkillsScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const SkillsScreen({super.key, required this.resumeId});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _skillController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'Technical';
  int _proficiency = 3;
  String _selectedRole = 'Software Engineer';
  String _suggestionCategory = 'Role-Specific';
  String _searchQuery = '';
  String? _selectedEmoji;

  final List<String> _categories = ['Technical', 'Soft Skills', 'Languages', 'Tools', 'Other'];
  final List<String> _suggestionCategories = ['Role-Specific', 'Soft Skills'];

  List<String> get _suggestedSkills {
    final all = SkillSuggestionsService.getCategorizedSkills(_selectedRole);
    final raw = all[_suggestionCategory] ?? [];
    if (_searchQuery.isEmpty) return raw;
    final q = _searchQuery.toLowerCase();
    return raw.where((s) => s.toLowerCase().contains(q)).toList();
  }

  void _clearSelectedEmoji() {
    setState(() => _selectedEmoji = null);
  }

  Widget _buildSuggestionChip(String skill) {
    return ActionChip(
      avatar: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Iconsax.add,
          size: 12,
          color: Color(0xFF8B5CF6),
        ),
      ),
      label: Text(skill),
      labelStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => _addSuggestedSkill(skill),
    );
  }

  void _addSkill() {
    final skillName = _normalizedSkillName(_skillController.text);
    if (skillName.isEmpty) return;

    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final skill = Skill(
      id: const Uuid().v4(),
      name: _selectedEmoji != null
          ? '$_selectedEmoji $skillName'
          : skillName,
      proficiency: _proficiency,
      category: _selectedCategory,
    );

    final updated = [...resume.skills, skill];
    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(skills: updated),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('${skill.name} added to skills'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    _skillController.clear();
    setState(() {
      _proficiency = 3;
      _selectedEmoji = null;
    });
  }

  void _addSuggestedSkill(String skillName) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;
    final normalizedSkillName = _normalizedSkillName(skillName).toLowerCase();
    
    // Check if skill already exists
    if (resume.skills.any(
      (s) => _normalizedSkillName(s.name).toLowerCase() == normalizedSkillName,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$skillName is already added')),
      );
      return;
    }

    final skill = Skill(
      id: const Uuid().v4(),
      name: skillName,
      proficiency: 3,
      category: _selectedCategory,
    );

    final updated = [...resume.skills, skill];
    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(skills: updated),
    );
  }

  void _removeSkillIcon(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final updated = resume.skills.map((skill) {
      if (skill.id != id) {
        return skill;
      }

      return skill.copyWith(name: _normalizedSkillName(skill.name));
    }).toList();

    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(skills: updated),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Skill icon removed'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _deleteSkill(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final skillName = resume.skills.firstWhere((s) => s.id == id).name;
    final updated = resume.skills.where((s) => s.id != id).toList();
    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(skills: updated),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('$skillName removed'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _updateProficiency(String id, int level) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume == null) return;

    final updated = resume.skills.map((s) {
      if (s.id == id) return s.copyWith(proficiency: level);
      return s;
    }).toList();

    ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(
      resume.copyWith(skills: updated),
    );
  }

  @override
  void dispose() {
    _skillController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    
    if (resume == null) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Loading skills',
          message: 'Preparing your skills inventory.',
        ),
      );
    }
    final qualityReport = ResumeQualityService.analyzeResume(resume);
    final categoriesCovered = resume.skills
      .map((skill) => (skill.category ?? 'Other').trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .length;
    final advancedSkills =
      resume.skills.where((skill) => skill.proficiency >= 4).length;
    
    // Group skills by category
    final groupedSkills = <String, List<Skill>>{};
    for (var skill in resume.skills) {
      final category = skill.category ?? 'Other';
      groupedSkills.putIfAbsent(category, () => []).add(skill);
    }
    
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
        title: const Text('Skills'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EditorIntroCard(
            title: 'Capability Mapping',
            subtitle:
                'Skills help ATS matching and make the preview easier to scan. Keep this list balanced, relevant, and evidence-backed by the rest of the resume.',
            icon: Iconsax.code,
            accentColor: AppColors.accent,
            stats: [
              EditorIntroStat(
                label: '${resume.skills.length} skills',
                icon: Iconsax.code,
              ),
              EditorIntroStat(
                label: '$categoriesCovered categories',
                icon: Iconsax.category,
              ),
              EditorIntroStat(
                label: '$advancedSkills advanced+',
                icon: Iconsax.flash_1,
              ),
            ],
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 16),
          ResumeQualityPanel(
            report: qualityReport,
            title: 'Skills Guidance',
            subtitle:
                'A strong skill block supports the claims you make in summary, experience, and projects. Changes here save immediately and will reflect in preview output.',
            accentColor: AppColors.accent,
            maxSuggestions: 2,
          ).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 20),
          // Add Skill Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.accent.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.code, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Add New Skill', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                // Category Selection
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Icon (Emoji) Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Skill Icon (optional)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        if (_selectedEmoji != null)
                          TextButton.icon(
                            onPressed: _clearSelectedEmoji,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.textSecondary,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            icon: const Icon(Iconsax.close_circle, size: 14),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _skillEmojis.length,
                        itemBuilder: (_, i) {
                          final emoji = _skillEmojis[i];
                          final selected = _selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setState(() =>
                                _selectedEmoji = selected ? null : emoji),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 6),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: InputDecoration(
                          hintText: 'Enter skill name',
                          prefixIcon: _selectedEmoji != null
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  child: Center(
                                    child: Text(
                                      _selectedEmoji!,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                )
                              : null,
                          prefixIconConstraints: _selectedEmoji != null
                              ? const BoxConstraints(minWidth: 0, minHeight: 0)
                              : null,
                          suffixIcon: _selectedEmoji != null
                              ? AdaptiveTooltip(
                                  message: 'Remove selected icon',
                                  button: true,
                                  child: IconButton(
                                    onPressed: _clearSelectedEmoji,
                                    icon: const Icon(
                                      Iconsax.close_circle,
                                      size: 18,
                                    ),
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Icon(Iconsax.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Proficiency Slider
                Row(
                  children: [
                    Text('Proficiency:', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: List.generate(5, (index) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _proficiency = index + 1),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 8,
                              decoration: BoxDecoration(
                                color: index < _proficiency ? AppColors.accent : AppColors.divider,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_getProficiencyLabel(_proficiency), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Smart Skill Suggestions
          if (resume.skills.length < 15) ...[
            Row(
              children: [
                const Icon(Iconsax.lamp_charge, size: 18, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text('Smart Suggestions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            // Role selector
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Target Role',
                prefixIcon: const Icon(Iconsax.briefcase, size: 18),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              isExpanded: true,
              items: SkillSuggestionsService.allRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
            ),
            const SizedBox(height: 10),
            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestionCategories
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: _suggestionCategory == cat,
                            onSelected: (_) => setState(() => _suggestionCategory = cat),
                            selectedColor: const Color(0xFF8B5CF6),
                            labelStyle: TextStyle(
                              color: _suggestionCategory == cat
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search skills…',
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? AdaptiveTooltip(
                        message: 'Clear skill search',
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedSkills
                  .where(
                    (s) => !resume.skills.any(
                      (rs) => _normalizedSkillName(rs.name).toLowerCase() ==
                          _normalizedSkillName(s).toLowerCase(),
                    ),
                  )
                  .take(18)
              .map(_buildSuggestionChip)
                  .toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],

          // Skills List
          if (resume.skills.isNotEmpty) ...[
            Text('Your Skills (${resume.skills.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...groupedSkills.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(entry.key, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
                ),
                ...entry.value.asMap().entries.map((skillEntry) => _SkillCard(
                  skill: skillEntry.value,
                  onRemoveIcon: _skillEmojiPrefix(skillEntry.value.name) == null
                      ? null
                      : () => _removeSkillIcon(skillEntry.value.id),
                  onDelete: () => _deleteSkill(skillEntry.value.id),
                  onUpdateProficiency: (level) => _updateProficiency(skillEntry.value.id, level),
                ).animate().fadeIn(delay: (300 + skillEntry.key * 50).ms).slideX(begin: 0.1, end: 0)),
              ],
            )),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _getProficiencyLabel(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Basic';
      case 3: return 'Intermediate';
      case 4: return 'Advanced';
      case 5: return 'Expert';
      default: return '';
    }
  }
}

class _SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback? onRemoveIcon;
  final VoidCallback onDelete;
  final Function(int) onUpdateProficiency;

  const _SkillCard({
    required this.skill,
    this.onRemoveIcon,
    required this.onDelete,
    required this.onUpdateProficiency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((skill.category ?? '').trim().isNotEmpty)
                      EditorStatPill(
                        label: skill.category!,
                        icon: Iconsax.category,
                        color: AppColors.accent,
                      ),
                    EditorStatPill(
                      label: 'Level ${skill.proficiency}',
                      icon: Iconsax.chart_success,
                      color: _getColorForProficiency(skill.proficiency),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) => GestureDetector(
                    onTap: () => onUpdateProficiency(index + 1),
                    child: Container(
                      width: 24, height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: index < skill.proficiency ? _getColorForProficiency(skill.proficiency) : AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRemoveIcon != null)
                AdaptiveTooltip(
                  message: 'Remove skill icon',
                  button: true,
                  child: IconButton(
                    onPressed: onRemoveIcon,
                    icon: const Icon(
                      Iconsax.close_circle,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              AdaptiveTooltip(
                message: 'Delete skill',
                button: true,
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Iconsax.trash, size: 20, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForProficiency(int level) {
    if (level <= 2) return AppColors.error;
    if (level <= 3) return AppColors.warning;
    return AppColors.success;
  }
}
