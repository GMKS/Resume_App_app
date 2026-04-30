import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';

class Skill {
  final String name;
  final String category;
  final int currentLevel;
  final int marketDemand;
  final String status; // 'Strong', 'Good', 'Needs Improvement'

  Skill({
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.marketDemand,
    required this.status,
  });
}

final skillsProvider = Provider<List<Skill>>((ref) {
  return [
    Skill(
      name: 'Flutter Development',
      category: 'Technical',
      currentLevel: 85,
      marketDemand: 90,
      status: 'Strong',
    ),
    Skill(
      name: 'Project Management',
      category: 'Leadership',
      currentLevel: 70,
      marketDemand: 85,
      status: 'Good',
    ),
    Skill(
      name: 'UI/UX Design',
      category: 'Design',
      currentLevel: 60,
      marketDemand: 95,
      status: 'Needs Improvement',
    ),
    Skill(
      name: 'Communication',
      category: 'Soft Skills',
      currentLevel: 75,
      marketDemand: 80,
      status: 'Good',
    ),
    Skill(
      name: 'Data Analysis',
      category: 'Technical',
      currentLevel: 50,
      marketDemand: 90,
      status: 'Needs Improvement',
    ),
  ];
});

class SkillAnalyzerScreen extends ConsumerStatefulWidget {
  const SkillAnalyzerScreen({super.key});

  @override
  ConsumerState<SkillAnalyzerScreen> createState() => _SkillAnalyzerScreenState();
}

class _SkillAnalyzerScreenState extends ConsumerState<SkillAnalyzerScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Technical', 'Leadership', 'Design', 'Soft Skills'];

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillsProvider);
    final filteredSkills = _selectedFilter == 'All'
        ? skills
        : skills.where((s) => s.category == _selectedFilter).toList();

    final averageScore = skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel) ~/
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
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
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
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSkills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final skill = filteredSkills[index];
                  return _SkillCard(skill: skill)
                      .animate()
                      .fadeIn(delay: (300 + index * 50).ms)
                      .slideX(begin: -0.05, end: 0);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showRecommendations,
          icon: const Icon(Iconsax.lamp_on),
          label: const Text('Get Recommendations'),
        ).animate().fadeIn(delay: 400.ms).scale(),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _addNewSkill() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Skill'),
        content: const Text('Skill addition feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
  final Skill skill;

  const _SkillCard({required this.skill});

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
                    ],
                  ),
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
