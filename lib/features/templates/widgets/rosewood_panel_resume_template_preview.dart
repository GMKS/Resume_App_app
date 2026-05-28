import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../rosewood_panel_template_support.dart';

class RosewoodPanelResumeTemplatePreview extends StatelessWidget {
  const RosewoodPanelResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(RosewoodPanelTemplateSupport.pageHex);
  Color get _sheet => const Color(RosewoodPanelTemplateSupport.sheetHex);
  Color get _panel => const Color(RosewoodPanelTemplateSupport.panelHex);
  Color get _accent =>
      templateColor ?? const Color(RosewoodPanelTemplateSupport.accentHex);
  Color get _ink => const Color(RosewoodPanelTemplateSupport.inkHex);
  Color get _muted => const Color(RosewoodPanelTemplateSupport.mutedHex);
  Color get _panelInk => const Color(RosewoodPanelTemplateSupport.panelInkHex);
  Color get _sectionRule => _accent.withValues(alpha: 0.55);
  Color get _sidebarBorder => _accent.withValues(alpha: 0.45);
  Color get _avatar => _accent.withValues(alpha: 0.22);

  @override
  Widget build(BuildContext context) {
    final awardLikeSectionPattern = RegExp(
      r'(award|honou?r|achievement|recognition)',
      caseSensitive: false,
    );
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    )
        .where((section) => !awardLikeSectionPattern.hasMatch(section.title))
        .toList(growable: false);
    final name = RosewoodPanelTemplateSupport.displayName(resume).toUpperCase();
    final title = RosewoodPanelTemplateSupport.displayTitle(resume);
    final contactItems = RosewoodPanelTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = RosewoodPanelTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final summaryLines = RosewoodPanelTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    final experienceEntries = RosewoodPanelTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: 2,
      yearOnly: true,
    );
    final awardEntries = RosewoodPanelTemplateSupport.awardEntries(
      resume?.customSections ?? const <CustomSection>[],
      maxItems: 1,
    );
    final skillNames = RosewoodPanelTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 3,
    );
    final projectEntries = RosewoodPanelTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries =
        RosewoodPanelTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final languageLines = RosewoodPanelTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            RosewoodContactItem(
              kind: RosewoodContactKind.phone,
              label: '(555) 123-4567',
            ),
            RosewoodContactItem(
              kind: RosewoodContactKind.address,
              label: 'New York, NY',
            ),
            RosewoodContactItem(
              kind: RosewoodContactKind.email,
              label: 'john.smith@email.com',
            ),
            RosewoodContactItem(
              kind: RosewoodContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            RosewoodContactItem(
              kind: RosewoodContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            RosewoodEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateRange: '2015 - 2019',
            ),
          ];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional delivering high-quality solutions across web, mobile, and cloud products.',
            'Builds reliable user-facing experiences with strong execution and stakeholder alignment.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            RosewoodExperienceEntry(
              title: 'Senior Developer',
              metaLine: 'Tech Corp',
              dateRange: '2021 - Present',
              detailLines: ['Led team of 5 to deliver cloud-based platform'],
            ),
          ];
    final previewAwards = awardEntries.isNotEmpty
        ? awardEntries
        : const [
            RosewoodAwardEntry(title: 'Recognition'),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase'];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            RosewoodProjectEntry(title: 'Portfolio Website'),
            RosewoodProjectEntry(title: 'Task Management App'),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            RosewoodCertificationEntry(
              name: 'AWS Certified Developer',
              metaLine: 'Amazon',
            ),
            RosewoodCertificationEntry(
              name: 'Scrum Master',
              metaLine: 'Scrum Alliance',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English Professional', 'German Professional'];

    Text text(
      String value, {
      double size = 3,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
      double height = 1.15,
    }) {
      final normalizedMaxLines =
          maxLines != null && maxLines <= 0 ? null : maxLines;
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
        maxLines: normalizedMaxLines,
        overflow: normalizedMaxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget mainSection(String title) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            text(
              title,
              size: 3.0,
              color: _accent,
              weight: FontWeight.bold,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 0.7,
                color: _sectionRule,
              ),
            ),
          ],
        );

    Widget subSection(String title) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            text(
              title,
              size: 2.7,
              color: _accent,
              weight: FontWeight.bold,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 0.65,
                color: _sectionRule,
              ),
            ),
          ],
        );

    Widget sidebarSection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: text(
            title,
            size: 2.55,
            color: _accent,
            weight: FontWeight.bold,
          ),
        );

    Widget skillMeter(String skill) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(skill, size: 2.1, color: _ink, maxLines: 1),
              const SizedBox(height: 0.8),
              Container(
                width: 28,
                height: 2.4,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );

    Widget aboutLine(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.1),
                child: Icon(
                  Icons.check,
                  size: 3.2,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 1.5),
              Expanded(
                child: text(
                  line,
                  size: 1.88,
                  color: _muted,
                  maxLines: 2,
                  align: TextAlign.justify,
                  height: 1.18,
                ),
              ),
            ],
          ),
        );

    Widget projectLine(RosewoodProjectEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.title,
                size: 2.28,
                color: _ink,
                weight: FontWeight.w600,
                maxLines: 1,
              ),
              if (entry.detailLines.isNotEmpty)
                text(
                  entry.detailLines.first,
                  size: 1.84,
                  color: _muted,
                  maxLines: 2,
                  align: TextAlign.justify,
                  height: 1.12,
                ),
              if (entry.links.isNotEmpty)
                text(
                  entry.links.first,
                  size: 1.9,
                  color: _accent,
                  maxLines: 1,
                ),
            ],
          ),
        );

    Widget certificationLine(RosewoodCertificationEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: text(
            [
              entry.name,
              if (entry.metaLine.isNotEmpty) entry.metaLine,
            ].join(' - '),
            size: 2.05,
            color: _muted,
            maxLines: 1,
          ),
        );

    Widget? customSectionBlock(CustomSection section) {
      final title = displayUserCustomSectionTitle(section);
      final itemBlocks = section.items
          .map((item) {
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
              padding: const EdgeInsets.only(bottom: 1.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayItem.heading.isNotEmpty)
                    text(
                      displayItem.heading,
                      size: 2.18,
                      color: _ink,
                      weight: FontWeight.w600,
                      maxLines: 0,
                    ),
                  if (metaParts.isNotEmpty)
                    text(
                      metaParts.join('  |  '),
                      size: 1.9,
                      color: _accent,
                      maxLines: 0,
                    ),
                  ...displayItem.detailLines.map(
                    (line) => text(
                      line,
                      size: 1.88,
                      color: _muted,
                      maxLines: 0,
                      align: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            );
          })
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainSection(title.toUpperCase()),
          const SizedBox(height: 1.4),
          ...itemBlocks,
        ],
      );
    }

    final education = previewEducation.first;
    final experience = previewExperience.first;

    return Container(
      color: _page,
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: _sheet,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border.all(color: _sidebarBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatar,
                          image: photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(photoBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoBytes == null
                            ? Icon(Icons.person, size: 14, color: _accent)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    sidebarSection('CONTACT'),
                    ...previewContacts.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.7),
                        child: text(
                          item.label,
                          size: 1.75,
                          color: _panelInk,
                          maxLines: 1,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    sidebarSection('EDUCATION'),
                    text(
                      education.degree,
                      size: 1.95,
                      color: _ink,
                      weight: FontWeight.w600,
                      maxLines: 2,
                    ),
                    text(
                      '${education.institutionLine} | ${education.dateRange}',
                      size: 1.75,
                      color: _panelInk,
                      maxLines: 2,
                      height: 1.1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text(
                      name,
                      size: 5.15,
                      color: _accent,
                      weight: FontWeight.w800,
                      maxLines: 1,
                    ),
                    text(
                      title,
                      size: 2.45,
                      color: _muted,
                      weight: FontWeight.w500,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    mainSection('ABOUT'),
                    const SizedBox(height: 1.6),
                    ...previewSummaryLines.map(aboutLine),
                    const SizedBox(height: 4),
                    mainSection('EXPERIENCE'),
                    const SizedBox(height: 1.6),
                    text(
                      experience.title,
                      size: 2.35,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                    text(
                      '${experience.metaLine}  |  ${experience.dateRange}',
                      size: 1.9,
                      color: _muted,
                      maxLines: 1,
                    ),
                    ...experience.detailLines.take(2).map(
                          (line) => text(
                            '- $line',
                            size: 1.82,
                            color: _muted,
                            maxLines: 2,
                            align: TextAlign.justify,
                          ),
                        ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              subSection('AWARDS'),
                              const SizedBox(height: 1.4),
                              ...previewAwards.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.2),
                                  child: text(
                                    entry.title,
                                    size: 1.95,
                                    color: _muted,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              subSection('SKILLS'),
                              const SizedBox(height: 1.4),
                              ...previewSkills.map(skillMeter),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    mainSection('PROJECTS'),
                    const SizedBox(height: 1.4),
                    ...previewProjects.map(projectLine),
                    const SizedBox(height: 3),
                    mainSection('CERTIFICATIONS'),
                    const SizedBox(height: 1.4),
                    ...previewCertifications.map(certificationLine),
                    const SizedBox(height: 3),
                    mainSection('LANGUAGES'),
                    const SizedBox(height: 1.4),
                    ...previewLanguages.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: text(
                          line,
                          size: 1.95,
                          color: _muted,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    for (final section in previewCustomSections)
                      if (customSectionBlock(section) case final block?) ...[
                        const SizedBox(height: 3),
                        block,
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List? _photoBytes(String? encoded) {
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
}
