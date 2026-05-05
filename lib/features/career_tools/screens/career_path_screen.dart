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

class CareerPlanMilestone {
  const CareerPlanMilestone({
    required this.title,
    required this.timeframe,
    required this.summary,
    required this.deliverables,
  });

  final String title;
  final String timeframe;
  final String summary;
  final List<String> deliverables;
}

class CourseRecommendation {
  const CourseRecommendation({
    required this.title,
    required this.format,
    required this.duration,
    required this.summary,
    required this.skills,
  });

  final String title;
  final String format;
  final String duration;
  final String summary;
  final List<String> skills;
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
  CareerPathNode _currentNode(List<CareerPathNode> careerPath) {
    return careerPath.firstWhere(
      (node) => node.isCurrent,
      orElse: () => careerPath.first,
    );
  }

  CareerPathNode _targetNode(List<CareerPathNode> careerPath) {
    return careerPath.firstWhere(
      (node) => node.isRecommended,
      orElse: () => careerPath.length > 1 ? careerPath[1] : careerPath.first,
    );
  }

  List<CareerPlanMilestone> _buildDetailedPlan(List<CareerPathNode> careerPath) {
    final current = _currentNode(careerPath);
    final target = _targetNode(careerPath);
    final focusSkills = target.skills.take(3).toList(growable: false);

    return [
      CareerPlanMilestone(
        title: 'Strengthen Core Technical Depth',
        timeframe: 'Weeks 1-4',
        summary:
            'Build stronger ownership in ${focusSkills.first} so your work shows clear next-level scope.',
        deliverables: [
          'Document one architecture decision for an active feature',
          'Ship one quality or performance improvement with measurable impact',
          'Create a short knowledge note on ${focusSkills.first.toLowerCase()}',
        ],
      ),
      CareerPlanMilestone(
        title: 'Expand Team Influence',
        timeframe: 'Weeks 5-8',
        summary:
            'Move from execution to guidance by mentoring others and improving delivery habits.',
        deliverables: [
          'Mentor one teammate through a review or debugging task',
          'Lead one planning or estimation discussion',
          'Create a reusable checklist around ${focusSkills[1].toLowerCase()}',
        ],
      ),
      CareerPlanMilestone(
        title: 'Lead a Cross-Functional Initiative',
        timeframe: 'Weeks 9-12',
        summary:
            'Demonstrate readiness for ${target.title} by coordinating delivery beyond your own tasks.',
        deliverables: [
          'Own a small project from kickoff to release',
          'Track risks, tradeoffs, and stakeholder updates weekly',
          'Present lessons learned tied to ${focusSkills[2].toLowerCase()}',
        ],
      ),
      CareerPlanMilestone(
        title: 'Package Promotion Evidence',
        timeframe: 'Weeks 13-14',
        summary:
            'Convert recent work into a clear case for the move from ${current.title} to ${target.title}.',
        deliverables: [
          'Update your resume with quantified impact',
          'Collect 3 examples of leadership or mentorship',
          'Prepare stories for architecture, ownership, and influence interviews',
        ],
      ),
    ];
  }

  List<CourseRecommendation> _buildCourseRecommendations(
    List<CareerPathNode> careerPath,
  ) {
    final target = _targetNode(careerPath);
    return [
      CourseRecommendation(
        title: 'Scalable System Design Sprint',
        format: 'Guided path',
        duration: '4 weeks',
        summary:
            'Practice tradeoffs, service boundaries, and reliability patterns for larger systems.',
        skills: [
          target.skills.elementAt(2),
          'Architecture reviews',
          'Reliability thinking',
        ],
      ),
      CourseRecommendation(
        title: 'Mentoring and Technical Coaching',
        format: 'Workshop series',
        duration: '2 weeks',
        summary:
            'Build repeatable habits for feedback, delegation, and growing other engineers.',
        skills: [
          target.skills.elementAt(1),
          'Feedback loops',
          'Growth planning',
        ],
      ),
      CourseRecommendation(
        title: 'Architecture Communication for Senior Engineers',
        format: 'Case study lab',
        duration: '3 weeks',
        summary:
            'Turn technical decisions into clear proposals for product, design, and engineering peers.',
        skills: [
          target.skills.first,
          'Stakeholder alignment',
          'Decision records',
        ],
      ),
      const CourseRecommendation(
        title: 'Leadership Foundations for Tech Teams',
        format: 'Self-paced',
        duration: '5 hours',
        summary:
            'Learn prioritization, delegation, and execution management before stepping into broader ownership.',
        skills: [
          'Prioritization',
          'Execution planning',
          'Team communication',
        ],
      ),
    ];
  }

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
    final careerPath = ref.read(careerPathProvider);
    final current = _currentNode(careerPath);
    final target = _targetNode(careerPath);
    final milestones = _buildDetailedPlan(careerPath);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CareerPlanSheet(
        current: current,
        target: target,
        milestones: milestones,
      ),
    );
  }

  void _exploreCourses() {
    final careerPath = ref.read(careerPathProvider);
    final target = _targetNode(careerPath);
    final courses = _buildCourseRecommendations(careerPath);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseExplorerSheet(
        target: target,
        courses: courses,
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

class _CareerPlanSheet extends StatelessWidget {
  const _CareerPlanSheet({
    required this.current,
    required this.target,
    required this.milestones,
  });

  final CareerPathNode current;
  final CareerPathNode target;
  final List<CareerPlanMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detailed Growth Plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Move from ${current.title} to ${target.title} with a focused 90-day plan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${current.title} -> ${target.title}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: target.skills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              backgroundColor: AppColors.primary.withOpacity(0.08),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.18),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...milestones.map(
              (milestone) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CareerPlanMilestoneCard(milestone: milestone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerPlanMilestoneCard extends StatelessWidget {
  const _CareerPlanMilestoneCard({required this.milestone});

  final CareerPlanMilestone milestone;

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
                  child: Text(
                    milestone.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    milestone.timeframe,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              milestone.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ...milestone.deliverables.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Iconsax.tick_circle, size: 18, color: AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseExplorerSheet extends StatelessWidget {
  const _CourseExplorerSheet({
    required this.target,
    required this.courses,
  });

  final CareerPathNode target;
  final List<CourseRecommendation> courses;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Course Recommendations',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Short learning paths to build the skills expected for ${target.title}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CourseRecommendationCard(course: course),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRecommendationCard extends StatelessWidget {
  const _CourseRecommendationCard({required this.course});

  final CourseRecommendation course;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _CourseMetaChip(icon: Iconsax.book_1, label: course.format),
                const SizedBox(width: 8),
                _CourseMetaChip(icon: Iconsax.clock, label: course.duration),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: course.skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.18)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseMetaChip extends StatelessWidget {
  const _CourseMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
