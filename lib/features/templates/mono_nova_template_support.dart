
import '../../core/models/resume_model.dart';

enum MonoNovaContactKind {
  location,
  email,
  phone,
  linkedin,
  github,
  website,
}

class MonoNovaContactItem {
  const MonoNovaContactItem({
    required this.kind,
    required this.label,
  });

  final MonoNovaContactKind kind;
  final String label;
}

class MonoNovaExperienceEntry {
  const MonoNovaExperienceEntry({
    required this.title,
    required this.metaLine,
    required this.dateRange,
    this.detailLines = const [],
  });

  final String title;
  final String metaLine;
  final String dateRange;
  final List<String> detailLines;
}

class MonoNovaEducationEntry {
  const MonoNovaEducationEntry({
    required this.degree,
    required this.institutionLine,
    required this.dateLabel,
  });

  final String degree;
  final String institutionLine;
  final String dateLabel;
}

class MonoNovaProjectEntry {
  const MonoNovaProjectEntry({
    required this.title,
    this.detailLines = const [],
    this.url = '',
  });

  final String title;
  final List<String> detailLines;
  final String url;
}

class MonoNovaTemplateSupport {
  static const int pageHex = 0xFFF8F7F4;
  static const int inkHex = 0xFF2F2C29;
  static const int mutedHex = 0xFF6B6763;
  static const int ruleHex = 0xFFC7C2BC;

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

  static List<MonoNovaContactItem> contactItems(
    PersonalInfo? info, {
    bool compactLinks = true,
  }) {
    final items = <MonoNovaContactItem>[];
    final seen = <String>{};

    void add(MonoNovaContactKind kind, String? value) {
      var label = value?.trim() ?? '';
      if (compactLinks &&
          (kind == MonoNovaContactKind.linkedin ||
              kind == MonoNovaContactKind.github ||
              kind == MonoNovaContactKind.website)) {
        label = compactLink(label);
      }

      final key = '${kind.name}|${label.toLowerCase()}';
      if (label.isEmpty || !seen.add(key)) {
        return;
      }

      items.add(MonoNovaContactItem(kind: kind, label: label));
    }

    add(MonoNovaContactKind.location, info?.address);
    add(MonoNovaContactKind.email, info?.email);
    add(MonoNovaContactKind.phone, info?.phone);
    add(MonoNovaContactKind.linkedin, info?.linkedIn);
    add(MonoNovaContactKind.github, info?.github);
    add(MonoNovaContactKind.website, info?.website);

    return List.unmodifiable(items);
  }

  static List<String> summaryLines(String? value, {int? maxItems}) {
    return splitLines(
      value ?? '',
      maxItems: maxItems,
      omitStandaloneLinks: true,
    );
  }

  static List<MonoNovaExperienceEntry> experienceEntries(
    List<Experience> experiences, {
    int? maxItems,
    int maxDetailLines = 3,
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
        if (!detailLines.contains(line)) {
          detailLines.add(line);
        }
      }
      for (final achievement in experience.achievements) {
        for (final line in splitLines(
          achievement,
          omitStandaloneLinks: true,
        )) {
          if (!detailLines.contains(line)) {
            detailLines.add(line);
          }
        }
      }

      return MonoNovaExperienceEntry(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        metaLine: metaLine.isNotEmpty ? metaLine : 'Company',
        dateRange: yearRange(
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

  static List<MonoNovaEducationEntry> educationEntries(
    List<Education> educations, {
    int? maxItems,
  }) {
    final entries = educations.map((education) {
      final degreeParts = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).toList(growable: false);
      return MonoNovaEducationEntry(
        degree: degreeParts.isNotEmpty ? degreeParts.join(' ') : 'Education',
        institutionLine: education.institution.trim().isNotEmpty
            ? education.institution.trim()
            : 'Institution',
        dateLabel: yearLabel(
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

  static List<String> skillNames(List<Skill> skills, {int? maxItems}) {
    final values = skills
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);
    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
  }

  static List<MonoNovaProjectEntry> projectEntries(
    List<Project> projects, {
    int? maxItems,
    int maxDetailLines = 2,
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
          if (cleaned.isNotEmpty && !detailLines.contains(cleaned)) {
            detailLines.add(cleaned);
          }
          if (detailLines.length >= maxDetailLines) {
            break;
          }
        }
      }

      final rawUrl = (project.url ?? '').trim().isNotEmpty
          ? project.url!.trim()
          : _firstLink(project.description);
      final resolvedUrl = compactLinks ? compactLink(rawUrl) : rawUrl.trim();
      final descriptionLinks = _linkPattern
          .allMatches(project.description)
          .map((match) => compactLink(match.group(0) ?? ''))
          .where((value) => value.isNotEmpty)
          .toSet();

      return MonoNovaProjectEntry(
        title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        detailLines: List.unmodifiable(detailLines),
        url: descriptionLinks.contains(resolvedUrl) ? '' : resolvedUrl,
      );
    }).toList(growable: false);

    if (maxItems == null) {
      return entries;
    }
    return entries.take(maxItems).toList(growable: false);
  }

  static List<String> certificationLines(
    List<Certification> certifications, {
    int? maxItems,
  }) {
    final values = certifications
        .map((certification) {
          final name = certification.name.trim();
          final issuer = certification.issuer.trim();
          final credentialId = certification.credentialId?.trim() ?? '';
          if (name.isEmpty) {
            return '';
          }

          final parts = <String>[name];
          if (issuer.isNotEmpty) {
            parts.add(issuer);
          } else if (credentialId.isNotEmpty) {
            parts.add(credentialId);
          }
          return parts.join('  •  ');
        })
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }
    return values.take(maxItems).toList(growable: false);
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
        .where((line) => line.isNotEmpty)
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

  static String yearLabel(DateTime start, DateTime? end, bool isCurrent) {
    if (isCurrent) {
      return 'Present';
    }
    return (end ?? start).year.toString();
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

  static String _firstLink(String value) {
    final match = _linkPattern.firstMatch(value);
    return match?.group(0)?.trim() ?? '';
  }

  static String _cleanProjectSummaryLine(String value) {
    final linkCount = _linkPattern.allMatches(value).length;
    var cleaned = value
        .replaceAllMapped(_linkPattern, (_) => ' ')
        .replaceAll(RegExp(r'\s+([,.;:])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (cleaned.isEmpty && linkCount > 0) {
      return '';
    }
    if (_linkOnlyLabelPattern.hasMatch(cleaned)) {
      return '';
    }
    return cleaned;
  }
}