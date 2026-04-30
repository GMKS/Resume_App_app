import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

class AtsFriendlyModernExperienceEntry {
  const AtsFriendlyModernExperienceEntry({
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

class AtsFriendlyModernEducationEntry {
  const AtsFriendlyModernEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.yearLabel,
  });

  final String degree;
  final String institutionLine;
  final String yearLabel;
}

class AtsFriendlyModernProjectEntry {
  const AtsFriendlyModernProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.links = const [],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class AtsFriendlyModernTemplateSupport {
  static const int pageHex = 0xFFFFFFFF;
  static const int inkHex = 0xFF1F2937;
  static const int bodyHex = 0xFF4B5563;
  static const int mutedHex = 0xFF9CA3AF;
  static const int dividerHex = 0xFFD1D5DB;
  static const int tagHex = 0xFFF28C28;
  static const int ruleHex = 0xFF1F5EA8;
  static const int accentHex = 0xFF6670EA;

  static const List<String> defaultSectionOrder = <String>[
    'summary',
    'skills',
    'experience',
    'education',
    'projects',
    'certifications',
    'languages',
  ];

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

  static List<String> primaryContactItems(PersonalInfo? info) {
    return [
      info?.email.trim() ?? '',
      info?.phone.trim() ?? '',
      info?.address.trim() ?? '',
    ].where((item) => item.isNotEmpty).toList(growable: false);
  }

  static List<String> secondaryContactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
  }) {
    final values = [
      info?.linkedIn?.trim() ?? '',
      info?.github?.trim() ?? '',
      info?.website?.trim() ?? '',
    ].map((item) => compactLinks ? compactLink(item) : item).where((item) {
      return item.isNotEmpty;
    }).toList(growable: false);

    return values;
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
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }

    return values.take(maxItems).toList(growable: false);
  }

  static List<AtsFriendlyModernExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines,
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

      final resolvedLines = maxDetailLines == null
          ? detailLines
          : detailLines.take(maxDetailLines).toList(growable: false);

      return AtsFriendlyModernExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: monthRange(
          experience.startDate,
          experience.endDate,
          experience.isCurrentlyWorking,
        ),
        detailLines: List.unmodifiable(resolvedLines),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<AtsFriendlyModernEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
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

      return AtsFriendlyModernEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Education',
        institutionLine:
            institutionLine.isNotEmpty ? institutionLine : 'Institution',
        yearLabel: educationYearLabel(education),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<AtsFriendlyModernProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines,
    bool compactLinks = true,
  }) {
    final entries = projects.map((project) {
      final detailLines = <String>[];
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
      _collectLinks(project.description, links, seen, compactLinks: compactLinks);
      _collectLinks(project.url, links, seen, compactLinks: compactLinks);

      return AtsFriendlyModernProjectEntry(
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

  static List<String> certificationLines(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final values = certifications
        .map((certification) {
          final name = certification.name.trim();
          final issuer = certification.issuer.trim();
          if (name.isEmpty) {
            return '';
          }
          return issuer.isNotEmpty ? '$name  •  $issuer' : name;
        })
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }

    return values.take(maxItems).toList(growable: false);
  }

  static List<String> languageLabels(
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

  static String monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final format = DateFormat('MMM yyyy');
    final startLabel = format.format(start);
    final endLabel =
        isCurrent ? 'Present' : (end != null ? format.format(end) : startLabel);
    return '$startLabel - $endLabel';
  }

  static String educationYearLabel(Education education) {
    if (education.isCurrentlyStudying) {
      return 'Present';
    }
    if (education.endDate != null) {
      return education.endDate!.year.toString();
    }
    return education.startDate.year.toString();
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

  static void _addUnique(List<String> values, String value) {
    if (value.isNotEmpty && !values.contains(value)) {
      values.add(value);
    }
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
