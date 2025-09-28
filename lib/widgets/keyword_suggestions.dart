import 'package:flutter/material.dart';

class KeywordSuggestionsPanel extends StatefulWidget {
  final String jobTitle;
  final String currentSkills;
  final void Function(String) onAddKeyword;

  const KeywordSuggestionsPanel({
    super.key,
    required this.jobTitle,
    required this.currentSkills,
    required this.onAddKeyword,
  });

  @override
  State<KeywordSuggestionsPanel> createState() =>
      _KeywordSuggestionsPanelState();
}

class _KeywordSuggestionsPanelState extends State<KeywordSuggestionsPanel> {
  List<String> _suggestions = [];
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(covariant KeywordSuggestionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobTitle != widget.jobTitle ||
        oldWidget.currentSkills != widget.currentSkills) {
      _loadSuggestions();
    }
  }

  void _loadSuggestions() {
    // Basic, offline keyword bank by role. This is intentionally simple.
    final Map<String, List<String>> bank = {
      'software': [
        'Agile',
        'REST',
        'CI/CD',
        'Flutter',
        'Dart',
        'Node.js',
        'SQL',
        'Unit Testing',
      ],
      'developer': ['Git', 'APIs', 'Cloud', 'TDD', 'Microservices', 'Docker'],
      'designer': ['Figma', 'UI', 'UX', 'Wireframing', 'Prototyping'],
      'manager': ['Stakeholders', 'Roadmap', 'KPI', 'Scrum', 'Budgeting'],
      'data': ['Python', 'Pandas', 'ETL', 'SQL', 'Dashboards'],
    };

    final role = widget.jobTitle.toLowerCase();
    final Set<String> current = widget.currentSkills
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final Set<String> base = {};
    bank.forEach((key, list) {
      if (role.contains(key)) base.addAll(list);
    });

    // default generic set if nothing matched
    if (base.isEmpty) {
      base.addAll([
        'Communication',
        'Teamwork',
        'Problem Solving',
        'Time Management',
      ]);
    }

    // Remove already present keywords
    base.removeWhere((kw) => current.contains(kw));

    setState(() {
      _suggestions = base.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Keyword Suggestions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions
                  .map(
                    (kw) => ActionChip(
                      label: Text(kw),
                      onPressed: () => widget.onAddKeyword(kw),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a keyword to add it into your Skills.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
