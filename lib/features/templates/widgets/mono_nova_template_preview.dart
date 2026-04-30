import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../mono_nova_template_support.dart';

class MonoNovaTemplatePreview extends StatelessWidget {
  const MonoNovaTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageBg => const Color(MonoNovaTemplateSupport.pageHex);
  Color get _ink => const Color(MonoNovaTemplateSupport.inkHex);
  Color get _muted => const Color(MonoNovaTemplateSupport.mutedHex);
  Color get _rule => const Color(MonoNovaTemplateSupport.ruleHex);

  @override
  Widget build(BuildContext context) {
    final name = MonoNovaTemplateSupport.displayName(resume);
    final title = MonoNovaTemplateSupport.displayTitle(resume);
    final contacts = MonoNovaTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
    );
    final summaryLines = MonoNovaTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 4,
    );
    final experiences = MonoNovaTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
    );
    final educations = MonoNovaTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
    );
    final skills = MonoNovaTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    final projects = MonoNovaTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certifications = MonoNovaTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
    );
    final languages = MonoNovaTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 5,
    );

    final previewContacts = contacts.isNotEmpty
        ? contacts
        : const [
            MonoNovaContactItem(
              kind: MonoNovaContactKind.location,
              label: 'New York, NY',
            ),
            MonoNovaContactItem(
              kind: MonoNovaContactKind.email,
              label: 'john.smith@email.com',
            ),
            MonoNovaContactItem(
              kind: MonoNovaContactKind.phone,
              label: '(555) 123-4567',
            ),
            MonoNovaContactItem(
              kind: MonoNovaContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            MonoNovaContactItem(
              kind: MonoNovaContactKind.github,
              label: 'github.com/johnsmith',
            ),
            MonoNovaContactItem(
              kind: MonoNovaContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
          ];
    final previewExperiences = experiences.isNotEmpty
        ? experiences
        : const [
            MonoNovaExperienceEntry(
              title: 'Senior Developer',
              metaLine: 'TechCorp',
              dateRange: '2021 - Present',
              detailLines: [
                'Led team of 5 to deliver cloud-based platform solutions.',
              ],
            ),
            MonoNovaExperienceEntry(
              title: 'Junior Developer',
              metaLine: 'StartupXYZ',
              dateRange: '2019 - 2020',
            ),
          ];
    final previewEducation = educations.isNotEmpty
        ? educations
        : const [
            MonoNovaEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateLabel: '2019',
            ),
          ];
    final previewSkills = skills.isNotEmpty
        ? skills
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
    final previewProjects = projects.isNotEmpty
        ? projects
        : const [
            MonoNovaProjectEntry(title: 'Portfolio Website'),
            MonoNovaProjectEntry(title: 'Task Management App'),
          ];
    final previewCertifications = certifications.isNotEmpty
        ? certifications
        : const [
            'AWS Certified Developer  •  Amazon',
            'Scrum Master  •  Scrum Alliance',
          ];
    final previewLanguages = languages.isNotEmpty
        ? languages
        : const ['English Professional', 'German Professional'];
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    ).where((section) => section.items.isNotEmpty).toList(growable: false);

    Widget text(
      String value, {
      double size = 3.5,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
    }) {
      final effectiveMaxLines =
          maxLines != null && maxLines > 0 ? maxLines : null;
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: 1.18,
        ),
        maxLines: effectiveMaxLines,
        overflow:
            effectiveMaxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sectionHeader(String title) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(
              title,
              size: 4.35,
              color: const Color(0xFF3F3C39),
              weight: FontWeight.bold,
            ),
            Container(height: 0.8, color: _rule),
          ],
        );

    Widget bulletLine(String line, {double size = 3.2, int? maxLines}) => Padding(
          padding: const EdgeInsets.only(bottom: 1.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text('-', size: size, color: _muted, weight: FontWeight.w600),
              const SizedBox(width: 3),
              Expanded(
                child: text(
                  line,
                  size: size,
                  color: _muted,
                  maxLines: maxLines,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(MonoNovaExperienceEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.title,
                size: 4.45,
                color: _ink,
                weight: FontWeight.w700,
              ),
              text(
                entry.metaLine.isNotEmpty
                    ? '${entry.metaLine}  •  ${entry.dateRange}'
                    : entry.dateRange,
                size: 3.45,
                color: _muted,
                maxLines: 1,
              ),
              if (entry.detailLines.isNotEmpty)
                bulletLine(entry.detailLines.first, size: 3.35, maxLines: 2),
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
        padding: const EdgeInsets.only(bottom: 2.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayItem.heading.isNotEmpty)
              text(
                displayItem.heading,
                size: 3.65,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 0,
              ),
            if (metaParts.isNotEmpty)
              text(
                metaParts.join('  •  '),
                size: 3.05,
                color: _muted,
                maxLines: 0,
              ),
            for (final line in displayItem.detailLines)
              bulletLine(line, size: 3.15, maxLines: 0),
          ],
        ),
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final title = normalizeUserCustomSectionTitle(section.title);
      final itemBlocks = section.items
          .map(customSectionItemBlock)
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(title.isEmpty ? 'Custom Section' : title),
          const SizedBox(height: 2),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: _pageBg,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
                        size: 8.6,
                        color: _ink,
                        weight: FontWeight.w800,
                        maxLines: 1,
                      ),
                      text(
                        title,
                        size: 4.9,
                        color: _muted,
                        weight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: previewContacts
                        .map(
                          (item) => text(
                            item.label,
                            size: item.kind.index >= MonoNovaContactKind.linkedin.index
                                ? 3.0
                                : 3.25,
                            color: _muted,
                            maxLines: 1,
                            align: TextAlign.right,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              color: _rule,
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),
            sectionHeader('PROFESSIONAL SUMMARY'),
            const SizedBox(height: 2),
            ...previewSummary.map(
              (line) => bulletLine(line, size: 3.05, maxLines: 2),
            ),
            const SizedBox(height: 4),
            sectionHeader('EXPERIENCE'),
            const SizedBox(height: 2),
            ...previewExperiences.map(experienceBlock),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionHeader('EDUCATION'),
                      const SizedBox(height: 2),
                      ...previewEducation.map(
                        (entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(
                              entry.degree,
                              size: 3.9,
                              color: _ink,
                              weight: FontWeight.w700,
                              maxLines: 1,
                            ),
                            text(
                              '${entry.institutionLine}  •  ${entry.dateLabel}',
                              size: 3.1,
                              color: _muted,
                              maxLines: 2,
                            ),
                          ],
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
                      sectionHeader('SKILLS'),
                      const SizedBox(height: 2),
                      text(
                        previewSkills.join(', '),
                        size: 3.15,
                        color: _muted,
                        maxLines: 4,
                        align: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (previewProjects.isNotEmpty) ...[
              const SizedBox(height: 4),
              sectionHeader('PROJECTS'),
              const SizedBox(height: 2),
              ...previewProjects.map(
                (entry) => text(
                  entry.title,
                  size: 3.65,
                  color: _ink,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
              ),
            ],
            if (previewCertifications.isNotEmpty) ...[
              const SizedBox(height: 4),
              sectionHeader('CERTIFICATIONS'),
              const SizedBox(height: 2),
              ...previewCertifications.map(
                (line) => text(
                  line,
                  size: 3.2,
                  color: _muted,
                  maxLines: 1,
                ),
              ),
            ],
            if (previewLanguages.isNotEmpty) ...[
              const SizedBox(height: 4),
              sectionHeader('LANGUAGES'),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 1,
                children: previewLanguages
                    .map(
                      (line) => text(
                        line,
                        size: 3.05,
                        color: _muted,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            for (final section in previewCustomSections)
              if (customSectionBlock(section) case final block?) ...[
                const SizedBox(height: 4),
                block,
              ],
          ],
        ),
      ),
    );
  }
}