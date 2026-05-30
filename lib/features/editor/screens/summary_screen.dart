import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import 'resume_editor_screen.dart';

class _SummaryExample {
  final String id;
  final String title;
  final String category;
  final String level;
  final String text;
  final List<String> tags;

  const _SummaryExample({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.text,
    required this.tags,
  });
}

const _kSummaryExamples = <_SummaryExample>[
  _SummaryExample(
    id: 'software_mid',
    title: 'Software Developer',
    category: 'Technology',
    level: 'Mid-Level',
    text:
        'Innovative software developer with 5+ years of experience building scalable web and mobile applications. Skilled in Flutter, APIs, and cloud-backed systems with a strong record of shipping reliable user-focused products.',
    tags: ['flutter', 'mobile', 'backend', 'cloud'],
  ),
  _SummaryExample(
    id: 'software_senior',
    title: 'Senior Software Engineer',
    category: 'Technology',
    level: 'Senior',
    text:
        'Senior software engineer with deep experience leading architecture decisions, mentoring teams, and delivering high-performance platforms. Known for improving code quality, release stability, and engineering velocity across complex products.',
    tags: ['architecture', 'leadership', 'quality', 'platform'],
  ),
  _SummaryExample(
    id: 'frontend',
    title: 'Frontend Engineer',
    category: 'Technology',
    level: 'Mid-Level',
    text:
        'Frontend engineer focused on building fast, accessible, and polished interfaces for web and mobile experiences. Combines strong UI craftsmanship with product thinking to turn complex workflows into intuitive user journeys.',
    tags: ['ui', 'ux', 'accessibility', 'product'],
  ),
  _SummaryExample(
    id: 'backend',
    title: 'Backend Engineer',
    category: 'Technology',
    level: 'Senior',
    text:
        'Backend engineer with expertise in distributed services, data modeling, and API design. Delivers resilient systems that support scale, simplify integrations, and improve operational reliability.',
    tags: ['api', 'microservices', 'data', 'scalability'],
  ),
  _SummaryExample(
    id: 'data_analyst',
    title: 'Data Analyst',
    category: 'Data',
    level: 'Mid-Level',
    text:
        'Data analyst with experience transforming raw data into actionable insights for business and product teams. Strong in dashboarding, trend analysis, and storytelling that supports faster, better-informed decisions.',
    tags: ['sql', 'dashboards', 'analytics', 'reporting'],
  ),
  _SummaryExample(
    id: 'data_scientist',
    title: 'Data Scientist',
    category: 'Data',
    level: 'Senior',
    text:
        'Data scientist with a track record of applying statistical modeling and machine learning to real-world business problems. Builds practical solutions that improve forecasting, segmentation, and decision accuracy.',
    tags: ['machine learning', 'forecasting', 'python', 'statistics'],
  ),
  _SummaryExample(
    id: 'product_manager',
    title: 'Product Manager',
    category: 'Product',
    level: 'Senior',
    text:
        'Product manager who aligns customer needs, business goals, and engineering execution to deliver measurable outcomes. Experienced in roadmap planning, stakeholder alignment, and iterative product discovery.',
    tags: ['roadmap', 'strategy', 'stakeholders', 'discovery'],
  ),
  _SummaryExample(
    id: 'project_manager',
    title: 'Project Manager',
    category: 'Operations',
    level: 'Mid-Level',
    text:
        'Project manager with strong experience coordinating cross-functional teams, managing timelines, and reducing delivery risks. Known for keeping initiatives organized, on budget, and aligned with business priorities.',
    tags: ['delivery', 'timelines', 'budget', 'coordination'],
  ),
  _SummaryExample(
    id: 'program_manager',
    title: 'Program Manager',
    category: 'Operations',
    level: 'Senior',
    text:
        'Program manager experienced in leading complex multi-team initiatives from planning through execution. Brings structure, governance, and visibility that improves delivery confidence and organizational alignment.',
    tags: ['governance', 'planning', 'execution', 'alignment'],
  ),
  _SummaryExample(
    id: 'marketing_manager',
    title: 'Marketing Manager',
    category: 'Marketing',
    level: 'Mid-Level',
    text:
        'Strategic marketing professional with experience driving brand growth, demand generation, and campaign performance. Blends creative execution with analytics to increase engagement, pipeline, and market visibility.',
    tags: ['campaigns', 'brand', 'seo', 'growth'],
  ),
  _SummaryExample(
    id: 'digital_marketer',
    title: 'Digital Marketing Specialist',
    category: 'Marketing',
    level: 'Mid-Level',
    text:
        'Digital marketer skilled in paid media, lifecycle campaigns, and performance optimization across multiple channels. Uses testing and audience insights to improve conversion rates and return on ad spend.',
    tags: ['paid media', 'crm', 'conversion', 'testing'],
  ),
  _SummaryExample(
    id: 'content_strategist',
    title: 'Content Strategist',
    category: 'Marketing',
    level: 'Senior',
    text:
        'Content strategist with experience building editorial systems and messaging frameworks that strengthen brand consistency. Creates audience-focused content programs that support awareness, engagement, and trust.',
    tags: ['content', 'editorial', 'messaging', 'brand'],
  ),
  _SummaryExample(
    id: 'sales_exec',
    title: 'Sales Executive',
    category: 'Sales',
    level: 'Senior',
    text:
        'Results-driven sales executive with a record of growing revenue, expanding accounts, and building strong client relationships. Skilled in consultative selling, negotiation, and pipeline management.',
    tags: ['revenue', 'accounts', 'negotiation', 'pipeline'],
  ),
  _SummaryExample(
    id: 'account_manager',
    title: 'Account Manager',
    category: 'Sales',
    level: 'Mid-Level',
    text:
        'Account manager who strengthens client retention through responsive service, clear communication, and strategic partnership building. Focused on uncovering growth opportunities while maintaining customer satisfaction.',
    tags: ['retention', 'clients', 'renewals', 'upsell'],
  ),
  _SummaryExample(
    id: 'customer_success',
    title: 'Customer Success Manager',
    category: 'Customer Success',
    level: 'Mid-Level',
    text:
        'Customer success manager dedicated to helping clients achieve measurable value from products and services. Excels at onboarding, adoption planning, and proactive relationship management that improves retention.',
    tags: ['onboarding', 'adoption', 'retention', 'relationships'],
  ),
  _SummaryExample(
    id: 'support_specialist',
    title: 'Customer Support Specialist',
    category: 'Customer Success',
    level: 'Entry-Level',
    text:
        'Customer support specialist with a strong service mindset and experience resolving inquiries efficiently across chat, email, and phone. Recognized for empathy, product knowledge, and consistent issue follow-through.',
    tags: ['support', 'service', 'tickets', 'communication'],
  ),
  _SummaryExample(
    id: 'ux_designer',
    title: 'UX Designer',
    category: 'Design',
    level: 'Mid-Level',
    text:
        'UX designer who turns research insights into clear, user-centered experiences across digital products. Skilled in wireframing, prototyping, and usability improvements that reduce friction and increase engagement.',
    tags: ['research', 'wireframes', 'prototyping', 'usability'],
  ),
  _SummaryExample(
    id: 'graphic_designer',
    title: 'Graphic Designer',
    category: 'Design',
    level: 'Mid-Level',
    text:
        'Graphic designer with experience producing compelling visual assets for digital, print, and social channels. Balances creativity with brand discipline to deliver work that is both distinctive and effective.',
    tags: ['branding', 'visual', 'creative', 'print'],
  ),
  _SummaryExample(
    id: 'brand_designer',
    title: 'Brand Designer',
    category: 'Design',
    level: 'Senior',
    text:
        'Brand designer experienced in shaping visual identity systems that scale across products and campaigns. Builds cohesive creative direction that improves recognition, consistency, and audience trust.',
    tags: ['identity', 'creative direction', 'systems', 'brand'],
  ),
  _SummaryExample(
    id: 'finance_analyst',
    title: 'Financial Analyst',
    category: 'Finance',
    level: 'Mid-Level',
    text:
        'Financial analyst with experience in budgeting, forecasting, and performance reporting for business leaders. Combines analytical rigor with clear communication to support sound financial decision-making.',
    tags: ['forecasting', 'budgeting', 'excel', 'reporting'],
  ),
  _SummaryExample(
    id: 'accountant',
    title: 'Accountant',
    category: 'Finance',
    level: 'Mid-Level',
    text:
        'Detail-oriented accountant with strong experience managing reconciliations, month-end close, and financial record accuracy. Committed to compliance, consistency, and process improvement in day-to-day finance operations.',
    tags: ['reconciliation', 'close', 'compliance', 'accuracy'],
  ),
  _SummaryExample(
    id: 'controller',
    title: 'Financial Controller',
    category: 'Finance',
    level: 'Senior',
    text:
        'Financial controller with a record of strengthening controls, improving reporting cadence, and guiding finance teams through growth. Partners closely with leadership to support visibility, governance, and planning.',
    tags: ['controls', 'governance', 'leadership', 'planning'],
  ),
  _SummaryExample(
    id: 'hr_generalist',
    title: 'HR Generalist',
    category: 'Human Resources',
    level: 'Mid-Level',
    text:
        'HR generalist with broad experience across recruitment, employee relations, onboarding, and policy administration. Supports people operations with professionalism, discretion, and a strong service mindset.',
    tags: ['recruitment', 'onboarding', 'people ops', 'policy'],
  ),
  _SummaryExample(
    id: 'recruiter',
    title: 'Recruiter',
    category: 'Human Resources',
    level: 'Mid-Level',
    text:
        'Recruiter skilled in sourcing, screening, and closing talent across technical and business roles. Builds strong candidate pipelines and hiring partnerships that improve speed, quality, and candidate experience.',
    tags: ['talent', 'sourcing', 'hiring', 'interviews'],
  ),
  _SummaryExample(
    id: 'people_ops',
    title: 'People Operations Manager',
    category: 'Human Resources',
    level: 'Senior',
    text:
        'People operations manager focused on building scalable employee programs, clear processes, and positive workplace experiences. Brings structure to growth while supporting culture, compliance, and manager effectiveness.',
    tags: ['culture', 'programs', 'compliance', 'process'],
  ),
  _SummaryExample(
    id: 'operations_manager',
    title: 'Operations Manager',
    category: 'Operations',
    level: 'Senior',
    text:
        'Operations manager with experience optimizing workflows, improving service levels, and coordinating teams across fast-moving environments. Focused on efficiency, accountability, and measurable operational improvements.',
    tags: ['efficiency', 'operations', 'service', 'process'],
  ),
  _SummaryExample(
    id: 'supply_chain',
    title: 'Supply Chain Specialist',
    category: 'Operations',
    level: 'Mid-Level',
    text:
        'Supply chain specialist experienced in inventory planning, vendor coordination, and logistics execution. Helps maintain continuity and cost control through organized, data-informed operational support.',
    tags: ['inventory', 'logistics', 'vendors', 'planning'],
  ),
  _SummaryExample(
    id: 'business_analyst',
    title: 'Business Analyst',
    category: 'Business',
    level: 'Mid-Level',
    text:
        'Business analyst with experience gathering requirements, mapping processes, and translating business needs into practical solutions. Bridges stakeholders and delivery teams with strong analytical and communication skills.',
    tags: ['requirements', 'process', 'stakeholders', 'analysis'],
  ),
  _SummaryExample(
    id: 'consultant',
    title: 'Management Consultant',
    category: 'Business',
    level: 'Senior',
    text:
        'Management consultant with experience diagnosing organizational challenges and shaping high-impact recommendations. Combines structured problem solving with executive-ready communication and implementation focus.',
    tags: ['strategy', 'executive', 'problem solving', 'implementation'],
  ),
  _SummaryExample(
    id: 'teacher',
    title: 'Teacher',
    category: 'Education',
    level: 'Mid-Level',
    text:
        'Dedicated teacher with experience creating engaging lessons, supporting diverse learners, and maintaining strong classroom outcomes. Combines subject expertise with patience, structure, and student-centered communication.',
    tags: ['classroom', 'curriculum', 'instruction', 'students'],
  ),
  _SummaryExample(
    id: 'academic_advisor',
    title: 'Academic Advisor',
    category: 'Education',
    level: 'Mid-Level',
    text:
        'Academic advisor experienced in guiding students through planning, progression, and support resources. Builds trust through clear communication and a practical approach to academic and career goal setting.',
    tags: ['student support', 'advising', 'planning', 'communication'],
  ),
  _SummaryExample(
    id: 'nurse',
    title: 'Registered Nurse',
    category: 'Healthcare',
    level: 'Mid-Level',
    text:
        'Registered nurse with experience delivering compassionate patient care in fast-paced clinical environments. Skilled in assessment, care coordination, and maintaining high standards of safety and documentation.',
    tags: ['patient care', 'clinical', 'safety', 'documentation'],
  ),
  _SummaryExample(
    id: 'medical_assistant',
    title: 'Medical Assistant',
    category: 'Healthcare',
    level: 'Entry-Level',
    text:
        'Medical assistant with hands-on experience supporting clinical teams, managing patient intake, and maintaining organized records. Known for reliability, empathy, and efficient front-to-back office support.',
    tags: ['patients', 'records', 'clinical support', 'administration'],
  ),
  _SummaryExample(
    id: 'pharmacist',
    title: 'Pharmacist',
    category: 'Healthcare',
    level: 'Senior',
    text:
        'Pharmacist with experience ensuring safe medication dispensing, counseling patients, and supporting interdisciplinary care teams. Balances accuracy, compliance, and patient service in high-responsibility settings.',
    tags: ['medication', 'compliance', 'patient counseling', 'safety'],
  ),
  _SummaryExample(
    id: 'admin_assistant',
    title: 'Administrative Assistant',
    category: 'Administration',
    level: 'Mid-Level',
    text:
        'Administrative assistant who keeps teams organized through strong calendar management, documentation, and day-to-day coordination. Brings professionalism, attention to detail, and dependable follow-through.',
    tags: ['scheduling', 'coordination', 'documents', 'support'],
  ),
  _SummaryExample(
    id: 'executive_assistant',
    title: 'Executive Assistant',
    category: 'Administration',
    level: 'Senior',
    text:
        'Executive assistant experienced in supporting senior leaders with scheduling, communication, travel, and operational coordination. Anticipates needs, handles sensitive information, and keeps priorities moving smoothly.',
    tags: ['executive support', 'travel', 'communication', 'organization'],
  ),
  _SummaryExample(
    id: 'paralegal',
    title: 'Paralegal',
    category: 'Legal',
    level: 'Mid-Level',
    text:
        'Paralegal with experience preparing legal documents, conducting research, and organizing case materials with accuracy and discretion. Supports attorneys effectively through strong detail management and deadline control.',
    tags: ['legal research', 'documents', 'cases', 'deadlines'],
  ),
  _SummaryExample(
    id: 'warehouse_supervisor',
    title: 'Warehouse Supervisor',
    category: 'Logistics',
    level: 'Senior',
    text:
        'Warehouse supervisor with experience leading teams, maintaining safety standards, and improving daily throughput. Focused on accurate inventory handling, process discipline, and reliable order fulfillment.',
    tags: ['warehouse', 'inventory', 'safety', 'fulfillment'],
  ),
  _SummaryExample(
    id: 'qa_engineer',
    title: 'QA Engineer',
    category: 'Technology',
    level: 'Mid-Level',
    text:
        'QA engineer with experience designing test coverage, identifying regressions, and strengthening release confidence across web and mobile products. Advocates for quality through clear bug reporting and practical automation.',
    tags: ['testing', 'automation', 'quality', 'regression'],
  ),
];

class SummaryScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const SummaryScreen({super.key, required this.resumeId});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final _summaryController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isInitialized = false;
  String _activeCategory = 'All';
  final Set<String> _selectedExampleIds = <String>{};

  @override
  void dispose() {
    _summaryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = _kSummaryExamples
        .map((example) => example.category)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...categories];
  }

  List<_SummaryExample> get _filteredExamples {
    final query = _searchController.text.trim().toLowerCase();
    return _kSummaryExamples.where((example) {
      final matchesCategory =
          _activeCategory == 'All' || example.category == _activeCategory;
      if (!matchesCategory) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        example.title,
        example.category,
        example.level,
        example.text,
        ...example.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  List<_SummaryExample> get _selectedExamples => _kSummaryExamples
      .where((example) => _selectedExampleIds.contains(example.id))
      .toList(growable: false);

  String get _mergedSelectionPreview =>
      _mergeSummaryTexts(_selectedExamples.map((example) => example.text));

  String _mergeSummaryTexts(Iterable<String> summaries) {
    final seen = <String>{};
    final fragments = <String>[];

    for (final summary in summaries) {
      final sentences = summary
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((sentence) => sentence.trim())
          .where((sentence) => sentence.isNotEmpty);

      for (final sentence in sentences) {
        final normalized = sentence
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();
        if (normalized.isEmpty || !seen.add(normalized)) {
          continue;
        }
        fragments.add(sentence);
      }
    }

    return fragments.join(' ');
  }

  void _toggleExampleSelection(String exampleId) {
    setState(() {
      if (_selectedExampleIds.contains(exampleId)) {
        _selectedExampleIds.remove(exampleId);
      } else {
        _selectedExampleIds.add(exampleId);
      }
    });
  }

  void _replaceSummary(String text) {
    setState(() {
      _summaryController.text = text;
      _summaryController.selection = TextSelection.collapsed(
        offset: _summaryController.text.length,
      );
    });
  }

  void _appendSummary(String text) {
    final merged = _mergeSummaryTexts([
      _summaryController.text.trim(),
      text,
    ]);
    _replaceSummary(merged);
  }

  void _saveChanges() {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updatedResume = resume.copyWith(
        objective: _summaryController.text.trim(),
      );
      ref
          .read(currentResumeProvider(widget.resumeId).notifier)
          .updateResume(updatedResume);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Summary saved'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sync controller with provider data on first load OR when objective was externally updated
    // (e.g. after AI content enhancer applies a summary)
    final latestObjective = resume.objective ?? '';
    if (!_isInitialized) {
      _summaryController.text = latestObjective;
      _isInitialized = true;
    } else if (_summaryController.text.isEmpty && latestObjective.isNotEmpty) {
      // External update arrived (AI applied) — sync without overwriting user edits
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _summaryController.text = latestObjective);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Professional Summary'),
        actions: [
          TextButton(onPressed: _saveChanges, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your Professional Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 8),

          Text(
            'A compelling summary helps recruiters quickly understand your value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          TextFormField(
            controller: _summaryController,
            maxLines: 8,
            maxLength: 2500,
            decoration: InputDecoration(
              hintText:
                  'Press Enter between each achievement point\nE.g.:\n5+ years of experience in software development\nExpertise in Flutter and cloud technologies\nProven track record of delivering high-quality applications',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          // Helper Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle,
                    size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Each line will appear as a bullet point in your PDF resume',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          // Example Summaries
          Text(
            'Example Summaries',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          Text(
            'Search by role, filter by category, select multiple examples, and merge the strongest lines into one tailored summary.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ).animate().fadeIn(delay: 325.ms),

          const SizedBox(height: 12),

          TextFormField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search examples by role, industry, or keyword',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Iconsax.close_circle),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: _activeCategory == category,
                    onSelected: (_) {
                      setState(() {
                        _activeCategory = category;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ).animate().fadeIn(delay: 375.ms),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.task_square,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_filteredExamples.length} examples available • ${_selectedExampleIds.length} selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          if (_selectedExampleIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SelectionPreviewCard(
              preview: _mergedSelectionPreview,
              selectedCount: _selectedExampleIds.length,
              onReplace: () => _replaceSummary(_mergedSelectionPreview),
              onAppend: () => _appendSummary(_mergedSelectionPreview),
              onClear: () {
                setState(_selectedExampleIds.clear);
              },
            ).animate().fadeIn(delay: 425.ms).slideY(begin: 0.08, end: 0),
          ],

          const SizedBox(height: 16),

          if (_filteredExamples.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                'No example summaries match the current search or category filter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            )
          else
            ..._filteredExamples.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final example = entry.value;
                return _ExampleCard(
                  example: example,
                  isSelected: _selectedExampleIds.contains(example.id),
                  onToggleSelected: () => _toggleExampleSelection(example.id),
                  onUseNow: () => _replaceSummary(example.text),
                  onAppendNow: () => _appendSummary(example.text),
                )
                    .animate()
                    .fadeIn(delay: (440 + (index * 20)).ms)
                    .slideX(begin: 0.06, end: 0);
              },
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Summary'),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final _SummaryExample example;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onUseNow;
  final VoidCallback onAppendNow;

  const _ExampleCard({
    required this.example,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onUseNow,
    required this.onAppendNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(label: example.category),
                          _MetaChip(label: example.level),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected ? Iconsax.tick_circle : Iconsax.add_circle,
                  size: 20,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              example.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onToggleSelected,
                  icon: Icon(isSelected ? Iconsax.tick_circle : Iconsax.add),
                  label: Text(isSelected ? 'Selected' : 'Select'),
                ),
                TextButton.icon(
                  onPressed: onUseNow,
                  icon: const Icon(Iconsax.copy, size: 18),
                  label: const Text('Use Now'),
                ),
                TextButton.icon(
                  onPressed: onAppendNow,
                  icon: const Icon(Iconsax.add_square, size: 18),
                  label: const Text('Append'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionPreviewCard extends StatelessWidget {
  final String preview;
  final int selectedCount;
  final VoidCallback onReplace;
  final VoidCallback onAppend;
  final VoidCallback onClear;

  const _SelectionPreviewCard({
    required this.preview,
    required this.selectedCount,
    required this.onReplace,
    required this.onAppend,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.magic_star,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Merged preview from $selectedCount selected example${selectedCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onReplace,
                icon: const Icon(Iconsax.copy, size: 18),
                label: const Text('Replace Editor'),
              ),
              OutlinedButton.icon(
                onPressed: onAppend,
                icon: const Icon(Iconsax.add_square, size: 18),
                label: const Text('Append to Editor'),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear Selection'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
