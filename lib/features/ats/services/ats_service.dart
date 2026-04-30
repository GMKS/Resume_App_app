import '../../../core/models/resume_model.dart';

/// Result of an ATS analysis run.
class ATSResult {
  final int score; // 0-100
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<ATSIssue> formattingIssues;
  final List<ATSIssue> weakVerbIssues;
  final List<ATSSuggestion> suggestions;
  final int keywordScore; // 0-40
  final int contactScore; // 0-20
  final int structureScore; // 0-20
  final int verbScore; // 0-10
  final int summaryScore; // 0-10

  const ATSResult({
    required this.score,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.formattingIssues,
    required this.weakVerbIssues,
    required this.suggestions,
    required this.keywordScore,
    required this.contactScore,
    required this.structureScore,
    required this.verbScore,
    required this.summaryScore,
  });
}

class ATSIssue {
  final String title;
  final String detail;
  final ATSSeverity severity;

  const ATSIssue({
    required this.title,
    required this.detail,
    required this.severity,
  });
}

class ATSSuggestion {
  final String title;
  final String description;
  final ATSSeverity priority;

  const ATSSuggestion({
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum ATSSeverity { high, medium, low }

class ATSService {
  // Common stop words to ignore during keyword extraction
  static const _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
    'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
    'would', 'could', 'should', 'may', 'might', 'shall', 'can', 'that',
    'this', 'these', 'those', 'i', 'you', 'we', 'they', 'he', 'she', 'it',
    'our', 'your', 'their', 'my', 'its', 'not', 'also', 'such', 'than',
    'then', 'so', 'no', 'up', 'out', 'if', 'about', 'who', 'which', 'all',
    'each', 'both', 'more', 'must', 'any', 'few', 'most', 'other', 'into',
    'through', 'during', 'before', 'after', 'above', 'below', 'between',
    'while', 'using', 'including',
  };

  // Weak action verbs to flag
  static const _weakVerbs = {
    'responsible for', 'helped', 'assisted with', 'worked on', 'involved in',
    'participated in', 'was part of', 'contributed to', 'made', 'did',
    'handled', 'dealt with', 'took care of', 'helped with', 'worked with',
  };

  // Strong action verbs
  static const _strongVerbs = [
    'Achieved', 'Accelerated', 'Accomplished', 'Architected', 'Automated',
    'Built', 'Championed', 'Collaborated', 'Created', 'Decreased',
    'Delivered', 'Designed', 'Developed', 'Drove', 'Enhanced',
    'Established', 'Executed', 'Expanded', 'Generated', 'Grew',
    'Implemented', 'Improved', 'Increased', 'Initiated', 'Integrated',
    'Launched', 'Led', 'Managed', 'Maximized', 'Mentored',
    'Migrated', 'Optimized', 'Oversaw', 'Pioneered', 'Reduced',
    'Revamped', 'Scaled', 'Spearheaded', 'Streamlined', 'Transformed',
  ];

  /// Extracts meaningful keywords from a block of text.
  static Set<String> _extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();
    return words;
  }

  /// Extracts all text content from a resume.
  static String _resumeToText(ResumeModel resume) {
    final buffer = StringBuffer();
    buffer.writeln(resume.personalInfo.fullName);
    buffer.writeln(resume.personalInfo.jobTitle ?? '');
    buffer.writeln(resume.objective ?? '');
    for (final exp in resume.experience) {
      buffer.writeln(exp.position);
      buffer.writeln(exp.company);
      buffer.writeln(exp.description);
    }
    for (final edu in resume.education) {
      buffer.writeln(edu.degree);
      buffer.writeln(edu.fieldOfStudy);
      buffer.writeln(edu.institution);
    }
    for (final skill in resume.skills) {
      buffer.writeln(skill.name);
    }
    for (final proj in resume.projects) {
      buffer.writeln(proj.title);
      buffer.writeln(proj.description);
      buffer.writeln(proj.technologies.join(' '));
    }
    for (final cert in resume.certifications) {
      buffer.writeln(cert.name);
      buffer.writeln(cert.issuer);
    }
    return buffer.toString();
  }

  /// Analyses a resume against an optional job description and returns
  /// a detailed [ATSResult].
  static ATSResult analyse(ResumeModel resume, String jobDescription) {
    final resumeText = _resumeToText(resume);
    final resumeKeywords = _extractKeywords(resumeText);

    // ── Keyword score (0-40) ────────────────────────────────────────────────
    final jobKeywords = jobDescription.trim().isEmpty
        ? <String>{}
        : _extractKeywords(jobDescription);

    List<String> matched = [];
    List<String> missing = [];

    if (jobKeywords.isNotEmpty) {
      matched = jobKeywords.intersection(resumeKeywords).toList()
        ..sort();
      missing = jobKeywords.difference(resumeKeywords).toList()
        ..sort();
    } else {
      // No JD provided – nothing to match
      matched = [];
      missing = [];
    }

    int keywordScore;
    if (jobKeywords.isEmpty) {
      keywordScore = 25; // Neutral when no JD provided
    } else {
      final ratio = matched.length / jobKeywords.length;
      keywordScore = (ratio * 40).round().clamp(0, 40);
    }

    // ── Contact score (0-20) ────────────────────────────────────────────────
    int contactScore = 0;
    final pi = resume.personalInfo;
    if (pi.fullName.isNotEmpty) contactScore += 5;
    if (pi.email.isNotEmpty) contactScore += 5;
    if (pi.phone.isNotEmpty) contactScore += 5;
    if ((pi.address.isNotEmpty) ||
        (pi.linkedIn?.isNotEmpty ?? false) ||
        (pi.website?.isNotEmpty ?? false)) {
      contactScore += 5;
    }

    // ── Structure score (0-20) ──────────────────────────────────────────────
    int structureScore = 0;
    if (resume.experience.isNotEmpty) structureScore += 5;
    if (resume.education.isNotEmpty) structureScore += 5;
    if (resume.skills.isNotEmpty) structureScore += 5;
    if (resume.projects.isNotEmpty || resume.certifications.isNotEmpty) {
      structureScore += 5;
    }

    // ── Summary score (0-10) ────────────────────────────────────────────────
    int summaryScore = 0;
    if (resume.objective?.isNotEmpty ?? false) summaryScore = 10;

    // ── Verb score (0-10) ───────────────────────────────────────────────────
    final resumeLower = resumeText.toLowerCase();
    int weakCount = 0;
    final List<ATSIssue> weakVerbIssues = [];

    for (final phrase in _weakVerbs) {
      if (resumeLower.contains(phrase)) {
        weakCount++;
        weakVerbIssues.add(ATSIssue(
          title: 'Weak phrase: "$phrase"',
          detail: 'Replace with a strong action verb (e.g. Led, Managed, Built)',
          severity: ATSSeverity.medium,
        ));
      }
    }

    // Deduct up to 10 pts for weak verbs
    int verbScore = (10 - (weakCount * 3)).clamp(0, 10);

    // ── Formatting issues ────────────────────────────────────────────────────
    final List<ATSIssue> formattingIssues = [];

    if (pi.fullName.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'Missing full name',
        detail: 'Add your full name in Personal Information',
        severity: ATSSeverity.high,
      ));
    }
    if (pi.email.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'Missing email address',
        detail: 'ATS systems require an email address',
        severity: ATSSeverity.high,
      ));
    }
    if (pi.phone.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'Missing phone number',
        detail: 'Add your phone number for recruiters to reach you',
        severity: ATSSeverity.high,
      ));
    }
    if (resume.experience.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'No work experience added',
        detail: 'Work experience is the most important section for ATS',
        severity: ATSSeverity.high,
      ));
    }
    if (resume.education.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'No education section',
        detail: 'Add your educational background',
        severity: ATSSeverity.medium,
      ));
    }
    if (resume.skills.isEmpty) {
      formattingIssues.add(const ATSIssue(
        title: 'No skills listed',
        detail: 'Skills are heavily scanned by ATS — add relevant skills',
        severity: ATSSeverity.high,
      ));
    }
    if (!(resume.objective?.isNotEmpty ?? false)) {
      formattingIssues.add(const ATSIssue(
        title: 'No professional summary',
        detail: 'A summary helps ATS match you to the job faster',
        severity: ATSSeverity.medium,
      ));
    }
    // Check for very short experience descriptions
    for (final exp in resume.experience) {
      if (exp.description.trim().split(' ').length < 10 &&
          exp.description.isNotEmpty) {
        formattingIssues.add(ATSIssue(
          title: 'Short description for "${exp.position}"',
          detail: 'Add more detail; ATS rewards keyword-rich descriptions',
          severity: ATSSeverity.medium,
        ));
      }
    }

    // ── Suggestions ──────────────────────────────────────────────────────────
    final List<ATSSuggestion> suggestions = [];

    if (missing.isNotEmpty) {
      final top = missing.take(5).toList();
      suggestions.add(ATSSuggestion(
        title: 'Add missing job-description keywords',
        description: 'Missing: ${top.join(', ')}${missing.length > 5 ? ' …and ${missing.length - 5} more' : ''}',
        priority: ATSSeverity.high,
      ));
    }
    if (weakVerbIssues.isNotEmpty) {
      suggestions.add(ATSSuggestion(
        title: 'Replace weak phrases with action verbs',
        description: 'Use verbs like: ${_strongVerbs.take(6).join(', ')}',
        priority: ATSSeverity.medium,
      ));
    }
    if (!(resume.objective?.isNotEmpty ?? false)) {
      suggestions.add(const ATSSuggestion(
        title: 'Add a professional summary',
        description:
            'A 2-3 sentence summary with role-specific keywords significantly improves ATS ranking',
        priority: ATSSeverity.high,
      ));
    }
    if (resume.skills.length < 5) {
      suggestions.add(const ATSSuggestion(
        title: 'Add more skills',
        description:
            'List at least 8-10 skills. Include both technical and soft skills from the job description',
        priority: ATSSeverity.medium,
      ));
    }
    if (pi.linkedIn?.isEmpty ?? true) {
      suggestions.add(const ATSSuggestion(
        title: 'Add your LinkedIn URL',
        description:
            'Many ATS systems and recruiters verify candidates via LinkedIn',
        priority: ATSSeverity.low,
      ));
    }
    if (resume.certifications.isEmpty) {
      suggestions.add(const ATSSuggestion(
        title: 'Add certifications',
        description:
            'Relevant certifications improve your credibility and keyword density',
        priority: ATSSeverity.low,
      ));
    }

    final totalScore =
        keywordScore + contactScore + structureScore + verbScore + summaryScore;

    return ATSResult(
      score: totalScore.clamp(0, 100),
      matchedKeywords: matched,
      missingKeywords: missing,
      formattingIssues: formattingIssues,
      weakVerbIssues: weakVerbIssues,
      suggestions: suggestions,
      keywordScore: keywordScore,
      contactScore: contactScore,
      structureScore: structureScore,
      verbScore: verbScore,
      summaryScore: summaryScore,
    );
  }
}
