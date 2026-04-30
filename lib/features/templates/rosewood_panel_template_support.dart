import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum RosewoodContactKind {
  phone,
  address,
  email,
  linkedin,
  github,
  website,
}

class RosewoodContactItem {
  const RosewoodContactItem({
    required this.kind,
    required this.label,
  });

  final RosewoodContactKind kind;
  final String label;
}

class RosewoodEducationEntry {
  const RosewoodEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degree;
  final String institutionLine;
  final String dateRange;
}

class RosewoodExperienceEntry {
  const RosewoodExperienceEntry({
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

class RosewoodProjectEntry {
  const RosewoodProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class RosewoodCertificationEntry {
  const RosewoodCertificationEntry({
    required this.name,
    this.metaLine = '',
    this.links = const <String>[],
  });

  final String name;
  final String metaLine;
  final List<String> links;
}

class RosewoodAwardEntry {
  const RosewoodAwardEntry({
    required this.title,
    this.subtitle = '',
    this.description = '',
  });

  final String title;
  final String subtitle;
  final String description;
}

class RosewoodPanelTemplateSupport {
  static const int pageHex = 0xFFF8F5F4;
  static const int sheetHex = 0xFFFFFFFF;
  static const int panelHex = 0xFFF1E7E5;
  static const int accentHex = 0xFFC7A09B;
  static const int inkHex = 0xFF555665;
  static const int mutedHex = 0xFF8A8592;
  static const int panelInkHex = 0xFF6D6771;
  static const int lineHex = 0xFFDEC7C4;
  static const int avatarHex = 0xFFE8D7D5;

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-•*▪■□✪✦★☆➣►→➜➤◦○]+\s*',
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
  static final RegExp _awardSectionPattern = RegExp(
    r'(award|honou?r|achievement|recognition)',
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

  static List<RosewoodContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <RosewoodContactItem>[];
    final seen = <String>{};

    void add(RosewoodContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == RosewoodContactKind.linkedin ||
              kind == RosewoodContactKind.github ||
              kind == RosewoodContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(RosewoodContactItem(kind: kind, label: label));
    }

    add(RosewoodContactKind.phone, info?.phone);
    if (includeAddress) {
      add(RosewoodContactKind.address, info?.address);
    }
    add(RosewoodContactKind.email, info?.email);
    add(RosewoodContactKind.linkedin, info?.linkedIn);
    add(RosewoodContactKind.github, info?.github);
    add(RosewoodContactKind.website, info?.website);

    return List.unmodifiable(items);
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
    return List.unmodifiable(
      splitLines(
        value ?? '',
        maxItems: maxItems,
        omitStandaloneLinks: true,
      ),
    );
  }

  static String summaryText(String? value, {int? maxItems}) {
    return summaryLines(value, maxItems: maxItems).join(' ');
  }

  static List<RosewoodEducationEntry> educationEntries(
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

      return RosewoodEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Degree',
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

  static List<RosewoodExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines = 2,
    bool yearOnly = true,
  }) {
    final entries = experiences.map((experience) {
      final metaLine = experience.company.trim().isNotEmpty
          ? experience.company.trim()
          : 'Company';

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

      return RosewoodExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        metaLine: metaLine,
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

  static List<RosewoodProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines = 1,
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
      }

      if (detailLines.isEmpty && project.technologies.isNotEmpty) {
        final technologies = project.technologies
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (technologies.isNotEmpty) {
          detailLines.add(technologies.join('  |  '));
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

      return RosewoodProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: maxDetailLines == null
            ? List.unmodifiable(detailLines)
            : List.unmodifiable(
                detailLines.take(maxDetailLines).toList(growable: false),
              ),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<RosewoodCertificationEntry> certificationEntries(
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

          final metaParts = <String>[];
          if (certification.issuer.trim().isNotEmpty) {
            metaParts.add(certification.issuer.trim());
          }
          if (certification.issueDate != null) {
            metaParts
                .add('Issued ${dateFormat.format(certification.issueDate!)}');
          }

          final links = <String>[];
          final seen = <String>{};
          _collectLinks(
            certification.credentialUrl ?? '',
            links,
            seen,
            compactLinks: compactLinks,
          );

          return RosewoodCertificationEntry(
            name: name,
            metaLine: metaParts.join('  |  '),
            links: List.unmodifiable(links),
          );
        })
        .whereType<RosewoodCertificationEntry>()
        .toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<RosewoodAwardEntry> awardEntries(
    List<CustomSection> customSections, {
    int? maxItems,
  }) {
    final entries = <RosewoodAwardEntry>[];
    for (final section in customSections) {
      if (!_awardSectionPattern.hasMatch(section.title)) {
        continue;
      }

      for (final item in section.items) {
        final title = item.title.trim();
        if (title.isEmpty) {
          continue;
        }

        final subtitleParts = <String>[];
        final subtitle = item.subtitle?.trim() ?? '';
        if (subtitle.isNotEmpty) {
          subtitleParts.add(subtitle);
        }
        if (item.date != null) {
          subtitleParts.add(DateFormat('yyyy').format(item.date!));
        }

        entries.add(
          RosewoodAwardEntry(
            title: title,
            subtitle: subtitleParts.join('  |  '),
            description: item.description?.trim() ?? '',
          ),
        );
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
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
