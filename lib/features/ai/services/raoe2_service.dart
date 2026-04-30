import 'package:uuid/uuid.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/resume_json.dart';

class RAOE2SectionRewrite {
  const RAOE2SectionRewrite({
    required this.sectionKey,
    required this.label,
    required this.originalText,
    required this.optimizedText,
    required this.keywordsAdded,
    required this.rationale,
  });

  final String sectionKey;
  final String label;
  final String originalText;
  final String optimizedText;
  final List<String> keywordsAdded;
  final String rationale;

  bool get hasVisibleChange =>
      originalText.trim() != optimizedText.trim() || keywordsAdded.isNotEmpty;

  factory RAOE2SectionRewrite.fromMap(Map<String, dynamic> map) {
    return RAOE2SectionRewrite(
      sectionKey: map['sectionKey']?.toString().trim().isNotEmpty == true
          ? map['sectionKey'].toString().trim()
          : 'section',
      label: map['label']?.toString().trim().isNotEmpty == true
          ? map['label'].toString().trim()
          : 'Section Rewrite',
      originalText: map['originalText']?.toString().trim() ?? '',
      optimizedText: map['optimizedText']?.toString().trim() ?? '',
      keywordsAdded: RAOE2Service.stringList(map['keywordsAdded']),
      rationale: map['rationale']?.toString().trim() ?? '',
    );
  }
}

class RAOE2ExperienceRewrite {
  const RAOE2ExperienceRewrite({
    required this.company,
    required this.position,
    required this.description,
    required this.achievements,
    required this.keywordsAdded,
    required this.rationale,
  });

  final String company;
  final String position;
  final String description;
  final List<String> achievements;
  final List<String> keywordsAdded;
  final String rationale;

  factory RAOE2ExperienceRewrite.fromMap(Map<String, dynamic> map) {
    return RAOE2ExperienceRewrite(
      company: map['company']?.toString().trim() ?? '',
      position: map['position']?.toString().trim() ?? '',
      description: map['description']?.toString().trim() ?? '',
      achievements: RAOE2Service.stringList(map['achievements']),
      keywordsAdded: RAOE2Service.stringList(map['keywordsAdded']),
      rationale: map['rationale']?.toString().trim() ?? '',
    );
  }
}

class RAOE2OptimizationResult {
  const RAOE2OptimizationResult({
    required this.originalResumeText,
    required this.optimizedResumeText,
    required this.missingKeywords,
    required this.keywordsAdded,
    required this.missingKeywordsAddressed,
    required this.actionableSuggestions,
    required this.sectionRewrites,
    required this.rewrittenSummary,
    required this.rewrittenExperience,
    required this.rewrittenSkills,
    required this.overallRationale,
    required this.engineId,
    required this.engineVersion,
  });

  final String originalResumeText;
  final String optimizedResumeText;
  final List<String> missingKeywords;
  final List<String> keywordsAdded;
  final List<String> missingKeywordsAddressed;
  final List<String> actionableSuggestions;
  final List<RAOE2SectionRewrite> sectionRewrites;
  final String rewrittenSummary;
  final List<RAOE2ExperienceRewrite> rewrittenExperience;
  final List<String> rewrittenSkills;
  final String overallRationale;
  final String engineId;
  final String engineVersion;

  bool get hasStructuredResumeUpdate =>
      rewrittenSummary.isNotEmpty ||
      rewrittenExperience.isNotEmpty ||
      rewrittenSkills.isNotEmpty;
}

/// RAOE 2: Resume Auto-Optimization Engine core logic.
class RAOE2Service {
  static const String engineId = 'raoe2-ai';
  static const String engineVersion = '2026-04-23-raoe2-ai-v1';

  static Future<RAOE2OptimizationResult> optimize({
    required String apiKey,
    required String resumeText,
    required String jobDescription,
    ResumeModel? resume,
    String tone = 'Professional',
  }) async {
    final normalizedResumeText = resumeText.trim();
    final normalizedJobDescription = jobDescription.trim();
    final missingKeywords = RAOE2KeywordAnalyzer.findMissingKeywords(
      resumeText: normalizedResumeText,
      jobDescription: normalizedJobDescription,
    ).toList(growable: false)
      ..sort();

    if (resume != null) {
      final response = await AiResumeService.optimizeStructuredResumeForJob(
        apiKey: apiKey,
        resumeJson: ResumeJson.toMap(resume),
        jobDescription: normalizedJobDescription,
        missingKeywords: missingKeywords,
        tone: tone,
      );
      return _buildStructuredResult(
        resume: resume,
        originalResumeText: normalizedResumeText,
        response: response,
        missingKeywords: missingKeywords,
      );
    }

    final response = await AiResumeService.optimizeResumeTextForJob(
      apiKey: apiKey,
      resumeText: normalizedResumeText,
      jobDescription: normalizedJobDescription,
      missingKeywords: missingKeywords,
      tone: tone,
    );
    return _buildTextResult(
      originalResumeText: normalizedResumeText,
      response: response,
      missingKeywords: missingKeywords,
    );
  }

  static ResumeModel applyToResume({
    required ResumeModel resume,
    required RAOE2OptimizationResult result,
  }) {
    ResumeModel updated = resume.copyWith(
      objective: result.rewrittenSummary.isNotEmpty
          ? result.rewrittenSummary
          : resume.objective,
      updatedAt: DateTime.now(),
    );

    if (result.rewrittenExperience.isNotEmpty && updated.experience.isNotEmpty) {
      final updatedExperience = updated.experience.asMap().entries.map((entry) {
        final index = entry.key;
        final experience = entry.value;
        if (index >= result.rewrittenExperience.length) {
          return experience;
        }
        final rewrite = result.rewrittenExperience[index];
        return experience.copyWith(
          position: rewrite.position.isNotEmpty ? rewrite.position : experience.position,
          description: rewrite.description.isNotEmpty
              ? rewrite.description
              : experience.description,
          achievements: rewrite.achievements.isNotEmpty
              ? rewrite.achievements
              : experience.achievements,
        );
      }).toList(growable: false);
      updated = updated.copyWith(experience: updatedExperience);
    }

    if (result.rewrittenSkills.isNotEmpty) {
      final incomingSkills = result.rewrittenSkills;
      final updatedSkills = incomingSkills.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        if (index < updated.skills.length) {
          return updated.skills[index].copyWith(name: name);
        }
        return Skill(
          id: const Uuid().v4(),
          name: name,
          proficiency: 3,
          category: 'Technical',
        );
      }).toList(growable: false);
      updated = updated.copyWith(skills: updatedSkills);
    }

    return updated.copyWith(updatedAt: DateTime.now());
  }

  static String buildEditableResumeText(ResumeModel resume) {
    final buffer = StringBuffer();

    final fullName = resume.personalInfo.fullName.trim();
    final jobTitle = resume.personalInfo.jobTitle?.trim() ?? '';
    if (fullName.isNotEmpty) {
      buffer.writeln(fullName);
    }
    if (jobTitle.isNotEmpty) {
      buffer.writeln(jobTitle);
    }

    final contactParts = <String>[
      resume.personalInfo.email.trim(),
      resume.personalInfo.phone.trim(),
      resume.personalInfo.address.trim(),
      resume.personalInfo.linkedIn?.trim() ?? '',
      resume.personalInfo.github?.trim() ?? '',
      resume.personalInfo.website?.trim() ?? '',
    ].where((item) => item.isNotEmpty).toList(growable: false);
    if (contactParts.isNotEmpty) {
      buffer.writeln(contactParts.join(' | '));
      buffer.writeln();
    }

    _writeSection(
      buffer,
      title: 'Professional Summary',
      body: resume.objective?.trim() ?? '',
    );

    if (resume.experience.isNotEmpty) {
      buffer.writeln('Experience');
      for (final experience in resume.experience) {
        buffer.writeln(_buildExperienceText(experience));
        buffer.writeln();
      }
    }

    final skillsText = resume.skills
        .map((skill) => skill.name.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    _writeSection(buffer, title: 'Skills', body: skillsText);

    if (resume.projects.isNotEmpty) {
      buffer.writeln('Projects');
      for (final project in resume.projects) {
        final projectLines = <String>[
          project.title.trim(),
          project.description.trim(),
          if (project.technologies.isNotEmpty)
            'Technologies: ${project.technologies.where((item) => item.trim().isNotEmpty).join(', ')}',
          if ((project.url ?? '').trim().isNotEmpty) project.url!.trim(),
        ].where((item) => item.isNotEmpty).join('\n');
        if (projectLines.isNotEmpty) {
          buffer.writeln(projectLines);
          buffer.writeln();
        }
      }
    }

    if (resume.education.isNotEmpty) {
      buffer.writeln('Education');
      for (final education in resume.education) {
        final educationLines = <String>[
          '${education.degree.trim()} ${education.fieldOfStudy.trim()}'.trim(),
          education.institution.trim(),
          education.description?.trim() ?? '',
        ].where((item) => item.isNotEmpty).join('\n');
        if (educationLines.isNotEmpty) {
          buffer.writeln(educationLines);
          buffer.writeln();
        }
      }
    }

    if (resume.certifications.isNotEmpty) {
      buffer.writeln('Certifications');
      for (final certification in resume.certifications) {
        final certificationLine = <String>[
          certification.name.trim(),
          certification.issuer.trim(),
        ].where((item) => item.isNotEmpty).join(' - ');
        if (certificationLine.isNotEmpty) {
          buffer.writeln(certificationLine);
        }
      }
      buffer.writeln();
    }

    if (resume.languages.isNotEmpty) {
      final languagesText = resume.languages
          .map((language) => '${language.name.trim()} (${language.proficiency.trim()})')
          .where((item) => item.isNotEmpty)
          .join(', ');
      _writeSection(buffer, title: 'Languages', body: languagesText);
    }

    return buffer.toString().trim();
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    final seen = <String>{};
    final items = <String>[];
    for (final item in value) {
      final text = item?.toString().trim() ?? '';
      if (text.isEmpty) {
        continue;
      }
      final normalized = text.toLowerCase();
      if (seen.add(normalized)) {
        items.add(text);
      }
    }
    return items;
  }

  static RAOE2OptimizationResult _buildStructuredResult({
    required ResumeModel resume,
    required String originalResumeText,
    required Map<String, dynamic> response,
    required List<String> missingKeywords,
  }) {
    final rewrittenSummary = response['rewrittenSummary']?.toString().trim() ?? '';
    final rewrittenExperience = _experienceRewrites(response['rewrittenExperience']);
    final rewrittenSkills = stringList(response['rewrittenSkills']);
    final keywordsAdded = stringList(response['keywordsAdded']);
    final addressedKeywords = stringList(response['missingKeywordsAddressed']);
    final suggestions = stringList(response['actionableSuggestions']);
    final overallRationale = response['overallRationale']?.toString().trim() ?? '';

    final sectionRewrites = <RAOE2SectionRewrite>[];
    final originalSummary = resume.objective?.trim() ?? '';
    if (rewrittenSummary.isNotEmpty && rewrittenSummary != originalSummary) {
      sectionRewrites.add(
        RAOE2SectionRewrite(
          sectionKey: 'summary',
          label: 'Professional Summary',
          originalText: originalSummary,
          optimizedText: rewrittenSummary,
          keywordsAdded: keywordsAdded
              .where((keyword) => rewrittenSummary.toLowerCase().contains(keyword.toLowerCase()))
              .toList(growable: false),
          rationale: overallRationale.isNotEmpty
              ? overallRationale
              : 'Refined the summary to match the target role more directly.',
        ),
      );
    }

    for (final entry in resume.experience.asMap().entries) {
      final index = entry.key;
      final experience = entry.value;
      if (index >= rewrittenExperience.length) {
        continue;
      }
      final rewrite = rewrittenExperience[index];
      final originalText = _buildExperienceText(experience);
      final optimizedText = _buildExperienceTextFromRewrite(experience, rewrite);
      if (optimizedText.trim() == originalText.trim()) {
        continue;
      }
      sectionRewrites.add(
        RAOE2SectionRewrite(
          sectionKey: 'experience_$index',
          label: experience.position.trim().isNotEmpty
              ? experience.position.trim()
              : 'Experience ${index + 1}',
          originalText: originalText,
          optimizedText: optimizedText,
          keywordsAdded: rewrite.keywordsAdded,
          rationale: rewrite.rationale.isNotEmpty
              ? rewrite.rationale
              : 'Reframed the experience for stronger relevance and impact.',
        ),
      );
    }

    final originalSkills = resume.skills
        .map((skill) => skill.name.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    final optimizedSkills = rewrittenSkills.join(', ');
    if (optimizedSkills.isNotEmpty && optimizedSkills != originalSkills) {
      sectionRewrites.add(
        RAOE2SectionRewrite(
          sectionKey: 'skills',
          label: 'Skills',
          originalText: originalSkills,
          optimizedText: optimizedSkills,
          keywordsAdded: keywordsAdded
              .where((keyword) => optimizedSkills.toLowerCase().contains(keyword.toLowerCase()))
              .toList(growable: false),
          rationale: 'Reordered and sharpened the skills section around the target job.',
        ),
      );
    }

    final seedResult = RAOE2OptimizationResult(
      originalResumeText: originalResumeText,
      optimizedResumeText: '',
      missingKeywords: missingKeywords,
      keywordsAdded: keywordsAdded,
      missingKeywordsAddressed: addressedKeywords,
      actionableSuggestions: suggestions,
      sectionRewrites: sectionRewrites,
      rewrittenSummary: rewrittenSummary,
      rewrittenExperience: rewrittenExperience,
      rewrittenSkills: rewrittenSkills,
      overallRationale: overallRationale,
      engineId: engineId,
      engineVersion: engineVersion,
    );

    final optimizedResume = applyToResume(resume: resume, result: seedResult);

    return RAOE2OptimizationResult(
      originalResumeText: originalResumeText,
      optimizedResumeText: buildEditableResumeText(optimizedResume),
      missingKeywords: missingKeywords,
      keywordsAdded: keywordsAdded,
      missingKeywordsAddressed: addressedKeywords,
      actionableSuggestions: suggestions,
      sectionRewrites: sectionRewrites,
      rewrittenSummary: rewrittenSummary,
      rewrittenExperience: rewrittenExperience,
      rewrittenSkills: rewrittenSkills,
      overallRationale: overallRationale,
      engineId: engineId,
      engineVersion: engineVersion,
    );
  }

  static RAOE2OptimizationResult _buildTextResult({
    required String originalResumeText,
    required Map<String, dynamic> response,
    required List<String> missingKeywords,
  }) {
    final optimizedResumeText = response['optimizedResumeText']?.toString().trim().isNotEmpty == true
        ? response['optimizedResumeText'].toString().trim()
        : originalResumeText;
    final sectionRewrites = (response['sectionRewrites'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .map(RAOE2SectionRewrite.fromMap)
        .where((section) => section.hasVisibleChange)
        .toList(growable: false);

    return RAOE2OptimizationResult(
      originalResumeText: originalResumeText,
      optimizedResumeText: optimizedResumeText,
      missingKeywords: missingKeywords,
      keywordsAdded: stringList(response['keywordsAdded']),
      missingKeywordsAddressed: stringList(response['missingKeywordsAddressed']),
      actionableSuggestions: stringList(response['actionableSuggestions']),
      sectionRewrites: sectionRewrites,
      rewrittenSummary: '',
      rewrittenExperience: const <RAOE2ExperienceRewrite>[],
      rewrittenSkills: const <String>[],
      overallRationale: response['overallRationale']?.toString().trim() ?? '',
      engineId: engineId,
      engineVersion: engineVersion,
    );
  }

  static List<RAOE2ExperienceRewrite> _experienceRewrites(dynamic value) {
    if (value is! List) {
      return const <RAOE2ExperienceRewrite>[];
    }

    return value
        .whereType<Map>()
        .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
        .map(RAOE2ExperienceRewrite.fromMap)
        .toList(growable: false);
  }

  static void _writeSection(
    StringBuffer buffer, {
    required String title,
    required String body,
  }) {
    if (body.trim().isEmpty) {
      return;
    }
    buffer.writeln(title);
    buffer.writeln(body.trim());
    buffer.writeln();
  }

  static String _buildExperienceText(Experience experience) {
    final achievements = experience.achievements
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => '- $item')
        .join('\n');
    final bodyParts = <String>[
      '${experience.position.trim()} at ${experience.company.trim()}'.trim(),
      experience.description.trim(),
      achievements,
    ].where((item) => item.isNotEmpty).toList(growable: false);
    return bodyParts.join('\n');
  }

  static String _buildExperienceTextFromRewrite(
    Experience original,
    RAOE2ExperienceRewrite rewrite,
  ) {
    final achievements = rewrite.achievements.isNotEmpty
        ? rewrite.achievements.map((item) => '- $item').join('\n')
        : original.achievements
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .map((item) => '- $item')
            .join('\n');

    final header = '${rewrite.position.isNotEmpty ? rewrite.position : original.position} '
        'at ${rewrite.company.isNotEmpty ? rewrite.company : original.company}'.trim();

    final bodyParts = <String>[
      header,
      rewrite.description.isNotEmpty ? rewrite.description : original.description,
      achievements,
    ].where((item) => item.isNotEmpty).toList(growable: false);

    return bodyParts.join('\n');
  }
}

/// Handles keyword extraction and gap analysis for resume/job description pairs.
class RAOE2KeywordAnalyzer {
  static Set<String> extractKeywords(String sourceText) {
    return sourceText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_stopWords.contains(word))
        .toSet();
  }

  static Set<String> findMissingKeywords({
    required String resumeText,
    required String jobDescription,
  }) {
    final resumeKeywords = extractKeywords(resumeText);
    final jobKeywords = extractKeywords(jobDescription);
    return jobKeywords.difference(resumeKeywords);
  }

  static const Set<String> _stopWords = <String>{
    'the',
    'and',
    'for',
    'with',
    'that',
    'this',
    'from',
    'are',
    'was',
    'but',
    'not',
    'you',
    'all',
    'can',
    'has',
    'have',
    'will',
    'your',
    'our',
    'their',
    'they',
    'his',
    'her',
    'its',
    'who',
    'what',
    'when',
    'where',
    'how',
    'why',
    'which',
    'while',
    'were',
    'had',
    'been',
    'out',
    'any',
    'get',
    'use',
    'one',
    'two',
    'may',
    'also',
    'such',
    'more',
    'than',
    'other',
    'some',
    'these',
    'those',
    'each',
    'per',
    'via',
    'etc',
    'job',
    'role',
    'must',
    'should',
    'could',
    'would',
    'like',
    'just',
    'very',
    'etc.',
  };
}