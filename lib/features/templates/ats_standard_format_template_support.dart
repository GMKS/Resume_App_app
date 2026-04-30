import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum AtsStandardContactKind {
  phone,
  email,
  location,
}

enum AtsStandardLinkKind {
  linkedin,
  github,
  website,
}

class AtsStandardContactItem {
  const AtsStandardContactItem({
    required this.kind,
    required this.label,
  });

  final AtsStandardContactKind kind;
  final String label;
}

class AtsStandardLinkItem {
  const AtsStandardLinkItem({
    required this.kind,
    required this.label,
  });

  final AtsStandardLinkKind kind;
  final String label;
}

class AtsStandardExperienceEntry {
  const AtsStandardExperienceEntry({
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

class AtsStandardEducationEntry {
  const AtsStandardEducationEntry({
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

class AtsStandardProjectEntry {
  const AtsStandardProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.url = '',
  });

  final String title;
  final List<String> detailLines;
  final String url;
}

class AtsStandardCertificationEntry {
  const AtsStandardCertificationEntry({
    required this.name,
    this.detailLines = const [],
    this.url = '',
  });

  final String name;
  final List<String> detailLines;
  final String url;
}

class AtsStandardFormatTemplateSupport {
  static const int pageHex = 0xFFF2F7FC;
  static const int inkHex = 0xFF111111;
  static const int bodyHex = 0xFF374151;
  static const int mutedHex = 0xFF6B7280;
  static const int guideHex = 0xFFD7E4F1;

  static const List<String> defaultSectionOrder = <String>[
    'summary',
    'education',
    'experience',
    'skills',
    'links',
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

  static List<AtsStandardContactItem> contactItems(PersonalInfo? info) {
    final items = <AtsStandardContactItem>[];

    void add(AtsStandardContactKind kind, String? value) {
      final label = value?.trim() ?? '';
      if (label.isNotEmpty) {
        items.add(AtsStandardContactItem(kind: kind, label: label));
      }
    }

    add(AtsStandardContactKind.phone, info?.phone);
    add(AtsStandardContactKind.email, info?.email);
    add(AtsStandardContactKind.location, info?.address);

    return List.unmodifiable(items);
  }

  static List<AtsStandardLinkItem> linkItems(
    PersonalInfo? info, {
    bool compactLinks = true,
  }) {
    final items = <AtsStandardLinkItem>[];

    void add(AtsStandardLinkKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks) {
        label = compactLink(label);
      }
      if (label.isNotEmpty) {
        items.add(AtsStandardLinkItem(kind: kind, label: label));
      }
    }

    add(AtsStandardLinkKind.linkedin, info?.linkedIn);
    add(AtsStandardLinkKind.github, info?.github);
    add(AtsStandardLinkKind.website, info?.website);

    return List.unmodifiable(items);
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

  static List<AtsStandardExperienceEntry> experienceEntries(
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

      final resolvedLines = maxDetailLines == null
          ? detailLines
          : detailLines.take(maxDetailLines).toList(growable: false);

      return AtsStandardExperienceEntry(
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
        detailLines: List.unmodifiable(resolvedLines),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<AtsStandardEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    int? maxSupportLines,
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
      _addUnique(supportingLines, education.grade?.trim() ?? '');
      for (final line in splitLines(
        education.description ?? '',
        omitStandaloneLinks: true,
      )) {
        _addUnique(supportingLines, line);
      }

      final resolvedLines = maxSupportLines == null
          ? supportingLines
          : supportingLines.take(maxSupportLines).toList(growable: false);

      return AtsStandardEducationEntry(
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
        supportingLines: List.unmodifiable(resolvedLines),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<AtsStandardProjectEntry> projectEntries(
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

      final resolvedLines = maxDetailLines == null
          ? detailLines
          : detailLines.take(maxDetailLines).toList(growable: false);
      final rawUrl = (project.url ?? '').trim().isNotEmpty
          ? project.url!.trim()
          : _firstLink(project.description);

      return AtsStandardProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(resolvedLines),
        url: compactLinks ? compactLink(rawUrl) : rawUrl.trim(),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }

    return entries.take(maxItems).toList(growable: false);
  }

  static List<AtsStandardCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
    bool compactLinks = true,
  }) {
    final dateFormat = DateFormat('MMM yyyy');
    final entries = certifications
        .map((certification) {
          final name = certification.name.trim();
          if (name.isEmpty) {
            return null;
          }

          final detailLines = <String>[];
          for (final line in splitLines(
            certification.issuer,
            omitStandaloneLinks: true,
          )) {
            _addUnique(detailLines, line);
          }

          final dateParts = <String>[];
          if (certification.issueDate != null) {
            dateParts
                .add('Issued ${dateFormat.format(certification.issueDate!)}');
          }
          if (certification.expiryDate != null) {
            dateParts
                .add('Expires ${dateFormat.format(certification.expiryDate!)}');
          }
          if (dateParts.isNotEmpty) {
            _addUnique(detailLines, dateParts.join('  •  '));
          }

          final credentialId = certification.credentialId?.trim() ?? '';
          if (credentialId.isNotEmpty &&
              !detailLines.any((line) => line.contains(credentialId))) {
            detailLines.add('Credential ID: $credentialId');
          }

          final rawUrl = (certification.credentialUrl ?? '').trim().isNotEmpty
              ? certification.credentialUrl!.trim()
              : _firstLink(certification.issuer);

          return AtsStandardCertificationEntry(
            name: name,
            detailLines: List.unmodifiable(detailLines),
            url: compactLinks ? compactLink(rawUrl) : rawUrl.trim(),
          );
        })
        .whereType<AtsStandardCertificationEntry>()
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

  static void _addUnique(List<String> target, String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty || target.contains(cleaned)) {
      return;
    }
    target.add(cleaned);
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
