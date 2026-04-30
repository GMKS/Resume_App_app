import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum EditorialFrameContactKind {
  phone,
  email,
  linkedin,
  github,
  website,
}

class EditorialFrameContactItem {
  const EditorialFrameContactItem({
    required this.kind,
    required this.label,
  });

  final EditorialFrameContactKind kind;
  final String label;
}

class EditorialFrameEducationEntry {
  const EditorialFrameEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateLabel,
  });

  final String degree;
  final String institutionLine;
  final String dateLabel;
}

class EditorialFrameExperienceEntry {
  const EditorialFrameExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    this.detailLines = const <String>[],
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> detailLines;
}

class EditorialFrameProjectEntry {
  const EditorialFrameProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class EditorialFrameCertificationEntry {
  const EditorialFrameCertificationEntry({
    required this.name,
    this.metaLine = '',
  });

  final String name;
  final String metaLine;
}

class EditorialFrameTemplateSupport {
  static const int paperHex = 0xFFF8F5F1;
  static const int accentHex = 0xFF8D6B49;
  static const int inkHex = 0xFF2C2A28;
  static const int mutedHex = 0xFF6E675F;
  static const int lineHex = 0xFFD8CEC4;
  static const int photoTintHex = 0xFFE7DDD1;

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-*•▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );
  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
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

  static String displayAddress(ResumeModel? resume) {
    return resume?.personalInfo.address.trim() ?? '';
  }

  static List<EditorialFrameContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
  }) {
    final items = <EditorialFrameContactItem>[];
    final seen = <String>{};

    void add(EditorialFrameContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == EditorialFrameContactKind.linkedin ||
              kind == EditorialFrameContactKind.github ||
              kind == EditorialFrameContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(EditorialFrameContactItem(kind: kind, label: label));
    }

    add(EditorialFrameContactKind.phone, info?.phone);
    add(EditorialFrameContactKind.email, info?.email);
    add(EditorialFrameContactKind.linkedin, info?.linkedIn);
    add(EditorialFrameContactKind.github, info?.github);
    add(EditorialFrameContactKind.website, info?.website);

    return List.unmodifiable(items);
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(
      value ?? '',
      maxItems: maxItems,
      omitStandaloneLinks: true,
    );
  }

  static List<EditorialFrameExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines = 2,
  }) {
    final entries = experiences.map((experience) {
      final companyLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  •  ');

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

      return EditorialFrameExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: monthRange(
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

  static List<EditorialFrameEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
  }) {
    final entries = educations.map((education) {
      final degree = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');
      return EditorialFrameEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Degree',
        institutionLine: education.institution.trim().isNotEmpty
            ? education.institution.trim()
            : 'Institution',
        dateLabel: yearLabel(
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

  static List<EditorialFrameProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines = 2,
    bool compactLinks = true,
  }) {
    final entries = projects.map((project) {
      final detailLines = <String>[];
      for (final line in splitLines(
        project.description,
        omitStandaloneLinks: true,
      )) {
        final cleaned = _cleanProjectSummaryLine(line);
        if (cleaned.isNotEmpty && !detailLines.contains(cleaned)) {
          detailLines.add(cleaned);
        }
        if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
          break;
        }
      }

      if (detailLines.isEmpty && project.technologies.isNotEmpty) {
        detailLines.add(
          project.technologies
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join('  •  '),
        );
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(project.url ?? '', links, seen, compactLinks: compactLinks);
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return EditorialFrameProjectEntry(
        title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(detailLines),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<EditorialFrameCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final entries = certifications
        .map((certification) {
          final name = certification.name.trim();
          if (name.isEmpty) {
            return null;
          }
          final issuer = certification.issuer.trim();
          return EditorialFrameCertificationEntry(
            name: name,
            metaLine: issuer,
          );
        })
        .whereType<EditorialFrameCertificationEntry>()
        .toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
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
          return proficiency.isNotEmpty ? '$name  •  $proficiency' : name;
        })
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
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
    for (final rawLine in normalized.split('\n')) {
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

  static String monthRange(
    DateTime start,
    DateTime? end,
    bool isCurrent,
  ) {
    final formatter = DateFormat('MMM yyyy');
    final startLabel = formatter.format(start);
    final endLabel = isCurrent ? 'Present' : formatter.format(end ?? start);
    return '$startLabel - $endLabel';
  }

  static String yearLabel(
    DateTime start,
    DateTime? end,
    bool isCurrent,
  ) {
    if (isCurrent) {
      return 'Present';
    }
    return DateFormat('yyyy').format(end ?? start);
  }

  static String _cleanProjectSummaryLine(String value) {
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