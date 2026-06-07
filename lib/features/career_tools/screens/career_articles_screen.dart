import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class CareerArticlesScreen extends StatefulWidget {
  const CareerArticlesScreen({super.key});

  @override
  State<CareerArticlesScreen> createState() => _CareerArticlesScreenState();
}

class _CareerArticlesScreenState extends State<CareerArticlesScreen> {
  String _selectedCategory = 'All';
  bool _isValidatingArticles = true;
  final Set<String> _validArticleUrls = <String>{};

  static const Map<String, String> _articleRequestHeaders = <String, String>{
    'User-Agent': 'Mozilla/5.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  };

  static const _categories = [
    'All',
    'Resume Tips',
    'Interview',
    'Career Growth',
    'Job Search',
  ];

  static const _articles = [
    {
      'title': 'Cover Letter Examples for Every Type of Job Seeker',
      'category': 'Resume Tips',
      'readTime': '7 min read',
      'emoji': '✉️',
      'description':
          'Use practical cover letter examples and structure tips to make your application stronger.',
      'url':
          'https://www.themuse.com/advice/cover-letter-examples-every-type-job-seeker',
    },
    {
      'title': '5 Career Pivots That Are More Achievable Than You Think',
      'category': 'Career Growth',
      'readTime': '8 min read',
      'emoji': '🔄',
      'description':
          'Changing careers doesn\'t have to mean starting over. Discover transferable skills you already have.',
      'url': 'https://hbr.org/topic/subject/career-transitions',
    },
    {
      'title': 'Interview Questions and Answers You Should Know',
      'category': 'Interview',
      'readTime': '9 min read',
      'emoji': '💬',
      'description':
          'Review common interview questions, strong answer patterns, and practical preparation advice.',
      'url': 'https://www.themuse.com/advice/interview-questions-and-answers',
    },
    {
      'title': 'STAR Interview Method: How to Answer with Clear Examples',
      'category': 'Interview',
      'readTime': '6 min read',
      'emoji': '⭐',
      'description':
          'Use the STAR framework to keep behavioral answers specific, organized, and persuasive.',
      'url': 'https://www.themuse.com/advice/star-interview-method',
    },
    {
      'title': 'Job Search Strategies That Keep Momentum High',
      'category': 'Job Search',
      'readTime': '7 min read',
      'emoji': '🔎',
      'description':
          'Build a more focused search plan, stay organized, and keep your applications moving.',
      'url': 'https://www.themuse.com/advice/job-search',
    },
  ];

  @override
  void initState() {
    super.initState();
    _validateArticles();
  }

  List<Map<String, String>> get _validArticles => _articles
      .where((a) => _validArticleUrls.contains(a['url']))
      .cast<Map<String, String>>()
      .toList(growable: false);

  List<Map<String, String>> get _filteredArticles {
    final source = _validArticles;
    if (_selectedCategory == 'All') {
      return source;
    }
    return source
        .where((a) => a['category'] == _selectedCategory)
        .cast<Map<String, String>>()
        .toList();
  }

  Future<void> _validateArticles() async {
    final checks = await Future.wait(
      _articles.map((article) => _isArticleAccessible(article['url']!)),
    );

    if (!mounted) {
      return;
    }

    final validUrls = <String>{};
    for (var index = 0; index < _articles.length; index++) {
      if (checks[index]) {
        validUrls.add(_articles[index]['url']!);
      }
    }

    final effectiveUrls = validUrls.length >= 3
        ? validUrls
        : _articles.map((article) => article['url']!).toSet();

    setState(() {
      _validArticleUrls
        ..clear()
        ..addAll(effectiveUrls);
      _isValidatingArticles = false;
    });
  }

  Future<bool> _isArticleAccessible(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return false;
    }

    try {
      final response = await http
          .get(uri, headers: _articleRequestHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return false;
      }

      final body = response.body.toLowerCase();
      return !body.contains('page not found') &&
          !body.contains('<title>404') &&
          !(body.contains('404') && body.contains('not found'));
    } catch (_) {
      return false;
    }
  }

  Future<void> _openArticle(String url) async {
    if (!_validArticleUrls.contains(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This article is currently unavailable')),
        );
      }
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

  Color _categoryColor(String category) {
    const colors = {
      'Resume Tips': Color(0xFF6366F1),
      'Interview': Color(0xFF10B981),
      'Career Growth': Color(0xFFF59E0B),
      'Job Search': Color(0xFF0EA5E9),
      'Salary': Color(0xFFEC4899),
      'Skills': Color(0xFF8B5CF6),
    };
    return colors[category] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;
    final hasAnyValidArticles = _validArticleUrls.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Articles'),
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                        color: selected ? AppColors.primary : null,
                        fontWeight: selected ? FontWeight.w600 : null),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Articles list
          Expanded(
            child: _isValidatingArticles
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            hasAnyValidArticles
                                ? 'No valid articles are available in this category right now.'
                                : 'No valid articles are available right now. Please check back later.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final article = filtered[i];
                          final catColor = _categoryColor(article['category']!);
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: InkWell(
                              onTap: () => _openArticle(article['url']!),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(article['emoji']!,
                                            style:
                                                const TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(
                                                      alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  article['category']!,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: catColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                article['readTime']!,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .textSecondary),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            article['title']!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 1.3),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            article['description']!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.4),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Iconsax.arrow_right_3,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (i * 50).ms)
                              .slideX(begin: -0.05, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
