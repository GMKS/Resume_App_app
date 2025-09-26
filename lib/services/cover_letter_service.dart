import '../services/premium_service.dart';

/// Cover letter service with templates and AI assistance
/// Optimized for minimal APK size impact
class CoverLetterService {
  static final CoverLetterService _instance = CoverLetterService._internal();
  factory CoverLetterService() => _instance;
  CoverLetterService._internal();

  /// Available cover letter templates
  static List<Map<String, dynamic>> get availableTemplates {
    List<Map<String, dynamic>> allTemplates = [
      {
        'id': 'professional',
        'name': 'Professional',
        'description': 'Classic professional format',
        'isPremium': false,
        'template': _professionalTemplate,
      },
      {
        'id': 'modern',
        'name': 'Modern',
        'description': 'Contemporary design with color accents',
        'isPremium': true,
        'template': _modernTemplate,
      },
      {
        'id': 'creative',
        'name': 'Creative',
        'description': 'Stand out with creative elements',
        'isPremium': true,
        'template': _creativeTemplate,
      },
      {
        'id': 'executive',
        'name': 'Executive',
        'description': 'For senior-level positions',
        'isPremium': true,
        'template': _executiveTemplate,
      },
    ];

    // Filter based on premium status
    if (PremiumService.hasCoverLetterFeature) {
      return allTemplates;
    } else {
      return allTemplates.where((template) => !template['isPremium']).toList();
    }
  }

  /// Pre-written content suggestions by industry
  static Map<String, List<String>> get contentSuggestions => {
    'Technology': [
      'I am excited to apply for the [Position] role at [Company].',
      'With [X] years of experience in software development...',
      'My expertise in [Technologies] aligns perfectly with your requirements.',
      'I have successfully delivered [Achievement] in my previous role.',
    ],
    'Healthcare': [
      'I am writing to express my interest in the [Position] at [Hospital/Clinic].',
      'My [X] years of experience in healthcare...',
      'I am passionate about providing quality patient care.',
      'My certifications include [Certifications].',
    ],
    'Finance': [
      'I am pleased to submit my application for the [Position] role.',
      'With a strong background in financial analysis...',
      'I have experience with [Financial Tools/Software].',
      'My track record includes [Financial Achievement].',
    ],
    'Education': [
      'I am excited to apply for the teaching position at [School].',
      'With [X] years of educational experience...',
      'I believe in creating engaging learning environments.',
      'My teaching philosophy focuses on [Teaching Approach].',
    ],
    'Marketing': [
      'I am thrilled to apply for the [Position] at [Company].',
      'My creative approach to marketing has resulted in [Achievement].',
      'I have experience with [Marketing Tools/Platforms].',
      'I excel at developing campaigns that drive [Metric].',
    ],
  };

  /// Generate cover letter with AI assistance (mock implementation)
  static Future<String> generateWithAI({
    required String jobTitle,
    required String companyName,
    required String industry,
    required Map<String, dynamic> resumeData,
  }) async {
    if (!PremiumService.hasAIFeatures) {
      throw Exception('AI-generated cover letters are a premium feature');
    }

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 2));

    // Mock AI-generated content
    String template = _selectBestTemplate(industry);
    String personalizedContent = _personalizeContent(
      template,
      jobTitle,
      companyName,
      industry,
      resumeData,
    );

    return personalizedContent;
  }

  /// Get template by ID
  static CoverLetterTemplate getTemplate(String templateId) {
    Map<String, dynamic>? template = availableTemplates.firstWhere(
      (t) => t['id'] == templateId,
      orElse: () => availableTemplates.first,
    );
    return CoverLetterTemplate(
      id: template['id'],
      name: template['name'],
      content: template['template'](),
    );
  }

  /// Generate cover letter with specified parameters
  Future<CoverLetterResult> generateCoverLetter({
    required String template,
    required String industry,
    required String companyName,
    required String positionTitle,
    required String customRequirements,
  }) async {
    if (!PremiumService.hasCoverLetterFeature) {
      throw Exception('Cover letter generation is a premium feature');
    }

    try {
      // Simulate AI processing
      await Future.delayed(const Duration(seconds: 1));

      String templateContent = getTemplate(template.toLowerCase()).content;

      // Personalize the template
      String personalizedContent = templateContent
          .replaceAll('[Position]', positionTitle)
          .replaceAll('[Company]', companyName)
          .replaceAll('[Industry]', industry);

      // Add industry-specific content suggestions
      List<String> suggestions =
          contentSuggestions[industry] ?? contentSuggestions['Technology']!;

      // Replace placeholder content with suggestions
      for (int i = 0; i < suggestions.length && i < 3; i++) {
        personalizedContent = personalizedContent.replaceAll(
          '[Content paragraph ${i + 1} - ${_getPlaceholderText(i)}]',
          suggestions[i]
              .replaceAll('[Position]', positionTitle)
              .replaceAll('[Company]', companyName),
        );
      }

      return CoverLetterResult(content: personalizedContent, success: true);
    } catch (e) {
      return CoverLetterResult(
        content: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  String _getPlaceholderText(int index) {
    switch (index) {
      case 0:
        return 'relevant experience';
      case 1:
        return 'specific achievements';
      case 2:
        return 'why this company';
      default:
        return 'additional content';
    }
  }

  static String _selectBestTemplate(String industry) {
    switch (industry.toLowerCase()) {
      case 'technology':
        return _modernTemplate();
      case 'finance':
        return _executiveTemplate();
      case 'creative':
        return _creativeTemplate();
      default:
        return _professionalTemplate();
    }
  }

  static String _personalizeContent(
    String template,
    String jobTitle,
    String companyName,
    String industry,
    Map<String, dynamic> resumeData,
  ) {
    String personalized = template
        .replaceAll('[Position]', jobTitle)
        .replaceAll('[Company]', companyName)
        .replaceAll('[Industry]', industry);

    // Add personal details from resume
    if (resumeData.containsKey('name')) {
      personalized = personalized.replaceAll('[Your Name]', resumeData['name']);
    }
    if (resumeData.containsKey('experience')) {
      personalized = personalized.replaceAll(
        '[X]',
        '${resumeData['experience']?.length ?? 3}',
      );
    }

    return personalized;
  }

  // Template content generators
  static String _professionalTemplate() {
    return '''Dear Hiring Manager,

I am writing to express my strong interest in the [Position] position at [Company]. With my background and skills, I believe I would be a valuable addition to your team.

[Content paragraph 1 - relevant experience]

[Content paragraph 2 - specific achievements]

[Content paragraph 3 - why this company]

I would welcome the opportunity to discuss how my experience and enthusiasm can contribute to [Company]'s continued success. Thank you for your consideration.

Sincerely,
[Your Name]''';
  }

  static String _modernTemplate() {
    return '''Hello [Company] Team,

I'm excited to apply for the [Position] role at [Company]. Your innovative approach to [Industry] aligns perfectly with my career goals and expertise.

[Content paragraph 1 - unique value proposition]

[Content paragraph 2 - relevant skills and achievements]

[Content paragraph 3 - cultural fit and enthusiasm]

I'd love to discuss how I can contribute to [Company]'s mission. Looking forward to hearing from you!

Best regards,
[Your Name]''';
  }

  static String _creativeTemplate() {
    return '''Dear [Company] Creative Team,

🎯 I'm [Your Name], and I'm passionate about joining [Company] as your next [Position].

What makes me different:
• [Unique skill/achievement 1]
• [Unique skill/achievement 2] 
• [Unique skill/achievement 3]

Why [Company]? [Specific reason about their work/culture]

Let's create something amazing together! I'd love to chat about how my creative approach can add value to your team.

Creatively yours,
[Your Name]''';
  }

  static String _executiveTemplate() {
    return '''Dear [Company] Leadership Team,

I am pleased to submit my candidacy for the [Position] position at [Company]. Having followed [Company]'s growth and innovation in the [Industry] sector, I am confident that my executive experience aligns with your strategic objectives.

[Content paragraph 1 - executive experience and leadership]

[Content paragraph 2 - strategic achievements and business impact]

[Content paragraph 3 - vision alignment and future contribution]

I would appreciate the opportunity to discuss how my leadership experience and strategic vision can drive [Company]'s continued growth and success.

Respectfully,
[Your Name]''';
  }
}

/// Cover letter template model
class CoverLetterTemplate {
  final String id;
  final String name;
  final String content;

  CoverLetterTemplate({
    required this.id,
    required this.name,
    required this.content,
  });
}

/// Cover letter generation result
class CoverLetterResult {
  final String content;
  final bool success;
  final String? error;

  CoverLetterResult({required this.content, required this.success, this.error});
}

/// Cover letter data model
class CoverLetter {
  final String id;
  final String title;
  final String content;
  final String templateId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoverLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CoverLetter.fromJson(Map<String, dynamic> json) {
    return CoverLetter(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      templateId: json['templateId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
