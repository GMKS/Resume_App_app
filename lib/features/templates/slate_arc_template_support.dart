import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum SlateArcContactKind {
  address,
  phone,
  email,
  linkedin,
  github,
  website,
}

class SlateArcContactItem {
  const SlateArcContactItem({
    required this.kind,
    required this.label,
  });

  final SlateArcContactKind kind;
  final String label;
}

class SlateArcEducationEntry {
  const SlateArcEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateLabel,
  });

  final String degree;
  final String institutionLine;
  final String dateLabel;
}

class SlateArcExperienceEntry {
  const SlateArcExperienceEntry({
    required this.title,
    required this.metaLine,
    required this.dateRange,
    this.detailLines = const <String>[],
  });

  final String title;
  final String metaLine;
  final String dateRange;
  final List<String> detailLines;
}

class SlateArcProjectEntry {
  const SlateArcProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class SlateArcCertificationEntry {
  const SlateArcCertificationEntry({
    required this.name,
    this.metaLine = '',
  });

  final String name;
  final String metaLine;
}

class SlateArcTemplateSupport {
  static const int pageHex = 0xFFF7F7F5;
  static const int headerHex = 0xFFE1E2E3;
  static const int headerInkHex = 0xFF494949;
  static const int sectionInkHex = 0xFF3C4650;
  static const int bodyMutedHex = 0xFF6F747A;
  static const int dividerHex = 0xFFD9DADB;
  static const int photoBgHex = 0xFF3C4650;

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-*•▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );
  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );
  static final RegExp _lineOrSentenceSeparatorPattern = RegExp(
    r'\n+|(?<=[.!?])\s+',
  );
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );
  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|website|web|portfolio|repo|repository|github|gitlab|docs?|documentation|reference|references|preview|view)\b[:\s-]*$',
    caseSensitive: false,
  );

  static String displayName(ResumeModel? resume) {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  static String displayTitle(ResumeModel? resume) {
    final jobTitle = resume?.personalInfo.jobTitle?.trim() ?? '';
    if (jobTitle.isNotEmpty) {
      return jobTitle;
    }

    final title = resume?.title.trim() ?? '';
    if (title.isNotEmpty) {
      return title;
    }

    return 'Software Engineer';
  }

  static List<SlateArcContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <SlateArcContactItem>[];
    final seen = <String>{};

    void add(SlateArcContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == SlateArcContactKind.linkedin ||
              kind == SlateArcContactKind.github ||
              kind == SlateArcContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(SlateArcContactItem(kind: kind, label: label));
    }

    if (includeAddress) {
      add(SlateArcContactKind.address, info?.address);
    }
    add(SlateArcContactKind.phone, info?.phone);
    add(SlateArcContactKind.email, info?.email);
    add(SlateArcContactKind.linkedin, info?.linkedIn);
    add(SlateArcContactKind.github, info?.github);
    add(SlateArcContactKind.website, info?.website);

    return List.unmodifiable(items);
  }

  static List<String> languageLines(
    List<Language> languages, {
    int? maxItems,
  }) {
    final values = languages
        .map((language) {
          final name = language.name.trim();
          final proficiency = language.proficiency.trim();
          if (name.isEmpty) {
            return '';
          }
          return proficiency.isNotEmpty ? '$name $proficiency' : name;
        })
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
  }

  static List<SlateArcEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
  }) {
    final entries = educations.map((education) {
      final degree = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      return SlateArcEducationEntry(
        degree: degree.isNotEmpty ? degree : 'B.Sc. Computer Science',
        institutionLine: education.institution.trim().isNotEmpty
            ? education.institution.trim()
            : 'State University',
        dateLabel: completionYear(
          education.startDate,
          education.endDate,
          education.isCurrentlyStudying,
        ),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = skills
        .map((skill) => skill.name.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(
      value ?? '',
      maxItems: maxItems,
      omitStandaloneLinks: true,
    );
  }

  static List<SlateArcExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines = 1,
  }) {
    final entries = experiences.map((experience) {
      final title = experience.position.trim().isNotEmpty
          ? experience.position.trim()
          : 'Senior Developer';
      final metaLine = experience.company.trim().isNotEmpty
          ? experience.company.trim()
          : 'TechCorp';
      final detailLines = <String>[];

      for (final line in splitLines(
        experience.description,
        omitStandaloneLinks: true,
      )) {
        if (!detailLines.contains(line)) {
          detailLines.add(line);
        }
        if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
          break;
        }
      }

      if (maxDetailLines == null || detailLines.length < maxDetailLines) {
        for (final achievement in experience.achievements) {
          for (final line in splitLines(
            achievement,
            omitStandaloneLinks: true,
          )) {
            if (!detailLines.contains(line)) {
              detailLines.add(line);
            }
            if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
              break;
            }
          }
          if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
            break;
          }
        }
      }

      return SlateArcExperienceEntry(
        title: title,
        metaLine: metaLine,
        dateRange: yearRange(
          experience.startDate,
          experience.endDate,
          experience.isCurrentlyWorking,
        ),
        detailLines: List.unmodifiable(detailLines),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<SlateArcProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines = 1,
    bool compactLinks = true,
  }) {
    final entries = projects.map((project) {
      final detailLines = <String>[];

      if (maxDetailLines == null || maxDetailLines > 0) {
        for (final line in splitLines(
          project.description,
          omitStandaloneLinks: true,
        )) {
          final cleaned = _cleanProjectLine(line);
          if (cleaned.isNotEmpty && !detailLines.contains(cleaned)) {
            detailLines.add(cleaned);
          }
          if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
            break;
          }
        }
      }

      if ((maxDetailLines == null || maxDetailLines > 0) &&
          detailLines.isEmpty &&
          project.technologies.isNotEmpty) {
        detailLines.add(
          project.technologies
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .take(3)
              .join(' | '),
        );
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(
        project.url ?? '',
        links,
        seen,
        compactLinks: compactLinks,
      );
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return SlateArcProjectEntry(
        title: project.title.trim().isNotEmpty
            ? project.title.trim()
            : 'Portfolio Website',
        detailLines: List.unmodifiable(
          detailLines.where((value) => value.trim().isNotEmpty),
        ),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<SlateArcCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final entries = certifications.map((certification) {
      final name = certification.name.trim();
      final issuer = certification.issuer.trim();
      final metaLine = issuer.isNotEmpty
          ? issuer
          : (certification.credentialId?.trim() ?? '');
      return SlateArcCertificationEntry(
        name: name.isNotEmpty ? name : 'AWS Certified Developer',
        metaLine: metaLine,
      );
    }).where((entry) => entry.name.trim().isNotEmpty).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<String> splitLines(
    String text, {
    int? maxItems,
    bool omitStandaloneLinks = false,
  }) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final parts = <String>[];
    for (final rawLine in normalized.split(_lineOrSentenceSeparatorPattern)) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final segments = _inlineBulletSeparatorPattern.hasMatch(trimmed)
          ? trimmed.split(_inlineBulletSeparatorPattern)
          : <String>[trimmed];
      for (final segment in segments) {
        final cleaned = segment
            .trim()
            .replaceFirst(_leadingMarkerPattern, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.isEmpty) {
          continue;
        }

        final linkOnly = _linkPattern.hasMatch(cleaned) &&
            cleaned.replaceAll(_linkPattern, '').trim().isEmpty;
        if (omitStandaloneLinks &&
            (linkOnly || _linkOnlyLabelPattern.hasMatch(cleaned))) {
          continue;
        }

        if (!parts.contains(cleaned)) {
          parts.add(cleaned);
        }
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(parts);
    }
    return List.unmodifiable(parts.take(maxItems));
  }

  static String compactLink(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return '';
    }

    result = result.replaceFirst(RegExp(r'^mailto:', caseSensitive: false), '');
    result = result.replaceFirst(
      RegExp(r'^https?:\/\/', caseSensitive: false),
      '',
    );
    result = result.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');

    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  static String completionYear(
    DateTime start,
    DateTime? end,
    bool isCurrent,
  ) {
    if (isCurrent) {
      return 'Present';
    }
    return DateFormat('yyyy').format(end ?? start);
  }

  static String yearRange(
    DateTime start,
    DateTime? end,
    bool isCurrent,
  ) {
    final startLabel = DateFormat('yyyy').format(start);
    final endLabel = isCurrent
        ? 'Present'
        : DateFormat('yyyy').format(end ?? start);
    return '$startLabel - $endLabel';
  }

  static String _cleanProjectLine(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    final linkOnly = _linkPattern.hasMatch(cleaned) &&
        cleaned.replaceAll(_linkPattern, '').trim().isEmpty;
    if (linkOnly || _linkOnlyLabelPattern.hasMatch(cleaned)) {
      return '';
    }

    return cleaned
        .replaceAll(_linkPattern, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[|•·,:;\-]+$'), '')
        .trim();
  }

  static void _collectLinks(
    String source,
    List<String> output,
    Set<String> seen, {
    required bool compactLinks,
  }) {
    for (final match in _linkPattern.allMatches(source)) {
      final raw = match.group(0)?.trim() ?? '';
      final label = compactLinks ? compactLink(raw) : raw;
      final key = label.toLowerCase();
      if (label.isEmpty || !seen.add(key)) {
        continue;
      }
      output.add(label);
    }
  }
}