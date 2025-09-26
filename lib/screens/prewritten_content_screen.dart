import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prewritten_content_service.dart';

class PrewrittenContentScreen extends StatefulWidget {
  final String? sectionType; // 'summary', 'experience', 'skills', etc.
  final String? currentContent;
  final Function(String)? onContentSelected;

  const PrewrittenContentScreen({
    super.key,
    this.sectionType,
    this.currentContent,
    this.onContentSelected,
  });

  @override
  State<PrewrittenContentScreen> createState() =>
      _PrewrittenContentScreenState();
}

class _PrewrittenContentScreenState extends State<PrewrittenContentScreen>
    with SingleTickerProviderStateMixin {
  final _prewrittenService = PrewrittenContentService();
  late TabController _tabController;

  String _selectedIndustry = 'Technology';
  String _selectedExperienceLevel = 'Mid-Level';

  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Marketing',
    'Education',
    'Retail',
    'Manufacturing',
    'Legal',
  ];

  final List<String> _experienceLevels = [
    'Entry-Level',
    'Mid-Level',
    'Senior-Level',
    'Executive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: _getInitialTabIndex(),
    );
  }

  int _getInitialTabIndex() {
    switch (widget.sectionType) {
      case 'experience':
        return 1;
      case 'skills':
        return 2;
      case 'achievements':
        return 3;
      case 'keywords':
        return 4;
      case 'guidance':
        return 5;
      default:
        return 0; // Summary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Assistant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Experience'),
            Tab(text: 'Skills'),
            Tab(text: 'Achievements'),
            Tab(text: 'Keywords'),
            Tab(text: 'Guidance'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Industry and Experience Level Selectors
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedIndustry,
                    decoration: const InputDecoration(
                      labelText: 'Industry',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _industries.map((industry) {
                      return DropdownMenuItem(
                        value: industry,
                        child: Text(industry),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIndustry = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedExperienceLevel,
                    decoration: const InputDecoration(
                      labelText: 'Experience Level',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _experienceLevels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExperienceLevel = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildExperienceTab(),
                _buildSkillsTab(),
                _buildAchievementsTab(),
                _buildKeywordsTab(),
                _buildGuidanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final summaries = _prewrittenService.getSummaryTemplates(
      _selectedIndustry,
      _selectedExperienceLevel,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return _buildContentCard(
          title: 'Summary ${index + 1}',
          content: summary,
          onUse: () => _useContent(summary),
          onCopy: () => _copyContent(summary),
        );
      },
    );
  }

  Widget _buildExperienceTab() {
    final actionVerbs = _prewrittenService.getActionVerbs(_selectedIndustry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action Verbs for Experience Descriptions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actionVerbs.map((verb) {
              return ActionChip(
                label: Text(verb),
                onPressed: () => _copyContent(verb),
                backgroundColor: Colors.indigo.shade50,
                labelStyle: const TextStyle(color: Colors.indigo),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Experience Description Templates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._buildExperienceTemplates(),
        ],
      ),
    );
  }

  List<Widget> _buildExperienceTemplates() {
    final templates = [
      "• Achieved [X%] improvement in [metric] by implementing [solution/strategy]",
      "• Led a team of [X] professionals to deliver [project/outcome] resulting in [impact]",
      "• Developed and executed [strategy/process] that increased [metric] by [X%]",
      "• Collaborated with [stakeholders] to [action] resulting in [quantified outcome]",
      "• Managed [budget/resources] of [amount] while maintaining [quality/efficiency metric]",
    ];

    return templates.map((template) {
      return _buildContentCard(
        title: 'Template',
        content: template,
        onUse: () => _useContent(template),
        onCopy: () => _copyContent(template),
      );
    }).toList();
  }

  Widget _buildSkillsTab() {
    final skills = _prewrittenService.getSkillsDatabase(_selectedIndustry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: skills.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((skill) {
                      return ActionChip(
                        label: Text(skill),
                        onPressed: () => _copyContent(skill),
                        backgroundColor: Colors.indigo.shade50,
                        labelStyle: const TextStyle(color: Colors.indigo),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = _prewrittenService.getAchievementTemplates(
      _selectedIndustry,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildContentCard(
          title: 'Achievement ${index + 1}',
          content: achievement,
          onUse: () => _useContent(achievement),
          onCopy: () => _copyContent(achievement),
        );
      },
    );
  }

  Widget _buildKeywordsTab() {
    final keywords = _prewrittenService.getATSKeywords(_selectedIndustry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATS-Optimized Keywords',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Include these keywords in your resume to improve ATS compatibility',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((keyword) {
              return ActionChip(
                label: Text(keyword),
                onPressed: () => _copyContent(keyword),
                backgroundColor: Colors.green.shade50,
                labelStyle: const TextStyle(color: Colors.green),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuidanceCard('Resume Writing Best Practices', [
            '• Keep it concise (1-2 pages maximum)',
            '• Use bullet points for easy scanning',
            '• Quantify achievements with numbers',
            '• Tailor content to each job application',
            '• Use action verbs to start bullet points',
            '• Include relevant keywords from job posting',
          ]),
          const SizedBox(height: 16),
          _buildGuidanceCard('Common Mistakes to Avoid', [
            '• Generic objective statements',
            '• Listing job duties instead of achievements',
            '• Poor formatting and inconsistent styling',
            '• Typos and grammatical errors',
            '• Including irrelevant information',
            '• Using unprofessional email addresses',
          ]),
          const SizedBox(height: 16),
          _buildGuidanceCard('ATS Optimization Tips', [
            '• Use standard section headings',
            '• Include keywords from job description',
            '• Use simple, clean formatting',
            '• Save as both PDF and Word formats',
            '• Avoid graphics and complex layouts',
            '• Test with ATS scanning tools',
          ]),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String content,
    required VoidCallback onUse,
    required VoidCallback onCopy,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: onCopy,
                      tooltip: 'Copy',
                    ),
                    if (widget.onContentSelected != null)
                      IconButton(
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: onUse,
                        tooltip: 'Use',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useContent(String content) {
    widget.onContentSelected?.call(content);
    Navigator.pop(context);
  }

  void _copyContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Content Assistant Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This tool provides:'),
            SizedBox(height: 8),
            Text('• Pre-written content templates'),
            Text('• Industry-specific examples'),
            Text('• ATS-optimized keywords'),
            Text('• Professional writing guidance'),
            Text('• Action verbs and phrases'),
            SizedBox(height: 12),
            Text(
              'Tip: Customize the templates with your specific experience and achievements.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
