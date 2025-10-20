import 'package:flutter/material.dart';

class AITextEnhancementService {
  /// Generate enhanced professional sentences from raw input
  static List<String> generateEnhancedSuggestions(String rawInput) {
    if (rawInput.trim().isEmpty) {
      return [];
    }

    // Extract key technologies and skills from the input
    final input = rawInput.toLowerCase();
    final suggestions = <String>[];

    // Template-based enhancement with keyword extraction
    final keywords = _extractKeywords(input);

    if (keywords.isEmpty) {
      return _generateGenericSuggestions(rawInput);
    }

    // Generate contextual suggestions based on keywords
    suggestions.addAll(_generateTechnicalSuggestions(keywords, input));
    suggestions.addAll(_generateActionBasedSuggestions(keywords, input));
    suggestions.addAll(_generateAchievementSuggestions(keywords, input));

    // Ensure we return 3-5 suggestions
    return suggestions.take(5).toList();
  }

  static List<String> _extractKeywords(String input) {
    final keywords = <String>[];

    // Common technical keywords
    final techKeywords = [
      'java',
      'python',
      'javascript',
      'typescript',
      'c++',
      'c#',
      'ruby',
      'go',
      'rust',
      'react',
      'angular',
      'vue',
      'flutter',
      'django',
      'spring',
      'node',
      'express',
      'sql',
      'mongodb',
      'postgresql',
      'mysql',
      'redis',
      'elasticsearch',
      'aws',
      'azure',
      'gcp',
      'docker',
      'kubernetes',
      'jenkins',
      'git',
      'selenium',
      'cypress',
      'junit',
      'pytest',
      'testng',
      'automation',
      'api',
      'rest',
      'graphql',
      'microservices',
      'agile',
      'scrum',
      'machine learning',
      'ai',
      'data science',
      'analytics',
      'tableau',
      'power bi',
      'android',
      'ios',
      'swift',
      'kotlin',
      'xamarin',
    ];

    for (final keyword in techKeywords) {
      if (input.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    return keywords;
  }

  static List<String> _generateTechnicalSuggestions(
    List<String> keywords,
    String input,
  ) {
    final suggestions = <String>[];

    final techStack = keywords.take(3).join(', ');

    if (input.contains('experience') || input.contains('worked')) {
      suggestions.add(
        'Proficient in $techStack with hands-on experience in developing scalable applications.',
      );
      suggestions.add(
        'Demonstrated expertise in $techStack through successful project deliveries.',
      );
    }

    if (input.contains('automation') || input.contains('testing')) {
      suggestions.add(
        'Skilled in test automation using ${keywords.first} to ensure quality and reliability.',
      );
      suggestions.add(
        'Extensive experience in designing and implementing automated testing frameworks with $techStack.',
      );
    }

    if (input.contains('development') || input.contains('developed')) {
      suggestions.add(
        'Successfully developed and maintained applications using $techStack, improving performance and user experience.',
      );
    }

    return suggestions;
  }

  static List<String> _generateActionBasedSuggestions(
    List<String> keywords,
    String input,
  ) {
    final suggestions = <String>[];
    final techStack = keywords.take(3).join(', ');

    // Action verbs mapping
    if (input.contains('design') || input.contains('architect')) {
      suggestions.add(
        'Designed and architected robust solutions using $techStack, ensuring scalability and maintainability.',
      );
    }

    if (input.contains('optimize') || input.contains('improve')) {
      suggestions.add(
        'Optimized system performance using $techStack, reducing response time by implementing best practices.',
      );
    }

    if (input.contains('lead') || input.contains('manage')) {
      suggestions.add(
        'Led development teams in implementing solutions with $techStack, delivering projects on time.',
      );
    }

    if (input.contains('integrate') || input.contains('implement')) {
      suggestions.add(
        'Integrated and implemented ${keywords.first}-based solutions to enhance functionality and user experience.',
      );
    }

    return suggestions;
  }

  static List<String> _generateAchievementSuggestions(
    List<String> keywords,
    String input,
  ) {
    final suggestions = <String>[];
    final mainTech = keywords.isNotEmpty ? keywords.first : 'technology';

    suggestions.add(
      'Achieved significant improvements in code quality and system reliability through effective use of $mainTech.',
    );

    suggestions.add(
      'Contributed to team success by leveraging ${keywords.take(2).join(' and ')} expertise in critical projects.',
    );

    return suggestions;
  }

  static List<String> _generateGenericSuggestions(String rawInput) {
    return [
      'Demonstrated strong technical skills and problem-solving abilities in delivering high-quality solutions.',
      'Contributed effectively to team projects, ensuring timely delivery and meeting quality standards.',
      'Applied best practices and industry standards to develop reliable and maintainable code.',
      'Collaborated with cross-functional teams to achieve project objectives and business goals.',
      'Continuously improved technical expertise through hands-on experience and self-learning.',
    ];
  }

  /// Show AI enhancement dialog with multiple generations
  static void showEnhancementDialog(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onUpdate,
  ) {
    final currentText = controller.text;

    if (currentText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text first to generate suggestions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AIEnhancementDialog(
        initialText: currentText,
        controller: controller,
        onUpdate: onUpdate,
      ),
    );
  }
}

/// Stateful dialog widget for AI enhancements with regeneration
class _AIEnhancementDialog extends StatefulWidget {
  final String initialText;
  final TextEditingController controller;
  final VoidCallback onUpdate;

  const _AIEnhancementDialog({
    required this.initialText,
    required this.controller,
    required this.onUpdate,
  });

  @override
  State<_AIEnhancementDialog> createState() => _AIEnhancementDialogState();
}

class _AIEnhancementDialogState extends State<_AIEnhancementDialog> {
  late List<String> suggestions;
  int generationCount = 0;
  final int maxGenerations = 4;
  final List<String> selectedSuggestions = [];

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  void _generateSuggestions() {
    setState(() {
      suggestions = AITextEnhancementService.generateEnhancedSuggestions(
        widget.initialText,
      );
      generationCount++;
    });
  }

  void _addToDescription(String suggestion) {
    setState(() {
      if (!selectedSuggestions.contains(suggestion)) {
        selectedSuggestions.add(suggestion);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to selection! (${selectedSuggestions.length} selected)',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyAllSelected() {
    if (selectedSuggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one suggestion'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Combine all selected suggestions - append to existing text if present
    final existingText = widget.controller.text.trim();
    final newSuggestions = selectedSuggestions.map((s) => '• $s').join('\n');

    if (existingText.isEmpty) {
      widget.controller.text = newSuggestions;
    } else {
      // Append to existing text with proper line break
      widget.controller.text = '$existingText\n$newSuggestions';
    }

    widget.onUpdate();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied ${selectedSuggestions.length} suggestion(s) to description!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRegenerate = generationCount < maxGenerations;
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('AI Suggestions', style: TextStyle(fontSize: 16)),
          ),
          Text(
            '$generationCount/$maxGenerations',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.6, // Constrain height to 60% of screen
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select suggestions to add (${selectedSuggestions.length} selected):',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (canRegenerate)
                  TextButton.icon(
                    onPressed: _generateSuggestions,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Generate'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
              ],
            ),
            if (!canRegenerate)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Maximum generations reached',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: suggestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final suggestion = entry.value;
                    final isSelected = selectedSuggestions.contains(suggestion);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _addToDescription(suggestion),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple.withOpacity(0.1)
                                : Colors.grey.shade50,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.deepPurple.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (selectedSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedSuggestions.length} suggestion(s) selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedSuggestions.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: selectedSuggestions.isEmpty ? null : _applyAllSelected,
          icon: const Icon(Icons.check, size: 18),
          label: Text(
            'Apply ${selectedSuggestions.isNotEmpty ? "(${selectedSuggestions.length})" : ""}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
