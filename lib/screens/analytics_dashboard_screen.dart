import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_widgets.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final SavedResume resume;

  const AnalyticsDashboardScreen({super.key, required this.resume});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      _analyticsData = await _analyticsService.analyzeResume(widget.resume);
    } catch (e) {
      debugPrint('Analytics loading error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Optimization'),
            Tab(icon: Icon(Icons.timeline), text: 'Tracking'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOptimizationTab(),
                _buildTrackingTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template-specific tips card
          _buildTemplateTipsCard(),
          const SizedBox(height: 20),

          // Smart Widgets Grid
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid based on screen width
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth < 400) {
                crossAxisCount = 1;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  TemplateFitScoreWidget(
                    score: _analyticsData['templateFitScore'] ?? 0.0,
                    template: widget.resume.template,
                  ),
                  ATSRiskAlertsWidget(
                    riskLevel: _analyticsData['atsRiskLevel'] ?? 'Low',
                    issues: _analyticsData['atsIssues'] ?? [],
                  ),
                  ImpactMeterWidget(
                    score: _analyticsData['impactScore'] ?? 0.0,
                    metrics: _analyticsData['metricsCount'] ?? 0,
                    actionVerbs: _analyticsData['actionVerbsCount'] ?? 0,
                  ),
                  ToneAnalyzerWidget(
                    tone: _analyticsData['tone'] ?? 'Professional',
                    consistency: _analyticsData['toneConsistency'] ?? 0.0,
                    template: widget.resume.template,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Optimization',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Keyword Heatmap
          KeywordHeatmapWidget(
            keywords: _analyticsData['keywords'] ?? {},
            density: _analyticsData['keywordDensity'] ?? {},
          ),

          const SizedBox(height: 20),

          // Job Match Predictor
          JobMatchPredictorWidget(
            matchScore: _analyticsData['jobMatchScore'] ?? 0.0,
            suggestions: _analyticsData['jobMatchSuggestions'] ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Version Tracking',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          VersionTrackerWidget(
            versions: _analyticsData['versions'] ?? [],
            currentScore: _analyticsData['currentScore'] ?? 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTipsCard() {
    final template = widget.resume.template.toLowerCase();
    String tips = '';
    Color cardColor = Colors.blue.shade50;
    IconData icon = Icons.lightbulb;

    switch (template) {
      case 'classic':
      case 'professional':
        tips =
            'Focus on ATS optimization, quantifiable metrics, and clean formatting. Use action verbs and avoid graphics.';
        cardColor = Colors.blue.shade50;
        icon = Icons.business_center;
        break;
      case 'modern':
      case 'minimal':
        tips =
            'Emphasize layout balance, keyword density, and strategic whitespace. Keep design elements subtle but impactful.';
        cardColor = Colors.green.shade50;
        icon = Icons.design_services;
        break;
      case 'creative':
        tips =
            'Prioritize storytelling, tone consistency, and visual impact. Show personality while maintaining professionalism.';
        cardColor = Colors.purple.shade50;
        icon = Icons.palette;
        break;
      case 'one page':
        tips =
            'Optimize for brevity, keyword punch, and section prioritization. Every word must earn its place.';
        cardColor = Colors.orange.shade50;
        icon = Icons.article;
        break;
      default:
        tips =
            'Follow general best practices: clear structure, relevant keywords, and quantifiable achievements.';
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.resume.template} Template Tips',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tips,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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
