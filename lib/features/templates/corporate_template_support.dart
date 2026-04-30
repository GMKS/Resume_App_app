import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum CorporateContactKind {
  email,
  phone,
  location,
  linkedin,
  github,
  website,
}

class CorporateContactItem {
  const CorporateContactItem({
    required this.kind,
    required this.label,
  });

  final CorporateContactKind kind;
  final String label;
}

class CorporateEducationEntry {
  const CorporateEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degree;
  final String institutionLine;
  final String dateRange;
}

class CorporateExperienceEntry {
  const CorporateExperienceEntry({
    required this.title,
    required this.metaLine,
    required this.dateRange,
    this.detailLines = const [],
  });

  final String title;
  final String metaLine;
  final String dateRange;
  final List<String> detailLines;
}

class CorporateProjectEntry {
  const CorporateProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.links = const [],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class CorporateCertificationEntry {
  const CorporateCertificationEntry({
    required this.name,
    this.detailLines = const [],
    this.links = const [],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class CorporateTemplateSupport {
  static const int sidebarBgHex = 0xFF1B2A3B;
  static const int sidebarMutedHex = 0xFFB0BEC5;
  static const int bodyInkHex = 0xFF1E293B;
  static const int bodyMutedHex = 0xFF64748B;
  static const int lineHex = 0xFFE2E8F0;

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

  static String displayName(ResumeModel? resume) {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Doe';
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

    return 'Senior Manager';
  }

  static List<CorporateContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <CorporateContactItem>[];
    final seen = <String>{};

    void add(CorporateContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == CorporateContactKind.linkedin ||
              kind == CorporateContactKind.github ||
              kind == CorporateContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(CorporateContactItem(kind: kind, label: label));
    }

    add(CorporateContactKind.email, info?.email);
    add(CorporateContactKind.phone, info?.phone);
    if (includeAddress) {
      add(CorporateContactKind.location, info?.address);
    }
    add(CorporateContactKind.linkedin, info?.linkedIn);
    add(CorporateContactKind.github, info?.github);
    add(CorporateContactKind.website, info?.website);

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
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
  }

  static List<CorporateEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
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
      ].where((part) => part.isNotEmpty).join('  |  ');

      return CorporateEducationEntry(
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
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<CorporateExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int maxDetailLines = 4,
    bool yearOnly = false,
  }) {
    final entries = experiences.map((experience) {
      final metaLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');

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

      return CorporateExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        metaLine: metaLine.isNotEmpty ? metaLine : 'Company',
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
        detailLines:
            detailLines.take(maxDetailLines).toList(growable: false),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<CorporateProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int maxDetailLines = 4,
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
          detailLines.add(technologies.join('  •  '));
        }
      }

      final resolvedLines =
          detailLines.take(maxDetailLines).toList(growable: false);
      final links = <String>[];
      final seen = <String>{};
      _collectLinks(project.url ?? '', links, seen, compactLinks: compactLinks);
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return CorporateProjectEntry(
        title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(resolvedLines),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<CorporateCertificationEntry> certificationEntries(
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
            dateParts.add('Issued ${dateFormat.format(certification.issueDate!)}');
          }
          if (certification.expiryDate != null) {
            dateParts.add('Expires ${dateFormat.format(certification.expiryDate!)}');
          }
          if (dateParts.isNotEmpty) {
            _addUnique(detailLines, dateParts.join('  •  '));
          }

          final credentialId = certification.credentialId?.trim() ?? '';
          if (credentialId.isNotEmpty) {
            _addUnique(detailLines, 'Credential ID: $credentialId');
          }

          final links = <String>[];
          final seen = <String>{};
          _collectLinks(
            certification.credentialUrl ?? '',
            links,
            seen,
            compactLinks: compactLinks,
          );
          _collectLinks(
            certification.issuer,
            links,
            seen,
            compactLinks: compactLinks,
          );

          return CorporateCertificationEntry(
            name: name,
            detailLines: List.unmodifiable(detailLines),
            links: List.unmodifiable(links),
          );
        })
        .whereType<CorporateCertificationEntry>()
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
          return proficiency.isNotEmpty ? '$name  |  $proficiency' : name;
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
        .where((part) => !_linkOnlyLabelPattern.hasMatch(part))
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
    compact = compact.replaceFirst(
      RegExp(r'^www\.', caseSensitive: false),
      '',
    );
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
    final endLabel = isCurrent
        ? 'Present'
        : (end != null ? format.format(end) : startLabel);
    return '$startLabel - $endLabel';
  }

  static void _collectLinks(
    String source,
    List<String> links,
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
      links.add(label);
    }
  }

  static void _addUnique(List<String> values, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (!values.contains(normalized)) {
      values.add(normalized);
    }
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

    final wordCount = cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (linkCount > 0 && wordCount <= 1) {
      return '';
    }

    return cleaned;
  }
}