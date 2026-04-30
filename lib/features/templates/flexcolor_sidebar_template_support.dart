import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

class FlexColorSidebarExperienceEntry {
  const FlexColorSidebarExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    this.locationLine = '',
    this.detailLines = const <String>[],
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final String locationLine;
  final List<String> detailLines;
}

class FlexColorSidebarProjectEntry {
  const FlexColorSidebarProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class FlexColorSidebarCertificationEntry {
  const FlexColorSidebarCertificationEntry({
    required this.name,
    this.metaLine = '',
    this.links = const <String>[],
  });

  final String name;
  final String metaLine;
  final List<String> links;
}

class FlexColorSidebarEducationEntry {
  const FlexColorSidebarEducationEntry({
    required this.degreeLine,
    required this.institutionLine,
    this.metaLine = '',
  });

  final String degreeLine;
  final String institutionLine;
  final String metaLine;
}

class FlexColorSidebarReferenceEntry {
  const FlexColorSidebarReferenceEntry({
    required this.name,
    this.metaLine = '',
    this.contactLines = const <String>[],
  });

  final String name;
  final String metaLine;
  final List<String> contactLines;
}

class FlexColorSidebarTemplateSupport {
  static const int pageHex = 0xFFF1F5F9;
  static const int panelHex = 0xFFFFFFFF;
  static const int lineHex = 0xFFD8E1EA;
  static const int inkHex = 0xFF172033;
  static const int mutedHex = 0xFF6B7280;
  static const int cardFillHex = 0xFFF8FAFC;
  static const int chipFillHex = 0xFFE2E8F0;
  static const int chipFillAltHex = 0xFFEEF2F7;

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-•*▪■□✦★☆➜➤>]+\s*',
  );
  static final RegExp _inlineBulletPattern = RegExp(
    r'\s+[•▪■□✦★☆➜➤]+\s+',
  );
  static final RegExp _lineSplitPattern = RegExp(r'[\r\n]+');
  static final RegExp _sentenceSplitPattern = RegExp(r'(?<=[.!?])\s+');
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
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

  static Uint8List? photoBytes(PersonalInfo? info) {
    final value = info?.profileImage?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value.split(',').last);
    } catch (_) {
      return null;
    }
  }

  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'JS';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  static String compactUrl(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return '';
    }

    result = result.replaceFirst(RegExp(r'^https?:\/\/'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  static List<String> contactLines(
    PersonalInfo? info, {
    int? maxItems,
    bool includeAddress = true,
  }) {
    final values = <String>[];
    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || values.contains(trimmed)) {
        return;
      }
      values.add(trimmed);
    }

    if (info == null) {
      return const [
        'john.smith@email.com',
        '(555) 123-4567',
        'New York, NY',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ];
    }

    add(info.email);
    add(info.phone);
    if (includeAddress) {
      add(info.address);
    }
    add(compactUrl(info.linkedIn ?? ''));
    add(compactUrl(info.github ?? ''));
    add(compactUrl(info.website ?? ''));

    if (values.isEmpty) {
      return const [
        'john.smith@email.com',
        '(555) 123-4567',
        'New York, NY',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<String> languageLines(
    List<Language> languages, {
    int? maxItems,
  }) {
    final values = <String>[];
    for (final language in languages) {
      final name = language.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final proficiency = language.proficiency.trim();
      final line = proficiency.isNotEmpty ? '$name $proficiency' : name;
      if (!values.contains(line)) {
        values.add(line);
      }
    }

    if (values.isEmpty) {
      return const [
        'English Professional',
        'German Professional',
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    final lines = splitLines(value ?? '', omitStandaloneLinks: true);
    if (lines.isEmpty) {
      return const [
        'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(lines);
    }
    return List.unmodifiable(lines.take(maxItems).toList(growable: false));
  }

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = <String>[];
    for (final skill in skills) {
      final name = skill.name.trim();
      if (name.isEmpty || values.contains(name)) {
        continue;
      }
      values.add(name);
    }

    if (values.isEmpty) {
      return const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<FlexColorSidebarExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines,
    bool yearOnly = true,
  }) {
    final entries = experiences.map((experience) {
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

      return FlexColorSidebarExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Senior Developer',
        companyLine: compactCompany(experience.company),
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
        locationLine: (experience.location ?? '').trim(),
        detailLines: maxDetailLines == null
            ? List.unmodifiable(detailLines)
            : List.unmodifiable(
                detailLines.take(maxDetailLines).toList(growable: false),
              ),
      );
    }).toList(growable: false);

    if (entries.isEmpty) {
      return const [
        FlexColorSidebarExperienceEntry(
          title: 'Senior Developer',
          companyLine: 'TechCorp',
          dateRange: '2022 - 2025',
          detailLines: <String>[
            'Led a team of 5 to deliver cloud-based platform features.',
          ],
        ),
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<FlexColorSidebarProjectEntry> projectEntries(
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
        final cleaned = line.trim();
        if (cleaned.isNotEmpty) {
          _addUnique(detailLines, cleaned);
        }
      }
      if (detailLines.isEmpty) {
        final technologyLine = project.technologies
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .join(' | ');
        if (technologyLine.isNotEmpty) {
          detailLines.add(technologyLine);
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

      return FlexColorSidebarProjectEntry(
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

    if (entries.isEmpty) {
      return const [
        FlexColorSidebarProjectEntry(
          title: 'Portfolio Website',
          detailLines: <String>[
            'Built a responsive portfolio and resume workflow.',
          ],
        ),
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<FlexColorSidebarCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
    bool compactLinks = true,
  }) {
    final dateFormat = DateFormat('MMM yyyy');
    final entries = certifications.map((certification) {
      final metaParts = <String>[];
      if (certification.issuer.trim().isNotEmpty) {
        metaParts.add(certification.issuer.trim());
      }
      if (certification.issueDate != null) {
        metaParts.add(dateFormat.format(certification.issueDate!));
      }
      if ((certification.credentialId ?? '').trim().isNotEmpty) {
        metaParts.add('ID ${certification.credentialId!.trim()}');
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(
        certification.credentialUrl ?? '',
        links,
        seen,
        compactLinks: compactLinks,
      );

      return FlexColorSidebarCertificationEntry(
        name: certification.name.trim().isNotEmpty
            ? certification.name.trim()
            : 'Certification',
        metaLine: metaParts.join(' | '),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (entries.isEmpty) {
      return const [
        FlexColorSidebarCertificationEntry(
          name: 'AWS Certified Developer',
          metaLine: 'Amazon',
        ),
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<FlexColorSidebarEducationEntry> educationEntries(
    List<Education> education, {
    int? maxItems,
    bool yearOnly = true,
  }) {
    final entries = education.map((entry) {
      final degreeLine = [entry.degree.trim(), entry.fieldOfStudy.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final institutionLine = entry.institution.trim().isNotEmpty
          ? entry.institution.trim()
          : 'Institution';
      final metaParts = <String>[];
      final location = (entry.location ?? '').trim();
      if (location.isNotEmpty) {
        metaParts.add(location);
      }
      final range = yearOnly
          ? yearRange(
              entry.startDate,
              entry.endDate,
              entry.isCurrentlyStudying,
            )
          : monthRange(
              entry.startDate,
              entry.endDate,
              entry.isCurrentlyStudying,
            );
      if (range.isNotEmpty) {
        metaParts.add(range);
      }
      final grade = (entry.grade ?? '').trim();
      if (grade.isNotEmpty) {
        metaParts.add('Grade $grade');
      }

      return FlexColorSidebarEducationEntry(
        degreeLine: degreeLine.isNotEmpty ? degreeLine : 'Education',
        institutionLine: institutionLine,
        metaLine: metaParts.join(' | '),
      );
    }).toList(growable: false);

    if (entries.isEmpty) {
      return const [
        FlexColorSidebarEducationEntry(
          degreeLine: 'B.Sc. Computer Science Software Engineering',
          institutionLine: 'State University',
          metaLine: '2019',
        ),
      ];
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<FlexColorSidebarReferenceEntry> referenceEntries(
    List<Reference> references, {
    int? maxItems,
  }) {
    final entries = references.map((reference) {
      final metaParts = [reference.position.trim(), reference.company.trim()]
          .where((part) => part.isNotEmpty)
          .join(' | ');
      final contactLines = [reference.email.trim(), reference.phone.trim()]
          .where((part) => part.isNotEmpty)
          .toList(growable: false);

      return FlexColorSidebarReferenceEntry(
        name: reference.name.trim().isNotEmpty
            ? reference.name.trim()
            : 'Reference',
        metaLine: metaParts,
        contactLines: List.unmodifiable(contactLines),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<String> splitLines(
    String text, {
    int? maxItems,
    bool omitStandaloneLinks = false,
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final values = <String>[];
    for (final rawLine in normalized.split(_lineSplitPattern)) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final inlineParts = trimmed.contains('•') ||
              trimmed.contains('▪') ||
              trimmed.contains('➜') ||
              trimmed.contains('➤')
          ? trimmed.split(_inlineBulletPattern)
          : <String>[trimmed];

      for (final part in inlineParts) {
        final stripped = cleanMarker(part);
        if (stripped.isEmpty) {
          continue;
        }
        final sentenceParts = stripped.split(_sentenceSplitPattern);
        for (final sentence in sentenceParts) {
          final cleaned = cleanMarker(sentence);
          if (cleaned.isEmpty) {
            continue;
          }
          if (omitStandaloneLinks && _isStandaloneLink(cleaned)) {
            continue;
          }
          _addUnique(values, cleaned);
        }
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static String cleanMarker(String text) {
    return text.trim().replaceFirst(_leadingMarkerPattern, '');
  }

  static String compactCompany(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return 'TechCorp';
    }

    final parts = normalized
        .split(RegExp(r'\s+[•·|]\s+|\s{2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return parts.isNotEmpty ? parts.first : normalized;
  }

  static String yearRange(
    DateTime startDate,
    DateTime? endDate,
    bool isCurrent,
  ) {
    final start = DateFormat('yyyy').format(startDate);
    final end =
        isCurrent ? 'Present' : DateFormat('yyyy').format(endDate ?? startDate);
    return '$start - $end';
  }

  static String monthRange(
    DateTime startDate,
    DateTime? endDate,
    bool isCurrent,
  ) {
    final formatter = DateFormat('MMM yyyy');
    final start = formatter.format(startDate);
    final end = isCurrent ? 'Present' : formatter.format(endDate ?? startDate);
    return '$start - $end';
  }

  static bool _isStandaloneLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final match = _linkPattern.firstMatch(trimmed);
    return match != null && match.group(0) == trimmed;
  }

  static void _addUnique(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || values.contains(trimmed)) {
      return;
    }
    values.add(trimmed);
  }

  static void _collectLinks(
    String text,
    List<String> output,
    Set<String> seen, {
    required bool compactLinks,
  }) {
    for (final match in _linkPattern.allMatches(text)) {
      final raw = match.group(0)?.trim() ?? '';
      if (raw.isEmpty) {
        continue;
      }
      final label = compactLinks ? compactUrl(raw) : raw;
      final key = label.toLowerCase();
      if (label.isEmpty || !seen.add(key)) {
        continue;
      }
      output.add(label);
    }
  }
}
