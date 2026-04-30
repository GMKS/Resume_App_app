import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum ClassicTempContactKind {
  phone,
  email,
  location,
  linkedin,
  github,
  website,
}

class ClassicTempContactItem {
  const ClassicTempContactItem({
    required this.kind,
    required this.label,
  });

  final ClassicTempContactKind kind;
  final String label;
}

class ClassicTempExperienceEntry {
  const ClassicTempExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    this.detailLines = const [],
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> detailLines;
}

class ClassicTempEducationEntry {
  const ClassicTempEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateRange,
    this.supportingLines = const [],
  });

  final String degree;
  final String institutionLine;
  final String dateRange;
  final List<String> supportingLines;
}

class ClassicTempProjectEntry {
  const ClassicTempProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.links = const [],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class ClassicTempCertificationEntry {
  const ClassicTempCertificationEntry({
    required this.title,
    this.supportingLines = const [],
  });

  final String title;
  final List<String> supportingLines;
}

class ClassicTempTemplateSupport {
  static const int accentHex = 0xFF6189BF;
  static const int inkHex = 0xFF312B28;
  static const int mutedHex = 0xFF6C6763;
  static const int subtleHex = 0xFF8D8782;
  static const int ruleHex = 0xFFD3D7DC;
  static const int pageHex = 0xFFFFFFFF;

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-*•▪■□✪✦★☆➣◦○]+\s*',
  );

  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portal|access|visit|preview|view)\b[:\s-]*$',
    caseSensitive: false,
  );

  static List<ClassicTempContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
  }) {
    final items = <ClassicTempContactItem>[];

    void add(ClassicTempContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ClassicTempContactKind.linkedin ||
              kind == ClassicTempContactKind.github ||
              kind == ClassicTempContactKind.website)) {
        label = compactLink(label);
      }
      if (label.isNotEmpty) {
        items.add(ClassicTempContactItem(kind: kind, label: label));
      }
    }

    add(ClassicTempContactKind.phone, info?.phone);
    add(ClassicTempContactKind.email, info?.email);
    add(ClassicTempContactKind.location, info?.address);
    add(ClassicTempContactKind.linkedin, info?.linkedIn);
    add(ClassicTempContactKind.github, info?.github);
    add(ClassicTempContactKind.website, info?.website);

    return List.unmodifiable(items);
  }

  static List<String> contactLines(PersonalInfo? info) {
    final items = contactItems(info);
    final lines = <String>[];
    final primary = <String>[];
    final links = <String>[];

    for (final item in items) {
      if (item.kind == ClassicTempContactKind.phone ||
          item.kind == ClassicTempContactKind.email) {
        primary.add(item.label);
      } else if (item.kind == ClassicTempContactKind.location) {
        lines.add(item.label);
      } else {
        links.add(item.label);
      }
    }

    final mergedLines = <String>[];
    if (primary.isNotEmpty) {
      mergedLines.add(primary.join('  |  '));
    }
    mergedLines.addAll(lines);
    if (links.isNotEmpty) {
      mergedLines.add(links.join('  |  '));
    }

    return List.unmodifiable(mergedLines);
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(value ?? '', maxItems: maxItems);
  }

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = skills
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);
    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
  }

  static List<ClassicTempExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int maxDetailLines = 3,
    bool yearOnly = false,
  }) {
    final entries = experiences.map((experience) {
      final companyParts = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).toList(growable: false);

      final detailLines = <String>[];
      for (final achievement in experience.achievements) {
        final cleaned = _cleanListMarker(achievement);
        if (cleaned.isNotEmpty && !detailLines.contains(cleaned)) {
          detailLines.add(cleaned);
        }
      }
      for (final line in splitLines(experience.description)) {
        if (!detailLines.contains(line)) {
          detailLines.add(line);
        }
      }

      return ClassicTempExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine:
            companyParts.isNotEmpty ? companyParts.join(' - ') : 'Company',
        dateRange: yearOnly
            ? yearRange(
                experience.startDate,
                experience.endDate,
                experience.isCurrentlyWorking,
              )
            : monthRange(
                experience.startDate,
                experience.endDate,
                experience.isCurrentlyWorking,
              ),
        detailLines: detailLines.take(maxDetailLines).toList(growable: false),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<ClassicTempEducationEntry> educationEntries(
    List<Education> education, {
    int? maxItems,
    int maxDetailLines = 2,
    bool yearOnly = false,
  }) {
    final entries = education.map((item) {
      final degree = [item.degree.trim(), item.fieldOfStudy.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final institutionParts = [
        item.institution.trim(),
        (item.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).toList(growable: false);

      final supportingLines = <String>[];
      final grade = item.grade?.trim() ?? '';
      if (grade.isNotEmpty) {
        supportingLines.add('Grade: $grade');
      }
      supportingLines.addAll(
        splitLines(item.description ?? '', maxItems: maxDetailLines),
      );

      return ClassicTempEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Education',
        institutionLine: institutionParts.isNotEmpty
            ? institutionParts.join(' - ')
            : 'Institution',
        dateRange: yearOnly
            ? yearRange(item.startDate, item.endDate, item.isCurrentlyStudying)
            : monthRange(
                item.startDate,
                item.endDate,
                item.isCurrentlyStudying,
              ),
        supportingLines: supportingLines,
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<ClassicTempProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int maxDetailLines = 3,
  }) {
    final entries = projects.map((project) {
      final links = <String>[];
      final seenLinks = <String>{};

      void collectLinks(String source) {
        for (final match in _linkPattern.allMatches(source)) {
          final compact = compactLink(match.group(0) ?? '');
          final key = compact.toLowerCase();
          if (compact.isEmpty || !seenLinks.add(key)) {
            continue;
          }
          links.add(compact);
        }
      }

      collectLinks(project.url ?? '');
      collectLinks(project.description);

      final detailLines = <String>[];
      for (final line
          in splitLines(project.description, omitStandaloneLinks: true)) {
        final cleaned = _cleanProjectSummaryLine(line);
        if (cleaned.isEmpty || detailLines.contains(cleaned)) {
          continue;
        }
        detailLines.add(cleaned);
        if (detailLines.length >= maxDetailLines) {
          break;
        }
      }

      if (detailLines.isEmpty) {
        for (final technology in project.technologies
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)) {
          if (detailLines.contains(technology)) {
            continue;
          }
          detailLines.add(technology);
          if (detailLines.length >= maxDetailLines) {
            break;
          }
        }
      }

      return ClassicTempProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: detailLines,
        links: links,
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<ClassicTempCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final entries = certifications.map((certification) {
      final title = certification.name.trim().isNotEmpty
          ? certification.name.trim()
          : 'Certification';
      final supportingLines = <String>[];

      final issuer = certification.issuer.trim();
      if (issuer.isNotEmpty) {
        supportingLines.add(issuer);
      }

      final dateParts = <String>[];
      if (certification.issueDate != null) {
        dateParts.add(
          'Issued ${DateFormat('MMM yyyy').format(certification.issueDate!)}',
        );
      }
      if (certification.expiryDate != null) {
        dateParts.add(
          'Expires ${DateFormat('MMM yyyy').format(certification.expiryDate!)}',
        );
      }
      if (dateParts.isNotEmpty) {
        supportingLines.add(dateParts.join(' | '));
      }

      final credentialId = certification.credentialId?.trim() ?? '';
      if (credentialId.isNotEmpty) {
        supportingLines.add('Credential ID: $credentialId');
      }

      final credentialUrl = compactLink(certification.credentialUrl ?? '');
      if (credentialUrl.isNotEmpty) {
        supportingLines.add(credentialUrl);
      }

      return ClassicTempCertificationEntry(
        title: title,
        supportingLines: supportingLines,
      );
    }).toList(growable: false);

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
          return proficiency.isNotEmpty ? '$name - $proficiency' : name;
        })
        .where((language) => language.isNotEmpty)
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
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final values = raw
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .where((part) => !omitStandaloneLinks || !_isStandaloneLink(part))
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }

    return values.take(maxItems).toList(growable: false);
  }

  static String compactLink(String value) {
    var compact = value.trim();
    if (compact.isEmpty) {
      return '';
    }

    compact = compact.replaceFirst(RegExp(r'^[<(\[]+'), '');
    compact = compact.replaceFirst(RegExp(r'[>\]),.;:]+$'), '');
    compact = compact.replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    compact = compact.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    compact = compact.replaceFirst(RegExp(r'[>\]),.;:]+$'), '');

    return compact.replaceAll(RegExp(r'/$'), '');
  }

  static String monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText = isCurrent || end == null
        ? 'Present'
        : DateFormat('MMM yyyy').format(end);
    return '${DateFormat('MMM yyyy').format(start)} - $endText';
  }

  static String yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText =
        isCurrent || end == null ? 'Present' : DateFormat('yyyy').format(end);
    return '${DateFormat('yyyy').format(start)} - $endText';
  }

  static String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingMarkerPattern, '');
  }

  static bool _isStandaloneLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final compact = compactLink(trimmed);
    if (compact.isEmpty) {
      return false;
    }

    final matches = _linkPattern.allMatches(trimmed).toList(growable: false);
    if (matches.isEmpty) {
      return false;
    }

    final stripped = trimmed
        .replaceAllMapped(_linkPattern, (_) => ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return stripped.isEmpty;
  }

  static String _cleanProjectSummaryLine(String value) {
    final linkCount = _linkPattern.allMatches(value).length;
    var cleaned = value
        .replaceAllMapped(_linkPattern, (_) => ' ')
        .replaceAll(RegExp(r'\s+([,.;:])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    cleaned = cleaned.replaceAll(RegExp(r'^[|,:;()\-\s]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[|,:;()\-\s]+$'), '');
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(?:and|or)\b\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceFirst(
      RegExp(r'\b(?:and|or)\s*$', caseSensitive: false),
      '',
    );
    cleaned = cleaned.trim();

    if (cleaned.isEmpty || _linkOnlyLabelPattern.hasMatch(cleaned)) {
      return '';
    }

    final wordCount =
        cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    if (linkCount > 0 && wordCount <= 1) {
      return '';
    }

    return cleaned;
  }
}
