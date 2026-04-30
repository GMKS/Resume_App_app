import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _queryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedType = 'All';

  static const _jobTypes = ['All', 'Full-time', 'Part-time', 'Remote', 'Contract', 'Internship'];

  static const _platforms = [
    {
      'name': 'LinkedIn',
      'icon': '💼',
      'color': 0xFF0A66C2,
      'description': 'Professional network with millions of jobs',
      'baseUrl': 'https://www.linkedin.com/jobs/search/?keywords=',
    },
    {
      'name': 'Indeed',
      'icon': '🔍',
      'color': 0xFF003A9B,
      'description': 'Largest global job aggregator',
      'baseUrl': 'https://www.indeed.com/jobs?q=',
    },
    {
      'name': 'Glassdoor',
      'icon': '🏢',
      'color': 0xFF0CAA41,
      'description': 'Jobs + company reviews & salary insights',
      'baseUrl': 'https://www.glassdoor.com/Job/jobs.htm?sc.keyword=',
    },
    {
      'name': 'Google Jobs',
      'icon': '🌐',
      'color': 0xFF4285F4,
      'description': 'Aggregated results from across the web',
      'baseUrl': 'https://www.google.com/search?q=',
    },
    {
      'name': 'Wellfound',
      'icon': '🚀',
      'color': 0xFFFF6154,
      'description': 'Startup & tech jobs (formerly AngelList)',
      'baseUrl': 'https://wellfound.com/jobs?q=',
    },
    {
      'name': 'RemoteOK',
      'icon': '🌍',
      'color': 0xFF00C795,
      'description': 'Fully remote jobs worldwide',
      'baseUrl': 'https://remoteok.com/remote-',
    },
  ];

  static const _trendingSearches = [
    'Software Engineer',
    'Data Scientist',
    'Product Manager',
    'UX Designer',
    'Marketing Manager',
    'Financial Analyst',
    'DevOps Engineer',
    'Sales Executive',
  ];

  Future<void> _openJobSite(Map<String, Object> platform) async {
    final query = _queryCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final type = _selectedType == 'All' ? '' : _selectedType;

    String searchQuery = query.isEmpty ? 'jobs' : query;
    if (location.isNotEmpty) searchQuery += ' $location';
    if (type.isNotEmpty) searchQuery += ' $type';

    final baseUrl = platform['baseUrl'] as String;
    final encodedQuery = Uri.encodeComponent(searchQuery);
    final url = Uri.parse('$baseUrl$encodedQuery');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Search'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.search_normal_1,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find Your Dream Job',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          'Search across LinkedIn, Indeed, Glassdoor and more.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 20),

            // Search fields
            TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(
                labelText: 'Job title or keyword',
                hintText: 'e.g. Software Engineer',
                prefixIcon: Icon(Iconsax.search_normal, size: 20),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                hintText: 'e.g. New York, Remote',
                prefixIcon: Icon(Iconsax.location, size: 20),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            // Job type chips
            Text('Job Type',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary)).animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _jobTypes.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                      color: selected ? AppColors.primary : null,
                      fontWeight: selected ? FontWeight.w600 : null),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Platform cards
            Text('Search on Platform',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 12),

            ..._platforms.asMap().entries.map((entry) {
              final i = entry.key;
              final p = Map<String, Object>.from(entry.value);
              final color = Color(p['color'] as int);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(p['icon'] as String,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  title: Text(p['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p['description'] as String,
                      style: const TextStyle(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () => _openJobSite(p),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Search',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ).animate().fadeIn(delay: ((i * 60) + 300).ms).slideX(begin: -0.05, end: 0);
            }),

            const SizedBox(height: 24),

            // Trending searches
            Text('Trending Searches',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingSearches.map((s) {
                return ActionChip(
                  avatar: const Icon(Iconsax.trend_up, size: 14),
                  label: Text(s),
                  onPressed: () {
                    _queryCtrl.text = s;
                    setState(() {});
                  },
                );
              }).toList(),
            ).animate().fadeIn(delay: 650.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
