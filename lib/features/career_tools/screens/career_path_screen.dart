import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';

class CareerPathNode {
  final String title;
  final String level;
  final int yearsExperience;
  final String salary;
  final List<String> skills;
  final bool isCurrent;
  final bool isRecommended;

  CareerPathNode({
    required this.title,
    required this.level,
    required this.yearsExperience,
    required this.salary,
    required this.skills,
    this.isCurrent = false,
    this.isRecommended = false,
  });
}

final careerPathProvider = Provider<List<CareerPathNode>>((ref) {
  return [
    CareerPathNode(
      title: 'Junior Developer',
      level: 'Entry',
      yearsExperience: 1,
      salary: '\$45k - \$65k',
      skills: ['Basic programming', 'Version control', 'Testing'],
      isCurrent: false,
    ),
    CareerPathNode(
      title: 'Software Developer',
      level: 'Mid',
      yearsExperience: 3,
      salary: '\$65k - \$95k',
      skills: ['Full-stack development', 'API design', 'Databases'],
      isCurrent: true,
    ),
    CareerPathNode(
      title: 'Senior Developer',
      level: 'Senior',
      yearsExperience: 5,
      salary: '\$95k - \$130k',
      skills: ['Architecture', 'Mentoring', 'System design'],
      isRecommended: true,
    ),
    CareerPathNode(
      title: 'Tech Lead',
      level: 'Leadership',
      yearsExperience: 7,
      salary: '\$120k - \$160k',
      skills: ['Team leadership', 'Project planning', 'Technical strategy'],
    ),
    CareerPathNode(
      title: 'Engineering Manager',
      level: 'Management',
      yearsExperience: 10,
      salary: '\$140k - \$200k',
      skills: ['People management', 'Hiring', 'Budget planning'],
    ),
  ];
});

class CareerPathScreen extends ConsumerStatefulWidget {
  const CareerPathScreen({super.key});

  @override
  ConsumerState<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends ConsumerState<CareerPathScreen> {
  @override
  Widget build(BuildContext context) {
    final careerPath = ref.watch(careerPathProvider);

    return FeatureGate(
      featureName: SubscriptionFeatures.careerPath,
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
          title: const Text('Career Path'),
          actions: [
            AdaptiveTooltip(
              message: 'Alternate Paths',
              button: true,
              child: IconButton(
                onPressed: _showAlternatePaths,
                icon: const Icon(Iconsax.hierarchy_square),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Iconsax.route_square, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your Career Roadmap',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Based on your current role and skills, here\'s a suggested career progression path with salary ranges and required skills.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).scale(),

              const SizedBox(height: 24),

              // Career Path Timeline
              ...List.generate(careerPath.length, (index) {
                final node = careerPath[index];
                final isLast = index == careerPath.length - 1;

                return Column(
                  children: [
                    _CareerPathCard(
                      node: node,
                      index: index,
                    ).animate().fadeIn(delay: (200 + index * 100).ms).slideX(begin: -0.1, end: 0),
                    if (!isLast)
                      _PathConnector(
                        isActive: node.isCurrent,
                      ).animate().fadeIn(delay: (250 + index * 100).ms),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _generateDetailedPlan,
                icon: const Icon(Iconsax.document_text_1),
                label: const Text('Generate Detailed Plan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _exploreCourses,
                icon: const Icon(Iconsax.book),
                label: const Text('Explore Courses'),
              ),

              const SizedBox(height: 24),

              // Insights Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Iconsax.lamp_on, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Career Insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _InsightItem(
                        icon: Iconsax.timer_1,
                        title: 'Time to Next Role',
                        value: '1-2 years',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      const _InsightItem(
                        icon: Iconsax.chart_1,
                        title: 'Potential Salary Increase',
                        value: '+35%',
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      const _InsightItem(
                        icon: Iconsax.task_square,
                        title: 'Skills to Acquire',
                        value: '3 core skills',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlternatePaths() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
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
                child: Text(
                  'Alternate Career Paths',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: const [
                    _AlternatePathCard(
                      title: 'Solution Architect',
                      description: 'Design large-scale technical solutions',
                      matchScore: 85,
                    ),
                    SizedBox(height: 12),
                    _AlternatePathCard(
                      title: 'Product Manager',
                      description: 'Lead product strategy and development',
                      matchScore: 72,
                    ),
                    SizedBox(height: 12),
                    _AlternatePathCard(
                      title: 'DevOps Engineer',
                      description: 'Build and maintain infrastructure',
                      matchScore: 68,
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

  void _generateDetailedPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed plan generation coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exploreCourses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course exploration feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CareerPathCard extends StatelessWidget {
  final CareerPathNode node;
  final int index;

  const _CareerPathCard({
    required this.node,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: node.isCurrent ? 4 : 1,
      color: node.isCurrent
          ? AppColors.primary.withOpacity(0.05)
          : node.isRecommended
              ? AppColors.warning.withOpacity(0.05)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: node.isCurrent
                        ? AppColors.primary
                        : node.isRecommended
                            ? AppColors.warning
                            : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: node.isCurrent
                        ? const Icon(Iconsax.location5, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: node.isRecommended ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (node.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (node.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEXT STEP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${node.level} • ${node.yearsExperience}+ years',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.money_4, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        node.salary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: node.skills
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  final bool isActive;

  const _PathConnector({this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 30,
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          Icon(
            Iconsax.arrow_down_1,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlternatePathCard extends StatelessWidget {
  final String title;
  final String description;
  final int matchScore;

  const _AlternatePathCard({
    required this.title,
    required this.description,
    required this.matchScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '$matchScore%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                ),
                Text(
                  'match',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
