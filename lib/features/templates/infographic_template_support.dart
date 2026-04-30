import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

class InfographicSkillEntry {
  const InfographicSkillEntry({
    required this.name,
    required this.progress,
  });

  final String name;
  final double progress;
}

class InfographicExperienceEntry {
  const InfographicExperienceEntry({
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

class InfographicEducationEntry {
  const InfographicEducationEntry({
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

class InfographicProjectEntry {
  const InfographicProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.links = const [],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class InfographicTemplateSupport {
  static const int canvasHex = 0xFFF5F6F2;
  static const int panelHex = 0xFFFFFCF8;
  static const int softPanelHex = 0xFFE6F1EA;
  static const int warmPanelHex = 0xFFF2E1D3;
  static const int skyPanelHex = 0xFFDDECF4;
  static const int lineHex = 0xFFD7E2E7;
  static const int inkHex = 0xFF26485A;
  static const int mutedHex = 0xFF617785;
  static const int accentBlendHex = 0xFF82B3C1;

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

  static List<String> contactItems(
    PersonalInfo? info, {
    int maxItems = 4,
    bool compactLinks = true,
  }) {
    final items = <String>[];

    void add(String? value, {bool compact = false}) {
      var label = value?.trim() ?? '';
      if (compact) {
        label = compactLink(label);
      }
      if (label.isNotEmpty && !items.contains(label)) {
        items.add(label);
      }
    }

    add(info?.phone);
    add(info?.email);
    add(info?.linkedIn, compact: compactLinks);
    add(info?.github, compact: compactLinks);
    add(info?.website, compact: compactLinks);

    return items.take(maxItems).toList(growable: false);
  }

  static String baseLabel(PersonalInfo? info) {
    final address = info?.address.trim() ?? '';
    if (address.isNotEmpty) {
      return address;
    }

    final email = info?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }

    return 'Available Remote';
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(
      value ?? '',
      maxItems: maxItems,
      omitStandaloneLinks: true,
    );
  }

  static List<InfographicSkillEntry> skillEntries(
    List<Skill> skills, {
    int? maxItems,
    int skip = 0,
  }) {
    final values = skills
        .where((skill) => skill.name.trim().isNotEmpty)
        .map(
          (skill) => InfographicSkillEntry(
            name: skill.name.trim(),
            progress: _skillProgress(skill.proficiency),
          ),
        )
        .toList(growable: false);

    final sliced =
        skip > 0 ? values.skip(skip).toList(growable: false) : values;
    if (maxItems == null) {
      return sliced;
    }

    return sliced.take(maxItems).toList(growable: false);
  }

  static List<InfographicExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines,
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
        _addUnique(detailLines, line);
      }
      for (final achievement in experience.achievements) {
        for (final line in splitLines(
          achievement,
          omitStandaloneLinks: true,
        )) {
          _addUnique(detailLines, line);
        }
      }

      return InfographicExperienceEntry(
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
        detailLines: maxDetailLines == null
            ? List.unmodifiable(detailLines)
            : List.unmodifiable(
                detailLines.take(maxDetailLines).toList(growable: false),
              ),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<InfographicEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    int maxSupportLines = 2,
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
      final description = education.description?.trim() ?? '';
      if (description.isNotEmpty) {
        for (final line in splitLines(
          description,
          maxItems: maxSupportLines,
          omitStandaloneLinks: true,
        )) {
          _addUnique(supportingLines, line);
          if (supportingLines.length >= maxSupportLines) {
            break;
          }
        }
      }

      return InfographicEducationEntry(
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
            supportingLines.take(maxSupportLines).toList(growable: false),
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
          if (name.isEmpty) {
            return '';
          }

          final parts = <String>[name];
          final issuer = certification.issuer.trim();
          if (issuer.isNotEmpty) {
            parts.add(issuer);
          }
          if (certification.issueDate != null) {
            parts.add(
                'Issued ${DateFormat('MMM yyyy').format(certification.issueDate!)}');
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

  static List<InfographicProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines,
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
          if (cleaned.isNotEmpty) {
            _addUnique(detailLines, cleaned);
          }
          if (maxDetailLines != null && detailLines.length >= maxDetailLines) {
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

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );
      _collectLinks(
        project.url,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return InfographicProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(detailLines),
        links: List.unmodifiable(links),
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
          if (name.isEmpty) {
            return '';
          }

          final proficiency = language.proficiency.trim();
          return proficiency.isNotEmpty ? '$name  •  $proficiency' : name;
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
    compact =
        compact.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
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

  static double _skillProgress(int proficiency) {
    final normalized = proficiency.clamp(1, 5);
    return (0.42 + ((normalized - 1) * 0.13)).clamp(0.42, 0.94).toDouble();
  }

  static void _addUnique(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || values.contains(trimmed)) {
      return;
    }
    values.add(trimmed);
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

  static void _collectLinks(
    String? raw,
    List<String> values,
    Set<String> seen, {
    required bool compactLinks,
  }) {
    final source = raw?.trim() ?? '';
    if (source.isEmpty) {
      return;
    }

    for (final match in _linkPattern.allMatches(source)) {
      final matchText = match.group(0)?.trim() ?? '';
      if (matchText.isEmpty) {
        continue;
      }

      final normalized = compactLinks ? compactLink(matchText) : matchText;
      final key = normalized.toLowerCase();
      if (normalized.isEmpty || !seen.add(key)) {
        continue;
      }

      values.add(normalized);
    }
  }
}
