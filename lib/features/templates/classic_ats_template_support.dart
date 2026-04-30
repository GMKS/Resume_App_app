import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum ClassicAtsContactKind {
  email,
  phone,
  location,
  linkedin,
  github,
  website,
}

class ClassicAtsContactItem {
  const ClassicAtsContactItem({
    required this.kind,
    required this.label,
  });

  final ClassicAtsContactKind kind;
  final String label;
}

class ClassicAtsExperienceEntry {
  const ClassicAtsExperienceEntry({
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

class ClassicAtsEducationEntry {
  const ClassicAtsEducationEntry({
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

class ClassicAtsProjectEntry {
  const ClassicAtsProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.url = '',
  });

  final String title;
  final List<String> detailLines;
  final String url;
}

class ClassicAtsTemplateSupport {
  static const int headerHex = 0xFF1B1B31;
  static const int pageHex = 0xFFFFFFFF;
  static const int inkHex = 0xFF23253A;
  static const int bodyHex = 0xFF666A76;
  static const int mutedHex = 0xFF8E91A3;
  static const int dateBgHex = 0xFFF0F1F5;

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-•*▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );

  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );

  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portal|access|visit|preview|view)\b[:\s-]*$',
    caseSensitive: false,
  );

  static List<ClassicAtsContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    int? maxItems,
  }) {
    final items = <ClassicAtsContactItem>[];

    void add(ClassicAtsContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ClassicAtsContactKind.linkedin ||
              kind == ClassicAtsContactKind.github ||
              kind == ClassicAtsContactKind.website)) {
        label = compactLink(label);
      }
      if (label.isNotEmpty) {
        items.add(ClassicAtsContactItem(kind: kind, label: label));
      }
    }

    add(ClassicAtsContactKind.email, info?.email);
    add(ClassicAtsContactKind.phone, info?.phone);
    add(ClassicAtsContactKind.location, info?.address);
    add(ClassicAtsContactKind.linkedin, info?.linkedIn);
    add(ClassicAtsContactKind.github, info?.github);
    add(ClassicAtsContactKind.website, info?.website);

    if (maxItems == null) {
      return List.unmodifiable(items);
    }
    return List.unmodifiable(items.take(maxItems));
  }

  static List<String> contactLabels(
    PersonalInfo? info, {
    bool compactLinks = true,
    int? maxItems,
  }) {
    return contactItems(
      info,
      compactLinks: compactLinks,
      maxItems: maxItems,
    ).map((item) => item.label).toList(growable: false);
  }

  static String contactBarText(
    PersonalInfo? info, {
    bool compactLinks = true,
    int? maxItems,
  }) {
    return contactLabels(
      info,
      compactLinks: compactLinks,
      maxItems: maxItems,
    ).join('  |  ');
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(
      value ?? '',
      maxItems: maxItems,
      omitStandaloneLinks: true,
    );
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

  static List<ClassicAtsExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int maxDetailLines = 3,
    bool yearOnly = true,
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
      }
      for (final achievement in experience.achievements) {
        for (final line in splitLines(
          achievement,
          omitStandaloneLinks: true,
        )) {
          if (!detailLines.contains(line)) {
            detailLines.add(line);
          }
        }
      }

      return ClassicAtsExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
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

  static List<ClassicAtsEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    int maxSupportingLines = 2,
    bool yearOnly = true,
  }) {
    final entries = educations.map((education) {
      final degree = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');
      final institutionLine = [
        education.institution.trim(),
        (education.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  •  ');

      final supportingLines = <String>[];
      final grade = education.grade?.trim() ?? '';
      if (grade.isNotEmpty) {
        supportingLines.add(grade);
      }
      for (final line in splitLines(
        education.description ?? '',
        omitStandaloneLinks: true,
      )) {
        if (!supportingLines.contains(line)) {
          supportingLines.add(line);
        }
        if (supportingLines.length >= maxSupportingLines) {
          break;
        }
      }

      return ClassicAtsEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Education',
        institutionLine:
            institutionLine.isNotEmpty ? institutionLine : 'Institution',
        dateRange: yearOnly
            ? yearRange(
                education.startDate,
                education.endDate,
                education.isCurrentlyStudying,
              )
            : monthRange(
                education.startDate,
                education.endDate,
                education.isCurrentlyStudying,
              ),
        supportingLines:
            supportingLines.take(maxSupportingLines).toList(growable: false),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<ClassicAtsProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int maxDetailLines = 2,
    bool compactLinks = true,
  }) {
    final entries = projects.map((project) {
      final detailLines = <String>[];
      if (project.description.trim().isNotEmpty) {
        for (final line in splitLines(
          project.description,
          omitStandaloneLinks: true,
        )) {
          final cleaned = _cleanProjectSummaryLine(line);
          if (cleaned.isNotEmpty && !detailLines.contains(cleaned)) {
            detailLines.add(cleaned);
          }
          if (detailLines.length >= maxDetailLines) {
            break;
          }
        }
      }

      if (detailLines.isEmpty) {
        final technologies = project.technologies
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (technologies.isNotEmpty) {
          detailLines.add(technologies.join(' • '));
        }
      }

      final rawUrl = (project.url ?? '').trim().isNotEmpty
          ? project.url!.trim()
          : _firstLink(project.description);

      return ClassicAtsProjectEntry(
        title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(detailLines),
        url: compactLinks ? compactLink(rawUrl) : rawUrl.trim(),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<String> certificationLines(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final values = certifications
        .map((certification) {
          final name = certification.name.trim();
          final issuer = certification.issuer.trim();
          final credentialId = certification.credentialId?.trim() ?? '';
          if (name.isEmpty) {
            return '';
          }
          final parts = <String>[name];
          if (issuer.isNotEmpty) {
            parts.add(issuer);
          }
          if (credentialId.isNotEmpty) {
            parts.add(credentialId);
          }
          return parts.join('  •  ');
        })
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
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
        .where((line) => line.isNotEmpty)
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

    final normalized = raw
        .replaceAll(_inlineBulletSeparatorPattern, '\n')
        .replaceAll(RegExp(r'\s+→\s+'), '\n');
    final segments = normalized
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .where((part) => !omitStandaloneLinks || !_isStandaloneLink(part))
        .toList(growable: false);

    if (maxItems == null) {
      return segments;
    }
    return segments.take(maxItems).toList(growable: false);
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

  static String yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final startLabel = start.year.toString();
    final endLabel = isCurrent
        ? 'Present'
        : (end != null ? end.year.toString() : startLabel);
    return '$startLabel - $endLabel';
  }

  static String monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final format = DateFormat('MMM yyyy');
    final startLabel = format.format(start);
    final endLabel =
        isCurrent ? 'Present' : (end != null ? format.format(end) : startLabel);
    return '$startLabel - $endLabel';
  }

  static String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingMarkerPattern, '');
  }

  static bool _isStandaloneLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final match = _linkPattern.firstMatch(trimmed);
    return match != null && match.group(0) == trimmed;
  }

  static String _firstLink(String value) {
    final match = _linkPattern.firstMatch(value);
    return match?.group(0)?.trim() ?? '';
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