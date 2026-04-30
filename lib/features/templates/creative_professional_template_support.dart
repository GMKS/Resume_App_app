import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum CreativeProfessionalContactKind {
  phone,
  email,
  address,
  linkedin,
  github,
  website,
}

class CreativeProfessionalContactItem {
  const CreativeProfessionalContactItem({
    required this.kind,
    required this.label,
  });

  final CreativeProfessionalContactKind kind;
  final String label;
}

class CreativeProfessionalEducationEntry {
  const CreativeProfessionalEducationEntry({
    required this.degreeLine,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degreeLine;
  final String institutionLine;
  final String dateRange;
}

class CreativeProfessionalExperienceEntry {
  const CreativeProfessionalExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    this.detailLines = const <String>[],
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> detailLines;
}

class CreativeProfessionalProjectEntry {
  const CreativeProfessionalProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.technologyLine = '',
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final String technologyLine;
  final List<String> links;
}

class CreativeProfessionalCertificationEntry {
  const CreativeProfessionalCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class CreativeProfessionalTemplateSupport {
  static const int pageHex = 0xFFF3ECE4;
  static const int paperHex = 0xFFFFFBF6;
  static const int headerHex = 0xFF2D8C87;
  static const int headerTextHex = 0xFFD7F0ED;
  static const int accentHex = 0xFF236E6A;
  static const int sidebarHex = 0xFFF1E4D5;
  static const int lineHex = 0xFFD7C8B8;
  static const int inkHex = 0xFF283638;
  static const int mutedHex = 0xFF6D6D69;
  static const int sidebarTextHex = 0xFF645E58;
  static const int avatarFillHex = 0xFFEDE2D4;

  static final RegExp _leadingMarkerPattern = RegExp(
    r'^[-*0123456789.)\s]*[•▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );

  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|website|web|portfolio|repo|repository|github|gitlab|docs?|documentation|reference|references|preview|view|case\s+study|case\s+studies)\b[:\s-]*$',
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

    return 'Creative Professional';
  }

  static String address(PersonalInfo? info) {
    return info?.address.trim() ?? '';
  }

  static List<CreativeProfessionalContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = false,
  }) {
    final items = <CreativeProfessionalContactItem>[];
    final seen = <String>{};

    void add(CreativeProfessionalContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == CreativeProfessionalContactKind.linkedin ||
              kind == CreativeProfessionalContactKind.github ||
              kind == CreativeProfessionalContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(CreativeProfessionalContactItem(kind: kind, label: label));
    }

    add(CreativeProfessionalContactKind.phone, info?.phone);
    add(CreativeProfessionalContactKind.email, info?.email);
    if (includeAddress) {
      add(CreativeProfessionalContactKind.address, info?.address);
    }
    add(CreativeProfessionalContactKind.linkedin, info?.linkedIn);
    add(CreativeProfessionalContactKind.github, info?.github);
    add(CreativeProfessionalContactKind.website, info?.website);

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

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = <String>[];
    for (final skill in skills) {
      _addUnique(values, skill.name);
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<CreativeProfessionalEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    bool yearOnly = true,
  }) {
    final entries = educations.map((education) {
      final degreeLine = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');
      final institutionLine = [
        education.institution.trim(),
        (education.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');

      return CreativeProfessionalEducationEntry(
        degreeLine: degreeLine.isNotEmpty ? degreeLine : 'Degree',
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
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<CreativeProfessionalExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines,
    bool yearOnly = false,
  }) {
    final entries = experiences.map((experience) {
      final companyLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');

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

      return CreativeProfessionalExperienceEntry(
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
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<CreativeProfessionalProjectEntry> projectEntries(
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
      }

      final technologyLine = project.technologies
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join('  |  ');

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(project.url ?? '', links, seen, compactLinks: compactLinks);
      _collectLinks(
        project.description,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return CreativeProfessionalProjectEntry(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: maxDetailLines == null
            ? List.unmodifiable(detailLines)
            : List.unmodifiable(
                detailLines.take(maxDetailLines).toList(growable: false),
              ),
        technologyLine: technologyLine,
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<CreativeProfessionalCertificationEntry> certificationEntries(
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

      return CreativeProfessionalCertificationEntry(
        name: certification.name.trim().isNotEmpty
            ? certification.name.trim()
            : 'Certification',
        detailLines: metaParts.isEmpty
            ? const <String>[]
            : List.unmodifiable([metaParts.join('  |  ')]),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<String> languageLines(List<Language> languages, {int? maxItems}) {
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

    final normalized = raw
        .replaceAll(_inlineBulletSeparatorPattern, '\n')
        .replaceAll(RegExp(r'\s+[-=]+>\s+'), '\n')
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
    var cleaned = value.trim();
    cleaned = cleaned.replaceFirst(_leadingMarkerPattern, '');
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
    return cleaned.trim();
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
        .replaceFirst(RegExp(r'[:\-]+\s*$'), '')
        .trim();
    if (cleaned.isEmpty || _linkOnlyLabelPattern.hasMatch(cleaned)) {
      return '';
    }
    return cleaned;
  }
}