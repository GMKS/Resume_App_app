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
  ConsumerState<SkillAnalyzerScreen> createState() =>
      _SkillAnalyzerScreenState();
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
    final filters = <String>{
      ..._baseFilters,
      ...skills.map((skill) => skill.category)
    }.toList(growable: false);
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
            if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final scoreDiameter = constraints.maxWidth
                              .clamp(96.0, 120.0)
                              .toDouble();
                          final innerDiameter =
                              (scoreDiameter - 28).clamp(68.0, 92.0);
                          final scaleFactor = scoreDiameter / 120;

                          return SizedBox(
                            width: scoreDiameter,
                            height: scoreDiameter,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: scoreDiameter,
                                  height: scoreDiameter,
                                  child: CircularProgressIndicator(
                                    value: averageScore / 100,
                                    strokeWidth: 12,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getScoreColor(averageScore),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: innerDiameter,
                                  height: innerDiameter,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$averageScore',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge
                                                ?.copyWith(
                                                  fontSize: ((Theme.of(context)
                                                                  .textTheme
                                                                  .headlineLarge
                                                                  ?.fontSize ??
                                                              32) *
                                                          scaleFactor)
                                                      .clamp(24.0, 32.0),
                                                  fontWeight: FontWeight.bold,
                                                  color: _getScoreColor(
                                                      averageScore),
                                                ),
                                          ),
                                          SizedBox(height: 4 * scaleFactor),
                                          Text(
                                            'out of 100',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QuickStat(
                            icon: Iconsax.arrow_up_3,
                            label: 'Strong',
                            value: skills
                                .where((s) => s.status == 'Strong')
                                .length
                                .toString(),
                            color: AppColors.success,
                          ),
                          _QuickStat(
                            icon: Iconsax.minus,
                            label: 'Good',
                            value: skills
                                .where((s) => s.status == 'Good')
                                .length
                                .toString(),
                            color: AppColors.warning,
                          ),
                          _QuickStat(
                            icon: Iconsax.arrow_down,
                            label: 'Need Work',
                            value: skills
                                .where((s) => s.status == 'Needs Improvement')
                                .length
                                .toString(),
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, listBottomPadding),
                      itemCount: filteredSkills.length +
                          (state.errorMessage == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (state.errorMessage != null && index == 0) {
                          return Card(
                            color: AppColors.error.withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                state.errorMessage!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          );
                        }

                        final skillIndex =
                            state.errorMessage == null ? index : index - 1;
                        final skill = filteredSkills[skillIndex];
                        return _SkillCard(
                          skill: skill,
                          onEdit: skill.isUserAdded
                              ? () => _editSkill(skill)
                              : null,
                          onDelete: skill.isUserAdded
                              ? () => _deleteSkill(skill)
                              : null,
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
          minimum: const EdgeInsets.symmetric(horizontal: 16),
          child: FloatingActionButton.extended(
            onPressed: _showRecommendations,
            shape: const StadiumBorder(),
            icon: const Icon(Iconsax.lamp_on),
            extendedPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            label: const Text(
              'Get Recommendations',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
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

    await ref
        .read(skillAnalyzerControllerProvider.notifier)
        .deleteSkill(skill.id);
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
            marketDemand: SkillAnalyzerService.defaultSkills
                .firstWhere(
                  (defaultSkill) => defaultSkill.category == category,
                  orElse: () => service.buildUserSkill(
                    name: name,
                    category: category,
                    currentLevel: currentLevel,
                    yearsOfExperience: yearsOfExperience,
                  ),
                )
                .marketDemand,
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
                      reason:
                          'High market demand (95%) vs your current level (60%)',
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
  const _SkillCard({
    required this.skill,
    this.onEdit,
    this.onDelete,
  });

  final AnalyzedSkill skill;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          '${skill.yearsOfExperience!.toStringAsFixed(skill.yearsOfExperience! % 1 == 0 ? 0 : 1)} yrs experience',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (skill.isUserAdded)
                  PopupMenuButton<String>(
                    tooltip: 'Skill actions',
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                _StatusBadge(status: skill.status),
              ],
            ),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: skill.marketDemand / 100,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
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

class _SkillEmptyState extends StatelessWidget {
  const _SkillEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.lamp_on,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No custom skills yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your own skills to compare them with the built-in recommendations and market demand scores.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _BuildSkillCallback = AnalyzedSkill Function({
  required String name,
  required String category,
  required int currentLevel,
  double? yearsOfExperience,
});

class _SkillFormSheet extends StatefulWidget {
  const _SkillFormSheet({
    this.initialSkill,
    required this.categories,
    required this.existingSkills,
    required this.onBuildSkill,
  });

  final AnalyzedSkill? initialSkill;
  final List<String> categories;
  final List<AnalyzedSkill> existingSkills;
  final _BuildSkillCallback onBuildSkill;

  @override
  State<_SkillFormSheet> createState() => _SkillFormSheetState();
}

class _SkillFormSheetState extends State<_SkillFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _yearsController;
  late String _selectedCategory;
  late double _currentLevel;
  String? _nameError;

  bool get _isEditing => widget.initialSkill != null;

  @override
  void initState() {
    super.initState();
    final initialSkill = widget.initialSkill;
    _nameController = TextEditingController(text: initialSkill?.name ?? '');
    _yearsController = TextEditingController(
      text: initialSkill?.yearsOfExperience?.toString() ?? '',
    );
    _selectedCategory = widget.categories.contains(initialSkill?.category)
        ? initialSkill!.category
        : widget.categories.first;
    _currentLevel = (initialSkill?.currentLevel ?? 70).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeBottomSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Skill' : 'Add Skill',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Skill name',
                hintText: 'e.g. Product Strategy',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Years of experience (optional)',
                hintText: 'e.g. 3.5',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current level: ${_currentLevel.round()}%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Save Changes' : 'Add Skill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final normalizedName = _nameController.text.trim();
    if (normalizedName.isEmpty) {
      setState(() => _nameError = 'Enter a skill name');
      return;
    }

    final isDuplicate = widget.existingSkills.any((skill) {
      if (widget.initialSkill != null && skill.id == widget.initialSkill!.id) {
        return false;
      }
      return skill.name.trim().toLowerCase() == normalizedName.toLowerCase();
    });
    if (isDuplicate) {
      setState(() => _nameError = 'This skill already exists');
      return;
    }

    final parsedYears = double.tryParse(_yearsController.text.trim());
    final result = widget.onBuildSkill(
      name: normalizedName,
      category: _selectedCategory,
      currentLevel: _currentLevel.round(),
      yearsOfExperience: parsedYears,
    );
    Navigator.of(context).pop(result);
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
                  const Icon(Iconsax.info_circle,
                      size: 16, color: AppColors.primary),
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
            ...suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.tick_circle,
                          size: 16, color: AppColors.success),
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
