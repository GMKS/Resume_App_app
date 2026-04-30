import 'package:intl/intl.dart';

import '../../core/models/resume_model.dart';
import '../../core/utils/professional_role_sections.dart';
import '../../core/utils/user_custom_sections.dart';

enum ElegantGoldContactKind {
  phone,
  email,
  linkedin,
  github,
  website,
  address,
}

class ElegantGoldContactItem {
  const ElegantGoldContactItem({
    required this.kind,
    required this.label,
  });

  final ElegantGoldContactKind kind;
  final String label;
}

class ElegantGoldEducationEntry {
  const ElegantGoldEducationEntry({
    required this.institution,
    required this.degreeLine,
    required this.dateRange,
  });

  final String institution;
  final String degreeLine;
  final String dateRange;
}

class ElegantGoldExperienceEntry {
  const ElegantGoldExperienceEntry({
    required this.title,
    required this.metaLine,
    this.detailLines = const <String>[],
  });

  final String title;
  final String metaLine;
  final List<String> detailLines;
}

class ElegantGoldProjectEntry {
  const ElegantGoldProjectEntry({
    required this.title,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String title;
  final List<String> detailLines;
  final List<String> links;
}

class ElegantGoldCertificationEntry {
  const ElegantGoldCertificationEntry({
    required this.name,
    this.detailLines = const <String>[],
    this.links = const <String>[],
  });

  final String name;
  final List<String> detailLines;
  final List<String> links;
}

class ElegantGoldCustomSectionEntry {
  const ElegantGoldCustomSectionEntry({
    required this.title,
    this.itemLines = const <String>[],
  });

  final String title;
  final List<String> itemLines;
}

class ElegantGoldReferenceEntry {
  const ElegantGoldReferenceEntry({
    required this.name,
    required this.metaLine,
    this.contactLine = '',
  });

  final String name;
  final String metaLine;
  final String contactLine;
}

class ElegantGoldTemplateSupport {
  static const int pageHex = 0xFFEDEDEA;
  static const int paperHex = 0xFFF4F1ED;
  static const int cardHex = 0xFFF9F6F2;
  static const int headerStartHex = 0xFF1B2B3E;
  static const int headerEndHex = 0xFF314C68;
  static const int headerTextHex = 0xFFF7F2EA;
  static const int accentHex = 0xFFC8A96A;
  static const int borderHex = 0xFFD9DDD8;
  static const int inkHex = 0xFF203041;
  static const int mutedHex = 0xFF66707C;

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
    r'^(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portfolio|preview|view)\b[:\s-]*$',
    caseSensitive: false,
  );

  static ResumeModel? normalizedResume(ResumeModel? resume) {
    if (resume == null) {
      return null;
    }

    if (resume.templateId != 'elegant_gold_layout') {
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

    return 'Software Engineer';
  }

  static List<ElegantGoldContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
    bool includeAddress = true,
  }) {
    final items = <ElegantGoldContactItem>[];
    final seen = <String>{};

    void add(ElegantGoldContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == ElegantGoldContactKind.linkedin ||
              kind == ElegantGoldContactKind.github ||
              kind == ElegantGoldContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(ElegantGoldContactItem(kind: kind, label: label));
    }

    add(ElegantGoldContactKind.phone, info?.phone);
    add(ElegantGoldContactKind.email, info?.email);
    add(ElegantGoldContactKind.linkedin, info?.linkedIn);
    add(ElegantGoldContactKind.github, info?.github);
    add(ElegantGoldContactKind.website, info?.website);
    if (includeAddress) {
      add(ElegantGoldContactKind.address, info?.address);
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

  static List<ElegantGoldEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
    bool yearOnly = true,
  }) {
    final entries = educations.map((education) {
      final institution = education.institution.trim();
      final degreeLine = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      return ElegantGoldEducationEntry(
        institution: institution.isNotEmpty ? institution : 'Institution',
        degreeLine: degreeLine.isNotEmpty ? degreeLine : 'Education',
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

  static List<ElegantGoldExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int? maxDetailLines,
    bool yearOnly = true,
  }) {
    final entries = experiences.map((experience) {
      final dateRange = yearOnly
          ? yearRange(
              experience.startDate,
              experience.endDate,
              experience.isCurrentlyWorking,
            )
          : monthRange(
              experience.startDate,
              experience.endDate,
              experience.isCurrentlyWorking,
            );
      final metaLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
        dateRange,
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

      return ElegantGoldExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        metaLine: metaLine.isNotEmpty ? metaLine : 'Company',
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

  static List<ElegantGoldProjectEntry> projectEntries(
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

      if (detailLines.isEmpty) {
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

      return ElegantGoldProjectEntry(
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

  static List<ElegantGoldCertificationEntry> certificationEntries(
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
                detailLines, dateFormat.format(certification.issueDate!));
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
          final seen = <String>{};
          _collectLinks(
            certification.credentialUrl ?? '',
            links,
            seen,
            compactLinks: compactLinks,
          );

          return ElegantGoldCertificationEntry(
            name: name,
            detailLines: List.unmodifiable(detailLines),
            links: List.unmodifiable(links),
          );
        })
        .whereType<ElegantGoldCertificationEntry>()
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

  static List<ElegantGoldCustomSectionEntry> customSectionEntries(
    List<CustomSection> sections, {
    int? maxItems,
    int? maxItemsPerSection,
  }) {
    final orderedSections = sections
        .where((section) => section.items.isNotEmpty)
        .toList(growable: false);
    final mutableSections = List<CustomSection>.from(orderedSections)
      ..sort((left, right) {
        final orderCompare = left.order.compareTo(right.order);
        if (orderCompare != 0) {
          return orderCompare;
        }

        final titleCompare = normalizeUserCustomSectionTitle(left.title)
            .toLowerCase()
            .compareTo(normalizeUserCustomSectionTitle(right.title).toLowerCase());
        if (titleCompare != 0) {
          return titleCompare;
        }

        return left.id.compareTo(right.id);
      });

    final entries = mutableSections
        .map((section) {
          final fallbackTitle = professionalRoleSectionConfigById(
                'elegant_gold_layout',
                section.id,
              )?.title ??
              'Details';

          final itemLines = <String>[];
          final sectionItems = maxItemsPerSection == null
              ? section.items
              : section.items.take(maxItemsPerSection);

          for (final item in sectionItems) {
            final displayItem = buildUserCustomSectionDisplayItem(item);
            if (!displayItem.hasContent) {
              continue;
            }

            final headlineParts = <String>[
              if (displayItem.heading.isNotEmpty) displayItem.heading,
              if (displayItem.subtitle.isNotEmpty) displayItem.subtitle,
              if (displayItem.date != null)
                DateFormat('MMM yyyy').format(displayItem.date!),
            ];

            if (headlineParts.isNotEmpty) {
              itemLines.add(headlineParts.join('  |  '));
            }

            for (final detailLine in displayItem.detailLines) {
              itemLines.add(detailLine);
            }
          }

          return ElegantGoldCustomSectionEntry(
            title: normalizeUserCustomSectionTitle(section.title).isNotEmpty
                ? normalizeUserCustomSectionTitle(section.title)
                : fallbackTitle,
            itemLines: List.unmodifiable(itemLines),
          );
        })
        .where((entry) => entry.itemLines.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return List.unmodifiable(entries);
    }

    return List.unmodifiable(entries.take(maxItems).toList(growable: false));
  }

  static List<ElegantGoldReferenceEntry> referenceEntries(
    List<Reference> references, {
    int? maxItems,
  }) {
    final entries = references.map((reference) {
      final metaLine = [
        reference.position.trim(),
        reference.company.trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');
      final contactLine = [
        reference.email.trim(),
        reference.phone.trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');

      return ElegantGoldReferenceEntry(
        name: reference.name.trim().isNotEmpty
            ? reference.name.trim()
            : 'Reference',
        metaLine: metaLine,
        contactLine: contactLine,
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
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final normalized = raw
        .replaceAll(_inlineBulletSeparatorPattern, '\n')
        .replaceAll(RegExp(r'\s+→\s+'), '\n')
        .replaceAll(RegExp(r'\s+[-=]+>\s+'), '\n');

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
