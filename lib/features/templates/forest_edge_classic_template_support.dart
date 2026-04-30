import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum ForestEdgeClassicContactKind {
  email,
  phone,
  linkedin,
  website,
  github,
  address,
}

class ForestEdgeClassicContactItem {
  const ForestEdgeClassicContactItem({
    required this.kind,
    required this.label,
  });

  final ForestEdgeClassicContactKind kind;
  final String label;
}

class ForestEdgeClassicEducationEntry {
  const ForestEdgeClassicEducationEntry({
    required this.institution,
    required this.degreeLine,
    required this.dateRange,
  });

  final String institution;
  final String degreeLine;
  final String dateRange;
}

class ForestEdgeClassicExperienceEntry {
  const ForestEdgeClassicExperienceEntry({
    required this.title,
    required this.company,
    required this.dateRange,
    this.location = '',
    this.detailLines = const <String>[],
  });

  final String title;
  final String company;
  final String dateRange;
  final String location;
  final List<String> detailLines;
}

class ForestEdgeClassicProjectEntry {
  const ForestEdgeClassicProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class ForestEdgeClassicCertificationEntry {
  const ForestEdgeClassicCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class ForestEdgeClassicTemplateSupport {
  static const int pageBgHex = 0xFFF2ECE1;
  static const int paperHex = 0xFFF6F0E7;
  static const int cardHex = 0xFFFBF7F0;
  static const int headerHex = 0xFF27483F;
  static const int headerCardHex = 0xFF3C6257;
  static const int accentHex = 0xFFC58B43;
  static const int lineHex = 0xFFD8C4A7;
  static const int inkHex = 0xFF26322F;
  static const int mutedHex = 0xFF55615C;
  static const int creamHex = 0xFFE8D8BF;
  static const int tagHex = 0xFFEDE1D0;

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  static final RegExp _leadingMarkerPattern = RegExp('^[-*\u2022]+\\s*');

  static final RegExp _inlineBulletSeparatorPattern =
      RegExp('\\s+[\u2022]+\\s+');

  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portal|access|visit|preview|view)\b[:\s-]*$',
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

  static List<ForestEdgeClassicContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <ForestEdgeClassicContactItem>[];
    final seen = <String>{};

    void add(ForestEdgeClassicContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ForestEdgeClassicContactKind.linkedin ||
              kind == ForestEdgeClassicContactKind.website ||
              kind == ForestEdgeClassicContactKind.github)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(ForestEdgeClassicContactItem(kind: kind, label: label));
    }

    add(ForestEdgeClassicContactKind.email, info?.email);
    add(ForestEdgeClassicContactKind.phone, info?.phone);
    add(ForestEdgeClassicContactKind.linkedin, info?.linkedIn);
    add(ForestEdgeClassicContactKind.website, info?.website);
    add(ForestEdgeClassicContactKind.github, info?.github);
    if (includeAddress) {
      add(ForestEdgeClassicContactKind.address, info?.address);
    }

    return List.unmodifiable(items);
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

  static List<ForestEdgeClassicEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    bool yearOnly = true,
  }) {
    final entries = educations.map((education) {
      final degreeLine = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((value) => value.isNotEmpty).join(' ');

      return ForestEdgeClassicEducationEntry(
        institution: education.institution.trim().isNotEmpty
            ? education.institution.trim()
            : 'State University',
        degreeLine: degreeLine.isNotEmpty ? degreeLine : 'Bachelor Degree',
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
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<ForestEdgeClassicExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines = 3,
    bool yearOnly = true,
  }) {
    final entries = experiences.map((experience) {
      final detailLines = <String>[];
      for (final achievement in experience.achievements) {
        for (final line in splitLines(
          achievement,
          omitStandaloneLinks: true,
        )) {
          _addUnique(detailLines, line);
        }
      }
      for (final line in splitLines(
        experience.description,
        omitStandaloneLinks: true,
      )) {
        _addUnique(detailLines, line);
      }

      return ForestEdgeClassicExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Senior Developer',
        company: experience.company.trim().isNotEmpty
            ? experience.company.trim()
            : 'Company',
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
        location: (experience.location ?? '').trim(),
        detailLines: maxDetailLines == null
            ? List.unmodifiable(detailLines)
            : List.unmodifiable(
                detailLines.take(maxDetailLines).toList(growable: false),
              ),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = <String>[];
    for (final skill in skills) {
      final name = skill.name.trim();
      if (name.isNotEmpty && !values.contains(name)) {
        values.add(name);
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<ForestEdgeClassicProjectEntry> projectEntries(
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
        if (cleaned.isNotEmpty) {
          _addUnique(detailLines, cleaned);
        }
      }

      if (detailLines.isEmpty) {
        final technologies = project.technologies
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (technologies.isNotEmpty) {
          detailLines.add(technologies.join(' | '));
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

      return ForestEdgeClassicProjectEntry(
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
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<ForestEdgeClassicCertificationEntry> certificationEntries(
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
          final issuer = certification.issuer.trim();
          if (issuer.isNotEmpty) {
            _addUnique(detailLines, issuer);
          }
          if (certification.issueDate != null) {
            _addUnique(
              detailLines,
              'Issued ${dateFormat.format(certification.issueDate!)}',
            );
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

          return ForestEdgeClassicCertificationEntry(
            name: name,
            detailLines: List.unmodifiable(detailLines),
            links: List.unmodifiable(links),
          );
        })
        .whereType<ForestEdgeClassicCertificationEntry>()
        .toList(growable: false);

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
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
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

    final normalized = raw.replaceAll(_inlineBulletSeparatorPattern, '\n');
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
    return '$startLabel-$endLabel';
  }

  static String monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final format = DateFormat('MMM yyyy');
    final startLabel = format.format(start);
    final endLabel = isCurrent ? 'Present' : format.format(end ?? start);
    return '$startLabel-$endLabel';
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

    final wordCount =
        cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    if (linkCount > 0 && wordCount <= 1) {
      return '';
    }

    return cleaned;
  }
}
