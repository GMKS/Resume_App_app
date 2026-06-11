import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../editor/widgets/keyboard_safe_bottom_sheet.dart';
import '../services/skill_analyzer_service.dart';

class SkillAnalyzerScreen extends ConsumerStatefulWidget {
  const SkillAnalyzerScreen({super.key});

  @override
  ConsumerState<SkillAnalyzerScreen> createState() => _SkillAnalyzerScreenState();
}

class _SkillAnalyzerScreenState extends ConsumerState<SkillAnalyzerScreen> {
  static const List<String> _baseFilters = <String>[
    'All',
    'Technical',
    'Leadership',
    'Design',
    'Soft Skills',
    'Domain',
    'Other',
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillAnalyzerControllerProvider);
    final skills = <AnalyzedSkill>[
      ...SkillAnalyzerService.defaultSkills,
      ...state.userSkills,
    ];
    final filters = <String>{..._baseFilters, ...skills.map((skill) => skill.category)}
        .toList(growable: false);
    final filteredSkills = _selectedFilter == 'All'
        ? skills
        : skills.where((s) => s.category == _selectedFilter).toList();
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    const fabHeight = 56.0;
    const fabGap = 48.0;
    final listBottomPadding = 16 + fabHeight + fabGap + safeBottomInset;

    final averageScore = skills.isEmpty
        ? 0
        : skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel) ~/
            skills.length;

    return FeatureGate(
      featureName: SubscriptionFeatures.skillAnalyzer,
      child: Scaffold(
        appBar: AppBar(
          leading: AdaptiveTooltip(
            message: 'Back',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left),
            ),
          ),
          title: const Text('Skill Analyzer'),
          actions: [
            AdaptiveTooltip(
              message: 'Add Skill',
              button: true,
              child: IconButton(
                onPressed: _addNewSkill,
                icon: const Icon(Iconsax.add_circle),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            // Overall Score Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Overall Skill Score',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: averageScore / 100,
                              strokeWidth: 12,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getScoreColor(averageScore),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '$averageScore',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(averageScore),
                                    ),
                              ),
                              Text(
                                'out of 100',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QuickStat(
                            icon: Iconsax.arrow_up_3,
                            label: 'Strong',
                            value: skills.where((s) => s.status == 'Strong').length.toString(),
                            color: AppColors.success,
                          ),
                          _QuickStat(
                            icon: Iconsax.minus,
                            label: 'Good',
                            value: skills.where((s) => s.status == 'Good').length.toString(),
                            color: AppColors.warning,
                          ),
                          _QuickStat(
                            icon: Iconsax.arrow_down,
                            label: 'Need Work',
                            value: skills.where((s) => s.status == 'Needs Improvement').length.toString(),
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).scale(),
            ),

            // Filters
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Skills List
            Expanded(
              child: filteredSkills.isEmpty && state.errorMessage == null
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 140),
                      child: _SkillEmptyState(),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPadding),
                      itemCount:
                          filteredSkills.length + (state.errorMessage == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (state.errorMessage != null && index == 0) {
                          return Card(
                            color: AppColors.error.withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                state.errorMessage!,
                                style:
                                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.error,
                                        ),
                              ),
                            ),
                          );
                        }

                        final skillIndex =
                            state.errorMessage == null ? index : index - 1;
                        final skill = filteredSkills[skillIndex];
                        return _SkillCard(
                          skill: skill,
                          onEdit: skill.isUserAdded ? () => _editSkill(skill) : null,
                          onDelete:
                              skill.isUserAdded ? () => _deleteSkill(skill) : null,
                        )
                            .animate()
                            .fadeIn(delay: (300 + skillIndex * 50).ms)
                            .slideX(begin: -0.05, end: 0);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 32,
            ),
            child: FloatingActionButton.extended(
              onPressed: _showRecommendations,
              icon: const Icon(Iconsax.lamp_on),
              label: const Text('Get Recommendations'),
            ).animate().fadeIn(delay: 400.ms).scale(),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _addNewSkill() async {
    final result = await _showSkillSheet();
    if (result == null) {
      return;
    }

    await ref.read(skillAnalyzerControllerProvider.notifier).saveSkill(result);
    if (_selectedFilter != 'All' && _selectedFilter != result.category) {
      setState(() => _selectedFilter = result.category);
    }
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.name} added to Skill Analyzer.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editSkill(AnalyzedSkill skill) async {
    final result = await _showSkillSheet(skill: skill);
    if (result == null) {
      return;
    }

    await ref.read(skillAnalyzerControllerProvider.notifier).saveSkill(result);
    if (_selectedFilter != 'All' && _selectedFilter != result.category) {
      setState(() => _selectedFilter = result.category);
    }
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.name} updated successfully.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSkill(AnalyzedSkill skill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete skill?'),
        content: Text('Remove ${skill.name} from your custom skills list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(skillAnalyzerControllerProvider.notifier).deleteSkill(skill.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${skill.name} deleted.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<AnalyzedSkill?> _showSkillSheet({AnalyzedSkill? skill}) {
    final allSkills = <AnalyzedSkill>[
      ...SkillAnalyzerService.defaultSkills,
      ...ref.read(skillAnalyzerControllerProvider).userSkills,
    ];
    final categories = <String>{
      'Technical',
      'Leadership',
      'Soft Skills',
      'Domain',
      'Design',
      'Other',
      ...allSkills.map((item) => item.category),
    }.toList(growable: false);

    return showModalBottomSheet<AnalyzedSkill>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SkillFormSheet(
        initialSkill: skill,
        categories: categories,
        existingSkills: allSkills,
        onBuildSkill: ({
          required String name,
          required String category,
          required int currentLevel,
          double? yearsOfExperience,
        }) {
          final service = ref.read(skillAnalyzerServiceProvider);
          if (skill == null) {
            return service.buildUserSkill(
              name: name,
              category: category,
              currentLevel: currentLevel,
              yearsOfExperience: yearsOfExperience,
            );
          }

          return skill.copyWith(
            name: name.trim(),
            category: category.trim(),
            currentLevel: currentLevel,
            marketDemand: SkillAnalyzerService.defaultSkills.firstWhere(
              (defaultSkill) => defaultSkill.category == category,
              orElse: () => service.buildUserSkill(
                name: name,
                category: category,
                currentLevel: currentLevel,
                yearsOfExperience: yearsOfExperience,
              ),
            ).marketDemand,
            yearsOfExperience: yearsOfExperience,
            clearYearsOfExperience: yearsOfExperience == null,
            updatedAt: DateTime.now(),
          );
        },
      ),
    );
  }

  void _showRecommendations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Iconsax.lamp_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Skill Recommendations',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: const [
                    _RecommendationCard(
                      title: 'Improve UI/UX Design Skills',
                      reason: 'High market demand (95%) vs your current level (60%)',
                      suggestions: [
                        'Take online UI/UX course',
                        'Practice with design tools (Figma, Sketch)',
                        'Study design principles and patterns',
                      ],
                    ),
                    SizedBox(height: 12),
                    _RecommendationCard(
                      title: 'Enhance Data Analysis',
                      reason: 'Critical skill gap for career growth',
                      suggestions: [
                        'Learn data visualization tools',
                        'Study statistical analysis',
                        'Practice with real datasets',
                      ],
                    ),
                    SizedBox(height: 12),
                    _RecommendationCard(
                      title: 'Boost Project Management',
                      reason: 'Align with market demand (85%)',
                      suggestions: [
                        'Get PMP or Agile certification',
                        'Lead team projects',
                        'Learn project management tools',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final AnalyzedSkill skill;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SkillCard({
    required this.skill,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skill.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (skill.yearsOfExperience != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${skill.yearsOfExperience!.toStringAsFixed(skill.yearsOfExperience! % 1 == 0 ? 0 : 1)} years experience',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (skill.isUserAdded)
                  PopupMenuButton<_SkillAction>(
                    tooltip: 'Skill actions',
                    onSelected: (action) {
                      switch (action) {
                        case _SkillAction.edit:
                          onEdit?.call();
                          break;
                        case _SkillAction.delete:
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_SkillAction>(
                        value: _SkillAction.edit,
                        child: ListTile(
                          leading: Icon(Iconsax.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem<_SkillAction>(
                        value: _SkillAction.delete,
                        child: ListTile(
                          leading: Icon(Iconsax.trash, color: AppColors.error),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                else
                  _StatusBadge(status: skill.status),
              ],
            ),
            if (skill.isUserAdded) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _StatusBadge(status: skill.status),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Level',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${skill.currentLevel}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: skill.currentLevel / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(skill.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Market Demand',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${skill.marketDemand}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: skill.marketDemand / 100,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Strong':
        return AppColors.success;
      case 'Good':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}

enum _SkillAction { edit, delete }

class _SkillEmptyState extends StatelessWidget {
  const _SkillEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Iconsax.chart_1, size: 36, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'No skills match this filter yet.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Add a new skill to track it here and update your overall score immediately.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillFormSheet extends StatefulWidget {
  const _SkillFormSheet({
    required this.initialSkill,
    required this.categories,
    required this.existingSkills,
    required this.onBuildSkill,
  });

  final AnalyzedSkill? initialSkill;
  final List<String> categories;
  final List<AnalyzedSkill> existingSkills;
  final AnalyzedSkill Function({
    required String name,
    required String category,
    required int currentLevel,
    double? yearsOfExperience,
  }) onBuildSkill;

  @override
  State<_SkillFormSheet> createState() => _SkillFormSheetState();
}

class _SkillFormSheetState extends State<_SkillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _yearsController;
  late String _selectedCategory;
  late double _currentLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialSkill?.name ?? '');
    _yearsController = TextEditingController(
      text: widget.initialSkill?.yearsOfExperience?.toString() ?? '',
    );
    _selectedCategory = widget.initialSkill?.category ?? widget.categories.first;
    _currentLevel = (widget.initialSkill?.currentLevel ?? 60).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardSafeBottomSheet(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.initialSkill == null ? 'Add New Skill' : 'Edit Skill',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track your proficiency and keep your skill profile up to date.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                hintText: 'e.g. Product Strategy',
                prefixIcon: Icon(Iconsax.flash_1),
              ),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return 'Enter a skill name.';
                }

                final duplicate = widget.existingSkills.any((skill) {
                  if (widget.initialSkill != null && skill.id == widget.initialSkill!.id) {
                    return false;
                  }
                  return skill.name.toLowerCase() == normalized.toLowerCase();
                });
                if (duplicate) {
                  return 'This skill already exists.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Skill Category',
                prefixIcon: Icon(Iconsax.category),
              ),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedCategory = value);
              },
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Select a category.' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current Proficiency Level',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_currentLevel.round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _currentLevel,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_currentLevel.round()}%',
              onChanged: (value) {
                setState(() => _currentLevel = value);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _yearsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Years of Experience (optional)',
                hintText: 'e.g. 3.5',
                prefixIcon: Icon(Iconsax.timer_1),
              ),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return null;
                }

                final parsed = double.tryParse(normalized);
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid number of years.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(widget.initialSkill == null ? Iconsax.add : Iconsax.save_2),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : (widget.initialSkill == null ? 'Save Skill' : 'Update Skill'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final yearsText = _yearsController.text.trim();
    final years = yearsText.isEmpty ? null : double.tryParse(yearsText);

    setState(() => _isSaving = true);
    final skill = widget.onBuildSkill(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      currentLevel: _currentLevel.round(),
      yearsOfExperience: years,
    );
    Navigator.of(context).pop(skill);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Strong':
        color = AppColors.success;
        icon = Iconsax.arrow_up_3;
        break;
      case 'Good':
        color = AppColors.warning;
        icon = Iconsax.minus;
        break;
      default:
        color = AppColors.error;
        icon = Iconsax.arrow_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String reason;
  final List<String> suggestions;

  const _RecommendationCard({
    required this.title,
    required this.reason,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suggested Actions:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...suggestions
                .map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Iconsax.tick_circle, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
