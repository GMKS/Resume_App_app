import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ai_resume_service.dart';

// Simple data classes for UI components
class ContentFeedback {
  final int score;
  final List<String> suggestions;

  ContentFeedback({required this.score, required this.suggestions});

  factory ContentFeedback.fromMap(Map<String, dynamic> map) {
    return ContentFeedback(
      score: map['score'] ?? 0,
      suggestions: List<String>.from(map['suggestions'] ?? []),
    );
  }
}

class ATSAnalysis {
  final int score;
  final List<String> foundKeywords;
  final List<String> missingKeywords;
  final List<String> recommendations;

  ATSAnalysis({
    required this.score,
    required this.foundKeywords,
    required this.missingKeywords,
    required this.recommendations,
  });

  factory ATSAnalysis.fromMap(Map<String, dynamic> map) {
    return ATSAnalysis(
      score: map['score'] ?? 0,
      foundKeywords: List<String>.from(map['foundKeywords'] ?? []),
      missingKeywords: List<String>.from(map['missingKeywords'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }
}

/// AI-powered input field with real-time suggestions and feedback
class AIEnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String section; // 'summary', 'experience', 'skills', etc.
  final int? maxLines;
  final Function(String)? onChanged;
  final bool enableAI;

  const AIEnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.section,
    this.maxLines,
    this.onChanged,
    this.enableAI = true,
  });

  @override
  State<AIEnhancedTextField> createState() => _AIEnhancedTextFieldState();
}

class _AIEnhancedTextFieldState extends State<AIEnhancedTextField> {
  ContentFeedback? _feedback;
  bool _isAnalyzing = false;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.enableAI && widget.controller.text.isNotEmpty) {
      _debounceAnalysis();
    }
    widget.onChanged?.call(widget.controller.text);
  }

  Timer? _debounceTimer;
  void _debounceAnalysis() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _analyzeContent);
  }

  Future<void> _analyzeContent() async {
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final feedback = await AIResumeService.getFeedback(
        content: widget.controller.text,
        section: widget.section,
      );

      if (mounted) {
        setState(() {
          _feedback = ContentFeedback.fromMap(feedback);
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (widget.enableAI) ...[
              const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
              const SizedBox(width: 4),
              const Text(
                'AI Enhanced',
                style: TextStyle(fontSize: 12, color: Colors.purple),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_isAnalyzing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text('Analyzing content...'),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFeedback = !_showFeedback;
                  });
                },
                icon: Icon(
                  _showFeedback ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
        ],
        if (_feedback != null && _showFeedback) ...[
          const SizedBox(height: 8),
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
                    const Icon(Icons.analytics, size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${_feedback!.score}/10',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...(_feedback!.suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: Text(suggestion)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// AI Bullet Point Generator
class AIBulletPointGenerator extends StatefulWidget {
  final String jobTitle;
  final String company;
  final String description;
  final Function(List<String>) onGenerated;

  const AIBulletPointGenerator({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.description,
    required this.onGenerated,
  });

  @override
  State<AIBulletPointGenerator> createState() => _AIBulletPointGeneratorState();
}

class _AIBulletPointGeneratorState extends State<AIBulletPointGenerator> {
  bool _isGenerating = false;
  List<String> _generatedPoints = [];

  Future<void> _generateBulletPoints() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final points = await AIResumeService.generateBulletPoints(
        jobTitle: widget.jobTitle,
        company: widget.company,
        description: widget.description,
      );

      setState(() {
        _generatedPoints = points;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'AI Bullet Point Generator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateBulletPoints,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(_isGenerating ? 'Generating...' : 'Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (_generatedPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Generated Bullet Points:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...(_generatedPoints.asMap().entries.map((entry) {
              final point = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(point, style: const TextStyle(fontSize: 13)),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.onGenerated([point]);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: 'Add this point',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onGenerated(_generatedPoints);
                    },
                    icon: const Icon(Icons.add_circle, size: 14),
                    label: const Text('Use All Points'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _generateBulletPoints,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Generate More'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ATS optimization widget
class ATSOptimizationPanel extends StatefulWidget {
  final String content;
  final String jobDescription;

  const ATSOptimizationPanel({
    super.key,
    required this.content,
    required this.jobDescription,
  });

  @override
  State<ATSOptimizationPanel> createState() => _ATSOptimizationPanelState();
}

class _ATSOptimizationPanelState extends State<ATSOptimizationPanel> {
  bool _isAnalyzing = false;
  ATSAnalysis? _analysis;

  Future<void> _analyzeATS() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await AIResumeService.optimizeForATS(
        content: widget.content,
        jobDescription: widget.jobDescription,
      );

      setState(() {
        _analysis = ATSAnalysis.fromMap(analysis);
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.verified_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'ATS Optimization',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeATS,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics, size: 14),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze ATS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (_analysis != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'ATS Score: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_analysis!.score}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _analysis!.score >= 80
                              ? Colors.green
                              : _analysis!.score >= 60
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keywords Found:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 4,
                    children: _analysis!.foundKeywords.map((keyword) {
                      return Chip(
                        label: Text(
                          keyword,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.green.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Missing Keywords:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 4,
                    children: _analysis!.missingKeywords.map((keyword) {
                      return Chip(
                        label: Text(
                          keyword,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.red.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recommendations:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ..._analysis!.recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// AI Summary Generator
class AISummaryGenerator extends StatefulWidget {
  final String name;
  final String targetRole;
  final List<String> skills;
  final List<String> experience;
  final Function(String) onGenerated;

  const AISummaryGenerator({
    super.key,
    required this.name,
    required this.targetRole,
    required this.skills,
    required this.experience,
    required this.onGenerated,
  });

  @override
  State<AISummaryGenerator> createState() => _AISummaryGeneratorState();
}

class _AISummaryGeneratorState extends State<AISummaryGenerator> {
  bool _isGenerating = false;
  String? _generatedSummary;

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final summary = await AIResumeService.generateSummary(
        name: widget.name,
        targetRole: widget.targetRole,
        skills: widget.skills,
        experience: widget.experience,
      );

      setState(() {
        _generatedSummary = summary;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'AI Summary Generator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateSummary,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(_isGenerating ? 'Generating...' : 'Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (_generatedSummary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generated Summary:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedSummary!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onGenerated(_generatedSummary!);
                          },
                          icon: const Icon(Icons.add_circle, size: 14),
                          label: const Text('Use This Summary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _generateSummary,
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('Generate New'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
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
    );
  }
}
