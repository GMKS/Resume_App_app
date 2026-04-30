import '../../../core/models/resume_model.dart';

enum ResumeJobMatchPriority { high, medium, low }

class ResumeJobMatchSuggestion {
  const ResumeJobMatchSuggestion({
    required this.title,
    required this.description,
    required this.priority,
    required this.sectionKey,
  });

  final String title;
  final String description;
  final ResumeJobMatchPriority priority;
  final String sectionKey;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'priority': priority.name,
      'sectionKey': sectionKey,
    };
  }
}

class ResumeJobSectionScore {
  const ResumeJobSectionScore({
    required this.sectionKey,
    required this.label,
    required this.score,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.summary,
  });

  final String sectionKey;
  final String label;
  final int score;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String summary;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sectionKey': sectionKey,
      'label': label,
      'score': score,
      'matchedKeywords': matchedKeywords,
      'missingKeywords': missingKeywords,
      'summary': summary,
    };
  }
}

class ResumeJobMatchResult {
  const ResumeJobMatchResult({
    required this.matchScore,
    required this.matchAssessment,
    required this.extractedKeywords,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.missingSkills,
    required this.topSkills,
    required this.sectionScores,
    required this.suggestions,
    required this.engineId,
    required this.engineVersion,
  });

  final int matchScore;
  final String matchAssessment;
  final List<String> extractedKeywords;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> missingSkills;
  final List<String> topSkills;
  final List<ResumeJobSectionScore> sectionScores;
  final List<ResumeJobMatchSuggestion> suggestions;
  final String engineId;
  final String engineVersion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'matchScore': matchScore,
      'matchAssessment': matchAssessment,
      'keywordsExtracted': extractedKeywords,
      'keywordsCovered': matchedKeywords,
      'missingKeywords': missingKeywords,
      'missingSkills': missingSkills,
      'topSkills': topSkills,
      'sectionScores':
          sectionScores.map((section) => section.toMap()).toList(growable: false),
      'suggestions':
          suggestions.map((suggestion) => suggestion.toMap()).toList(growable: false),
      'improvementTips': suggestions
          .map((suggestion) => suggestion.description)
          .toList(growable: false),
      'engineId': engineId,
      'engineVersion': engineVersion,
    };
  }
}

abstract class ResumeJobSimilarityProvider {
  const ResumeJobSimilarityProvider();

  String get id;

  double computeSimilarity({
    required String resumeText,
    required String jobText,
    required Set<String> resumeKeywords,
    required Set<String> jobKeywords,
  });
}

class KeywordOverlapSimilarityProvider extends ResumeJobSimilarityProvider {
  const KeywordOverlapSimilarityProvider();

  @override
  String get id => 'keyword-overlap';

  @override
  double computeSimilarity({
    required String resumeText,
    required String jobText,
    required Set<String> resumeKeywords,
    required Set<String> jobKeywords,
  }) {
    if (jobKeywords.isEmpty) {
      return resumeKeywords.isEmpty ? 0 : 1;
    }

    final intersection = resumeKeywords.intersection(jobKeywords).length;
    final union = resumeKeywords.union(jobKeywords).length;
    final coverage = intersection / jobKeywords.length;
    final jaccard = union == 0 ? 0 : intersection / union;
    final phraseBonus = _sharedPhraseBonus(
      resumeText: resumeText,
      jobText: jobText,
    );

    final score = (coverage * 0.55) + (jaccard * 0.35) + (phraseBonus * 0.10);
    return score.clamp(0, 1);
  }

  double _sharedPhraseBonus({
    required String resumeText,
    required String jobText,
  }) {
    final resumePhrases = ResumeJobMatchService.extractSkillCandidates(resumeText)
        .map(ResumeJobMatchService.canonicalPhrase)
        .toSet();
    final jobPhrases = ResumeJobMatchService.extractSkillCandidates(jobText)
        .map(ResumeJobMatchService.canonicalPhrase)
        .toSet();

    if (jobPhrases.isEmpty) {
      return 0;
    }

    final shared = resumePhrases.intersection(jobPhrases).length;
    return (shared / jobPhrases.length).clamp(0, 1);
  }
}

class ResumeJobMatchService {
  const ResumeJobMatchService({
    this.similarityProvider = const KeywordOverlapSimilarityProvider(),
  });

  static const String engineVersion = '2026-04-keyword-match-v1';

  static const Set<String> _stopWords = <String>{
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'been',
    'being',
    'but',
    'by',
    'can',
    'for',
    'from',
    'have',
    'in',
    'into',
    'is',
    'it',
    'its',
    'of',
    'on',
    'or',
    'our',
    'that',
    'the',
    'their',
    'this',
    'to',
    'using',
    'with',
    'you',
    'your',
    'will',
    'must',
    'should',
    'who',
    'we',
    'they',
    'them',
    'these',
    'those',
    'across',
    'about',
    'ability',
    'able',
    'all',
    'any',
    'build',
    'building',
    'candidate',
    'candidates',
    'company',
    'deliver',
    'driven',
    'experience',
    'familiarity',
    'focus',
    'job',
    'knowledge',
    'looking',
    'maintain',
    'manage',
    'preferred',
    'professional',
    'proven',
    'required',
    'requirements',
    'role',
    'strong',
    'support',
    'team',
    'work',
    'working',
    'years',
  };

  static const Set<String> _shortTokens = <String>{
    'ai',
    'ml',
    'ui',
    'ux',
    'bi',
    'hr',
    'it',
    'qa',
    'go',
    'r',
    'c#',
    'c++',
    '.net',
  };

  static const Map<String, String> _aliases = <String, String>{
    'nodejs': 'node.js',
    'node': 'node.js',
    'reactjs': 'react',
    'react.js': 'react',
    'nextjs': 'next.js',
    'next': 'next.js',
    'vuejs': 'vue',
    'vue.js': 'vue',
    'javascript': 'javascript',
    'js': 'javascript',
    'typescript': 'typescript',
    'ts': 'typescript',
    'postgres': 'postgresql',
    'postgresql': 'postgresql',
    'mysql': 'mysql',
    'mongodb': 'mongodb',
    'mongo': 'mongodb',
    'aws': 'aws',
    'gcp': 'gcp',
    'azure': 'azure',
    'dotnet': '.net',
    'csharp': 'c#',
    'ci': 'ci/cd',
    'cd': 'ci/cd',
    'graphql': 'graphql',
    'restful': 'rest',
  };

  static const Set<String> _multiWordSkills = <String>{
    'machine learning',
    'data analysis',
    'data modeling',
    'data engineering',
    'product management',
    'project management',
    'stakeholder management',
    'agile delivery',
    'software architecture',
    'system design',
    'mobile development',
    'web development',
    'frontend development',
    'back end development',
    'back-end development',
    'full stack',
    'quality assurance',
    'test automation',
    'continuous integration',
    'continuous delivery',
    'cloud architecture',
    'user research',
    'design systems',
    'product design',
    'visual design',
    'content strategy',
    'search engine optimization',
    'customer success',
    'account management',
    'business analysis',
    'financial analysis',
    'sales enablement',
    'cross functional',
    'team leadership',
    'change management',
  };

  static const List<String> _skillTriggerPrefixes = <String>[
    'experience with',
    'proficient in',
    'proficiency in',
    'knowledge of',
    'familiar with',
    'expertise in',
    'background in',
    'working knowledge of',
    'hands on',
    'hands-on',
    'skills:',
    'requirements:',
    'responsibilities:',
    'technologies:',
    'tools:',
    'stack:',
  ];

  static const Map<String, double> _sectionWeights = <String, double>{
    'personal': 0.08,
    'summary': 0.16,
    'experience': 0.30,
    'skills': 0.24,
    'projects': 0.12,
    'education': 0.06,
    'certifications': 0.04,
  };

  final ResumeJobSimilarityProvider similarityProvider;

  static ResumeJobMatchResult analyze({
    required ResumeModel resume,
    required String jobDescription,
    ResumeJobSimilarityProvider similarityProvider =
        const KeywordOverlapSimilarityProvider(),
  }) {
    return ResumeJobMatchService(
      similarityProvider: similarityProvider,
    ).match(resume: resume, jobDescription: jobDescription);
  }

  ResumeJobMatchResult match({
    required ResumeModel resume,
    required String jobDescription,
  }) {
    final normalizedJobDescription = jobDescription.trim();
    final extractedKeywords = _extractRankedKeywords(normalizedJobDescription);
    final extractedKeywordSet = extractedKeywords.toSet();
    final resumeText = _buildResumeText(resume);
    final resumeKeywords = _extractKeywords(resumeText);

    final matchedKeywords = extractedKeywords
        .where(resumeKeywords.contains)
        .toList(growable: false);
    final missingKeywords = extractedKeywords
        .where((keyword) => !resumeKeywords.contains(keyword))
        .toList(growable: false);

    final sectionScores = <ResumeJobSectionScore>[
      _scorePersonalSection(resume, normalizedJobDescription, extractedKeywordSet),
      _scoreFreeTextSection(
        sectionKey: 'summary',
        label: 'Summary',
        text: resume.objective ?? '',
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
      _scoreFreeTextSection(
        sectionKey: 'experience',
        label: 'Experience',
        text: _experienceText(resume),
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
      _scoreFreeTextSection(
        sectionKey: 'skills',
        label: 'Skills',
        text: _skillsText(resume),
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
      _scoreFreeTextSection(
        sectionKey: 'projects',
        label: 'Projects',
        text: _projectsText(resume),
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
      _scoreFreeTextSection(
        sectionKey: 'education',
        label: 'Education',
        text: _educationText(resume),
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
      _scoreFreeTextSection(
        sectionKey: 'certifications',
        label: 'Certifications',
        text: _certificationsText(resume),
        jobDescription: normalizedJobDescription,
        jobKeywords: extractedKeywordSet,
      ),
    ];

    final missingSkills = _extractMissingSkills(
      resume: resume,
      resumeKeywords: resumeKeywords,
      jobDescription: normalizedJobDescription,
    );
    final topSkills = _prioritizeResumeSkills(
      resume: resume,
      extractedKeywords: extractedKeywords,
    );
    final overallScore = _overallScore(
      sectionScores: sectionScores,
      matchedKeywords: matchedKeywords,
      extractedKeywords: extractedKeywords,
    );
    final suggestions = _buildSuggestions(
      resume: resume,
      overallScore: overallScore,
      missingKeywords: missingKeywords,
      missingSkills: missingSkills,
      sectionScores: sectionScores,
    );

    return ResumeJobMatchResult(
      matchScore: overallScore,
      matchAssessment: _buildAssessment(
        score: overallScore,
        missingSkills: missingSkills,
        matchedKeywords: matchedKeywords,
        extractedKeywords: extractedKeywords,
      ),
      extractedKeywords: extractedKeywords,
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      missingSkills: missingSkills,
      topSkills: topSkills,
      sectionScores: sectionScores,
      suggestions: suggestions,
      engineId: similarityProvider.id,
      engineVersion: engineVersion,
    );
  }

  static String canonicalPhrase(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\+\#\.\s/-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> extractSkillCandidates(String text) {
    final candidates = <String, int>{};
    final lowerText = text.toLowerCase();

    for (final phrase in _multiWordSkills) {
      if (lowerText.contains(phrase)) {
        candidates[phrase] = (candidates[phrase] ?? 0) + 3;
      }
    }

    for (final rawLine in text.split(RegExp(r'[\n\r]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final normalizedLine = line.toLowerCase();
      for (final trigger in _skillTriggerPrefixes) {
        final triggerIndex = normalizedLine.indexOf(trigger);
        if (triggerIndex == -1) {
          continue;
        }

        final segment = line.substring(triggerIndex + trigger.length).trim();
        for (final candidate in _splitSkillSegment(segment)) {
          final normalizedCandidate = canonicalPhrase(candidate);
          if (_isUsefulCandidate(normalizedCandidate)) {
            candidates[normalizedCandidate] =
                (candidates[normalizedCandidate] ?? 0) + 2;
          }
        }
      }

      if (_looksLikeSkillLine(normalizedLine)) {
        for (final candidate in _splitSkillSegment(line)) {
          final normalizedCandidate = canonicalPhrase(candidate);
          if (_isUsefulCandidate(normalizedCandidate)) {
            candidates[normalizedCandidate] =
                (candidates[normalizedCandidate] ?? 0) + 1;
          }
        }
      }
    }

    final ranked = candidates.entries.toList(growable: false)
      ..sort((left, right) {
        final scoreCompare = right.value.compareTo(left.value);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return left.key.compareTo(right.key);
      });

    return ranked.map((entry) => entry.key).toList(growable: false);
  }

  static List<String> _splitSkillSegment(String value) {
    return value
        .split(RegExp(r'[,;|•·/]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.split(RegExp(r'\s+')).length <= 4)
        .toList(growable: false);
  }

  static bool _looksLikeSkillLine(String line) {
    return line.contains('skills') ||
        line.contains('technologies') ||
        line.contains('stack') ||
        line.contains('tools') ||
        line.contains('frameworks');
  }

  static bool _isUsefulCandidate(String candidate) {
    if (candidate.isEmpty) {
      return false;
    }
    final words = candidate.split(' ');
    if (words.length == 1) {
      return _isUsefulKeyword(words.first);
    }
    return words.every(_isUsefulKeyword);
  }

  static Set<String> _extractKeywords(String text) {
    final keywords = <String>{};
    for (final match in RegExp(r'[A-Za-z0-9\+\#\./-]+').allMatches(text)) {
      final raw = match.group(0);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final normalized = _canonicalKeyword(raw);
      if (_isUsefulKeyword(normalized)) {
        keywords.add(normalized);
      }
    }
    return keywords;
  }

  static List<String> _extractRankedKeywords(String text, {int max = 16}) {
    if (text.trim().isEmpty) {
      return const <String>[];
    }

    final counts = <String, int>{};
    for (final match in RegExp(r'[A-Za-z0-9\+\#\./-]+').allMatches(text)) {
      final raw = match.group(0);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final normalized = _canonicalKeyword(raw);
      if (_isUsefulKeyword(normalized)) {
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }

    for (final skill in extractSkillCandidates(text)) {
      counts[skill] = (counts[skill] ?? 0) + 2;
    }

    final ranked = counts.entries.toList(growable: false)
      ..sort((left, right) {
        final scoreCompare = right.value.compareTo(left.value);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return left.key.compareTo(right.key);
      });

    return ranked.take(max).map((entry) => entry.key).toList(growable: false);
  }

  static String _canonicalKeyword(String raw) {
    var normalized = raw.toLowerCase().trim();
    normalized = normalized
        .replaceAll('ci/cd', 'cicd')
        .replaceAll('c#', 'csharp')
        .replaceAll('c++', 'cplusplus');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\.]'), '');

    if (normalized == 'csharp') {
      return 'c#';
    }
    if (normalized == 'cplusplus') {
      return 'c++';
    }
    if (normalized == 'cicd') {
      return 'ci/cd';
    }
    return _aliases[normalized] ?? normalized;
  }

  static bool _isUsefulKeyword(String keyword) {
    if (keyword.isEmpty) {
      return false;
    }
    if (_stopWords.contains(keyword)) {
      return false;
    }
    if (_shortTokens.contains(keyword)) {
      return true;
    }
    return keyword.length > 2;
  }

  String _buildResumeText(ResumeModel resume) {
    final buffer = StringBuffer();
    buffer.writeln(resume.personalInfo.fullName);
    buffer.writeln(resume.personalInfo.jobTitle ?? '');
    buffer.writeln(resume.personalInfo.email);
    buffer.writeln(resume.personalInfo.phone);
    buffer.writeln(resume.personalInfo.address);
    buffer.writeln(resume.objective ?? '');
    buffer.writeln(_experienceText(resume));
    buffer.writeln(_skillsText(resume));
    buffer.writeln(_projectsText(resume));
    buffer.writeln(_educationText(resume));
    buffer.writeln(_certificationsText(resume));
    return buffer.toString();
  }

  String _experienceText(ResumeModel resume) {
    return resume.experience
        .map((experience) {
          final achievements = experience.achievements.join(' ');
          return [
            experience.position,
            experience.company,
            experience.location ?? '',
            experience.description,
            achievements,
          ].where((value) => value.trim().isNotEmpty).join(' ');
        })
        .join(' ');
  }

  String _skillsText(ResumeModel resume) {
    return resume.skills
        .map((skill) => [skill.name, skill.category ?? ''].join(' '))
        .join(' ');
  }

  String _projectsText(ResumeModel resume) {
    return resume.projects
        .map((project) => [
              project.title,
              project.description,
              project.technologies.join(' '),
              project.url ?? '',
            ].where((value) => value.trim().isNotEmpty).join(' '))
        .join(' ');
  }

  String _educationText(ResumeModel resume) {
    return resume.education
        .map((education) => [
              education.degree,
              education.fieldOfStudy,
              education.institution,
              education.description ?? '',
            ].where((value) => value.trim().isNotEmpty).join(' '))
        .join(' ');
  }

  String _certificationsText(ResumeModel resume) {
    return resume.certifications
        .map((certification) => [
              certification.name,
              certification.issuer,
              certification.credentialId ?? '',
            ].where((value) => value.trim().isNotEmpty).join(' '))
        .join(' ');
  }

  ResumeJobSectionScore _scorePersonalSection(
    ResumeModel resume,
    String jobDescription,
    Set<String> jobKeywords,
  ) {
    final personal = resume.personalInfo;
    final text = [
      personal.fullName,
      personal.jobTitle ?? '',
      personal.email,
      personal.phone,
      personal.address,
      personal.linkedIn ?? '',
      personal.github ?? '',
      personal.website ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');

    final contactPoints = <String>[
      personal.fullName,
      personal.email,
      personal.phone,
      personal.address,
      personal.linkedIn ?? '',
      personal.github ?? '',
      personal.website ?? '',
    ].where((value) => value.trim().isNotEmpty).length;
    final titleKeywords = _extractKeywords(personal.jobTitle ?? '');
    final matchedKeywords = jobKeywords.intersection(titleKeywords).toList()
      ..sort();
    final missingKeywords = jobKeywords.difference(titleKeywords).take(4).toList()
      ..sort();

    final similarity = similarityProvider.computeSimilarity(
      resumeText: text,
      jobText: jobDescription,
      resumeKeywords: _extractKeywords(text),
      jobKeywords: jobKeywords,
    );
    final completeness = (contactPoints / 7).clamp(0, 1);
    final score = ((similarity * 0.55) + (completeness * 0.45)) * 100;

    return ResumeJobSectionScore(
      sectionKey: 'personal',
      label: 'Header & Role Fit',
      score: score.round().clamp(0, 100),
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      summary: matchedKeywords.isNotEmpty
          ? 'Your role headline already overlaps with the job language.'
          : 'Your header is complete, but the title can align more closely with the target role.',
    );
  }

  ResumeJobSectionScore _scoreFreeTextSection({
    required String sectionKey,
    required String label,
    required String text,
    required String jobDescription,
    required Set<String> jobKeywords,
  }) {
    final keywords = _extractKeywords(text);
    final matchedKeywords = jobKeywords.intersection(keywords).toList()..sort();
    final missingKeywords = jobKeywords.difference(keywords).take(6).toList()
      ..sort();
    final similarity = similarityProvider.computeSimilarity(
      resumeText: text,
      jobText: jobDescription,
      resumeKeywords: keywords,
      jobKeywords: jobKeywords,
    );
    final completeness = _textCompleteness(text);
    final coverage = jobKeywords.isEmpty ? 0 : matchedKeywords.length / jobKeywords.length;
    final score = ((coverage * 0.50) + (similarity * 0.35) + (completeness * 0.15)) * 100;

    return ResumeJobSectionScore(
      sectionKey: sectionKey,
      label: label,
      score: score.round().clamp(0, 100),
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      summary: _sectionSummary(
        label: label,
        score: score.round().clamp(0, 100),
        matchedCount: matchedKeywords.length,
      ),
    );
  }

  static double _textCompleteness(String text) {
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
    if (wordCount >= 90) {
      return 1;
    }
    if (wordCount >= 45) {
      return 0.8;
    }
    if (wordCount >= 20) {
      return 0.6;
    }
    if (wordCount >= 8) {
      return 0.4;
    }
    if (wordCount > 0) {
      return 0.2;
    }
    return 0;
  }

  String _sectionSummary({
    required String label,
    required int score,
    required int matchedCount,
  }) {
    if (score >= 80) {
      return '$label strongly reinforces the job requirements.';
    }
    if (score >= 60) {
      return '$label partially supports the role and matches $matchedCount relevant keywords.';
    }
    if (score > 0) {
      return '$label needs stronger alignment with the target job language.';
    }
    return '$label is effectively missing for this job comparison.';
  }

  List<String> _extractMissingSkills({
    required ResumeModel resume,
    required Set<String> resumeKeywords,
    required String jobDescription,
  }) {
    final resumeSkillTerms = <String>{
      ...resume.skills.map((skill) => canonicalPhrase(skill.name)),
      ...resume.projects.expand(
        (project) => project.technologies.map(canonicalPhrase),
      ),
      ...resume.certifications.map((certification) => canonicalPhrase(certification.name)),
    }..removeWhere((value) => value.isEmpty);

    final candidates = extractSkillCandidates(jobDescription);
    return candidates
        .where((candidate) => !resumeSkillTerms.contains(candidate))
        .where((candidate) => !resumeKeywords.contains(candidate))
        .take(8)
        .toList(growable: false);
  }

  List<String> _prioritizeResumeSkills({
    required ResumeModel resume,
    required List<String> extractedKeywords,
  }) {
    final scored = <MapEntry<String, int>>[];
    final keywordWeights = <String, int>{};
    for (var index = 0; index < extractedKeywords.length; index++) {
      keywordWeights[extractedKeywords[index]] = extractedKeywords.length - index;
    }

    for (final skill in resume.skills) {
      final normalized = canonicalPhrase(skill.name);
      var score = 0;
      for (final keyword in _extractKeywords(skill.name)) {
        score += keywordWeights[keyword] ?? 0;
      }
      if (keywordWeights.containsKey(normalized)) {
        score += (keywordWeights[normalized] ?? 0) * 2;
      }
      if (score > 0) {
        scored.add(MapEntry(skill.name, score + skill.proficiency));
      }
    }

    scored.sort((left, right) => right.value.compareTo(left.value));
    return scored
        .map((entry) => entry.key)
        .toSet()
        .take(6)
        .toList(growable: false);
  }

  int _overallScore({
    required List<ResumeJobSectionScore> sectionScores,
    required List<String> matchedKeywords,
    required List<String> extractedKeywords,
  }) {
    var weightedTotal = 0.0;
    var totalWeight = 0.0;

    for (final section in sectionScores) {
      final weight = _sectionWeights[section.sectionKey] ?? 0.05;
      weightedTotal += section.score * weight;
      totalWeight += weight;
    }

    final sectionAverage = totalWeight == 0 ? 0 : weightedTotal / totalWeight;
    final keywordCoverage = extractedKeywords.isEmpty
        ? sectionAverage
        : (matchedKeywords.length / extractedKeywords.length) * 100;

    final score = (sectionAverage * 0.72) + (keywordCoverage * 0.28);
    return score.round().clamp(0, 100);
  }

  String _buildAssessment({
    required int score,
    required List<String> missingSkills,
    required List<String> matchedKeywords,
    required List<String> extractedKeywords,
  }) {
    if (score >= 85) {
      return 'Strong match. Your resume already covers most of the job language and needs only minor polishing.';
    }
    if (score >= 70) {
      return 'Good match. You have relevant evidence, but tightening a few sections will improve alignment.';
    }
    if (score >= 55) {
      return 'Moderate match. The resume fits some of the role, but several requirements are underrepresented.';
    }
    if (missingSkills.isNotEmpty) {
      return 'Low match right now. Add missing skills like ${missingSkills.take(3).join(', ')} and strengthen job-specific evidence.';
    }
    if (extractedKeywords.isNotEmpty && matchedKeywords.isEmpty) {
      return 'Low match right now. The job description language is not showing up in the resume sections yet.';
    }
    return 'Low match right now. The resume needs stronger role-specific keywords and examples to compete for this posting.';
  }

  List<ResumeJobMatchSuggestion> _buildSuggestions({
    required ResumeModel resume,
    required int overallScore,
    required List<String> missingKeywords,
    required List<String> missingSkills,
    required List<ResumeJobSectionScore> sectionScores,
  }) {
    final suggestions = <ResumeJobMatchSuggestion>[];

    if (missingSkills.isNotEmpty) {
      suggestions.add(
        ResumeJobMatchSuggestion(
          title: 'Add missing skills to the resume',
          description:
              'Add or validate skill coverage for ${missingSkills.take(4).join(', ')} so recruiters and ATS systems can see explicit fit.',
          priority: ResumeJobMatchPriority.high,
          sectionKey: 'skills',
        ),
      );
    }

    final summaryScore = sectionScores.firstWhere(
      (section) => section.sectionKey == 'summary',
    );
    if (summaryScore.score < 65) {
      suggestions.add(
        const ResumeJobMatchSuggestion(
          title: 'Rewrite the professional summary for this role',
          description:
              'Mirror the job title, seniority, and core themes in a concise 2-3 sentence summary.',
          priority: ResumeJobMatchPriority.high,
          sectionKey: 'summary',
        ),
      );
    }

    final experienceScore = sectionScores.firstWhere(
      (section) => section.sectionKey == 'experience',
    );
    if (experienceScore.score < 70) {
      suggestions.add(
        ResumeJobMatchSuggestion(
          title: 'Strengthen experience bullets with job language',
          description:
              missingKeywords.isEmpty
                  ? 'Add clearer outcomes, scope, and tools so your experience lines up with the posting.'
                  : 'Use evidence-driven bullets that naturally cover keywords like ${missingKeywords.take(3).join(', ')}.',
          priority: ResumeJobMatchPriority.high,
          sectionKey: 'experience',
        ),
      );
    }

    final projectScore = sectionScores.firstWhere(
      (section) => section.sectionKey == 'projects',
    );
    if (resume.projects.isNotEmpty && projectScore.score < 60) {
      suggestions.add(
        const ResumeJobMatchSuggestion(
          title: 'Use projects to back up missing requirements',
          description:
              'Highlight the tools, outcomes, and links that directly support the target role requirements.',
          priority: ResumeJobMatchPriority.medium,
          sectionKey: 'projects',
        ),
      );
    }

    if (resume.projects.isEmpty && overallScore < 75) {
      suggestions.add(
        const ResumeJobMatchSuggestion(
          title: 'Add a relevant project or case study',
          description:
              'A project can prove technologies or responsibilities that are not yet clear in work experience.',
          priority: ResumeJobMatchPriority.medium,
          sectionKey: 'projects',
        ),
      );
    }

    final educationScore = sectionScores.firstWhere(
      (section) => section.sectionKey == 'education',
    );
    if (resume.education.isNotEmpty && educationScore.score < 40) {
      suggestions.add(
        const ResumeJobMatchSuggestion(
          title: 'Clarify education relevance',
          description:
              'Include field of study, coursework, or specialization if it supports the target role.',
          priority: ResumeJobMatchPriority.low,
          sectionKey: 'education',
        ),
      );
    }

    if (resume.certifications.isEmpty &&
        _looksCertificationHeavy(missingKeywords)) {
      suggestions.add(
        const ResumeJobMatchSuggestion(
          title: 'Add certifications if the role expects them',
          description:
              'Relevant credentials can close a gap when the job repeatedly references certification-heavy requirements.',
          priority: ResumeJobMatchPriority.low,
          sectionKey: 'certifications',
        ),
      );
    }

    return suggestions.take(6).toList(growable: false);
  }

  bool _looksCertificationHeavy(List<String> missingKeywords) {
    const certificationTerms = <String>{
      'certification',
      'certified',
      'license',
      'licensed',
      'aws',
      'azure',
      'pmp',
      'scrum',
    };
    return missingKeywords.any(certificationTerms.contains);
  }
}