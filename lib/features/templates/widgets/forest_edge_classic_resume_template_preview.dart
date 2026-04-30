import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../forest_edge_classic_template_support.dart';

class ForestEdgeClassicResumeTemplatePreview extends StatelessWidget {
  const ForestEdgeClassicResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageBg => const Color(ForestEdgeClassicTemplateSupport.pageBgHex);
  Color get _paper => const Color(ForestEdgeClassicTemplateSupport.paperHex);
  Color get _card => const Color(ForestEdgeClassicTemplateSupport.cardHex);
  Color get _header => const Color(ForestEdgeClassicTemplateSupport.headerHex);
  Color get _headerCard =>
      const Color(ForestEdgeClassicTemplateSupport.headerCardHex);
  Color get _accent => const Color(ForestEdgeClassicTemplateSupport.accentHex);
  Color get _line => const Color(ForestEdgeClassicTemplateSupport.lineHex);
  Color get _ink => const Color(ForestEdgeClassicTemplateSupport.inkHex);
  Color get _muted => const Color(ForestEdgeClassicTemplateSupport.mutedHex);
  Color get _cream => const Color(ForestEdgeClassicTemplateSupport.creamHex);
  Color get _tag => const Color(ForestEdgeClassicTemplateSupport.tagHex);

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name = ForestEdgeClassicTemplateSupport.displayName(previewResume);
    final title = ForestEdgeClassicTemplateSupport.displayTitle(previewResume);
    final contactItems = ForestEdgeClassicTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ForestEdgeClassicTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final educationEntries = ForestEdgeClassicTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final experienceEntries =
        ForestEdgeClassicTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: null,
      yearOnly: true,
    );
    final skillNames = ForestEdgeClassicTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final projectEntries = ForestEdgeClassicTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 1,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        ForestEdgeClassicTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = ForestEdgeClassicTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: 2,
    );

    final previewContacts = (contactItems.isNotEmpty
            ? contactItems
            : const [
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.email,
                  label: 'john.smith@email.com',
                ),
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.phone,
                  label: '(555) 123-4567',
                ),
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.linkedin,
                  label: 'linkedin.com/in/johnsmith',
                ),
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.website,
                  label: 'johnsmith.dev',
                ),
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.github,
                  label: 'github.com/johnsmith',
                ),
                ForestEdgeClassicContactItem(
                  kind: ForestEdgeClassicContactKind.address,
                  label: 'New York, NY',
                ),
              ])
        .toList(growable: false);
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines.take(3).toList(growable: false)
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
            'Improves delivery quality through dependable systems and clear communication.',
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries.first
        : const ForestEdgeClassicEducationEntry(
            institution: 'State University',
            degreeLine: 'Bachelor of Science Software Engineering',
            dateRange: '2018-2022',
          );
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries.first
        : const ForestEdgeClassicExperienceEntry(
            title: 'Senior Developer',
            company: 'TechCorp',
            dateRange: '2022-Present',
            detailLines: ['Led teams of 5 to deliver cloud-based platforms.'],
          );
    final previewProject = projectEntries.isNotEmpty
        ? projectEntries.first
        : const ForestEdgeClassicProjectEntry(
            title: 'Portfolio Website',
            detailLines: [
              'Developed a responsive portfolio showcasing projects and skills.'
            ],
          );
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English Professional', 'German Professional'];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            ForestEdgeClassicCertificationEntry(
              name: 'AWS Certified Developer',
              detailLines: ['Amazon'],
            ),
            ForestEdgeClassicCertificationEntry(
              name: 'Oracle Cloud Certification',
              detailLines: ['Oracle'],
            ),
          ];
    Text text(
      String value, {
      double size = 1.6,
      Color? color,
      FontWeight weight = FontWeight.normal,
      TextAlign align = TextAlign.left,
      int? maxLines,
      double height = 1.16,
    }) {
      final effectiveMaxLines =
          maxLines != null && maxLines > 0 ? maxLines : null;
      return Text(
        value,
        textAlign: align,
        maxLines: effectiveMaxLines,
        overflow:
            effectiveMaxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
      );
    }

    Widget bodyText(
      String value, {
      double size = 1.42,
      int maxLines = 3,
      Color? color,
      FontWeight weight = FontWeight.normal,
    }) {
      return SizedBox(
        width: double.infinity,
        child: text(
          value,
          size: size,
          color: color,
          weight: weight,
          align: TextAlign.justify,
          maxLines: maxLines,
          height: 1.18,
        ),
      );
    }

    Widget ribbon(String title) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: text(
              title,
              size: 1.72,
              color: _paper,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 0.5,
              color: _line,
            ),
          ),
        ],
      );
    }

    Widget card(Widget child) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line, width: 1.1),
        ),
        child: child,
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final title = normalizeUserCustomSectionTitle(section.title);
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayItem.heading.isNotEmpty)
                  text(
                    displayItem.heading,
                    size: 1.56,
                    color: _ink,
                    weight: FontWeight.w700,
                    maxLines: 0,
                  ),
                if (metaParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 0.8),
                    child: bodyText(
                      metaParts.join('  |  '),
                      size: 1.28,
                      maxLines: 0,
                      color: _accent,
                    ),
                  ),
                for (final line in displayItem.detailLines)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: bodyText(
                      line,
                      size: 1.36,
                      maxLines: 0,
                      color: _muted,
                    ),
                  ),
              ],
            );
          })
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return null;
      }

      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(
              title.isEmpty ? 'CUSTOM SECTION' : title.toUpperCase(),
              size: 1.56,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 0,
            ),
            const SizedBox(height: 2),
            ...itemBlocks
                .expand((widget) => [widget, const SizedBox(height: 1.4)]),
          ],
        ),
      );
    }

    final previewCustomSections = orderedUserCustomSectionsFromList(
      previewResume?.customSections ?? const <CustomSection>[],
    ).map(customSectionBlock).whereType<Widget>().toList(growable: false);

    Widget contactLine(String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.4,
              height: 6.8,
              margin: const EdgeInsets.only(top: 0.2),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: text(
                value,
                size: 1.24,
                color: _paper,
                maxLines: 2,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    Widget yearPill(String range, {required bool dark}) {
      final parts = range.split('-');
      final start = parts.isNotEmpty ? parts.first : range;
      final end = parts.length > 1 ? parts.sublist(1).join('-') : '';
      return Container(
        width: 16,
        padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.1),
        decoration: BoxDecoration(
          color: dark ? _header : _cream,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            text(
              start,
              size: 1.42,
              color: dark ? Colors.white : _ink,
              weight: FontWeight.w700,
              maxLines: 1,
              align: TextAlign.center,
            ),
            Container(
              width: 8,
              height: 0.5,
              color: dark ? _cream : _accent,
              margin: const EdgeInsets.symmetric(vertical: 1.1),
            ),
            text(
              end,
              size: 1.32,
              color: dark ? Colors.white : _ink,
              weight: FontWeight.w700,
              maxLines: 2,
              align: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget goldBarBullet(String line, {int maxLines = 2}) {
      return Padding(
        padding: const EdgeInsets.only(top: 1.6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4.8,
              height: 0.9,
              margin: const EdgeInsets.only(top: 3.2),
              color: _accent,
            ),
            const SizedBox(width: 2.2),
            Expanded(
              child: bodyText(
                line,
                size: 1.4,
                maxLines: maxLines,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    Widget profileBullet(String line, {int maxLines = 2}) {
      return Padding(
        padding: const EdgeInsets.only(top: 1.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.5),
              child: Icon(
                Icons.check,
                size: 4.6,
                color: _accent,
              ),
            ),
            const SizedBox(width: 2.1),
            Expanded(
              child: bodyText(
                line,
                size: 1.34,
                maxLines: maxLines,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    Widget header() {
      return Container(
        decoration: BoxDecoration(
          color: _header,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 2.6,
              height: previewContacts.length > 4 ? 36 : 28,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(
                    name.toUpperCase(),
                    size: 4.15,
                    color: Colors.white,
                    weight: FontWeight.w900,
                    maxLines: 2,
                  ),
                  text(
                    title,
                    size: 1.7,
                    color: _cream,
                    maxLines: 2,
                  ),
                  Container(
                    width: 34,
                    height: 0.55,
                    color: _accent,
                    margin: const EdgeInsets.only(top: 2.3),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              padding: const EdgeInsets.fromLTRB(3.2, 3.2, 3.2, 2.4),
              decoration: BoxDecoration(
                color: _headerCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: previewContacts
                    .map((item) => contactLine(item.label))
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ribbon('PROFILE'),
                    const SizedBox(height: 3),
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: previewSummaryLines
                            .map(
                              (line) => profileBullet(
                                line,
                                maxLines: 2,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ribbon('EXPERIENCE'),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        yearPill(previewExperience.dateRange, dark: true),
                        const SizedBox(width: 3),
                        Expanded(
                          child: card(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  previewExperience.title,
                                  size: 1.82,
                                  color: _ink,
                                  weight: FontWeight.w800,
                                  maxLines: 1,
                                ),
                                text(
                                  previewExperience.company,
                                  size: 1.56,
                                  color: _accent,
                                  weight: FontWeight.w700,
                                  maxLines: 1,
                                ),
                                if (previewExperience.location.isNotEmpty)
                                  text(
                                    previewExperience.location,
                                    size: 1.34,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ...previewExperience.detailLines.map(
                                  (line) => goldBarBullet(
                                    line,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ribbon('PROJECTS'),
                    const SizedBox(height: 3),
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            previewProject.title,
                            size: 1.84,
                            color: _ink,
                            weight: FontWeight.w800,
                            maxLines: 1,
                          ),
                          ...previewProject.detailLines.map(
                            (line) => goldBarBullet(
                              line,
                            ),
                          ),
                          if (previewProject.links.isNotEmpty)
                            text(
                              previewProject.links.first,
                              size: 1.34,
                              color: _header,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ribbon('EDUCATION'),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        yearPill(previewEducation.dateRange, dark: false),
                        const SizedBox(width: 3),
                        Expanded(
                          child: card(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  previewEducation.institution,
                                  size: 1.74,
                                  color: _ink,
                                  weight: FontWeight.w700,
                                  maxLines: 1,
                                ),
                                bodyText(
                                  previewEducation.degreeLine,
                                  size: 1.44,
                                  maxLines: 2,
                                  color: _muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ribbon('SKILLS'),
                              const SizedBox(height: 3),
                              card(
                                Wrap(
                                  spacing: 2,
                                  runSpacing: 2,
                                  children: previewSkills
                                      .map(
                                        (skill) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2.8,
                                            vertical: 1.2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _tag,
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: text(
                                            skill,
                                            size: 1.48,
                                            color: _ink,
                                            maxLines: 1,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ribbon('LANGUAGES'),
                              const SizedBox(height: 3),
                              card(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: previewLanguages
                                      .map(
                                        (line) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 1),
                                          child: text(
                                            line,
                                            size: 1.38,
                                            color: _muted,
                                            maxLines: 1,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                              const SizedBox(height: 3),
                              ribbon('CERTIFICATIONS'),
                              const SizedBox(height: 3),
                              card(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: previewCertifications
                                      .expand(
                                        (entry) => [
                                          text(
                                            entry.name,
                                            size: 1.56,
                                            color: _ink,
                                            weight: FontWeight.w700,
                                            maxLines: 1,
                                          ),
                                          ...entry.detailLines.map(
                                            (line) => goldBarBullet(
                                              line,
                                              maxLines: 1,
                                            ),
                                          ),
                                          if (previewCertifications.last != entry)
                                            const SizedBox(height: 1.1),
                                        ],
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (previewCustomSections.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...previewCustomSections,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
