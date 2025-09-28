import 'dart:convert';
import 'package:http/http.dart' as http;
import 'premium_service.dart';

/// AI-powered resume writing service using GPT for content generation
class AIResumeService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  // Provide API key via --dart-define=OPENAI_API_KEY=sk-...
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Generate professional bullet points for work experience
  static Future<List<String>> generateBulletPoints({
    required String jobTitle,
    required String company,
    required String description,
    String? industry,
    int count = 3,
  }) async {
    if (!PremiumService.hasAIFeatures) {
      throw Exception('AI features require Premium subscription');
    }

    try {
      final prompt =
          '''
Generate $count professional bullet points for a resume based on this work experience:

Job Title: $jobTitle
Company: $company
Description: $description
${industry != null ? 'Industry: $industry' : ''}

Requirements:
- Start with strong action verbs
- Include quantifiable achievements when possible
- Use keywords relevant to the role
- Keep each bullet point to 1-2 lines
- Focus on impact and results
- Make them ATS-friendly

Format as a JSON array of strings.
''';

      final response = await _makeOpenAIRequest(
        prompt,
        temperature: 0.9,
        seed: DateTime.now().millisecondsSinceEpoch % 1000,
      );
      return _parseBulletPoints(response);
    } catch (e) {
      // Fallback to template-based generation
      return _generateFallbackBulletPoints(jobTitle, description, count);
    }
  }

  /// Generate professional summary based on user background
  static Future<String> generateSummary({
    required String name,
    required String targetRole,
    required List<String> skills,
    required List<String> experience,
    String? industry,
  }) async {
    try {
      // Add a small salt to encourage varied responses across runs
      final salt = DateTime.now().millisecondsSinceEpoch % 1000;
      final prompt =
          '''
Generate a professional resume summary for:

Name: $name
Target Role: $targetRole
Skills: ${skills.join(', ')}
Experience: ${experience.join(', ')}
${industry != null ? 'Industry: $industry' : ''}

Requirements:
- 2-3 sentences maximum
- Highlight key strengths and achievements
- Include relevant keywords for ATS
- Professional tone
- Focus on value proposition
 - Provide a slightly different phrasing from previous outputs

 Return only the summary text.
''';

      final response = await _makeOpenAIRequest(
        prompt,
        temperature: 0.9,
        seed: salt,
      );
      return _parseSummary(response);
    } catch (e) {
      // Fallback summary
      return _generateFallbackSummary(name, targetRole, skills);
    }
  }

  /// Generate cover letter based on job description
  static Future<String> generateCoverLetter({
    required String name,
    required String targetRole,
    required String company,
    required String jobDescription,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final prompt =
          '''
Generate a professional cover letter for:

Applicant: $name
Target Role: $targetRole
Company: $company
Job Description: $jobDescription

User Background:
${_formatUserProfile(userProfile)}

Requirements:
- Professional business format
- 3-4 paragraphs
- Highlight relevant experience
- Show enthusiasm for the role
- Include specific examples
- Professional closing

Return the complete cover letter.
''';

      final response = await _makeOpenAIRequest(prompt);
      return _parseCoverLetter(response);
    } catch (e) {
      // Fallback cover letter
      return _generateFallbackCoverLetter(name, targetRole, company);
    }
  }

  /// Optimize content for ATS keywords
  static Future<Map<String, dynamic>> optimizeForATS({
    required String content,
    required String jobDescription,
  }) async {
    try {
      final prompt =
          '''
Analyze this resume content for ATS optimization:

Resume Content: $content
Job Description: $jobDescription

Provide:
1. Missing keywords that should be added
2. ATS compatibility score (0-100)
3. Specific improvement suggestions
4. Recommended keyword density

Format as JSON with keys: missingKeywords, score, suggestions, recommendations
''';

      final response = await _makeOpenAIRequest(prompt);
      return _parseATSAnalysis(response);
    } catch (e) {
      return _generateFallbackATSAnalysis(content, jobDescription);
    }
  }

  /// Get real-time feedback on content quality
  static Future<Map<String, dynamic>> getFeedback({
    required String content,
    required String section, // 'summary', 'experience', 'skills', etc.
  }) async {
    try {
      final prompt =
          '''
Provide real-time feedback on this resume $section:

Content: $content

Analyze for:
1. Grammar and spelling
2. Clarity and readability
3. Impact and action verbs
4. Professional tone
5. Overall score (0-100)

Format as JSON with keys: grammar, clarity, impact, tone, score, suggestions
''';

      final response = await _makeOpenAIRequest(prompt);
      return _parseFeedback(response);
    } catch (e) {
      return _generateFallbackFeedback(content, section);
    }
  }

  /// Recommend templates based on industry and role
  static Map<String, dynamic> recommendTemplate({
    required String industry,
    required String role,
    required String experienceLevel,
  }) {
    // Industry-specific template recommendations
    final recommendations = <String, Map<String, dynamic>>{
      'technology': {
        'template': 'modern',
        'reason': 'Modern template showcases technical skills and innovation',
        'features': [
          'Skills section emphasis',
          'Clean design',
          'Project highlights',
        ],
      },
      'finance': {
        'template': 'professional',
        'reason': 'Professional template conveys trust and reliability',
        'features': [
          'Conservative design',
          'Achievement focus',
          'Formal structure',
        ],
      },
      'creative': {
        'template': 'creative',
        'reason': 'Creative template demonstrates design sensibility',
        'features': [
          'Visual appeal',
          'Portfolio integration',
          'Creative layout',
        ],
      },
      'consulting': {
        'template': 'professional',
        'reason': 'Professional template emphasizes analytical skills',
        'features': [
          'Problem-solving focus',
          'Results-driven',
          'Executive summary',
        ],
      },
      'startup': {
        'template': 'modern',
        'reason': 'Modern template shows adaptability and innovation',
        'features': [
          'Versatile design',
          'Skills emphasis',
          'Achievement focus',
        ],
      },
    };

    // Experience level adjustments
    if (experienceLevel.toLowerCase().contains('entry') ||
        experienceLevel.toLowerCase().contains('junior')) {
      return {
        'template': 'onepage',
        'reason': 'One-page template is perfect for entry-level professionals',
        'features': ['Concise format', 'Skills focus', 'Education emphasis'],
      };
    }

    final industryKey = industry.toLowerCase();
    for (final key in recommendations.keys) {
      if (industryKey.contains(key)) {
        return recommendations[key]!;
      }
    }

    // Default recommendation
    return {
      'template': 'modern',
      'reason': 'Modern template is versatile for most industries',
      'features': [
        'Professional appearance',
        'ATS-friendly',
        'Balanced layout',
      ],
    };
  }

  // Private helper methods
  static Future<String> _makeOpenAIRequest(
    String prompt, {
    double temperature = 0.7,
    int? seed,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OpenAI API key. Pass --dart-define=OPENAI_API_KEY=... at build/run time.',
      );
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
        'temperature': temperature,
        if (seed != null) 'seed': seed,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI API request failed: ${response.statusCode}');
    }
  }

  static List<String> _parseBulletPoints(String response) {
    try {
      final List<dynamic> parsed = jsonDecode(response);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      // Parse as plain text if JSON parsing fails
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
          .toList();
    }
  }

  static String _parseSummary(String response) {
    String result = response.trim();
    if (result.startsWith('"') && result.endsWith('"')) {
      result = result.substring(1, result.length - 1);
    }
    if (result.startsWith("'") && result.endsWith("'")) {
      result = result.substring(1, result.length - 1);
    }
    return result;
  }

  static String _parseCoverLetter(String response) {
    return response.trim();
  }

  static Map<String, dynamic> _parseATSAnalysis(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      return {
        'missingKeywords': [],
        'score': 75,
        'suggestions': ['Unable to parse AI response'],
        'recommendations': 'Review content manually',
      };
    }
  }

  static Map<String, dynamic> _parseFeedback(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      return {
        'grammar': 85,
        'clarity': 80,
        'impact': 75,
        'tone': 90,
        'score': 82,
        'suggestions': ['Unable to parse AI feedback'],
      };
    }
  }

  // Fallback methods for when AI service is unavailable
  static List<String> _generateFallbackBulletPoints(
    String jobTitle,
    String description,
    int count,
  ) {
    final templates = [
      'Collaborated with cross-functional teams to deliver high-quality results',
      'Improved operational efficiency through strategic process optimization',
      'Managed multiple projects simultaneously while meeting tight deadlines',
      'Developed and implemented innovative solutions to complex challenges',
      'Mentored team members and contributed to skill development initiatives',
    ];
    return templates.take(count).toList();
  }

  static String _generateFallbackSummary(
    String name,
    String targetRole,
    List<String> skills,
  ) {
    return 'Experienced professional with expertise in ${skills.take(3).join(', ')}. '
        'Proven track record of delivering results in dynamic environments. '
        'Seeking to leverage skills and experience in a $targetRole role.';
  }

  static String _generateFallbackCoverLetter(
    String name,
    String targetRole,
    String company,
  ) {
    return '''Dear Hiring Manager,

I am writing to express my strong interest in the $targetRole position at $company. With my proven track record of success and passion for excellence, I am confident that I would be a valuable addition to your team.

Throughout my career, I have developed strong skills in problem-solving, communication, and project management. I am particularly drawn to $company because of its reputation for innovation and commitment to quality.

I would welcome the opportunity to discuss how my experience and enthusiasm can contribute to your team's continued success. Thank you for your consideration.

Sincerely,
$name''';
  }

  static Map<String, dynamic> _generateFallbackATSAnalysis(
    String content,
    String jobDescription,
  ) {
    return {
      'missingKeywords': ['communication', 'leadership', 'problem-solving'],
      'score': 78,
      'suggestions': [
        'Add more industry-specific keywords',
        'Include quantifiable achievements',
        'Use standard section headings',
      ],
      'recommendations': 'Focus on relevant skills and experience',
    };
  }

  static Map<String, dynamic> _generateFallbackFeedback(
    String content,
    String section,
  ) {
    return {
      'grammar': 88,
      'clarity': 82,
      'impact': 79,
      'tone': 91,
      'score': 85,
      'suggestions': [
        'Use more specific action verbs',
        'Add quantifiable results where possible',
        'Ensure consistent formatting',
      ],
    };
  }

  static String _formatUserProfile(Map<String, dynamic> profile) {
    final buffer = StringBuffer();
    profile.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }
}

/// Data models for AI features
class AIGeneratedContent {
  final String content;
  final double confidence;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  AIGeneratedContent({
    required this.content,
    required this.confidence,
    required this.generatedAt,
    this.metadata = const {},
  });
}

class ATSAnalysis {
  final List<String> missingKeywords;
  final int score;
  final List<String> suggestions;
  final String recommendations;

  ATSAnalysis({
    required this.missingKeywords,
    required this.score,
    required this.suggestions,
    required this.recommendations,
  });

  factory ATSAnalysis.fromJson(Map<String, dynamic> json) {
    return ATSAnalysis(
      missingKeywords: List<String>.from(json['missingKeywords'] ?? []),
      score: json['score'] ?? 0,
      suggestions: List<String>.from(json['suggestions'] ?? []),
      recommendations: json['recommendations'] ?? '',
    );
  }
}

class ContentFeedback {
  final int grammarScore;
  final int clarityScore;
  final int impactScore;
  final int toneScore;
  final int overallScore;
  final List<String> suggestions;

  ContentFeedback({
    required this.grammarScore,
    required this.clarityScore,
    required this.impactScore,
    required this.toneScore,
    required this.overallScore,
    required this.suggestions,
  });

  factory ContentFeedback.fromJson(Map<String, dynamic> json) {
    return ContentFeedback(
      grammarScore: json['grammar'] ?? 0,
      clarityScore: json['clarity'] ?? 0,
      impactScore: json['impact'] ?? 0,
      toneScore: json['tone'] ?? 0,
      overallScore: json['score'] ?? 0,
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}
