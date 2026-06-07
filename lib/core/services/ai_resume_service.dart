import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_api_key_storage_service.dart';

/// AI Resume Service for resume content generation and job tailoring.
class AiResumeService {
  // Configured AI endpoint for chat completions.
  static const _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Always returns true — no usage limits, AI is free and unlimited.
  static Future<bool> hasRemainingUsage({required bool isPremium}) async =>
      true;

  /// Returns -1 (unlimited) for all users.
  static Future<int> getRemainingUsage({required bool isPremium}) async => -1;

  /// No-op — usage is no longer tracked.
  static Future<void> _incrementUsage() async {}

  /// Generate professional resume content using AI
  ///
  /// Returns a map containing:
  /// - `professionalSummary`: A compelling professional summary
  /// - `optimizedExperience`: List of enhanced experience bullet points
  /// - `suggestedMetrics`: Quantifiable achievements to add
  /// - `atsKeywordsUsed`: Keywords optimized for ATS systems
  static Future<Map<String, dynamic>> generateResumeContent({
    required String apiKey,
    required String jobTitle,
    required int experienceYears,
    required String industry,
    required List<String> skillsList,
    String? existingDescription,
    bool isPremium = false,
  }) async {
    // Check usage limits
    if (!await hasRemainingUsage(isPremium: isPremium)) {
      throw AiUsageLimitException(
        'Daily AI usage limit reached. Upgrade to premium for unlimited access.',
      );
    }

    final skillsText = skillsList.join(', ');
    final existingContext =
        existingDescription != null && existingDescription.isNotEmpty
            ? '\n\nExisting description to improve: $existingDescription'
            : '';

    final prompt = '''
You are an expert resume writer and career coach. Generate professional resume content for the following profile:

**Job Title:** $jobTitle
**Years of Experience:** $experienceYears
**Industry:** $industry
**Key Skills:** $skillsText$existingContext

Please provide the following in JSON format:

1. **professionalSummary**: A compelling 2-3 sentence professional summary that highlights key strengths and value proposition. Make it specific to the industry and experience level.

2. **optimizedExperience**: An array of 5-6 powerful bullet points for work experience. Each should:
   - Start with a strong action verb
   - Include quantifiable metrics where possible
   - Demonstrate impact and results
   - Be relevant to the $jobTitle role

3. **suggestedMetrics**: An array of 4-5 specific metrics/achievements that could strengthen the resume (e.g., "Increased sales by X%", "Managed team of X people")

4. **atsKeywordsUsed**: An array of 8-10 ATS-friendly keywords that were incorporated and are relevant for $jobTitle positions

Respond ONLY with valid JSON, no markdown code blocks or additional text.
''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.6);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Tailor an existing resume for a specific job description
  ///
  /// Returns a map containing:
  /// - `tailoredSummary`: Summary customized for the job
  /// - `tailoredExperience`: Experience bullet points aligned with job requirements
  /// - `prioritizedSkills`: Skills reordered by relevance to the job
  /// - `keywordsAdded`: New keywords extracted from job description and added
  /// - `matchScore`: Estimated match percentage (0-100)
  /// - `suggestions`: Additional suggestions to improve the match
  static Future<Map<String, dynamic>> tailorResumeForJob({
    required String apiKey,
    required Map<String, dynamic> resumeJson,
    required String jobDescription,
    bool isPremium = false,
  }) async {
    // Check usage limits
    if (!await hasRemainingUsage(isPremium: isPremium)) {
      throw AiUsageLimitException(
        'Daily AI usage limit reached. Upgrade to premium for unlimited access.',
      );
    }

    // Extract comprehensive resume data
    final personalInfo =
        resumeJson['personalInfo'] as Map<String, dynamic>? ?? {};
    final objective = resumeJson['objective'] as String? ?? '';
    final experiences = resumeJson['experience'] as List? ?? [];
    final skills = resumeJson['skills'] as List? ?? [];
    final education = resumeJson['education'] as List? ?? [];
    final certifications = resumeJson['certifications'] as List? ?? [];

    final currentJobTitle = personalInfo['jobTitle'] ?? 'Professional';

    // Format experience
    final experienceText = experiences.isEmpty
        ? 'No experience'
        : experiences.take(5).map((exp) {
            final e = exp as Map<String, dynamic>;
            return '${e['position'] ?? ''} at ${e['company'] ?? ''}: ${e['description'] ?? ''}';
          }).join(' | ');

    // Format education
    final educationText = education.isEmpty
        ? 'No education'
        : education.take(3).map((edu) {
            final e = edu as Map<String, dynamic>;
            return '${e['degree'] ?? ''} from ${e['institution'] ?? ''}';
          }).join(' | ');

    // Format skills
    final skillsText = skills.isEmpty
        ? 'No skills'
        : skills.take(15).map((s) {
            if (s is Map<String, dynamic>) return s['name'] ?? '';
            return s.toString();
          }).join(', ');

    // Format certifications
    final certificationsText = certifications.isEmpty
        ? ''
        : certifications.take(3).map((c) {
            final cert = c as Map<String, dynamic>;
            return cert['name'] ?? '';
          }).join(', ');

    final certLine = certificationsText.isNotEmpty
        ? '\nCertifications: $certificationsText'
        : '';

    final prompt =
        '''Analyze this resume against a job description and provide tailoring recommendations in valid JSON format.

RESUME DATA:
Current Title: $currentJobTitle
Summary: $objective
Experience: $experienceText
Education: $educationText
Skills: $skillsText$certLine

JOB DESCRIPTION:
$jobDescription

RESPOND WITH ONLY THIS JSON STRUCTURE (no markdown, no extra text):
{
  "matchScore": <0-100>,
  "matchAssessment": "<1 sentence on how well resume fits>",
  "tailoredSummary": "<2-3 sentences rewritten to match job requirements>",
  "tailoredExperience": [
    {
      "original": "<original position>",
      "tailored": "<rewritten description with job keywords, 3-4 lines>"
    }
  ],
  "topSkills": ["skill1", "skill2", "skill3", "skill4", "skill5"],
  "keywordsCovered": ["keyword1", "keyword2", "keyword3"],
  "improvementTips": [
    "Action 1",
    "Action 2",
    "Action 3"
  ]
}''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.5);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Optimize a structured resume for a specific job description.
  ///
  /// Returns a map containing:
  /// - `rewrittenSummary`: Job-targeted professional summary
  /// - `rewrittenExperience`: Experience entries rewritten for stronger fit
  /// - `rewrittenSkills`: ATS-aligned skills to emphasize
  /// - `keywordsAdded`: Keywords the rewrite intentionally added
  /// - `missingKeywordsAddressed`: Missing keywords now covered by the rewrite
  /// - `actionableSuggestions`: Follow-up suggestions outside the rewrite scope
  /// - `overallRationale`: Short explanation of the rewrite strategy
  static Future<Map<String, dynamic>> optimizeStructuredResumeForJob({
    required String apiKey,
    required Map<String, dynamic> resumeJson,
    required String jobDescription,
    List<String> missingKeywords = const <String>[],
    String tone = 'Professional',
    bool isPremium = false,
  }) async {
    if (!await hasRemainingUsage(isPremium: isPremium)) {
      throw AiUsageLimitException(
        'Daily AI usage limit reached. Upgrade to premium for unlimited access.',
      );
    }

    final personalInfo =
        resumeJson['personalInfo'] as Map<String, dynamic>? ?? {};
    final currentTitle =
        personalInfo['jobTitle']?.toString().trim().isNotEmpty == true
            ? personalInfo['jobTitle'].toString().trim()
            : 'Professional';
    final currentSummary = resumeJson['objective'] as String? ?? '';
    final experiences = (resumeJson['experience'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .take(4)
        .toList(growable: false);
    final skills = (resumeJson['skills'] as List? ?? const <dynamic>[])
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item['name']?.toString().trim() ?? '';
          }
          if (item is Map) {
            return item['name']?.toString().trim() ?? '';
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final projects = (resumeJson['projects'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .toList(growable: false);
    final education = (resumeJson['education'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .toList(growable: false);

    final experienceText = experiences.isEmpty
        ? 'No experience provided.'
        : experiences.asMap().entries.map((entry) {
            final exp = entry.value;
            final achievements =
                (exp['achievements'] as List? ?? const <dynamic>[])
                    .map((item) => item.toString().trim())
                    .where((item) => item.isNotEmpty)
                    .join(' | ');
            final achievementText =
                achievements.isEmpty ? '' : '\n   Achievements: $achievements';
            return '${entry.key + 1}. ${exp['position'] ?? ''} at ${exp['company'] ?? ''}\n'
                '   Description: ${exp['description'] ?? ''}$achievementText';
          }).join('\n');

    final projectText = projects.isEmpty
        ? 'No projects provided.'
        : projects.take(4).map((project) {
            final tech = (project['technologies'] as List? ?? const <dynamic>[])
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .join(', ');
            return '- ${project['title'] ?? ''}: ${project['description'] ?? ''}'
                '${tech.isEmpty ? '' : ' (Tech: $tech)'}';
          }).join('\n');

    final educationText = education.isEmpty
        ? 'No education provided.'
        : education.take(3).map((edu) {
            return '- ${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''} at ${edu['institution'] ?? ''}';
          }).join('\n');

    final missingKeywordText = missingKeywords.isEmpty
        ? 'No explicit missing keywords were detected by the local analyzer.'
        : missingKeywords.join(', ');

    final prompt =
        '''You are an expert ATS resume strategist. Rewrite this resume so it aligns better with the target job while remaining truthful.

Rules:
- Do not invent employers, titles, dates, degrees, certifications, or metrics.
- You may strengthen wording and reorganize phrasing for impact.
- Use the missing keywords when they fit naturally and honestly.
- Preserve the candidate's actual experience and seniority level.
- Focus on summary, experience, and skills.
- Return rewrittenExperience for at most the first 4 experience entries, preserving their original order.
- Keep each rewritten description concise enough to fit within 2-4 sentences.

TARGET TONE: $tone
TARGET ROLE: $currentTitle
MISSING KEYWORDS TO ADDRESS: $missingKeywordText

JOB DESCRIPTION:
$jobDescription

CURRENT SUMMARY:
$currentSummary

CURRENT EXPERIENCE:
$experienceText

CURRENT SKILLS:
${skills.join(', ')}

PROJECT CONTEXT:
$projectText

EDUCATION CONTEXT:
$educationText

Respond with strict JSON only in this exact structure:
{
  "rewrittenSummary": "<2-4 sentence summary>",
  "rewrittenExperience": [
    {
      "company": "<company name>",
      "position": "<same or improved position title>",
      "description": "<rewritten high-impact description paragraph>",
      "achievements": ["<bullet 1>", "<bullet 2>", "<bullet 3>"],
      "keywordsAdded": ["<keyword>"],
      "rationale": "<1 sentence explaining the improvement>"
    }
  ],
  "rewrittenSkills": ["<skill1>", "<skill2>", "<skill3>"],
  "keywordsAdded": ["<keyword1>", "<keyword2>"],
  "missingKeywordsAddressed": ["<keyword1>", "<keyword2>"],
  "actionableSuggestions": [
    "<suggestion 1>",
    "<suggestion 2>",
    "<suggestion 3>"
  ],
  "overallRationale": "<2 sentence summary of what changed and why>"
}
''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.45);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Optimize a free-text resume draft for a specific job description.
  ///
  /// Returns a map containing:
  /// - `optimizedResumeText`: Full rewritten draft text
  /// - `sectionRewrites`: Per-section before/after rewrite details
  /// - `keywordsAdded`: Keywords the rewrite intentionally added
  /// - `missingKeywordsAddressed`: Missing keywords now covered by the rewrite
  /// - `actionableSuggestions`: Follow-up recommendations outside the rewrite
  /// - `overallRationale`: Short explanation of the rewrite strategy
  static Future<Map<String, dynamic>> optimizeResumeTextForJob({
    required String apiKey,
    required String resumeText,
    required String jobDescription,
    List<String> missingKeywords = const <String>[],
    String tone = 'Professional',
    bool isPremium = false,
  }) async {
    if (!await hasRemainingUsage(isPremium: isPremium)) {
      throw AiUsageLimitException(
        'Daily AI usage limit reached. Upgrade to premium for unlimited access.',
      );
    }

    final missingKeywordText = missingKeywords.isEmpty
        ? 'No explicit missing keywords were detected by the local analyzer.'
        : missingKeywords.join(', ');

    final prompt =
        '''You are an expert ATS resume strategist. Rewrite the resume draft below for the target job.

Rules:
- Keep the candidate truthful. Do not invent employers, degrees, dates, or metrics.
- Strengthen wording, structure, and keyword coverage.
- Use the missing keywords only when they fit naturally and honestly.
- Preserve the candidate's intent and core facts.

TARGET TONE: $tone
MISSING KEYWORDS TO ADDRESS: $missingKeywordText

JOB DESCRIPTION:
$jobDescription

CURRENT RESUME DRAFT:
$resumeText

Respond with strict JSON only in this exact structure:
{
  "optimizedResumeText": "<full rewritten resume text>",
  "sectionRewrites": [
    {
      "sectionKey": "summary",
      "label": "Professional Summary",
      "originalText": "<original section text>",
      "optimizedText": "<rewritten section text>",
      "keywordsAdded": ["<keyword1>", "<keyword2>"],
      "rationale": "<1 sentence explanation>"
    }
  ],
  "keywordsAdded": ["<keyword1>", "<keyword2>"],
  "missingKeywordsAddressed": ["<keyword1>", "<keyword2>"],
  "actionableSuggestions": [
    "<suggestion 1>",
    "<suggestion 2>",
    "<suggestion 3>"
  ],
  "overallRationale": "<2 sentence summary of what changed and why>"
}
''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.45);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Fully rewrite an entire resume using AI for maximum professional impact.
  ///
  /// Returns a map containing:
  /// - `rewrittenSummary`: New professional summary
  /// - `rewrittenExperience`: List of maps with {company, position, description}
  /// - `rewrittenSkills`: List of refined skill name strings
  /// - `improvements`: Bullet list of changes made
  static Future<Map<String, dynamic>> rewriteFullResume({
    required String apiKey,
    required Map<String, dynamic> resumeJson,
    String tone = 'Professional',
    String? targetJobTitle,
    bool isPremium = false,
  }) async {
    if (!await hasRemainingUsage(isPremium: isPremium)) {
      throw AiUsageLimitException(
        'Daily AI usage limit reached. Upgrade to premium for unlimited access.',
      );
    }

    final personalInfo =
        resumeJson['personalInfo'] as Map<String, dynamic>? ?? {};
    final currentTitle = targetJobTitle?.isNotEmpty == true
        ? targetJobTitle!
        : (personalInfo['jobTitle'] ?? 'Professional');
    final currentSummary = resumeJson['objective'] as String? ?? '';
    final experiences = resumeJson['experience'] as List? ?? [];
    final skills = resumeJson['skills'] as List? ?? [];

    final expText = experiences.map((e) {
      final m = e as Map<String, dynamic>;
      return '  - ${m['position'] ?? ''} at ${m['company'] ?? ''}: ${m['description'] ?? ''}';
    }).join('\n');

    final skillsText = skills.map((s) {
      if (s is Map<String, dynamic>) return s['name'] ?? '';
      return s.toString();
    }).join(', ');

    final prompt = '''
You are a world-class resume writer. Rewrite the following resume content in a $tone tone targeting the role of "$currentTitle". Make every sentence impactful — use strong action verbs, add quantifiable achievement hints, and ensure ATS compatibility.

**CURRENT CONTENT:**
Summary: $currentSummary

Experience:
$expText

Skills: $skillsText

**OUTPUT FORMAT (strict JSON only):**

{
  "rewrittenSummary": "<2–3 sentence $tone professional summary targeting $currentTitle>",
  "rewrittenExperience": [
    {
      "company": "<same company name>",
      "position": "<same or improved position title>",
      "description": "<rewritten bullet-point-rich description, 3–5 lines, strong action verbs, metrics>"
    }
  ],
  "rewrittenSkills": ["<skill1>", "<skill2>", "...up to 12 most impactful skills>"],
  "improvements": ["<change 1>", "<change 2>", "<change 3>", "<change 4>"]
}

Respond ONLY with valid JSON. No markdown, no preamble, no trailing text.
''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.65);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Parse raw resume text and extract all structured fields.
  ///
  /// Returns a map containing all resume fields:
  /// - `fullName`, `email`, `phone`, `address`, `jobTitle`, `linkedIn`, `github`, `website`
  /// - `objective`: professional summary
  /// - `experience`: list of {company, position, location, startYear, startMonth, endYear, endMonth, isCurrentlyWorking, description, achievements}
  /// - `education`: list of {institution, degree, fieldOfStudy, startYear, endYear, isCurrentlyStudying, grade, description, location}
  /// - `skills`: list of skill name strings
  /// - `certifications`: list of {name, issuer, issueYear, expiryYear, credentialId, credentialUrl}
  /// - `languages`: list of {name, proficiency}
  /// - `projects`: list of {title, description, technologies, url, startYear, endYear}
  /// - `hobbies`: list of hobbies/interests
  /// - `references`: list of {name, position, company, email, phone, relationship}
  /// - `customSections`: list of {title, items[]}
  static Future<Map<String, dynamic>> parseResumeFromText({
    required String apiKey,
    required String resumeText,
  }) async {
    final prompt =
        '''You are an expert resume parser. Extract ALL information from the following resume text and return it as structured JSON. Be thorough — extract every detail you can find.

RESUME TEXT:
$resumeText

RESPOND WITH ONLY THIS JSON STRUCTURE (no markdown, no extra text):
{
  "fullName": "<full name or empty string>",
  "email": "<email or empty string>",
  "phone": "<phone number or empty string>",
  "address": "<city, country or empty string>",
  "jobTitle": "<current/target job title or empty string>",
  "linkedIn": "<LinkedIn URL or empty string>",
  "github": "<GitHub URL or empty string>",
  "website": "<website URL or empty string>",
  "objective": "<professional summary / objective, 2-3 sentences>",
  "experience": [
    {
      "company": "<company name>",
      "position": "<job title>",
      "location": "<city or empty string>",
      "startYear": <year as integer>,
      "startMonth": <month 1-12 as integer, or 1 if unknown>,
      "endYear": <year as integer or null if current>,
      "endMonth": <month 1-12 as integer or null if current>,
      "isCurrentlyWorking": <true or false>,
      "description": "<responsibilities and achievements as a paragraph>",
      "achievements": ["<achievement 1>", "<achievement 2>"]
    }
  ],
  "education": [
    {
      "institution": "<school/university name>",
      "degree": "<degree type e.g. Bachelor of Science>",
      "fieldOfStudy": "<major/field e.g. Computer Science>",
      "startYear": <year as integer>,
      "endYear": <year as integer or null if current>,
      "isCurrentlyStudying": <true or false>,
      "grade": "<GPA or grade or empty string>",
      "description": "<honors, coursework, thesis, or empty string>",
      "location": "<city or empty string>"
    }
  ],
  "skills": ["<skill1>", "<skill2>", "<skill3>"],
  "certifications": [
    {
      "name": "<certification name>",
      "issuer": "<issuing organization>",
      "issueYear": <year as integer or null>,
      "expiryYear": <year as integer or null>,
      "credentialId": "<credential id or empty string>",
      "credentialUrl": "<verification URL or empty string>"
    }
  ],
  "languages": [
    {
      "name": "<language name>",
      "proficiency": "<Native|Fluent|Advanced|Intermediate|Basic>"
    }
  ],
  "projects": [
    {
      "title": "<project name>",
      "description": "<project description>",
      "technologies": ["<tech1>", "<tech2>"],
      "url": "<URL or empty string>",
      "startYear": <year as integer or null>,
      "endYear": <year as integer or null>
    }
  ],
  "hobbies": ["<interest 1>", "<interest 2>"],
  "references": [
    {
      "name": "<reference name>",
      "position": "<reference title>",
      "company": "<reference company>",
      "email": "<reference email or empty string>",
      "phone": "<reference phone or empty string>",
      "relationship": "<relationship or empty string>"
    }
  ],
  "customSections": [
    {
      "title": "<section title such as Awards, Publications, Volunteer Experience>",
      "items": [
        {
          "title": "<item heading>",
          "subtitle": "<organization, role, or empty string>",
          "description": "<details or bullet summary>",
          "date": "<ISO date, year string, or empty string>"
        }
      ]
    }
  ]
}

Rules:
- Preserve all meaningful resume information. Do not omit sections that are present in the source text.
- If information does not fit the standard sections above, place it in `customSections` instead of dropping it.
- Keep dates numeric where requested; use null when unknown.
- Return empty arrays for missing list sections.
- Return ONLY valid JSON.''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.2);
      return normalizeParsedResumePayload(response);
    } catch (e) {
      rethrow;
    }
  }

  static Map<String, dynamic> normalizeParsedResumePayload(
    Map<String, dynamic> payload,
  ) {
    final personalInfo = _firstMap(payload, const <String>[
      'personalInfo',
      'contact',
      'contactInfo',
      'basics',
    ]);
    final profiles = _firstMap(payload, const <String>[
      'profiles',
      'links',
      'socialLinks',
    ]);

    final hobbies = _normalizeStringList(
      _firstPresent(payload, const <String>['hobbies', 'interests']),
    );
    final references = _normalizeReferences(
      _firstPresent(payload, const <String>['references', 'recommendations']),
    );

    return <String, dynamic>{
      'fullName': _firstString(
            payload,
            const <String>['fullName', 'name', 'candidateName'],
            extraMaps: <Map<String, dynamic>>[personalInfo],
          ) ??
          '',
      'email': _firstString(
            payload,
            const <String>['email'],
            extraMaps: <Map<String, dynamic>>[personalInfo],
          ) ??
          '',
      'phone': _firstString(
            payload,
            const <String>['phone', 'phoneNumber', 'mobile'],
            extraMaps: <Map<String, dynamic>>[personalInfo],
          ) ??
          '',
      'address': _firstString(
            payload,
            const <String>['address', 'location', 'city'],
            extraMaps: <Map<String, dynamic>>[personalInfo],
          ) ??
          '',
      'jobTitle': _firstString(
            payload,
            const <String>['jobTitle', 'title', 'headline', 'targetRole'],
            extraMaps: <Map<String, dynamic>>[personalInfo],
          ) ??
          '',
      'linkedIn': _firstString(
            payload,
            const <String>['linkedIn', 'linkedin', 'linkedinUrl'],
            extraMaps: <Map<String, dynamic>>[personalInfo, profiles],
          ) ??
          '',
      'github': _firstString(
            payload,
            const <String>['github', 'githubUrl'],
            extraMaps: <Map<String, dynamic>>[personalInfo, profiles],
          ) ??
          '',
      'website': _firstString(
            payload,
            const <String>['website', 'portfolio', 'portfolioUrl'],
            extraMaps: <Map<String, dynamic>>[personalInfo, profiles],
          ) ??
          '',
      'objective': _firstString(
            payload,
            const <String>[
              'objective',
              'summary',
              'professionalSummary',
              'profile',
              'about',
            ],
          ) ??
          '',
      'experience': _normalizeExperience(
        _firstPresent(
          payload,
          const <String>[
            'experience',
            'experiences',
            'workExperience',
            'workHistory',
            'employmentHistory',
          ],
        ),
      ),
      'education': _normalizeEducation(
        _firstPresent(
          payload,
          const <String>['education', 'educations', 'academicHistory'],
        ),
      ),
      'skills': _normalizeSkills(
        _firstPresent(
          payload,
          const <String>['skills', 'technicalSkills', 'coreCompetencies'],
        ),
      ),
      'certifications': _normalizeCertifications(
        _firstPresent(
          payload,
          const <String>['certifications', 'certificates', 'licenses'],
        ),
      ),
      'languages': _normalizeLanguages(
        _firstPresent(
            payload, const <String>['languages', 'languageProficiencies']),
      ),
      'projects': _normalizeProjects(
        _firstPresent(
          payload,
          const <String>['projects', 'projectExperience', 'portfolioProjects'],
        ),
      ),
      'hobbies': hobbies,
      'references': references,
      'customSections': _normalizeCustomSections(payload),
    };
  }

  static const Map<String, String> _extraCustomSectionLabels = <String, String>{
    'awards': 'Awards',
    'honors': 'Honors',
    'publications': 'Publications',
    'volunteerExperience': 'Volunteer Experience',
    'volunteering': 'Volunteer Experience',
    'leadership': 'Leadership',
    'achievements': 'Achievements',
    'memberships': 'Memberships',
    'workshops': 'Workshops',
    'trainings': 'Training',
    'internships': 'Internships',
    'activities': 'Activities',
    'extracurriculars': 'Extracurricular Activities',
    'patents': 'Patents',
    'conferences': 'Conferences',
  };

  static Map<String, dynamic> _firstMap(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }
    return <String, dynamic>{};
  }

  static dynamic _firstPresent(
      Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      if (payload.containsKey(key) && payload[key] != null) {
        return payload[key];
      }
    }
    return null;
  }

  static String? _firstString(
    Map<String, dynamic> payload,
    List<String> keys, {
    List<Map<String, dynamic>> extraMaps = const <Map<String, dynamic>>[],
  }) {
    final sources = <Map<String, dynamic>>[payload, ...extraMaps];
    for (final source in sources) {
      for (final key in keys) {
        final value = _stringValue(source[key]);
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _normalizeExperience(dynamic value) {
    return _mapList(value).map((entry) {
      return <String, dynamic>{
        'company': _stringValue(entry['company']) ??
            _stringValue(entry['employer']) ??
            '',
        'position': _stringValue(entry['position']) ??
            _stringValue(entry['title']) ??
            _stringValue(entry['role']) ??
            '',
        'location': _stringValue(entry['location']) ??
            _stringValue(entry['city']) ??
            '',
        'startYear':
            _intValue(entry['startYear']) ?? _intValue(entry['fromYear']),
        'startMonth': _intValue(entry['startMonth']) ??
            _intValue(entry['fromMonth']) ??
            1,
        'endYear': _intValue(entry['endYear']) ?? _intValue(entry['toYear']),
        'endMonth': _intValue(entry['endMonth']) ?? _intValue(entry['toMonth']),
        'isCurrentlyWorking': _boolValue(entry['isCurrentlyWorking']) ??
            _boolValue(entry['current']) ??
            (_stringValue(entry['endDate']) == null &&
                (_intValue(entry['endYear']) == null)),
        'description': _joinedText(
              entry['description'] ??
                  entry['summary'] ??
                  entry['responsibilities'] ??
                  entry['details'],
            ) ??
            '',
        'achievements': _normalizeStringList(
          entry['achievements'] ?? entry['highlights'] ?? entry['bullets'],
        ),
      };
    }).where((entry) {
      return (entry['company'] as String).isNotEmpty ||
          (entry['position'] as String).isNotEmpty ||
          (entry['description'] as String).isNotEmpty ||
          (entry['achievements'] as List).isNotEmpty;
    }).toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeEducation(dynamic value) {
    return _mapList(value).map((entry) {
      return <String, dynamic>{
        'institution': _stringValue(entry['institution']) ??
            _stringValue(entry['school']) ??
            _stringValue(entry['university']) ??
            '',
        'degree': _stringValue(entry['degree']) ?? '',
        'fieldOfStudy': _stringValue(entry['fieldOfStudy']) ??
            _stringValue(entry['major']) ??
            _stringValue(entry['field']) ??
            '',
        'startYear': _intValue(entry['startYear']),
        'endYear': _intValue(entry['endYear']),
        'isCurrentlyStudying': _boolValue(entry['isCurrentlyStudying']) ??
            _boolValue(entry['current']) ??
            false,
        'grade':
            _stringValue(entry['grade']) ?? _stringValue(entry['gpa']) ?? '',
        'description':
            _joinedText(entry['description'] ?? entry['details']) ?? '',
        'location': _stringValue(entry['location']) ??
            _stringValue(entry['city']) ??
            '',
      };
    }).where((entry) {
      return (entry['institution'] as String).isNotEmpty ||
          (entry['degree'] as String).isNotEmpty ||
          (entry['fieldOfStudy'] as String).isNotEmpty ||
          (entry['description'] as String).isNotEmpty;
    }).toList(growable: false);
  }

  static List<String> _normalizeSkills(dynamic value) {
    final results = <String>[];
    final seen = <String>{};

    void addEntry(dynamic entry) {
      final normalized = entry is Map
          ? _stringValue(
              (entry)['name'] ??
                  entry['skill'] ??
                  entry['title'] ??
                  entry['technology'],
            )
          : _stringValue(entry);
      if (normalized == null) {
        return;
      }
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        results.add(normalized);
      }
    }

    if (value is Map) {
      for (final entry in (value).values) {
        for (final item in _listValue(entry)) {
          addEntry(item);
        }
      }
    } else {
      for (final entry in _listValue(value)) {
        addEntry(entry);
      }
    }

    return List<String>.unmodifiable(results);
  }

  static List<Map<String, dynamic>> _normalizeCertifications(dynamic value) {
    return _mapList(value).map((entry) {
      return <String, dynamic>{
        'name':
            _stringValue(entry['name']) ?? _stringValue(entry['title']) ?? '',
        'issuer': _stringValue(entry['issuer']) ??
            _stringValue(entry['organization']) ??
            '',
        'issueYear': _intValue(entry['issueYear']),
        'expiryYear': _intValue(entry['expiryYear']),
        'credentialId': _stringValue(entry['credentialId']) ?? '',
        'credentialUrl': _stringValue(entry['credentialUrl']) ??
            _stringValue(entry['url']) ??
            '',
      };
    }).where((entry) {
      return (entry['name'] as String).isNotEmpty ||
          (entry['issuer'] as String).isNotEmpty;
    }).toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeLanguages(dynamic value) {
    return _listValue(value)
        .map((entry) {
          if (entry is Map) {
            final map = Map<String, dynamic>.from(entry);
            return <String, dynamic>{
              'name': _stringValue(map['name']) ??
                  _stringValue(map['language']) ??
                  '',
              'proficiency': _stringValue(map['proficiency']) ??
                  _stringValue(map['level']) ??
                  'Professional',
            };
          }
          return <String, dynamic>{
            'name': _stringValue(entry) ?? '',
            'proficiency': 'Professional',
          };
        })
        .where((entry) => (entry['name'] as String).isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeProjects(dynamic value) {
    return _mapList(value).map((entry) {
      return <String, dynamic>{
        'title':
            _stringValue(entry['title']) ?? _stringValue(entry['name']) ?? '',
        'description': _joinedText(
              entry['description'] ?? entry['summary'] ?? entry['details'],
            ) ??
            '',
        'technologies': _normalizeStringList(
          entry['technologies'] ?? entry['techStack'],
        ),
        'url': _stringValue(entry['url']) ??
            _stringValue(entry['link']) ??
            _stringValue(entry['website']) ??
            '',
        'startYear': _intValue(entry['startYear']),
        'endYear': _intValue(entry['endYear']),
      };
    }).where((entry) {
      return (entry['title'] as String).isNotEmpty ||
          (entry['description'] as String).isNotEmpty ||
          (entry['technologies'] as List).isNotEmpty;
    }).toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeReferences(dynamic value) {
    return _listValue(value).map((entry) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        return <String, dynamic>{
          'name': _stringValue(map['name']) ?? '',
          'position':
              _stringValue(map['position']) ?? _stringValue(map['title']) ?? '',
          'company': _stringValue(map['company']) ??
              _stringValue(map['organization']) ??
              '',
          'email': _stringValue(map['email']) ?? '',
          'phone': _stringValue(map['phone']) ?? '',
          'relationship': _stringValue(map['relationship']) ??
              _stringValue(map['relation']) ??
              '',
        };
      }
      return <String, dynamic>{
        'name': _stringValue(entry) ?? '',
        'position': '',
        'company': '',
        'email': '',
        'phone': '',
        'relationship': '',
      };
    }).where((entry) {
      return (entry['name'] as String).isNotEmpty ||
          (entry['company'] as String).isNotEmpty ||
          (entry['email'] as String).isNotEmpty ||
          (entry['phone'] as String).isNotEmpty;
    }).toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeCustomSections(
    Map<String, dynamic> payload,
  ) {
    final sections = <Map<String, dynamic>>[];

    for (final section in _mapList(
      _firstPresent(
          payload, const <String>['customSections', 'additionalSections']),
    )) {
      final normalized = _normalizeCustomSection(section, fallbackTitle: null);
      if (normalized != null) {
        sections.add(normalized);
      }
    }

    final nestedSections = _firstMap(
      payload,
      const <String>['sections', 'additionalInfo', 'extraSections'],
    );
    for (final entry in nestedSections.entries) {
      final normalized = _normalizeCustomSection(
        entry.value,
        fallbackTitle: _labelForSectionKey(entry.key),
      );
      if (normalized != null) {
        sections.add(normalized);
      }
    }

    for (final entry in _extraCustomSectionLabels.entries) {
      final normalized = _normalizeCustomSection(
        payload[entry.key],
        fallbackTitle: entry.value,
      );
      if (normalized != null) {
        sections.add(normalized);
      }
    }

    final deduped = <String, Map<String, dynamic>>{};
    for (final section in sections) {
      final key = (_stringValue(section['title']) ?? '').toLowerCase();
      if (key.isEmpty) {
        continue;
      }
      deduped[key] = section;
    }
    return deduped.values.toList(growable: false);
  }

  static Map<String, dynamic>? _normalizeCustomSection(
    dynamic value, {
    required String? fallbackTitle,
  }) {
    if (value == null) {
      return null;
    }

    String? title = fallbackTitle;
    dynamic itemsSource = value;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      title = _stringValue(map['title']) ??
          _stringValue(map['name']) ??
          _stringValue(map['heading']) ??
          fallbackTitle;
      itemsSource = map['items'] ?? map['entries'] ?? map['content'] ?? map;
    }

    final items = _normalizeCustomSectionItems(itemsSource);
    if ((title ?? '').trim().isEmpty || items.isEmpty) {
      return null;
    }

    return <String, dynamic>{
      'title': title,
      'items': items,
    };
  }

  static List<Map<String, dynamic>> _normalizeCustomSectionItems(
      dynamic value) {
    if (value is Map) {
      final item = _normalizeCustomSectionItem(
        Map<String, dynamic>.from(value),
      );
      return item == null
          ? const <Map<String, dynamic>>[]
          : <Map<String, dynamic>>[item];
    }

    return _listValue(value)
        .map((entry) {
          if (entry is Map) {
            return _normalizeCustomSectionItem(
              Map<String, dynamic>.from(entry),
            );
          }
          final text = _stringValue(entry);
          if (text == null) {
            return null;
          }
          return <String, dynamic>{
            'title': text,
            'subtitle': '',
            'description': '',
            'date': '',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic>? _normalizeCustomSectionItem(
    Map<String, dynamic> item,
  ) {
    final title = _stringValue(item['title']) ??
        _stringValue(item['heading']) ??
        _stringValue(item['name']);
    final subtitle = _stringValue(item['subtitle']) ??
        _stringValue(item['role']) ??
        _stringValue(item['organization']) ??
        '';
    final description = _joinedText(
          item['description'] ??
              item['content'] ??
              item['details'] ??
              item['summary'],
        ) ??
        '';
    final date = _stringValue(item['date']) ?? _stringValue(item['year']) ?? '';

    if ([title, subtitle, description, date]
        .every((value) => (value ?? '').isEmpty)) {
      return null;
    }

    return <String, dynamic>{
      'title': title ?? '',
      'subtitle': subtitle,
      'description': description,
      'date': date,
    };
  }

  static String _labelForSectionKey(String key) {
    if (_extraCustomSectionLabels.containsKey(key)) {
      return _extraCustomSectionLabels[key]!;
    }
    final words = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}')
        .replaceAll('_', ' ')
        .trim()
        .split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    return _listValue(value)
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  static List<dynamic> _listValue(dynamic value) {
    if (value is List) {
      return value;
    }
    if (value is String) {
      return value
          .split(RegExp(r'[\n,;|]+'))
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <dynamic>[];
  }

  static List<String> _normalizeStringList(dynamic value) {
    final seen = <String>{};
    final results = <String>[];

    for (final entry in _listValue(value)) {
      final normalized = entry is Map
          ? _stringValue(
              (entry)['name'] ??
                  entry['title'] ??
                  entry['value'] ??
                  entry['label'],
            )
          : _stringValue(entry);
      if (normalized == null) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        results.add(normalized);
      }
    }

    return List<String>.unmodifiable(results);
  }

  static String? _joinedText(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is List) {
      final items = value
          .map(_stringValue)
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      return items.isEmpty ? null : items.join('\n');
    }
    return null;
  }

  static String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  static bool? _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }
    final text = _stringValue(value)?.toLowerCase();
    if (text == null) {
      return null;
    }
    if (text == 'true' || text == 'yes' || text == 'present') {
      return true;
    }
    if (text == 'false' || text == 'no') {
      return false;
    }
    return null;
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final text = _stringValue(value);
    return text == null ? null : int.tryParse(text);
  }

  /// Generate professional bullet points for a job experience entry.
  ///
  /// Returns a map with key `bullets` (List of strings).
  static Future<Map<String, dynamic>> generateBulletPoints({
    required String apiKey,
    required String jobTitle,
    required String company,
    required String industry,
    required String existingDescription,
    bool isPremium = false,
  }) async {
    final context = existingDescription.isNotEmpty
        ? '\n\nExisting description to improve: $existingDescription'
        : '';

    final prompt =
        '''You are an expert resume writer. Generate 5 powerful, ATS-optimised bullet points for the following work experience entry.

Job Title: $jobTitle
Company: $company
Industry: $industry$context

Rules:
- Start each bullet with a strong action verb (not "Responsible for" or "Helped")
- Include quantifiable metrics wherever plausible (%, \$, counts, time savings)
- Each bullet must be ONE concise sentence (max 20 words)
- Bullets must be distinct — no repeating the same theme

RESPOND ONLY with this JSON:
{"bullets": ["<bullet 1>", "<bullet 2>", "<bullet 3>", "<bullet 4>", "<bullet 5>"]}''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.65);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Brutally critique a resume (Roast My Resume feature).
  ///
  /// Returns a map with keys: `grade`, `overallScore`, `scores` (map by category),
  /// `roast` (entertaining critique paragraph), `improvements` (list of strings).
  static Future<Map<String, dynamic>> roastResume({
    required String apiKey,
    required Map<String, dynamic> resumeJson,
    bool isPremium = false,
  }) async {
    final personalInfo =
        resumeJson['personalInfo'] as Map<String, dynamic>? ?? {};
    final currentTitle =
        personalInfo['jobTitle'] ?? resumeJson['title'] ?? 'Professional';
    final summary = resumeJson['objective'] as String? ??
        resumeJson['summary'] as String? ??
        '';
    final experiences = resumeJson['experience'] as List? ?? [];
    final skills = resumeJson['skills'] as List? ?? [];
    final education = resumeJson['education'] as List? ?? [];

    final expText = experiences.isEmpty
        ? 'None'
        : experiences.take(4).map((e) {
            if (e is String) return e;
            final m = e as Map<String, dynamic>;
            return '${m['position'] ?? ''} at ${m['company'] ?? ''}: ${m['description'] ?? ''}';
          }).join(' | ');

    final skillsText = skills.isEmpty
        ? 'None'
        : skills.take(12).map((s) {
            if (s is Map<String, dynamic>) return s['name'] ?? '';
            return s.toString();
          }).join(', ');

    final eduText = education.isEmpty
        ? 'None'
        : education.take(2).map((e) {
            if (e is String) return e;
            final m = e as Map<String, dynamic>;
            return '${m['degree'] ?? ''} from ${m['institution'] ?? ''}';
          }).join(' | ');

    final prompt =
        '''You are a brutally honest, witty resume critic — like a Gordon Ramsay for resumes. Roast this resume with sharp, funny, but constructive criticism. Be entertaining, not mean-spirited.

RESUME:
Title: $currentTitle
Summary: $summary
Experience: $expText
Education: $eduText
Skills: $skillsText

Score the resume from 0–100 across five categories. Assign a letter grade (A–F). Write one entertaining roast paragraph (3–5 sentences). List 4 concrete improvements.

RESPOND ONLY with this JSON (no markdown):
{
  "grade": "<A|B|C|D|F>",
  "overallScore": <0-100>,
  "scores": {
    "impact": <0-100>,
    "clarity": <0-100>,
    "skills": <0-100>,
    "formatting": <0-100>,
    "atsCompatibility": <0-100>
  },
  "roast": "<3-5 sentences of witty, pointed critique>",
  "improvements": ["<improvement 1>", "<improvement 2>", "<improvement 3>", "<improvement 4>"]
}''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.75);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get country-specific resume style tips and AI-adapted content.
  ///
  /// Returns a map with keys: `countryName`, `keyDifferences` (list),
  /// `adaptedSummary`, `formatTips` (list), `doList` (list), `dontList` (list).
  static Future<Map<String, dynamic>> convertResumeStyle({
    required String apiKey,
    required Map<String, dynamic> resumeJson,
    required String targetCountry,
    bool isPremium = false,
  }) async {
    final personalInfo =
        resumeJson['personalInfo'] as Map<String, dynamic>? ?? {};
    final currentTitle =
        personalInfo['jobTitle'] ?? resumeJson['title'] ?? 'Professional';
    final summary = resumeJson['objective'] as String? ??
        resumeJson['summary'] as String? ??
        '';

    final prompt =
        '''You are an expert in international resume standards. Adapt this resume for the job market in $targetCountry.

Resume title: $currentTitle
Current summary: $summary

Provide:
1. Key resume differences for $targetCountry vs standard
2. An adapted professional summary (2-3 sentences) following $targetCountry norms
3. Formatting guidance specific to $targetCountry
4. 4 DOs and 4 DON'Ts for resumes in $targetCountry

RESPOND ONLY with this JSON (no markdown):
{
  "countryName": "$targetCountry",
  "keyDifferences": ["<difference 1>", "<difference 2>", "<difference 3>", "<difference 4>"],
  "adaptedSummary": "<2-3 sentences in $targetCountry style>",
  "formatTips": ["<tip 1>", "<tip 2>", "<tip 3>"],
  "doList": ["<do 1>", "<do 2>", "<do 3>", "<do 4>"],
  "dontList": ["<dont 1>", "<dont 2>", "<dont 3>", "<dont 4>"]
}''';

    try {
      final response = await _callGeminiApi(apiKey, prompt, temperature: 0.55);
      await _incrementUsage();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Internal method to call Together AI API
  static Future<Map<String, dynamic>> _callGeminiApi(
    String apiKey,
    String prompt, {
    double temperature = 0.7,
    bool preferJsonObjectMode = true,
  }) async {
    // Strip whitespace, then remove any non-ASCII characters (code points > 127).
    // The browser's fetch API requires HTTP header values to be ISO-8859-1 safe,
    // so invisible Unicode chars (zero-width spaces, curly quotes, etc.) copied
    // alongside the key will cause "String contains non ISO-8859-1 code point".
    final trimmedKey = _normalizeApiKey(apiKey);
    if (trimmedKey.isEmpty) {
      throw AiConfigException(
        'AI service is currently unavailable. Please try again later.',
      );
    }
    if (!_looksLikeGroqApiKey(trimmedKey)) {
      throw AiConfigException(
        'AI service configuration is invalid right now. Please try again later.',
      );
    }

    final url = Uri.parse(_groqEndpoint);

    final requestBody = <String, dynamic>{
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert resume writer. Always respond with a single valid JSON object only, with no markdown and no extra text.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': temperature,
      'max_tokens': 2048,
    };

    if (preferJsonObjectMode) {
      requestBody['response_format'] = {
        'type': 'json_object',
      };
    }

    final body = jsonEncode(requestBody);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $trimmedKey',
        },
        body: utf8.encode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;

        if (choices == null || choices.isEmpty) {
          throw AiResponseException('No response generated. Please try again.');
        }

        final message = choices[0]['message'] as Map<String, dynamic>?;

        if (message == null) {
          throw AiResponseException(
              'Invalid API response format. Please try again.');
        }

        final text = _extractMessageContent(message, choices[0]);

        if (text == null || text.isEmpty) {
          throw AiResponseException(
              'Empty response received. Please ensure your API key is valid and try again.');
        }

        // Parse the JSON response
        try {
          final cleanText = _cleanJsonResponseText(text);

          return _decodeJsonObjectResponse(cleanText);
        } catch (e) {
          throw AiResponseException(
              'Failed to parse AI response. Please try again.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        String errorMsg =
            'AI service is currently unavailable. Please try again later.';
        try {
          final errorData = jsonDecode(response.body);
          final detail =
              (errorData['error']?['message'] ?? errorData['message'])
                  ?.toString();
          if (detail != null && detail.isNotEmpty) {
            final lowerDetail = detail.toLowerCase();
            if (!(lowerDetail.contains('api key') ||
                lowerDetail.contains('authentication') ||
                lowerDetail.contains('unauthorized'))) {
              errorMsg = 'AI service request was rejected: $detail';
            }
          }
        } catch (_) {}
        throw AiConfigException(errorMsg);
      } else if (response.statusCode == 429) {
        throw AiRateLimitException(
            'API rate limit exceeded. Please wait a few minutes and try again.');
      } else if (response.statusCode == 400) {
        // Parse error message from response body
        String errorMsg = 'Bad request (400).';
        dynamic errorData;
        try {
          errorData = jsonDecode(response.body);
          final detail = errorData['error']?['message'] ??
              errorData['message'] ??
              errorData.toString();
          errorMsg = 'API Error: $detail';
        } catch (_) {
          errorMsg = 'API Error (400): ${response.body}';
        }

        if (preferJsonObjectMode &&
            _isJsonGenerationFailure(errorData, response.body)) {
          final fallbackTemperature = temperature > 0.35 ? 0.35 : temperature;
          return _callGeminiApi(
            apiKey,
            prompt,
            temperature: fallbackTemperature,
            preferJsonObjectMode: false,
          );
        }

        throw AiResponseException(errorMsg);
      } else {
        String errorMsg = 'API error (${response.statusCode}).';
        try {
          final errorData = jsonDecode(response.body);
          final detail = errorData['error']?['message'] ?? errorData['message'];
          if (detail != null) errorMsg = 'API Error: $detail';
        } catch (_) {}
        throw AiResponseException(errorMsg);
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiResponseException('Network error: ${e.toString()}');
    }
  }

  static String _normalizeApiKey(String apiKey) {
    return String.fromCharCodes(
      apiKey.trim().codeUnits.where((c) => c >= 0x20 && c <= 0x7E),
    );
  }

  static bool _looksLikeGroqApiKey(String apiKey) {
    return apiKey.startsWith('gsk_');
  }

  static String? _extractMessageContent(
    Map<String, dynamic> message,
    dynamic choice,
  ) {
    final directContent = message['content'];
    if (directContent is String && directContent.trim().isNotEmpty) {
      return directContent;
    }
    if (directContent is List) {
      final parts = directContent
          .map((part) {
            if (part is Map) {
              final text = part['text'] ?? part['content'] ?? part['value'];
              return text?.toString().trim() ?? '';
            }
            return part?.toString().trim() ?? '';
          })
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
    }

    final fallbackText = choice is Map ? choice['text'] : null;
    if (fallbackText is String && fallbackText.trim().isNotEmpty) {
      return fallbackText;
    }

    return null;
  }

  static String _cleanJsonResponseText(String text) {
    var cleanText = text.trim();
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    }
    if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }
    cleanText = cleanText.trim();

    final objectStart = cleanText.indexOf('{');
    final objectEnd = cleanText.lastIndexOf('}');
    if (objectStart != -1 && objectEnd != -1 && objectEnd > objectStart) {
      cleanText = cleanText.substring(objectStart, objectEnd + 1);
    }

    return cleanText.trim();
  }

  static bool _isJsonGenerationFailure(dynamic errorData, String rawBody) {
    final topLevel = errorData is Map ? errorData : const <dynamic, dynamic>{};
    final nestedError = topLevel['error'] is Map
        ? topLevel['error'] as Map
        : const <dynamic, dynamic>{};

    final candidates = <String>[
      rawBody,
      errorData?.toString() ?? '',
      topLevel['message']?.toString() ?? '',
      topLevel['code']?.toString() ?? '',
      topLevel['type']?.toString() ?? '',
      nestedError['message']?.toString() ?? '',
      nestedError['code']?.toString() ?? '',
      nestedError['type']?.toString() ?? '',
    ].map((value) => value.toLowerCase()).toList(growable: false);

    return candidates.any(
      (value) =>
          value.contains('failed to generate json') ||
          value.contains('failed_generation') ||
          value.contains('json_object'),
    );
  }

  static Map<String, dynamic> _decodeJsonObjectResponse(String text) {
    final normalizedQuotes = text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
    final withoutTrailingCommas = normalizedQuotes.replaceAll(
      RegExp(r',\s*([}\]])'),
      r'$1',
    );

    final candidates = <String>{
      text,
      normalizedQuotes,
      withoutTrailingCommas,
    };

    for (final candidate in candidates) {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        final first = decoded.first as Map;
        return first.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    throw const FormatException('Response is not a JSON object.');
  }
}

// ── Custom Exceptions ──

abstract class AiException implements Exception {
  final String message;
  AiException(this.message);

  @override
  String toString() => message;
}

class AiUsageLimitException extends AiException {
  AiUsageLimitException(super.message);
}

class AiConfigException extends AiException {
  AiConfigException(super.message);
}

class AiRateLimitException extends AiException {
  AiRateLimitException(super.message);
}

class AiResponseException extends AiException {
  AiResponseException(super.message);
}

// ── Providers ──

/// Provider for AI settings (API key storage)
final aiApiKeyProvider = FutureProvider<String>((ref) async {
  return AiApiKeyStorageService.read();
});

/// Provider for remaining AI usage
final aiRemainingUsageProvider =
    FutureProvider.family<int, bool>((ref, isPremium) async {
  return AiResumeService.getRemainingUsage(isPremium: isPremium);
});
