import 'package:flutter/material.dart';

/// Template Fit Score Widget - Rates how well content matches template strengths
class TemplateFitScoreWidget extends StatelessWidget {
  final double score;
  final String template;

  const TemplateFitScoreWidget({
    super.key,
    required this.score,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 28, color: color),
            const SizedBox(height: 6),
            const Text(
              'Template Fit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              template,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// ATS Risk Alerts Widget - Flags risky formatting or missing metadata
class ATSRiskAlertsWidget extends StatelessWidget {
  final String riskLevel;
  final List<String> issues;

  const ATSRiskAlertsWidget({
    super.key,
    required this.riskLevel,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor(riskLevel);
    final icon = _getRiskIcon(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            const Text(
              'ATS Risk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              riskLevel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${issues.length} issues',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

/// Impact Meter Widget - Measures metrics, achievements, and action verbs
class ImpactMeterWidget extends StatelessWidget {
  final double score;
  final int metrics;
  final int actionVerbs;

  const ImpactMeterWidget({
    super.key,
    required this.score,
    required this.metrics,
    required this.actionVerbs,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 32, color: color),
            const SizedBox(height: 8),
            const Text(
              'Impact Score',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$metrics metrics, $actionVerbs verbs',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Tone Analyzer Widget - Rates tone consistency and professionalism
class ToneAnalyzerWidget extends StatelessWidget {
  final String tone;
  final double consistency;
  final String template;

  const ToneAnalyzerWidget({
    super.key,
    required this.tone,
    required this.consistency,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getToneColor(tone);
    final isGoodMatch = _isGoodToneForTemplate(tone, template);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 32,
              color: isGoodMatch ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tone Analysis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              tone,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${consistency.toInt()}% consistent',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getToneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'professional':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'casual':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isGoodToneForTemplate(String tone, String template) {
    final templateLower = template.toLowerCase();
    final toneLower = tone.toLowerCase();

    if ((templateLower.contains('creative') && toneLower == 'creative') ||
        (templateLower.contains('professional') &&
            toneLower == 'professional') ||
        (templateLower.contains('classic') && toneLower == 'professional')) {
      return true;
    }
    return false;
  }
}

/// Keyword Heatmap Widget - Visual map showing keyword density
class KeywordHeatmapWidget extends StatelessWidget {
  final Map<String, int> keywords;
  final Map<String, double> density;

  const KeywordHeatmapWidget({
    super.key,
    required this.keywords,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Keyword Heatmap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedKeywords.isEmpty)
              const Text('No keywords detected')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedKeywords.take(15).map((entry) {
                  final intensity = (entry.value / sortedKeywords.first.value)
                      .clamp(0.0, 1.0);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(
                        intensity * 0.7 + 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.key} (${entry.value})',
                      style: TextStyle(
                        color: intensity > 0.5 ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Text(
              'Section Density',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...density.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (entry.value / 20).clamp(
                          0.0,
                          1.0,
                        ), // Max 20% density
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 10),
                    ),
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

/// Job Match Predictor Widget - Estimates job alignment
class JobMatchPredictorWidget extends StatelessWidget {
  final double matchScore;
  final List<String> suggestions;

  const JobMatchPredictorWidget({
    super.key,
    required this.matchScore,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getMatchColor(matchScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: color),
                const SizedBox(width: 8),
                const Text(
                  'Job Match Predictor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    value: matchScore / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${matchScore.toInt()}% Match',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (suggestions.isNotEmpty) ...[
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...suggestions
                  .take(3)
                  .map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Version Tracker Widget - Shows score changes over time
class VersionTrackerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> versions;
  final double currentScore;

  const VersionTrackerWidget({
    super.key,
    required this.versions,
    required this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Version Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (versions.isEmpty)
              const Text('No version history available')
            else ...[
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: ScoreChartPainter(versions),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Score',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${currentScore.toInt()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Versions',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${versions.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the score chart
class ScoreChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> versions;

  ScoreChartPainter(this.versions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    if (versions.length < 2) return;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < versions.length; i++) {
      final x = (i / (versions.length - 1)) * size.width;
      final score = versions[i]['score'] as double? ?? 0.0;
      final y = size.height - (score / 100) * size.height;

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
