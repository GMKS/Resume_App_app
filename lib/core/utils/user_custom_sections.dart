import 'package:uuid/uuid.dart';

import '../models/resume_model.dart';
import 'professional_role_sections.dart';
import 'startup_profile_sections.dart';

class UserCustomSectionDisplayItem {
  const UserCustomSectionDisplayItem({
    required this.heading,
    required this.subtitle,
    required this.date,
    required this.detailLines,
  });

  final String heading;
  final String subtitle;
  final DateTime? date;
  final List<String> detailLines;

  bool get hasContent =>
      heading.isNotEmpty ||
      subtitle.isNotEmpty ||
      date != null ||
      detailLines.isNotEmpty;
}

const String kUserCustomSectionIdPrefix = 'user_custom_';
const String kUserCustomSectionFeatureKey = 'custom_sections';

const List<String> kSuggestedUserCustomSectionTitles = <String>[
  'Awards',
  'Leadership Experience',
  'Open Source Contributions',
  'Publications',
];

const _professionalRoleTemplateIds = <String>[
  'executive',
  'designer_profile',
  'professional_tone',
  'elegant_gold_layout',
];

bool isBuiltInCustomSectionId(String id) {
  if (startupSectionConfigById(id) != null) {
    return true;
  }

  for (final templateId in _professionalRoleTemplateIds) {
    if (professionalRoleSectionConfigById(templateId, id) != null) {
      return true;
    }
  }

  return false;
}

bool isUserCustomSectionId(String id) {
  return id.startsWith(kUserCustomSectionIdPrefix) ||
      !isBuiltInCustomSectionId(id);
}

bool isUserCustomSection(CustomSection section) {
  return isUserCustomSectionId(section.id);
}

String normalizeUserCustomSectionTitle(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String buildUserCustomSectionId() {
  return '$kUserCustomSectionIdPrefix${const Uuid().v4()}';
}

List<CustomSection> orderedUserCustomSections(ResumeModel resume) {
  return orderedUserCustomSectionsFromList(resume.customSections);
}

List<CustomSection> orderedUserCustomSectionsFromList(
  Iterable<CustomSection> sections,
) {
  final ordered = sections.where(isUserCustomSection).toList(growable: false);
  final mutable = List<CustomSection>.from(ordered);
  mutable.sort((left, right) {
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
  return List.unmodifiable(mutable);
}

List<CustomSection> mergeUserCustomSections({
  required List<CustomSection> existingSections,
  required List<CustomSection> orderedUserSections,
}) {
  final nonUserSections = existingSections
      .where((section) => !isUserCustomSection(section))
      .toList(growable: false);
  final normalizedUsers = orderedUserSections
      .asMap()
      .entries
      .map(
        (entry) => entry.value.copyWith(order: entry.key),
      )
      .toList(growable: false);

  return List.unmodifiable(<CustomSection>[
    ...nonUserSections,
    ...normalizedUsers,
  ]);
}

bool hasDuplicateUserCustomSectionTitle(
  List<CustomSection> sections,
  String title, {
  String? excludingId,
}) {
  final normalized = normalizeUserCustomSectionTitle(title).toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  for (final section in sections.where(isUserCustomSection)) {
    if (section.id == excludingId) {
      continue;
    }
    if (normalizeUserCustomSectionTitle(section.title).toLowerCase() ==
        normalized) {
      return true;
    }
  }

  return false;
}

List<String> splitUserCustomSectionContent(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) {
    return const <String>[];
  }

  final normalized = value
      .replaceAll(RegExp(r'\r\n?'), '\n')
      .replaceAll(RegExp(r'\s+[•▪■✦→]+\s+'), '\n')
      .replaceAll(RegExp(r'\s+[-=]+>\s+'), '\n');

  final parts = normalized
      .split(RegExp(r'\n+'))
      .map(
        (line) => line.replaceFirst(RegExp(r'^[-*•▪■✦→]+\s*'), '').trim(),
      )
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  return parts;
}

UserCustomSectionDisplayItem buildUserCustomSectionDisplayItem(
  CustomSectionItem item,
) {
  var heading = item.title.trim();
  var detailLines = splitUserCustomSectionContent(item.description);

  if (heading.isEmpty && detailLines.isNotEmpty) {
    heading = detailLines.first;
    detailLines = detailLines.skip(1).toList(growable: false);
  }

  return UserCustomSectionDisplayItem(
    heading: heading,
    subtitle: (item.subtitle ?? '').trim(),
    date: item.date,
    detailLines: List.unmodifiable(detailLines),
  );
}

List<String> userCustomSectionItemLines(CustomSectionItem item) {
  final lines = <String>[];

  if (item.title.trim().isNotEmpty) {
    lines.add(item.title.trim());
  }
  if ((item.subtitle ?? '').trim().isNotEmpty) {
    lines.add((item.subtitle ?? '').trim());
  }
  for (final line in splitUserCustomSectionContent(item.description)) {
    lines.add(line);
  }

  return List.unmodifiable(lines);
}

String userCustomSectionItemPreview(CustomSectionItem item) {
  final lines = userCustomSectionItemLines(item);
  if (lines.isEmpty) {
    return 'No content yet';
  }
  return lines.first;
}

CustomSectionItem buildUserCustomSectionItem({
  String? id,
  String? heading,
  String? subtitle,
  required String content,
}) {
  final normalizedHeading = heading?.trim() ?? '';
  final normalizedSubtitle = subtitle?.trim() ?? '';
  final rawLines = splitUserCustomSectionContent(content);

  if (normalizedHeading.isNotEmpty) {
    return CustomSectionItem(
      id: id ?? const Uuid().v4(),
      title: normalizedHeading,
      subtitle: normalizedSubtitle.isEmpty ? null : normalizedSubtitle,
      description: content.trim(),
    );
  }

  if (rawLines.isEmpty) {
    return CustomSectionItem(
      id: id ?? const Uuid().v4(),
      title: '',
      subtitle: normalizedSubtitle.isEmpty ? null : normalizedSubtitle,
      description: null,
    );
  }

  final lead = rawLines.first;
  final remaining = rawLines.skip(1).join('\n');
  return CustomSectionItem(
    id: id ?? const Uuid().v4(),
    title: lead,
    subtitle: normalizedSubtitle.isEmpty ? null : normalizedSubtitle,
    description: remaining.isEmpty ? null : remaining,
  );
}