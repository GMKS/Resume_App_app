import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../modern_edge_template_support.dart';

class ModernEdgeResumeTemplatePreview extends StatelessWidget {
  const ModernEdgeResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(ModernEdgeTemplateSupport.pageHex);
  Color get _sheet => const Color(ModernEdgeTemplateSupport.sheetHex);
  Color get _accent =>
      templateColor ?? const Color(ModernEdgeTemplateSupport.accentHex);
  Color get _accentDark => const Color(ModernEdgeTemplateSupport.accentDarkHex);
  Color get _accentSoft => const Color(ModernEdgeTemplateSupport.accentSoftHex);
  Color get _line => const Color(ModernEdgeTemplateSupport.lineHex);
  Color get _ink => const Color(ModernEdgeTemplateSupport.inkHex);
  Color get _muted => const Color(ModernEdgeTemplateSupport.mutedHex);
  Color get _sidebarInk => const Color(ModernEdgeTemplateSupport.sidebarInkHex);
  Color get _sidebarMuted =>
      const Color(ModernEdgeTemplateSupport.sidebarMutedHex);

  @override
  Widget build(BuildContext context) {
    final name = ModernEdgeTemplateSupport.displayName(resume);
    final title = ModernEdgeTemplateSupport.displayTitle(resume);
    final contactItems = ModernEdgeTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ModernEdgeTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: null,
    );
    final experienceEntries = ModernEdgeTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: null,
      maxDetailLines: null,
      yearOnly: true,
    );
    final projectEntries = ModernEdgeTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final skillNames = ModernEdgeTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
    );
    final educationEntries = ModernEdgeTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: null,
      yearOnly: true,
    );
    final certificationEntries = ModernEdgeTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = ModernEdgeTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.phone,
              label: '(555) 123-4567',
            ),
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.email,
              label: 'john.smith@email.com',
            ),
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.address,
              label: 'New York, NY',
            ),
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.github,
              label: 'github.com/johnsmith',
            ),
            ModernEdgeContactItem(
              kind: ModernEdgeContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven product builder focused on polished digital experiences.',
            'Turns stakeholder goals into reliable launches with strong execution.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            ModernEdgeExperienceEntry(
              title: 'Senior Product Designer',
              companyLine: 'Studio North  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Led design systems and launch-ready product flows across web and mobile.',
                'Improved delivery quality by aligning research, UI, and engineering handoff.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            ModernEdgeProjectEntry(
              title: 'Platform Redesign',
              detailLines: [
                'Delivered a cleaner onboarding and conversion-focused account flow.',
              ],
              links: ['example.com/platform'],
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Figma', 'Dart', 'Design Systems'];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            ModernEdgeEducationEntry(
              degreeLine: 'B.Des. Product Design',
              institutionLine: 'State University',
              dateRange: '2016 - 2020',
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            ModernEdgeCertificationEntry(
              name: 'Google UX Design Certificate',
              metaLine: 'Google  |  Jan 2025',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'French  |  Conversational'];
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    ).where((section) => section.items.isNotEmpty).toList(growable: false);

    Text text(
      String value, {
      double size = 2.5,
      Color? color,
      FontWeight weight = FontWeight.normal,
      double height = 1.18,
      TextAlign align = TextAlign.left,
    }) {
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
        textAlign: align,
      );
    }

    Widget sectionHeader(String titleText) => Padding(
          padding: const EdgeInsets.only(bottom: 2.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              text(
                titleText,
                size: 3.0,
                color: _accent,
                weight: FontWeight.w700,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 0.7,
                  color: _line,
                ),
              ),
            ],
          ),
        );

    Widget sidebarHeader(String titleText) => Padding(
          padding: const EdgeInsets.only(bottom: 1.7),
          child: text(
            titleText,
            size: 2.65,
            color: _sidebarInk,
            weight: FontWeight.w700,
          ),
        );

    Widget bulletLine(String line,
            {Color? bulletColor, double fontSize = 2.1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Container(
                  width: 2.6,
                  height: 2.6,
                  decoration: BoxDecoration(
                    color: bulletColor ?? _accentDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: text(
                  line,
                  size: fontSize,
                  color: _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget skillChip(String skill) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 0.3,
            ),
          ),
          child: text(
            skill,
            size: 1.9,
            color: _accentDark,
            weight: FontWeight.w600,
          ),
        );

    Widget educationBlock(ModernEdgeEducationEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.degreeLine,
                size: 2.05,
                color: _sidebarInk,
                weight: FontWeight.w700,
              ),
              text(
                entry.institutionLine,
                size: 1.9,
                color: _sidebarMuted,
              ),
              text(
                entry.dateRange,
                size: 1.82,
                color: _sidebarMuted,
              ),
            ],
          ),
        );

    Widget certificationBlock(ModernEdgeCertificationEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.name,
                size: 2.2,
                color: _ink,
                weight: FontWeight.w700,
              ),
              if (entry.metaLine.isNotEmpty)
                text(
                  entry.metaLine,
                  size: 1.95,
                  color: _muted,
                ),
              for (final link in entry.links)
                text(
                  link,
                  size: 1.92,
                  color: _accent,
                ),
            ],
          ),
        );

    Widget projectBlock(ModernEdgeProjectEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.title,
                size: 2.5,
                color: _ink,
                weight: FontWeight.w700,
              ),
              if (entry.technologyLine.isNotEmpty)
                text(
                  entry.technologyLine,
                  size: 1.9,
                  color: _accentDark,
                ),
              for (final line in entry.detailLines)
                bulletLine(line, fontSize: 2.02),
              for (final link in entry.links)
                Padding(
                  padding: const EdgeInsets.only(top: 0.4),
                  child: text(
                    link,
                    size: 1.96,
                    color: _accent,
                  ),
                ),
            ],
          ),
        );

    Widget experienceBlock(ModernEdgeExperienceEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: text(
                      entry.title,
                      size: 2.62,
                      color: _ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  text(
                    entry.dateRange,
                    size: 1.9,
                    color: _muted,
                  ),
                ],
              ),
              text(
                entry.companyLine,
                size: 2.02,
                color: _accentDark,
                weight: FontWeight.w600,
              ),
              const SizedBox(height: 1),
              for (final line in entry.detailLines)
                bulletLine(line, fontSize: 2.04),
            ],
          ),
        );

    Widget? customSectionItemBlock(CustomSectionItem item) {
      final displayItem = buildUserCustomSectionDisplayItem(item);

      final metaParts = <String>[
        if (displayItem.subtitle.isNotEmpty) displayItem.subtitle,
        if (displayItem.date != null)
          DateFormat('MMM yyyy').format(displayItem.date!),
      ];

      if (!displayItem.hasContent) {
        return null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 2.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayItem.heading.isNotEmpty)
              text(
                displayItem.heading,
                size: 2.34,
                color: _ink,
                weight: FontWeight.w700,
              ),
            if (metaParts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.4, bottom: 0.7),
                child: text(
                  metaParts.join('  |  '),
                  size: 1.9,
                  color: _accentDark,
                  weight: FontWeight.w600,
                ),
              ),
            for (final line in displayItem.detailLines)
              bulletLine(line, fontSize: 2.0),
          ],
        ),
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final titleText = normalizeUserCustomSectionTitle(section.title);
      final itemBlocks = <Widget>[];

      for (final item in section.items) {
        final block = customSectionItemBlock(item);
        if (block != null) {
          itemBlocks.add(block);
        }
      }

      if (itemBlocks.isEmpty) {
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(titleText.isEmpty ? 'Custom Section' : titleText),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: _page,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: _sheet,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(ModernEdgeTemplateSupport.sidebarTopHex),
                      Color(ModernEdgeTemplateSupport.sidebarBottomHex),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: photoBytes == null ? Colors.white : null,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1,
                          ),
                          image: photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(photoBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoBytes == null
                            ? Center(
                                child: text(
                                  _initials(name),
                                  size: 5,
                                  color: _accent,
                                  weight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    sidebarHeader('Contact'),
                    for (final item in previewContacts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1.1),
                        child: text(
                          item.label,
                          size: 1.82,
                          color: _sidebarMuted,
                        ),
                      ),
                    const SizedBox(height: 3),
                    sidebarHeader('Skills'),
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children:
                          previewSkills.map(skillChip).toList(growable: false),
                    ),
                    const SizedBox(height: 3),
                    sidebarHeader('Education'),
                    for (final entry in previewEducation) educationBlock(entry),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  text(
                                    name,
                                    size: 5.8,
                                    color: _ink,
                                    weight: FontWeight.w900,
                                  ),
                                  text(
                                    title,
                                    size: 2.7,
                                    color: _accentDark,
                                    weight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: _accentSoft,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 13,
                                color: _accent,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 0.7,
                          color: _line,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                        ),
                        sectionHeader('About Me'),
                        for (final line in previewSummaryLines)
                          bulletLine(line),
                        if (previewExperience.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          sectionHeader('Experience'),
                          for (final entry in previewExperience)
                            experienceBlock(entry),
                        ],
                        for (final section in previewCustomSections)
                          if (customSectionBlock(section) case final block?) block,
                        if (previewProjects.isNotEmpty) ...[
                          sectionHeader('Projects'),
                          for (final entry in previewProjects)
                            projectBlock(entry),
                        ],
                        if (previewCertifications.isNotEmpty) ...[
                          sectionHeader('Certifications'),
                          for (final entry in previewCertifications)
                            certificationBlock(entry),
                        ],
                        if (previewLanguages.isNotEmpty) ...[
                          sectionHeader('Languages'),
                          Wrap(
                            spacing: 3,
                            runSpacing: 2,
                            children: previewLanguages
                                .map(
                                  (line) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1.6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: text(
                                      line,
                                      size: 1.92,
                                      color: _accentDark,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Uint8List? _photoBytes(String? encoded) {
    final value = encoded?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .toList(growable: false);
    return parts.isEmpty ? 'ME' : parts.join();
  }
}
