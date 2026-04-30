import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum GraphiteContactKind {
  phone,
  email,
  address,
  linkedin,
  github,
  website,
}

class GraphiteContactItem {
  const GraphiteContactItem({
    required this.kind,
    required this.label,
  });

  final GraphiteContactKind kind;
  final String label;
}

class GraphiteEducationEntry {
  const GraphiteEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degree;
  final String institutionLine;
  final String dateRange;
}

class GraphiteExperienceEntry {
  const GraphiteExperienceEntry({
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

class GraphiteProjectEntry {
  const GraphiteProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class GraphiteCertificationEntry {
  const GraphiteCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class GraphiteColumnTemplateSupport {
  static const int pageHex = 0xFFF7F7F7;
  static const int panelHex = 0xFF5B5D62;
  static const int panelMutedHex = 0xFFD5D9DE;
  static const int inkHex = 0xFF2C2E32;
  static const int mutedHex = 0xFF6E7176;
  static const int lineHex = 0xFFD7D9DD;
  static const int photoTintHex = 0xFF808287;

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
    r'^(?:link|links|url|urls|demo|demos|live|website|web|portfolio|repo|repository|github|gitlab|docs?|documentation|reference|references|preview|view)\b[:\s-]*$',
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

  static List<GraphiteContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <GraphiteContactItem>[];
    final seen = <String>{};

    void add(GraphiteContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == GraphiteContactKind.linkedin ||
              kind == GraphiteContactKind.github ||
              kind == GraphiteContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(GraphiteContactItem(kind: kind, label: label));
    }

    add(GraphiteContactKind.phone, info?.phone);
    add(GraphiteContactKind.email, info?.email);
    if (includeAddress) {
      add(GraphiteContactKind.address, info?.address);
    }
    add(GraphiteContactKind.linkedin, info?.linkedIn);
    add(GraphiteContactKind.github, info?.github);
    add(GraphiteContactKind.website, info?.website);

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

  static List<GraphiteEducationEntry> educationEntries(
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

      return GraphiteEducationEntry(
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

  static List<GraphiteExperienceEntry> experienceEntries(
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

      return GraphiteExperienceEntry(
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
        detailLines: detailLines.take(maxDetailLines).toList(growable: false),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<GraphiteProjectEntry> projectEntries(
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

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(project.url ?? '', links, seen, compactLinks: compactLinks);
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return GraphiteProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: detailLines.take(maxDetailLines).toList(growable: false),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<GraphiteCertificationEntry> certificationEntries(
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

          return GraphiteCertificationEntry(
            name: name,
            detailLines: List.unmodifiable(detailLines),
            links: List.unmodifiable(links),
          );
        })
        .whereType<GraphiteCertificationEntry>()
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
    final endLabel =
        isCurrent ? 'Present' : (end != null ? format.format(end) : startLabel);
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
    var cleaned = value.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    cleaned = cleaned.replaceAll(_linkPattern, ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    cleaned = _cleanListMarker(cleaned)
        .replaceFirst(RegExp(r'[:\-–—]+\s*$'), '')
        .trim();
    if (cleaned.isEmpty || _linkOnlyLabelPattern.hasMatch(cleaned)) {
      return '';
    }
    return cleaned;
  }
}
