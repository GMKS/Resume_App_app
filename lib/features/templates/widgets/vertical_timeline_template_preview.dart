import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../vertical_timeline_template_support.dart';

class VerticalTimelineTemplatePreview extends StatelessWidget {
  const VerticalTimelineTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  @override
  Widget build(BuildContext context) {
    final name = VerticalTimelineTemplateSupport.displayName(resume);
    final title = VerticalTimelineTemplateSupport.displayTitle(resume);
    final summaryLines = VerticalTimelineTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    final educationEntries = VerticalTimelineTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
    );
    final experienceEntries = VerticalTimelineTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
    );
    final projectEntries = VerticalTimelineTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final skillNames = VerticalTimelineTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    final certificationLines =
        VerticalTimelineTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
    );
    final languageLines = VerticalTimelineTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    final contactItems = VerticalTimelineTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
    );
    final hasPhoto = resume != null &&
        (resume!.personalInfo.profileImage?.isNotEmpty ?? false);

    final objective = summaryLines.isNotEmpty
        ? summaryLines.join(' ')
        : 'Passionate software engineer with 5+ years of experience in full-stack development, seeking to leverage expertise in scalable architectures and modern web technologies to drive innovation and deliver impactful user experiences.';
    final educationEntry = educationEntries.isNotEmpty
        ? educationEntries.first
        : const VerticalTimelineEducationEntry(
            degree: 'B.S. Computer Science',
            institutionLine: 'Stanford University',
            dateRange: '2014 - 2018',
          );
    final previewExperiences = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            VerticalTimelineExperienceEntry(
              title: 'Senior Developer',
              metaLine: 'Tech Corp',
              dateRange: '2020 - Present',
              detailLines: [
                'Led the migration of legacy monolithic architecture to microservices and improved deployment efficiency.',
              ],
            ),
            VerticalTimelineExperienceEntry(
              title: 'Software Engineer',
              metaLine: 'Startup Inc',
              dateRange: '2018 - 2020',
              detailLines: [
                'Developed and maintained RESTful APIs for mobile integration and backend performance improvements.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            VerticalTimelineProjectEntry(
              title: 'E-Commerce Platform',
              detailLines: [
                'Built a scalable storefront and checkout experience.'
              ],
              links: ['github.com/johndoe/ecommerce'],
            ),
            VerticalTimelineProjectEntry(
              title: 'Real-time Chat App',
              detailLines: [
                'Implemented live messaging with synchronized presence.'
              ],
              links: ['github.com/johndoe/chat'],
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const [
            'Flutter',
            'Dart',
            'React',
            'Node.js',
            'Firebase',
            'AWS',
          ];
    final previewCertifications = certificationLines.isNotEmpty
        ? certificationLines
        : const [
            'AWS Certified Developer',
            'Google Cloud Professional',
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const [
            'English - Native',
            'Spanish - Conversational',
            'French - Basic',
          ];
    final footerItems = contactItems.isNotEmpty
        ? contactItems
        : const [
            VerticalTimelineContactItem(
              kind: VerticalTimelineContactKind.email,
              label: 'john.doe@email.com',
            ),
            VerticalTimelineContactItem(
              kind: VerticalTimelineContactKind.phone,
              label: '+1 (555) 123-4567',
            ),
            VerticalTimelineContactItem(
              kind: VerticalTimelineContactKind.linkedin,
              label: 'linkedin.com/in/johndoe',
            ),
            VerticalTimelineContactItem(
              kind: VerticalTimelineContactKind.github,
              label: 'github.com/johndoe',
            ),
            VerticalTimelineContactItem(
              kind: VerticalTimelineContactKind.website,
              label: 'johndoe.dev',
            ),
          ];
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    ).where((section) => section.items.isNotEmpty).toList(growable: false);

    Widget txt(
      String text, {
      double size = 3.5,
      Color color = Colors.black87,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      bool justify = false,
    }) {
      final effectiveMaxLines =
          maxLines != null && maxLines > 0 ? maxLines : null;
      return Text(
        text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          fontFamily: 'Helvetica',
        ),
        maxLines: effectiveMaxLines,
        overflow: effectiveMaxLines != null ? TextOverflow.ellipsis : null,
        textAlign: justify ? TextAlign.justify : TextAlign.left,
      );
    }

    Widget vtSectionLabel(String titleStr) => Padding(
          padding: const EdgeInsets.only(bottom: 2, top: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(
                titleStr,
                size: 4.0,
                color: const Color(0xFF1A2535),
                weight: FontWeight.bold,
              ),
              Container(
                height: 1.2,
                color: accentColor,
                margin: const EdgeInsets.only(top: 1, bottom: 1),
              ),
            ],
          ),
        );

    Widget vtDotEntry(
      String titleStr,
      String sub,
      String? desc,
      Color dotColor, {
      String? trailing,
    }) {
      if (titleStr.isEmpty) {
        return const SizedBox.shrink();
      }

      final subLine = trailing?.isNotEmpty == true ? '$sub | $trailing' : sub;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 1),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
                Container(
                  width: 1,
                  height: desc != null ? 20 : 14,
                  color: dotColor.withValues(alpha: 0.25),
                ),
              ],
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt(
                    titleStr,
                    size: 3.5,
                    color: const Color(0xFF1A2535),
                    weight: FontWeight.w600,
                  ),
                  txt(
                    subLine,
                    size: 2.8,
                    color: dotColor,
                    weight: FontWeight.w500,
                  ),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    txt(
                      desc,
                      size: 2.8,
                      color: Colors.grey.shade700,
                      maxLines: 2,
                      justify: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

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

      final connectorHeight = 14 + (displayItem.detailLines.length * 9);
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: connectorHeight.toDouble(),
                  color: accentColor.withValues(alpha: 0.25),
                ),
              ],
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayItem.heading.isNotEmpty)
                    txt(
                      displayItem.heading,
                      size: 3.0,
                      color: const Color(0xFF1A2535),
                      weight: FontWeight.w600,
                    ),
                  if (metaParts.isNotEmpty)
                    txt(
                      metaParts.join('  |  '),
                      size: 2.7,
                      color: accentColor,
                      weight: FontWeight.w500,
                    ),
                  for (final line in displayItem.detailLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: txt(
                        line,
                        size: 2.7,
                        color: Colors.grey.shade700,
                        maxLines: 0,
                        justify: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final title = displayUserCustomSectionTitle(section);
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
          vtSectionLabel(title.toUpperCase()),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      txt(
                        name,
                        size: 9.0,
                        color: const Color(0xFF1A2535),
                        weight: FontWeight.w900,
                      ),
                      txt(
                        title,
                        size: 4.2,
                        color: accentColor,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (hasPhoto)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Container(
                      width: 28,
                      height: 28,
                      color: accentColor.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
            child: Container(height: 1.5, color: accentColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 1, 8, 0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    vtSectionLabel('ABOUT'),
                    txt(
                      objective,
                      size: 2.8,
                      color: Colors.grey.shade600,
                      maxLines: hasPhoto ? 4 : 3,
                      justify: true,
                    ),
                    const SizedBox(height: 4),
                    vtSectionLabel('EDUCATION'),
                    vtDotEntry(
                      educationEntry.degree,
                      educationEntry.institutionLine,
                      null,
                      accentColor,
                      trailing: educationEntry.dateRange,
                    ),
                    const SizedBox(height: 3),
                    vtSectionLabel('EXPERIENCE'),
                    ...previewExperiences.map(
                      (entry) => vtDotEntry(
                        entry.title,
                        entry.metaLine,
                        entry.detailLines.isNotEmpty
                            ? entry.detailLines.first
                            : null,
                        accentColor,
                        trailing: entry.dateRange,
                      ),
                    ),
                    const SizedBox(height: 3),
                    vtSectionLabel('SKILLS'),
                    Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      children: previewSkills
                          .map(
                            (skill) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor,
                                  ),
                                ),
                                txt(
                                  skill,
                                  size: 2.8,
                                  color: Colors.grey.shade800,
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (previewProjects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      vtSectionLabel('PROJECTS'),
                      ...previewProjects.map(
                        (project) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              txt(
                                project.title,
                                size: 3.0,
                                color: Colors.grey.shade800,
                                weight: FontWeight.w600,
                              ),
                              if (project.detailLines.isNotEmpty)
                                txt(
                                  project.detailLines.first,
                                  size: 2.55,
                                  color: Colors.grey.shade600,
                                  maxLines: 2,
                                  justify: true,
                                ),
                              ...project.links.map(
                                (link) => txt(
                                  link,
                                  size: 2.5,
                                  color: accentColor,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (previewCertifications.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      vtSectionLabel('CERTIFICATIONS'),
                      ...previewCertifications.map(
                        (line) => txt(
                          line,
                          size: 2.8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (previewLanguages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      vtSectionLabel('LANGUAGES'),
                      ...previewLanguages.map(
                        (line) => txt(
                          line,
                          size: 2.8,
                          color: Colors.grey.shade600,
                        ),
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
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
            color: accentColor,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: footerItems
                  .map((item) => item.label)
                  .map(
                    (item) => txt(
                      item,
                      size: 2.5,
                      color: Colors.white,
                      weight: FontWeight.w600,
                      maxLines: 1,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
