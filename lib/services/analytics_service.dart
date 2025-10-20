import 'dart:math';
import '../models/saved_resume.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Analyze a resume and return comprehensive analytics data
  Future<Map<String, dynamic>> analyzeResume(SavedResume resume) async {
    final data = resume.data;
    final template = resume.template.toLowerCase();

    return {
      'templateFitScore': _calculateTemplateFitScore(data, template),
      'atsRiskLevel': _assessATSRisk(data),
      'atsIssues': _identifyATSIssues(data),
      'impactScore': _calculateImpactScore(data),
      'metricsCount': _countMetrics(data),
      'actionVerbsCount': _countActionVerbs(data),
      'tone': _analyzeTone(data),
      'toneConsistency': _calculateToneConsistency(data),
      'keywords': _extractKeywords(data),
      'keywordDensity': _calculateKeywordDensity(data),
      'jobMatchScore': _calculateJobMatchScore(data),
      'jobMatchSuggestions': _generateJobMatchSuggestions(data),
      'versions': _getVersionHistory(resume),
      'currentScore': _calculateOverallScore(data),
    };
  }

  /// Calculate how well content matches the chosen template's strengths
  double _calculateTemplateFitScore(
    Map<String, dynamic> data,
    String template,
  ) {
    double score = 0.0;
    int checks = 0;

    switch (template) {
      case 'classic':
      case 'professional':
        // Check for structured, professional content
        if (_hasStructuredWorkHistory(data)) {
          score += 25;
        }
        if (_hasQuantifiableAchievements(data)) {
          score += 25;
        }
        if (_hasCleanFormatting(data)) {
          score += 25;
        }
        if (_hasRelevantSkills(data)) {
          score += 25;
        }
        checks = 4;
        break;

      case 'modern':
      case 'minimal':
        // Check for balanced, concise content
        if (_hasOptimalLength(data)) {
          score += 20;
        }
        if (_hasKeywordRichContent(data)) {
          score += 30;
        }
        if (_hasGoodWhitespaceBalance(data)) {
          score += 25;
        }
        if (_hasModernLanguage(data)) {
          score += 25;
        }
        checks = 4;
        break;

      case 'creative':
        // Check for personality and storytelling
        if (_hasPersonalityMarkers(data)) {
          score += 30;
        }
        if (_hasStorytellingElements(data)) {
          score += 25;
        }
        if (_hasCreativeLanguage(data)) {
          score += 25;
        }
        if (_hasUniqueValue(data)) {
          score += 20;
        }
        checks = 4;
        break;

      case 'one page':
        // Check for brevity and impact
        if (_isOptimallyBrief(data)) {
          score += 30;
        }
        if (_hasHighKeywordDensity(data)) {
          score += 25;
        }
        if (_hasPrioritizedSections(data)) {
          score += 25;
        }
        if (_hasImpactfulLanguage(data)) {
          score += 20;
        }
        checks = 4;
        break;

      default:
        score = 75.0; // Default good score
        checks = 1;
    }

    return checks > 0 ? score / checks : 0.0;
  }

  /// Assess ATS (Applicant Tracking System) risk level
  String _assessATSRisk(Map<String, dynamic> data) {
    final issues = _identifyATSIssues(data);
    if (issues.length >= 3) return 'High';
    if (issues.isNotEmpty) return 'Medium';
    return 'Low';
  }

  /// Identify specific ATS parsing issues
  List<String> _identifyATSIssues(Map<String, dynamic> data) {
    List<String> issues = [];

    // Check for missing contact info
    if (data['email']?.toString().isEmpty ?? true) {
      issues.add('Missing email address');
    }
    if (data['phone']?.toString().isEmpty ?? true) {
      issues.add('Missing phone number');
    }

    // Check for problematic formatting
    final summary = data['summary']?.toString() ?? '';
    if (summary.contains('•') || summary.contains('→')) {
      issues.add('Special characters may cause parsing issues');
    }

    // Check for missing sections
    if (data['skills']?.toString().isEmpty ?? true) {
      issues.add('Missing skills section');
    }

    return issues;
  }

  /// Calculate impact score based on metrics and achievements
  double _calculateImpactScore(Map<String, dynamic> data) {
    int metricsCount = _countMetrics(data);
    int actionVerbsCount = _countActionVerbs(data);
    int achievementsCount = _countAchievements(data);

    // Weighted scoring
    double score = 0.0;
    score += (metricsCount * 15).clamp(0, 40); // Max 40 points for metrics
    score += (actionVerbsCount * 5).clamp(
      0,
      30,
    ); // Max 30 points for action verbs
    score += (achievementsCount * 10).clamp(
      0,
      30,
    ); // Max 30 points for achievements

    return score.clamp(0, 100);
  }

  /// Count quantifiable metrics in the resume
  int _countMetrics(Map<String, dynamic> data) {
    final text = _getAllText(data);
    final metrics = RegExp(
      r'\d+[%$kmb]|\d+\+|\d+x|\d+:\d+|\$\d+',
    ).allMatches(text);
    return metrics.length;
  }

  /// Count action verbs in the resume
  int _countActionVerbs(Map<String, dynamic> data) {
    final actionVerbs = [
      'achieved',
      'built',
      'created',
      'delivered',
      'developed',
      'enhanced',
      'established',
      'generated',
      'implemented',
      'improved',
      'increased',
      'launched',
      'led',
      'managed',
      'optimized',
      'reduced',
      'streamlined',
    ];

    final text = _getAllText(data).toLowerCase();
    int count = 0;
    for (final verb in actionVerbs) {
      count += RegExp(r'\b' + verb + r'\b').allMatches(text).length;
    }
    return count;
  }

  /// Count achievements and accomplishments
  int _countAchievements(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    final achievementWords = [
      'achieved',
      'accomplished',
      'awarded',
      'recognized',
      'exceeded',
    ];

    int count = 0;
    for (final word in achievementWords) {
      count += RegExp(r'\b' + word + r'\b').allMatches(text).length;
    }
    return count;
  }

  /// Analyze tone and professionalism
  String _analyzeTone(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();

    // Check for different tone indicators
    final casualWords = ['awesome', 'cool', 'amazing', 'love', 'hate'];
    final professionalWords = [
      'experienced',
      'accomplished',
      'demonstrated',
      'collaborated',
    ];
    final creativeTone = ['innovative', 'creative', 'artistic', 'visionary'];

    int casualCount = 0;
    int professionalCount = 0;
    int creativeCount = 0;

    for (final word in casualWords) {
      casualCount += RegExp(r'\b' + word + r'\b').allMatches(text).length;
    }
    for (final word in professionalWords) {
      professionalCount += RegExp(r'\b' + word + r'\b').allMatches(text).length;
    }
    for (final word in creativeTone) {
      creativeCount += RegExp(r'\b' + word + r'\b').allMatches(text).length;
    }

    if (creativeCount > professionalCount && creativeCount > casualCount) {
      return 'Creative';
    } else if (casualCount > professionalCount) {
      return 'Casual';
    } else {
      return 'Professional';
    }
  }

  /// Calculate tone consistency across sections
  double _calculateToneConsistency(Map<String, dynamic> data) {
    // Simplified consistency check - in reality this would be more sophisticated
    final sections = ['summary', 'experience', 'skills'];
    final tones = sections.map((section) {
      final sectionData = {section: data[section]};
      return _analyzeTone(sectionData);
    }).toList();

    // Calculate consistency percentage
    final mainTone = tones.isNotEmpty ? tones.first : 'Professional';
    final consistentSections = tones.where((tone) => tone == mainTone).length;

    return (consistentSections / max(tones.length, 1)) * 100;
  }

  /// Extract relevant keywords from resume content
  Map<String, int> _extractKeywords(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    final words = text.split(RegExp(r'[^\w]+'));

    // Common tech and business keywords
    final relevantKeywords = [
      'leadership',
      'management',
      'development',
      'analysis',
      'project',
      'team',
      'strategy',
      'implementation',
      'optimization',
      'growth',
      'innovation',
      'collaboration',
      'communication',
      'problem-solving',
      'technical',
      'strategic',
      'operational',
      'analytical',
    ];

    Map<String, int> keywordCounts = {};
    for (final keyword in relevantKeywords) {
      final count = words.where((word) => word.contains(keyword)).length;
      if (count > 0) {
        keywordCounts[keyword] = count;
      }
    }

    return keywordCounts;
  }

  /// Calculate keyword density across sections
  Map<String, double> _calculateKeywordDensity(Map<String, dynamic> data) {
    final sections = ['summary', 'experience', 'skills', 'education'];
    Map<String, double> density = {};

    for (final section in sections) {
      final sectionText = data[section]?.toString() ?? '';
      final words = sectionText.split(RegExp(r'\s+'));
      final keywords = _extractKeywords({section: sectionText});
      final totalKeywords = keywords.values.fold(
        0,
        (sum, count) => sum + count,
      );

      density[section] = words.isNotEmpty
          ? (totalKeywords / words.length) * 100
          : 0.0;
    }

    return density;
  }

  /// Calculate job match score (simplified)
  double _calculateJobMatchScore(Map<String, dynamic> data) {
    // This would typically compare against a job posting
    // For now, return a score based on content completeness
    int completeness = 0;

    if (data['summary']?.toString().isNotEmpty ?? false) completeness += 20;
    if (data['experience']?.toString().isNotEmpty ?? false) completeness += 30;
    if (data['skills']?.toString().isNotEmpty ?? false) completeness += 25;
    if (data['education']?.toString().isNotEmpty ?? false) completeness += 15;
    if (_countMetrics(data) > 0) completeness += 10;

    return completeness.toDouble();
  }

  /// Generate job match suggestions
  List<String> _generateJobMatchSuggestions(Map<String, dynamic> data) {
    List<String> suggestions = [];

    if (_countMetrics(data) < 3) {
      suggestions.add('Add more quantifiable achievements with numbers');
    }
    if (_countActionVerbs(data) < 5) {
      suggestions.add('Use more action verbs to describe your accomplishments');
    }
    if ((data['skills']?.toString().split(',').length ?? 0) < 8) {
      suggestions.add('Include more relevant technical and soft skills');
    }

    return suggestions;
  }

  /// Get version history (simplified - would track actual changes)
  List<Map<String, dynamic>> _getVersionHistory(SavedResume resume) {
    return [
      {
        'version': '1.0',
        'date': resume.createdAt,
        'score': _calculateOverallScore(resume.data),
        'changes': 'Initial version',
      },
    ];
  }

  /// Calculate overall resume score
  double _calculateOverallScore(Map<String, dynamic> data) {
    final templateScore = _calculateTemplateFitScore(data, 'professional');
    final impactScore = _calculateImpactScore(data);
    final completeness = _calculateJobMatchScore(data);

    return (templateScore + impactScore + completeness) / 3;
  }

  // Helper methods for template fit scoring
  bool _hasStructuredWorkHistory(Map<String, dynamic> data) {
    final workExp =
        data['workExperiences']?.toString() ??
        data['experience']?.toString() ??
        '';
    return workExp.isNotEmpty && workExp.length > 100;
  }

  bool _hasQuantifiableAchievements(Map<String, dynamic> data) {
    return _countMetrics(data) >= 2;
  }

  bool _hasCleanFormatting(Map<String, dynamic> data) {
    final text = _getAllText(data);
    // Check for excessive special characters that might confuse ATS
    final specialChars = RegExp(r'[★♦●▪►]').allMatches(text);
    return specialChars.length < 5;
  }

  bool _hasRelevantSkills(Map<String, dynamic> data) {
    final skills = data['skills']?.toString() ?? '';
    return skills.split(',').length >= 5;
  }

  bool _hasOptimalLength(Map<String, dynamic> data) {
    final text = _getAllText(data);
    final wordCount = text.split(RegExp(r'\s+')).length;
    return wordCount >= 200 && wordCount <= 800;
  }

  bool _hasKeywordRichContent(Map<String, dynamic> data) {
    final keywords = _extractKeywords(data);
    return keywords.length >= 5;
  }

  bool _hasGoodWhitespaceBalance(Map<String, dynamic> data) {
    // Simplified check - assume good balance if sections are properly filled
    int filledSections = 0;
    final sections = ['summary', 'experience', 'skills', 'education'];
    for (final section in sections) {
      if (data[section]?.toString().isNotEmpty ?? false) filledSections++;
    }
    return filledSections >= 3;
  }

  bool _hasModernLanguage(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    final modernTerms = [
      'digital',
      'agile',
      'collaborative',
      'innovative',
      'strategic',
    ];
    return modernTerms.any((term) => text.contains(term));
  }

  bool _hasPersonalityMarkers(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    final personalityWords = [
      'passionate',
      'creative',
      'innovative',
      'unique',
      'artistic',
    ];
    return personalityWords.any((word) => text.contains(word));
  }

  bool _hasStorytellingElements(Map<String, dynamic> data) {
    final summary = data['summary']?.toString() ?? '';
    return summary.length > 150 && summary.contains('.');
  }

  bool _hasCreativeLanguage(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    final creativeWords = ['designed', 'crafted', 'conceived', 'envisioned'];
    return creativeWords.any((word) => text.contains(word));
  }

  bool _hasUniqueValue(Map<String, dynamic> data) {
    final text = _getAllText(data).toLowerCase();
    return text.contains('unique') ||
        text.contains('distinct') ||
        text.contains('specialized');
  }

  bool _isOptimallyBrief(Map<String, dynamic> data) {
    final text = _getAllText(data);
    final wordCount = text.split(RegExp(r'\s+')).length;
    return wordCount <= 400; // Optimal for one page
  }

  bool _hasHighKeywordDensity(Map<String, dynamic> data) {
    final keywords = _extractKeywords(data);
    final totalWords = _getAllText(data).split(RegExp(r'\s+')).length;
    final totalKeywords = keywords.values.fold(0, (sum, count) => sum + count);
    return totalWords > 0 &&
        (totalKeywords / totalWords) > 0.05; // 5% keyword density
  }

  bool _hasPrioritizedSections(Map<String, dynamic> data) {
    // Check if most important sections are present and substantial
    final summary = data['summary']?.toString() ?? '';
    final experience = data['experience']?.toString() ?? '';
    return summary.length > 50 && experience.length > 100;
  }

  bool _hasImpactfulLanguage(Map<String, dynamic> data) {
    return _countActionVerbs(data) >= 5 && _countMetrics(data) >= 2;
  }

  /// Get all text content from resume data
  String _getAllText(Map<String, dynamic> data) {
    return data.values
        .whereType<String>()
        .map((value) => value.toString())
        .join(' ');
  }
}
