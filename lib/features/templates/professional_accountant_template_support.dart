import '../../core/models/resume_model.dart';

enum ProfessionalAccountantContactKind {
  email,
  phone,
  location,
  linkedin,
  github,
  website,
}

class ProfessionalAccountantContactItem {
  const ProfessionalAccountantContactItem({
    required this.kind,
    required this.label,
  });

  final ProfessionalAccountantContactKind kind;
  final String label;
}

class ProfessionalAccountantProjectContent {
  const ProfessionalAccountantProjectContent({
    this.details = const [],
    this.links = const [],
  });

  final List<String> details;
  final List<String> links;
}

class ProfessionalAccountantTemplateSupport {
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  static final RegExp _leadingListMarkerPattern = RegExp(
    r'^[-*•▪■□✪✦★☆➣◦○]+\s*',
  );

  static final RegExp _linkOnlyLabelPattern = RegExp(
    r'^(?:link|links|url|urls|demo|demos|live|app|apps|website|web|source|repo|repository|github|gitlab|docs?|documentation|reference|references|portal|access|visit|preview|view)\b[:\s-]*$',
    caseSensitive: false,
  );

  static List<ProfessionalAccountantContactItem> contactItems(
    PersonalInfo? info,
  ) {
    final items = <ProfessionalAccountantContactItem>[];

    void add(
      ProfessionalAccountantContactKind kind,
      String? value, {
      bool compact = false,
    }) {
      var label = value?.trim() ?? '';
      if (compact) {
        label = compactLink(label);
      }
      if (label.isNotEmpty) {
        items.add(ProfessionalAccountantContactItem(kind: kind, label: label));
      }
    }

    add(ProfessionalAccountantContactKind.email, info?.email);
    add(ProfessionalAccountantContactKind.phone, info?.phone);
    add(ProfessionalAccountantContactKind.location, info?.address);
    add(
      ProfessionalAccountantContactKind.linkedin,
      info?.linkedIn,
      compact: true,
    );
    add(
      ProfessionalAccountantContactKind.github,
      info?.github,
      compact: true,
    );
    add(
      ProfessionalAccountantContactKind.website,
      info?.website,
      compact: true,
    );

    return List.unmodifiable(items);
  }

  static ProfessionalAccountantProjectContent projectContent(
    Project project, {
    int? maxSummaryLines,
  }) {
    final links = <String>[];
    final seenLinks = <String>{};

    void collectLinks(String source) {
      for (final match in _linkPattern.allMatches(source)) {
        final compact = compactLink(match.group(0) ?? '');
        final key = compact.toLowerCase();
        if (compact.isEmpty || !seenLinks.add(key)) {
          continue;
        }
        links.add(compact);
      }
    }

    collectLinks(project.url ?? '');
    collectLinks(project.description);

    final details = <String>[];
    if (project.description.trim().isNotEmpty) {
      for (final segment in _splitLines(project.description)) {
        final cleaned = _cleanProjectSummaryLine(segment);
        if (cleaned.isEmpty || details.contains(cleaned)) {
          continue;
        }
        details.add(cleaned);
        if (maxSummaryLines != null && details.length >= maxSummaryLines) {
          break;
        }
      }
    }

    if (details.isEmpty) {
      for (final technology in project.technologies
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)) {
        if (details.contains(technology)) {
          continue;
        }
        details.add(technology);
        if (maxSummaryLines != null && details.length >= maxSummaryLines) {
          break;
        }
      }
    }

    return ProfessionalAccountantProjectContent(
      details: List.unmodifiable(details),
      links: List.unmodifiable(links),
    );
  }

  static String compactLink(String value) {
    var compact = value.trim();
    if (compact.isEmpty) {
      return '';
    }

    compact = compact.replaceFirst(RegExp(r'^[<(\[]+'), '');
    compact = compact.replaceFirst(RegExp(r'[>\]),.;:]+$'), '');
    compact =
        compact.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    compact = compact.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    compact = compact.replaceFirst(RegExp(r'[>\]),.;:]+$'), '');

    return compact.replaceAll(RegExp(r'/$'), '');
  }

  static List<String> _splitLines(String text) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    return raw
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingListMarkerPattern, '');
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
