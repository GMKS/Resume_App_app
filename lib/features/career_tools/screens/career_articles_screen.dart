import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  static const _categories = [
    'All', 'Resume Tips', 'Interview', 'Career Growth', 'Job Search', 'Salary', 'Skills'
  ];

  static const _articles = [
    {
      'title': '10 Resume Mistakes That Get You Rejected Instantly',
      'category': 'Resume Tips',
      'readTime': '5 min read',
      'emoji': '📄',
      'description': 'Hiring managers spend just 7 seconds on your resume. Here are the mistakes that send yours straight to the bin.',
      'url': 'https://www.linkedin.com/pulse/10-resume-mistakes-get-you-rejected-instantly/',
    },
    {
      'title': 'How to Answer "Tell Me About Yourself" Perfectly',
      'category': 'Interview',
      'readTime': '4 min read',
      'emoji': '🎤',
      'description': 'Structure your answer to make a strong first impression in every interview.',
      'url': 'https://www.indeed.com/career-advice/interviewing/tell-me-about-yourself',
    },
    {
      'title': 'How to Negotiate Your Salary With Confidence',
      'category': 'Salary',
      'readTime': '6 min read',
      'emoji': '💰',
      'description': 'Data-backed scripts and tactics for negotiating the salary you deserve — without awkwardness.',
      'url': 'https://www.glassdoor.com/blog/guide/how-to-negotiate-salary/',
    },
    {
      'title': 'The ATS Secret: How to Beat the Bots',
      'category': 'Resume Tips',
      'readTime': '7 min read',
      'emoji': '🤖',
      'description': 'Over 75% of resumes are screened by software before human eyes see them. Learn how to make the cut.',
      'url': 'https://www.jobscan.co/blog/ats-resume/',
    },
    {
      'title': '5 Career Pivots That Are More Achievable Than You Think',
      'category': 'Career Growth',
      'readTime': '8 min read',
      'emoji': '🔄',
      'description': 'Changing careers doesn\'t have to mean starting over. Discover transferable skills you already have.',
      'url': 'https://hbr.org/topic/subject/career-transitions',
    },
    {
      'title': 'LinkedIn Profile Optimization: The 2024 Guide',
      'category': 'Job Search',
      'readTime': '9 min read',
      'emoji': '💼',
      'description': 'A fully optimized LinkedIn profile increases recruiter messages by 40x. Here\'s the complete checklist.',
      'url': 'https://www.linkedin.com/help/linkedin/answer/a548441',
    },
    {
      'title': 'Top 10 In-Demand Skills for 2024',
      'category': 'Skills',
      'readTime': '5 min read',
      'emoji': '🎯',
      'description': 'From AI literacy to data analysis — the skills employers are actively searching for right now.',
      'url': 'https://www.coursera.org/articles/in-demand-skills',
    },
    {
      'title': 'Behavioral Interview Questions: STAR Method Guide',
      'category': 'Interview',
      'readTime': '6 min read',
      'emoji': '⭐',
      'description': 'Master the Situation-Task-Action-Result framework to ace behavioral interview questions every time.',
      'url': 'https://www.indeed.com/career-advice/interviewing/how-to-use-the-star-interview-response-technique',
    },
    {
      'title': 'The Hidden Job Market: How to Find Unadvertised Jobs',
      'category': 'Job Search',
      'readTime': '7 min read',
      'emoji': '🔎',
      'description': 'Up to 80% of jobs are never publicly advertised. Learn the networking strategies to tap into them.',
      'url': 'https://www.glassdoor.com/blog/hidden-job-market/',
    },
    {
      'title': 'Build a Personal Brand That Gets You Hired',
      'category': 'Career Growth',
      'readTime': '10 min read',
      'emoji': '🌟',
      'description': 'Your personal brand is what people say about you when you\'re not in the room. Here\'s how to shape it.',
      'url': 'https://hbr.org/2023/01/develop-your-personal-brand',
    },
    {
      'title': 'Remote Work: How to Land a Remote Job in 2024',
      'category': 'Job Search',
      'readTime': '6 min read',
      'emoji': '🏡',
      'description': 'Proven strategies for finding and securing fully remote opportunities in any industry.',
      'url': 'https://remoteok.com/remote-work-guide',
    },
    {
      'title': 'Cover Letter Formula That Gets Callbacks',
      'category': 'Resume Tips',
      'readTime': '5 min read',
      'emoji': '✉️',
      'description': 'Most cover letters are ignored. Use this three-paragraph formula to make yours impossible to skip.',
      'url': 'https://www.indeed.com/career-advice/resumes-cover-letters/how-to-write-a-cover-letter',
    },
  ];

  List<Map<String, String>> get _filteredArticles {
    if (_selectedCategory == 'All') {
      return _articles.cast<Map<String, String>>();
    }
    return _articles
        .where((a) => a['category'] == _selectedCategory)
        .cast<Map<String, String>>()
        .toList();
  }

  Future<void> _openArticle(String url) async {
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
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                        color: selected ? AppColors.primary : null,
                        fontWeight:
                            selected ? FontWeight.w600 : null),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Articles list
          Expanded(
            child: ListView.builder(
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
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        article['category']!,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: catColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      article['readTime']!,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
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
                              size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: -0.05, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
