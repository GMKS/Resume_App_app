import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';

enum ModernEdgeContactKind {
  phone,
  email,
  address,
  linkedin,
  github,
  website,
}

class ModernEdgeContactItem {
  const ModernEdgeContactItem({
    required this.kind,
    required this.label,
  });

  final ModernEdgeContactKind kind;
  final String label;
}

class ModernEdgeEducationEntry {
  const ModernEdgeEducationEntry({
    required this.degreeLine,
    required this.institutionLine,
    required this.dateRange,
  });

  final String degreeLine;
  final String institutionLine;
  final String dateRange;
}

class ModernEdgeExperienceEntry {
  const ModernEdgeExperienceEntry({
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

class ModernEdgeProjectEntry {
  const ModernEdgeProjectEntry({
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

class ModernEdgeCertificationEntry {
  const ModernEdgeCertificationEntry({
    required this.name,
    this.metaLine = '',
    this.links = const <String>[],
  });

  final String name;
  final String metaLine;
  final List<String> links;
}

class ModernEdgeTemplateSupport {
  static const int pageHex = 0xFFF5FBF6;
  static const int sheetHex = 0xFFFFFFFF;
  static const int sidebarTopHex = 0xFF86C5A3;
  static const int sidebarBottomHex = 0xFF5F9F7D;
  static const int accentHex = 0xFF5E9A78;
  static const int accentDarkHex = 0xFF4D7F66;
  static const int accentSoftHex = 0xFFE8F3EC;
  static const int lineHex = 0xFFD7E7DC;
  static const int inkHex = 0xFF3D5561;
  static const int mutedHex = 0xFF67756C;
  static const int sidebarInkHex = 0xFFF7FFF9;
  static const int sidebarMutedHex = 0xFFE2F1E7;

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
    r'^(?:link|links|url|urls|demo|demos|live|website|web|portfolio|repo|repository|github|gitlab|docs?|documentation|reference|references|preview|view|case study)\b[:\s-]*$',
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

    return 'Product Designer';
  }

  static List<ModernEdgeContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <ModernEdgeContactItem>[];
    final seen = <String>{};

    void add(ModernEdgeContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ModernEdgeContactKind.linkedin ||
              kind == ModernEdgeContactKind.github ||
              kind == ModernEdgeContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(ModernEdgeContactItem(kind: kind, label: label));
    }

    add(ModernEdgeContactKind.phone, info?.phone);
    add(ModernEdgeContactKind.email, info?.email);
    if (includeAddress) {
      add(ModernEdgeContactKind.address, info?.address);
    }
    add(ModernEdgeContactKind.linkedin, info?.linkedIn);
    add(ModernEdgeContactKind.github, info?.github);
    add(ModernEdgeContactKind.website, info?.website);

    return List.unmodifiable(items);
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

    if (maxItems == null) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(values.take(maxItems).toList(growable: false));
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

  static List<ModernEdgeEducationEntry> educationEntries(
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

      return ModernEdgeEducationEntry(
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

  static List<ModernEdgeExperienceEntry> experienceEntries(
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

      return ModernEdgeExperienceEntry(
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

  static List<ModernEdgeProjectEntry> projectEntries(
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

      return ModernEdgeProjectEntry(
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

  static List<ModernEdgeCertificationEntry> certificationEntries(
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

          return ModernEdgeCertificationEntry(
            name: name,
            metaLine: metaParts.join('  |  '),
            links: List.unmodifiable(links),
          );
        })
        .whereType<ModernEdgeCertificationEntry>()
        .toList(growable: false);

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
