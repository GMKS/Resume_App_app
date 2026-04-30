import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum ProfessionalContactKind {
  email,
  phone,
  address,
  linkedin,
  github,
  website,
}

class ProfessionalContactItem {
  const ProfessionalContactItem({
    required this.kind,
    required this.label,
  });

  final ProfessionalContactKind kind;
  final String label;
}

class ProfessionalExperienceEntry {
  const ProfessionalExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.locationLine,
    required this.dateRange,
    this.detailLines = const <String>[],
  });

  final String title;
  final String companyLine;
  final String locationLine;
  final String dateRange;
  final List<String> detailLines;
}

class ProfessionalEducationEntry {
  const ProfessionalEducationEntry({
    required this.degreeLine,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degreeLine;
  final String institutionLine;
  final String dateRange;
}

class ProfessionalProjectEntry {
  const ProfessionalProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class ProfessionalCertificationEntry {
  const ProfessionalCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class ProfessionalTemplateSupport {
  static const int paperHex = 0xFFF7F8FC;
  static const int cardHex = 0xFFFFFFFF;
  static const int railHex = 0xFFD7DFEA;
  static const int inkHex = 0xFF243041;
  static const int mutedHex = 0xFF667085;
  static const int lineHex = 0xFFD9E2EC;

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

  static List<ProfessionalContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <ProfessionalContactItem>[];
    final seen = <String>{};

    void add(ProfessionalContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ProfessionalContactKind.linkedin ||
              kind == ProfessionalContactKind.github ||
              kind == ProfessionalContactKind.website)) {
        label = compactLink(label);
      }

      final key = label.toLowerCase();
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(ProfessionalContactItem(kind: kind, label: label));
    }

    add(ProfessionalContactKind.email, info?.email);
    add(ProfessionalContactKind.phone, info?.phone);
    if (includeAddress) {
      add(ProfessionalContactKind.address, info?.address);
    }
    add(ProfessionalContactKind.linkedin, info?.linkedIn);
    add(ProfessionalContactKind.github, info?.github);
    add(ProfessionalContactKind.website, info?.website);

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

  static List<ProfessionalExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines = 5,
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

      return ProfessionalExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: experience.company.trim().isNotEmpty
            ? experience.company.trim()
            : 'Company',
        locationLine: (experience.location ?? '').trim(),
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

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = skills
        .map((skill) => skill.name.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<ProfessionalEducationEntry> educationEntries(
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

      return ProfessionalEducationEntry(
        degreeLine: degreeLine.isNotEmpty ? degreeLine : 'Education',
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

  static List<ProfessionalProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int? maxDetailLines,
    bool compactLinks = true,
  }) {
    final entries = projects.map((project) {
      final detailLines = <String>[];
      for (final line in splitLines(project.description)) {
        final cleaned = _cleanProjectSummaryLine(line);
        if (cleaned.isNotEmpty) {
          _addUnique(detailLines, cleaned);
        }
      }

      if (detailLines.isEmpty && project.technologies.isNotEmpty) {
        detailLines.add(
          project.technologies
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join('  •  '),
        );
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(project.description, links, seen, compactLinks: compactLinks);
      _collectLinks(project.url, links, seen, compactLinks: compactLinks);

      return ProfessionalProjectEntry(
        title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
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

  static List<ProfessionalCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    int? maxItems,
    bool compactLinks = true,
  }) {
    final entries = certifications.map((certification) {
      final details = <String>[];
      if (certification.issuer.trim().isNotEmpty) {
        details.add(certification.issuer.trim());
      }
      if (certification.issueDate != null) {
        details.add('Issued ${DateFormat('yyyy').format(certification.issueDate!)}');
      }
      if ((certification.credentialId ?? '').trim().isNotEmpty) {
        details.add('ID ${certification.credentialId!.trim()}');
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(
        certification.credentialUrl,
        links,
        seen,
        compactLinks: compactLinks,
      );

      return ProfessionalCertificationEntry(
        name: certification.name.trim().isNotEmpty
            ? certification.name.trim()
            : 'Certification',
        detailLines: List.unmodifiable(details),
        links: List.unmodifiable(links),
      );
    }).toList(growable: false);

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
        .map(
          (language) => [
            language.name.trim(),
            language.proficiency.trim(),
          ].where((part) => part.isNotEmpty).join(' '),
        )
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static String compactLink(String? value) {
    var link = value?.trim() ?? '';
    if (link.isEmpty) {
      return '';
    }

    link = link.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), '');
    link = link.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    link = link.replaceAll(RegExp(r'\/$'), '');
    return link;
  }

  static List<String> splitLines(
    String? raw, {
    int? maxItems,
    bool omitStandaloneLinks = false,
  }) {
    final normalized = raw?.replaceAll('\r', '\n').trim() ?? '';
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final directLines = normalized
        .split(RegExp(r'\n+'))
        .expand((line) => line.split(_inlineBulletSeparatorPattern))
        .map(_sanitizeFragment)
        .where((line) => line.isNotEmpty)
        .map((line) => omitStandaloneLinks ? _removeLinks(line) : line)
        .where((line) => line.isNotEmpty)
        .where((line) => !_linkOnlyLabelPattern.hasMatch(line))
        .toList(growable: false);

    final segments = directLines.isNotEmpty
        ? directLines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map(_sanitizeFragment)
            .where((line) => line.isNotEmpty)
            .map((line) => omitStandaloneLinks ? _removeLinks(line) : line)
            .where((line) => line.isNotEmpty)
            .where((line) => !_linkOnlyLabelPattern.hasMatch(line))
            .toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(segments);
    }

    return List.unmodifiable(segments.take(maxItems).toList(growable: false));
  }

  static String yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final startLabel = DateFormat('yyyy').format(start);
    final endLabel = isCurrent
        ? 'Present'
        : DateFormat('yyyy').format(end ?? start);
    return '$startLabel - $endLabel';
  }

  static String monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final startLabel = DateFormat('MMM yyyy').format(start);
    final endLabel = isCurrent
        ? 'Present'
        : DateFormat('MMM yyyy').format(end ?? start);
    return '$startLabel - $endLabel';
  }

  static String _sanitizeFragment(String line) {
    return line
        .trim()
        .replaceFirst(_leadingMarkerPattern, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _removeLinks(String value) {
    return value
        .replaceAll(_linkPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[:;,.-]+$'), '')
        .trim();
  }

  static void _addUnique(List<String> values, String line) {
    final normalized = line.trim();
    if (normalized.isEmpty) {
      return;
    }

    final exists = values.any(
      (value) => value.toLowerCase() == normalized.toLowerCase(),
    );
    if (!exists) {
      values.add(normalized);
    }
  }

  static String _cleanProjectSummaryLine(String line) {
    var cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_linkPattern.hasMatch(line)) {
      cleaned = _removeLinks(line)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      cleaned = cleaned
          .replaceAll(
            RegExp(
              r'\s+(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portal|access|visit|preview|view)\s*$',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'[:;,\-()]+\s*$'), '')
          .trim();
    }
    if (cleaned.isEmpty || _linkOnlyLabelPattern.hasMatch(cleaned)) {
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