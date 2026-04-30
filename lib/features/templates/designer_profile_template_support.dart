import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum DesignerProfileContactKind {
  phone,
  email,
  address,
  linkedin,
  github,
  website,
}

class DesignerProfileContactItem {
  const DesignerProfileContactItem({
    required this.kind,
    required this.label,
  });

  final DesignerProfileContactKind kind;
  final String label;
}

class DesignerProfileEducationEntry {
  const DesignerProfileEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degree;
  final String institutionLine;
  final String dateRange;
}

class DesignerProfileExperienceEntry {
  const DesignerProfileExperienceEntry({
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

class DesignerProfileReferenceEntry {
  const DesignerProfileReferenceEntry({
    required this.name,
    this.roleLine = '',
    this.contactLine = '',
  });

  final String name;
  final String roleLine;
  final String contactLine;
}

class DesignerProfileProjectEntry {
  const DesignerProfileProjectEntry({
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

class DesignerProfileCertificationEntry {
  const DesignerProfileCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class DesignerProfileTemplateSupport {
  static const int pageHex = 0xFFF7F8FB;
  static const int sheetHex = 0xFFFFFFFF;
  static const int sidebarTopHex = 0xFF4267B4;
  static const int sidebarBottomHex = 0xFF223A73;
  static const int headingHex = 0xFF2F3F68;
  static const int inkHex = 0xFF24304A;
  static const int mutedHex = 0xFF677181;
  static const int dividerHex = 0xFFDDE3EF;
  static const int sidebarTextHex = 0xFFDCE4F8;
  static const int profileTintHex = 0xFFE8EEF9;

  static const Set<String> _skillSectionIds = {
    'design_tools_software',
    'design_specializations',
  };
  static const Set<String> _projectSectionIds = {
    'design_portfolio_highlights',
  };
  static const Set<String> _awardSectionIds = {
    'design_awards_recognition',
  };

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

    return 'Creative Director';
  }

  static List<DesignerProfileContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <DesignerProfileContactItem>[];
    final seen = <String>{};

    void add(DesignerProfileContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == DesignerProfileContactKind.linkedin ||
              kind == DesignerProfileContactKind.github ||
              kind == DesignerProfileContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(DesignerProfileContactItem(kind: kind, label: label));
    }

    add(DesignerProfileContactKind.phone, info?.phone);
    add(DesignerProfileContactKind.email, info?.email);
    if (includeAddress) {
      add(DesignerProfileContactKind.address, info?.address);
    }
    add(DesignerProfileContactKind.linkedin, info?.linkedIn);
    add(DesignerProfileContactKind.github, info?.github);
    add(DesignerProfileContactKind.website, info?.website);

    return List.unmodifiable(items);
  }

  static String summaryText(String? value, {int? maxItems}) {
    return summaryLines(value, maxItems: maxItems).join(' ');
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

    for (final item in _customSectionItems(customSections, _skillSectionIds)) {
      for (final line in _sectionItemLines(item)) {
        _addUnique(values, line);
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
  }

  static List<DesignerProfileEducationEntry> educationEntries(
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

      return DesignerProfileEducationEntry(
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

  static List<DesignerProfileExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int maxDetailLines = 4,
    bool yearOnly = false,
  }) {
    final entries = experiences.map((experience) {
      final companyLine = [
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

      return DesignerProfileExperienceEntry(
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
        detailLines: detailLines.take(maxDetailLines).toList(growable: false),
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<DesignerProfileReferenceEntry> referenceEntries(
    List<Reference> references, {
    int? maxItems,
  }) {
    final entries = references
        .map((reference) {
          final name = reference.name.trim();
          if (name.isEmpty) {
            return null;
          }

          final roleParts = <String>[];
          if (reference.position.trim().isNotEmpty) {
            roleParts.add(reference.position.trim());
          }
          if (reference.company.trim().isNotEmpty) {
            roleParts.add(reference.company.trim());
          }
          if (roleParts.isEmpty &&
              (reference.relationship?.trim().isNotEmpty ?? false)) {
            roleParts.add(reference.relationship!.trim());
          }

          final contactParts = <String>[];
          if (reference.email.trim().isNotEmpty) {
            contactParts.add(reference.email.trim());
          }
          if (reference.phone.trim().isNotEmpty) {
            contactParts.add(reference.phone.trim());
          }

          return DesignerProfileReferenceEntry(
            name: name,
            roleLine: roleParts.join('  |  '),
            contactLine: contactParts.join('  |  '),
          );
        })
        .whereType<DesignerProfileReferenceEntry>()
        .toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<DesignerProfileProjectEntry> projectEntries(
    List<Project> projects, {
    List<CustomSection> customSections = const <CustomSection>[],
    int? maxItems,
    int maxDetailLines = 4,
    bool compactLinks = true,
  }) {
    final entries = <DesignerProfileProjectEntry>[];
    final seenTitles = <String>{};

    void addEntry(DesignerProfileProjectEntry entry) {
      final key = entry.title.trim().toLowerCase();
      if (entry.title.trim().isEmpty || !seenTitles.add(key)) {
        return;
      }
      entries.add(entry);
    }

    for (final project in projects) {
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

      final technologies = project.technologies
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

      final links = <String>[];
      final seenLinks = <String>{};
      _collectLinks(project.url ?? '', links, seenLinks,
          compactLinks: compactLinks);
      _collectLinks(
        project.description,
        links,
        seenLinks,
        compactLinks: compactLinks,
      );

      addEntry(
        DesignerProfileProjectEntry(
          title: project.title.trim().isNotEmpty
              ? project.title.trim()
              : 'Project',
          detailLines: detailLines.take(maxDetailLines).toList(growable: false),
          technologyLine:
              technologies.isNotEmpty ? technologies.join('  |  ') : '',
          links: List.unmodifiable(links),
        ),
      );
    }

    for (final item
        in _customSectionItems(customSections, _projectSectionIds)) {
      final entry = _projectFromCustomItem(
        item,
        compactLinks: compactLinks,
        maxDetailLines: maxDetailLines,
      );
      if (entry != null) {
        addEntry(entry);
      }
    }

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }
    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<DesignerProfileCertificationEntry> certificationEntries(
    List<Certification> certifications, {
    List<CustomSection> customSections = const <CustomSection>[],
    int? maxItems,
    bool compactLinks = true,
  }) {
    final dateFormat = DateFormat('MMM yyyy');
    final entries = <DesignerProfileCertificationEntry>[];

    for (final certification in certifications) {
      final name = certification.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final detailLines = <String>[];
      for (final line in splitLines(
        certification.issuer,
        omitStandaloneLinks: true,
      )) {
        _addUnique(detailLines, line);
      }

      if (certification.issueDate != null) {
        _addUnique(
          detailLines,
          'Issued ${dateFormat.format(certification.issueDate!)}',
        );
      }
      if (certification.expiryDate != null) {
        _addUnique(
          detailLines,
          'Expires ${dateFormat.format(certification.expiryDate!)}',
        );
      }
      final credentialId = certification.credentialId?.trim() ?? '';
      if (credentialId.isNotEmpty) {
        _addUnique(detailLines, 'Credential ID: $credentialId');
      }

      final links = <String>[];
      final seenLinks = <String>{};
      _collectLinks(
        certification.credentialUrl ?? '',
        links,
        seenLinks,
        compactLinks: compactLinks,
      );
      _collectLinks(
        certification.issuer,
        links,
        seenLinks,
        compactLinks: compactLinks,
      );

      entries.add(
        DesignerProfileCertificationEntry(
          name: name,
          detailLines: List.unmodifiable(detailLines),
          links: List.unmodifiable(links),
        ),
      );
    }

    for (final item in _customSectionItems(customSections, _awardSectionIds)) {
      final detailLines = <String>[];
      if ((item.subtitle ?? '').trim().isNotEmpty) {
        _addUnique(detailLines, item.subtitle!.trim());
      }
      if (item.date != null) {
        _addUnique(detailLines, item.date!.year.toString());
      }
      for (final line in splitLines(
        item.description ?? '',
        maxItems: 2,
        omitStandaloneLinks: true,
      )) {
        _addUnique(detailLines, line);
      }

      final links = <String>[];
      final seenLinks = <String>{};
      _collectLinks(
        item.subtitle ?? '',
        links,
        seenLinks,
        compactLinks: compactLinks,
      );
      _collectLinks(
        item.description ?? '',
        links,
        seenLinks,
        compactLinks: compactLinks,
      );

      final name = item.title.trim();
      if (name.isEmpty) {
        continue;
      }

      entries.add(
        DesignerProfileCertificationEntry(
          name: name,
          detailLines: List.unmodifiable(detailLines),
          links: List.unmodifiable(links),
        ),
      );
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
        .where((value) => value.isNotEmpty)
        .where((value) => !_linkOnlyLabelPattern.hasMatch(value))
        .where((value) => !omitStandaloneLinks || !_isStandaloneLink(value))
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

  static DesignerProfileProjectEntry? _projectFromCustomItem(
    CustomSectionItem item, {
    required bool compactLinks,
    required int maxDetailLines,
  }) {
    final title = item.title.trim();
    if (title.isEmpty) {
      return null;
    }

    final detailLines = <String>[];
    for (final line in splitLines(
      [item.subtitle ?? '', item.description ?? '']
          .where((value) => value.trim().isNotEmpty)
          .join('\n'),
      omitStandaloneLinks: true,
    )) {
      final cleaned = _cleanProjectSummaryLine(line);
      if (cleaned.isNotEmpty) {
        _addUnique(detailLines, cleaned);
      }
    }

    final links = <String>[];
    final seenLinks = <String>{};
    _collectLinks(item.subtitle ?? '', links, seenLinks,
        compactLinks: compactLinks);
    _collectLinks(
      item.description ?? '',
      links,
      seenLinks,
      compactLinks: compactLinks,
    );

    return DesignerProfileProjectEntry(
      title: title,
      detailLines: detailLines.take(maxDetailLines).toList(growable: false),
      links: List.unmodifiable(links),
    );
  }

  static Iterable<CustomSectionItem> _customSectionItems(
    List<CustomSection> customSections,
    Set<String> ids,
  ) sync* {
    for (final section in customSections) {
      if (!ids.contains(section.id)) {
        continue;
      }
      for (final item in section.items) {
        yield item;
      }
    }
  }

  static List<String> _sectionItemLines(CustomSectionItem item) {
    final values = <String>[];
    for (final raw in [
      item.title,
      item.subtitle ?? '',
      item.description ?? ''
    ]) {
      for (final line in splitLines(raw, omitStandaloneLinks: true)) {
        _addUnique(values, line);
      }
    }
    return values;
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
