import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/subscription_model.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';

class InterviewQuestion {
  final String category;
  final String question;
  final String? sampleAnswer;
  final List<String> tips;

  const InterviewQuestion({
    required this.category,
    required this.question,
    this.sampleAnswer,
    required this.tips,
  });
}

final interviewQuestionsProvider = Provider<List<InterviewQuestion>>((ref) {
  return const [
    InterviewQuestion(
      category: 'Common',
      question: 'Tell me about yourself',
      sampleAnswer:
          'I\'m a software engineer with 5 years of experience in mobile development. I\'ve led teams in building scalable applications and I\'m passionate about creating user-friendly experiences.',
      tips: [
        'Keep it concise (1-2 minutes)',
        'Focus on professional background',
        'Highlight relevant achievements',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'What are your greatest strengths?',
      sampleAnswer:
          'My greatest strength is problem-solving. I excel at breaking down complex challenges and finding innovative solutions.',
      tips: [
        'Choose 2-3 relevant strengths',
        'Provide specific examples',
        'Align with job requirements',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'What is one weakness you are improving right now?',
      sampleAnswer:
          'I used to take on too much work myself instead of delegating early. I now break work into smaller ownership areas and communicate expectations sooner, which has improved delivery and team collaboration.',
      tips: [
        'Choose a real but manageable weakness',
        'Show the concrete action you are taking',
        'End with measurable improvement',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'Where do you see yourself in 5 years?',
      tips: [
        'Show career ambition',
        'Align with company growth',
        'Be realistic and honest',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'Why do you want to work here?',
      tips: [
        'Research the company',
        'Show genuine interest',
        'Mention specific aspects',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'Why should we hire you?',
      tips: [
        'Match your strengths to the role',
        'Mention business impact, not just effort',
        'Keep the answer direct and specific',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'What motivates you in your work?',
      tips: [
        'Talk about meaningful work and growth',
        'Avoid generic answers only about salary',
        'Tie motivation to the role you want',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'Why are you leaving your current role?',
      tips: [
        'Stay positive and professional',
        'Focus on growth, scope, or fit',
        'Do not criticize your current employer',
      ],
    ),
    InterviewQuestion(
      category: 'Common',
      question: 'What salary range are you targeting?',
      tips: [
        'Show that you researched the market',
        'Give a realistic range instead of one exact number',
        'Keep flexibility for total compensation and scope',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'Describe a challenging situation you faced',
      tips: [
        'Use STAR method',
        'Be specific',
        'Focus on positive outcome',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'How do you handle tight deadlines?',
      tips: [
        'Prioritize tasks effectively',
        'Communicate with your team',
        'Stay calm and focused',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'Tell me about a time you missed a target or deadline',
      tips: [
        'Take accountability without overexplaining',
        'Explain what you changed afterward',
        'Show better planning or communication next time',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'How do you handle conflicts in a team?',
      tips: [
        'Stay professional and calm',
        'Focus on finding a solution',
        'Communicate openly and listen actively',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'Describe a time you had to learn something quickly',
      tips: [
        'Describe the urgency and constraints',
        'Explain how you ramped up fast',
        'Show the business result',
      ],
    ),
    InterviewQuestion(
      category: 'Behavioral',
      question: 'Tell me about a time you received difficult feedback',
      tips: [
        'Show maturity and coachability',
        'Explain what changed after the feedback',
        'Demonstrate measurable improvement',
      ],
    ),
    InterviewQuestion(
      category: 'Technical',
      question: 'How do you test a feature before release?',
      sampleAnswer:
          'I start by clarifying the risk areas, then cover happy path, edge cases, and failure states. I combine unit, integration, and manual exploratory testing, and I verify analytics, logging, and rollback readiness before release.',
      tips: [
        'Mention risk-based testing',
        'Cover automation and manual validation',
        'Include production readiness checks',
      ],
    ),
    InterviewQuestion(
      category: 'Technical',
      question: 'Describe a bug you diagnosed end-to-end',
      tips: [
        'Explain how you reproduced it',
        'Show how you narrowed the root cause',
        'Mention the fix and prevention step',
      ],
    ),
    InterviewQuestion(
      category: 'Technical',
      question: 'How would you improve application performance?',
      tips: [
        'Start with measurement and profiling',
        'Prioritize the biggest bottlenecks',
        'Balance speed with maintainability',
      ],
    ),
    InterviewQuestion(
      category: 'Technical',
      question: 'How do you design stable API contracts between teams?',
      tips: [
        'Discuss versioning and backward compatibility',
        'Mention schema validation and contract testing',
        'Show how you handle change management',
      ],
    ),
    InterviewQuestion(
      category: 'Technical',
      question: 'How do you debug an issue you cannot reproduce locally?',
      tips: [
        'Start with logs, telemetry, and environment differences',
        'Reduce the problem with targeted hypotheses',
        'Add temporary instrumentation if needed',
      ],
    ),
    InterviewQuestion(
      category: 'Leadership',
      question: 'Can you give an example of a time you showed leadership?',
      tips: [
        'Describe the situation clearly',
        'Explain your role and actions',
        'Highlight the positive outcome',
      ],
    ),
    InterviewQuestion(
      category: 'Leadership',
      question: 'How do you mentor junior teammates?',
      tips: [
        'Mention structured feedback and pairing',
        'Show how you build confidence over time',
        'Connect mentoring to team outcomes',
      ],
    ),
    InterviewQuestion(
      category: 'Leadership',
      question: 'How do you prioritize across multiple projects?',
      tips: [
        'Talk about impact, urgency, and dependencies',
        'Explain how you communicate tradeoffs',
        'Show how you revisit priorities regularly',
      ],
    ),
    InterviewQuestion(
      category: 'Leadership',
      question: 'Tell me about a time you influenced without authority',
      tips: [
        'Show how you built alignment',
        'Use evidence instead of title-based influence',
        'Highlight the result for the team or product',
      ],
    ),
    InterviewQuestion(
      category: 'Leadership',
      question: 'How do you handle underperformance on a team?',
      tips: [
        'Start with clarity and direct feedback',
        'Offer support and a concrete improvement plan',
        'Balance empathy with accountability',
      ],
    ),
  ];
});

class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  int? _expandedIndex;
  String _selectedCategory = 'Common';

  final List<String> _categories = [
    'Common',
    'Behavioral',
    'Technical',
    'Leadership',
  ];

  @override
  Widget build(BuildContext context) {
    final allQuestions = ref.watch(interviewQuestionsProvider);
    final questions = allQuestions
        .where((question) => question.category == _selectedCategory)
        .toList(growable: false);

    return FeatureGate(
      featureName: SubscriptionFeatures.interviewPrep,
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
          title: const Text('Interview Preparation'),
          actions: [
            AdaptiveTooltip(
              message: 'Tips',
              button: true,
              child: IconButton(
                onPressed: _showTips,
                icon: const Icon(Iconsax.lamp_on),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Category Filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _expandedIndex = null;
                      });
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
            ).animate().fadeIn(delay: 100.ms),

            // Practice Stats Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _StatItem(
                          icon: Iconsax.task_square,
                          label: 'Practiced',
                          value: '12/50',
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                      ),
                      const Expanded(
                        child: _StatItem(
                          icon: Iconsax.timer_1,
                          label: 'This Week',
                          value: '3',
                          color: AppColors.success,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                      ),
                      const Expanded(
                        child: _StatItem(
                          icon: Iconsax.star_1,
                          label: 'Confidence',
                          value: '85%',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
            ),

            // Questions List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final isExpanded = _expandedIndex == index;

                  return _QuestionCard(
                    question: question,
                    isExpanded: isExpanded,
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                  ).animate().fadeIn(delay: (300 + index * 50).ms).slideX(begin: -0.05, end: 0);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startPracticeSession,
          icon: const Icon(Iconsax.video_play),
          label: const Text('Start Practice'),
        ).animate().fadeIn(delay: 400.ms).scale(),
      ),
    );
  }

  void _showTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.lamp_on, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Interview Tips'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem('Research the company thoroughly'),
              _buildTipItem('Practice your answers out loud'),
              _buildTipItem('Prepare questions to ask the interviewer'),
              _buildTipItem('Dress appropriately for the role'),
              _buildTipItem('Arrive 10-15 minutes early'),
              _buildTipItem('Bring extra copies of your resume'),
              _buildTipItem('Use the STAR method for behavioral questions'),
              _buildTipItem('Follow up with a thank-you email'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.tick_circle, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  void _startPracticeSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Practice Session'),
        content: const Text(
          'Practice sessions with video recording and AI feedback are coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

class _QuestionCard extends StatelessWidget {
  final InterviewQuestion question;
  final bool isExpanded;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.question,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.message_question, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.question,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                if (question.sampleAnswer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.microphone, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Sample Answer',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.sampleAnswer!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Tips:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                ...question.tips
                    .map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Iconsax.tick_circle,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Iconsax.microphone, size: 18),
                  label: const Text('Practice This'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
