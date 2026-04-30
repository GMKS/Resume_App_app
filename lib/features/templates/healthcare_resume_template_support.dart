import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';
import '../../core/utils/professional_role_sections.dart';

enum HealthcareResumeContactKind {
  phone,
  email,
  address,
  linkedin,
  github,
  website,
}

class HealthcareResumeContactItem {
  const HealthcareResumeContactItem({
    required this.kind,
    required this.label,
  });

  final HealthcareResumeContactKind kind;
  final String label;
}

class HealthcareResumeEducationEntry {
  const HealthcareResumeEducationEntry({
    required this.degreeLine,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degreeLine;
  final String institutionLine;
  final String dateRange;
}

class HealthcareResumeExperienceEntry {
  const HealthcareResumeExperienceEntry({
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

class HealthcareResumeProjectEntry {
  const HealthcareResumeProjectEntry({
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

class HealthcareResumeCertificationEntry {
  const HealthcareResumeCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class HealthcareResumeBodySection {
  const HealthcareResumeBodySection({
    required this.id,
    required this.title,
    this.lines = const <String>[],
  });

  final String id;
  final String title;
  final List<String> lines;
}

class HealthcareResumeTemplateSupport {
  static const int pageHex = 0xFFF1EFEE;
  static const int paperHex = 0xFFF8F8F8;
  static const int sidebarHex = 0xFFE4EBF3;
  static const int headingHex = 0xFF3F5875;
  static const int accentHex = 0xFF516785;
  static const int inkHex = 0xFF48546D;
  static const int mutedHex = 0xFF6B7480;
  static const int sidebarTextHex = 0xFF566270;
  static const int lineHex = 0xFFD2D8E0;
  static const int avatarFillHex = 0xFFF7FAFD;

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
    r'^(?:link|links|url|urls|demo|demos|live|website|web|portfolio|repo|repository|github|gitlab|docs?|documentation|reference|references|preview|view|case study)\b[:\s-]*$',
    caseSensitive: false,
  );

  static const Set<String> _skillSectionIds = {
    'healthcare_clinical_skills',
  };

  static const Set<String> _certificationSectionIds = {
    'healthcare_licenses_certifications',
  };

  static const List<String> _preferredCustomSectionIds = [
    'healthcare_specializations',
    'healthcare_hospital_affiliations',
  ];

  static ResumeModel? normalizeResume(ResumeModel? resume) {
    if (resume == null || resume.templateId != 'professional_tone') {
      return resume;
    }

    return resume.copyWith(
      customSections: ensureProfessionalRoleSections(resume),
    );
  }

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

    return 'Healthcare Professional';
  }

  static String address(PersonalInfo? info) {
    return info?.address.trim() ?? '';
  }

  static List<HealthcareResumeContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = false,
  }) {
    final items = <HealthcareResumeContactItem>[];
    final seen = <String>{};

    void add(HealthcareResumeContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == HealthcareResumeContactKind.linkedin ||
              kind == HealthcareResumeContactKind.github ||
              kind == HealthcareResumeContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(HealthcareResumeContactItem(kind: kind, label: label));
    }

    add(HealthcareResumeContactKind.phone, info?.phone);
    add(HealthcareResumeContactKind.email, info?.email);
    if (includeAddress) {
      add(HealthcareResumeContactKind.address, info?.address);
    }
    add(HealthcareResumeContactKind.linkedin, info?.linkedIn);
    add(HealthcareResumeContactKind.github, info?.github);
    add(HealthcareResumeContactKind.website, info?.website);

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

  static List<String> skillNames(
    List<Skill> skills, {
    List<CustomSection> customSections = const <CustomSection>[],
    int? maxItems,
  }) {
    final values = <String>[];

    for (final skill in skills) {
      _addUnique(values, skill.name);
    }

    for (final section in customSections.where(
      (section) => _skillSectionIds.contains(section.id),
    )) {
      for (final line in _customSectionLines(section)) {
        _addUnique(values, line);
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }

    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<HealthcareResumeEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    bool yearOnly = false,
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

      return HealthcareResumeEducationEntry(
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

  static List<HealthcareResumeExperienceEntry> experienceEntries(
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

      return HealthcareResumeExperienceEntry(
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

  static List<HealthcareResumeProjectEntry> projectEntries(
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

      return HealthcareResumeProjectEntry(
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

  static List<HealthcareResumeCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    List<CustomSection> customSections = const <CustomSection>[],
    int? maxItems,
    bool compactLinks = true,
  }) {
    final dateFormat = DateFormat('MMM yyyy');
    final entries = <HealthcareResumeCertificationEntry>[];
    final nameToIndex = <String, int>{};

    void addEntry({
      required String name,
      List<String> detailLines = const <String>[],
      List<String> links = const <String>[],
    }) {
      final normalizedName = name.trim();
      if (normalizedName.isEmpty) {
        return;
      }

      final key = normalizedName.toLowerCase();
      final existingIndex = nameToIndex[key];
      if (existingIndex != null) {
        final existing = entries[existingIndex];
        final mergedDetails = <String>[...existing.detailLines];
        for (final line in detailLines) {
          _addUnique(mergedDetails, line);
        }
        final mergedLinks = <String>[...existing.links];
        for (final link in links) {
          _addUnique(mergedLinks, link);
        }
        entries[existingIndex] = HealthcareResumeCertificationEntry(
          name: existing.name,
          detailLines: List.unmodifiable(mergedDetails),
          links: List.unmodifiable(mergedLinks),
        );
        return;
      }

      nameToIndex[key] = entries.length;
      entries.add(
        HealthcareResumeCertificationEntry(
          name: normalizedName,
          detailLines: List.unmodifiable(detailLines),
          links: List.unmodifiable(links),
        ),
      );
    }

    for (final certification in certifications) {
      final name = certification.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final detailLines = <String>[];
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
      if (metaParts.isNotEmpty) {
        detailLines.add(metaParts.join('  |  '));
      }

      final links = <String>[];
      final seen = <String>{};
      _collectLinks(
        certification.credentialUrl ?? '',
        links,
        seen,
        compactLinks: compactLinks,
      );

      addEntry(name: name, detailLines: detailLines, links: links);
    }

    for (final section in customSections.where(
      (section) => _certificationSectionIds.contains(section.id),
    )) {
      for (final item in section.items) {
        final name = item.title.trim();
        if (name.isEmpty) {
          continue;
        }

        final detailLines = <String>[];
        final metaParts = <String>[];
        if ((item.subtitle ?? '').trim().isNotEmpty) {
          metaParts.add(item.subtitle!.trim());
        }
        if (item.date != null) {
          metaParts.add(dateFormat.format(item.date!));
        }
        if (metaParts.isNotEmpty) {
          detailLines.add(metaParts.join('  |  '));
        }
        for (final line in splitLines(
          item.description ?? '',
          omitStandaloneLinks: true,
        )) {
          _addUnique(detailLines, line);
        }

        final links = <String>[];
        final seen = <String>{};
        _collectLinks(
          item.subtitle ?? '',
          links,
          seen,
          compactLinks: compactLinks,
        );
        _collectLinks(
          item.description ?? '',
          links,
          seen,
          compactLinks: compactLinks,
        );

        addEntry(name: name, detailLines: detailLines, links: links);
      }
    }

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

  static List<HealthcareResumeBodySection> bodyCustomSections(
    List<CustomSection> customSections, {
    int? maxSections,
    int? maxItemsPerSection,
  }) {
    final sections = <HealthcareResumeBodySection>[];

    for (final section in _orderedCustomSections(customSections)) {
      if (_skillSectionIds.contains(section.id) ||
          _certificationSectionIds.contains(section.id)) {
        continue;
      }

      final lines = _customSectionLines(
        section,
        maxItems: maxItemsPerSection,
      );
      if (lines.isEmpty) {
        continue;
      }

      sections.add(
        HealthcareResumeBodySection(
          id: section.id,
          title: _displaySectionTitle(section),
          lines: List.unmodifiable(lines),
        ),
      );
    }

    if (maxSections == null) {
      return List.unmodifiable(sections);
    }

    return List.unmodifiable(sections.take(maxSections).toList(growable: false));
  }

  static bool isSidebarCustomSection(CustomSection section) {
    final normalized = '${section.id} ${section.title}'.toLowerCase();
    return normalized.contains('achievement') ||
        normalized.contains('automation_tools') ||
        normalized.contains('automation tool') ||
        normalized.contains(' tools') ||
        normalized.endsWith('tool') ||
        normalized.endsWith('tools') ||
        normalized.contains('_tools') ||
        (normalized.contains('automation') && normalized.contains('tool'));
  }

  static List<String> customSectionLines(
    CustomSection section, {
    int? maxItems,
  }) {
    return List.unmodifiable(
      _customSectionLines(section, maxItems: maxItems),
    );
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

  static Iterable<CustomSection> _orderedCustomSections(
    List<CustomSection> customSections,
  ) sync* {
    final emitted = <String>{};

    for (final id in _preferredCustomSectionIds) {
      for (final section in customSections.where((section) => section.id == id)) {
        if (emitted.add(section.id)) {
          yield section;
        }
      }
    }

    for (final section in customSections) {
      if (emitted.add(section.id)) {
        yield section;
      }
    }
  }

  static List<String> _customSectionLines(
    CustomSection section, {
    int? maxItems,
  }) {
    final lines = <String>[];
    for (final item in section.items) {
      for (final raw in [item.title, item.subtitle ?? '', item.description ?? '']) {
        for (final part in splitLines(raw, omitStandaloneLinks: true)) {
          _addUnique(lines, part);
          if (maxItems != null && lines.length >= maxItems) {
            return lines;
          }
        }
      }
      if (item.date != null) {
        _addUnique(lines, DateFormat('MMM yyyy').format(item.date!));
        if (maxItems != null && lines.length >= maxItems) {
          return lines;
        }
      }
    }

    return lines;
  }

  static String _displaySectionTitle(CustomSection section) {
    final explicit = section.title.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final base = section.id.startsWith('healthcare_')
        ? section.id.substring('healthcare_'.length)
        : section.id;
    return base
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
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