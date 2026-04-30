import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../forest_edge_template_support.dart';

class ForestEdgeResumeTemplatePreview extends StatelessWidget {
  const ForestEdgeResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageBg => const Color(ForestEdgeTemplateSupport.pageBgHex);
  Color get _paper => const Color(ForestEdgeTemplateSupport.paperHex);
  Color get _card => const Color(ForestEdgeTemplateSupport.cardHex);
  Color get _headerTint => const Color(ForestEdgeTemplateSupport.headerTintHex);
  Color get _headerAccent =>
      const Color(ForestEdgeTemplateSupport.headerAccentHex);
  Color get _line => const Color(ForestEdgeTemplateSupport.lineHex);
  Color get _ink => const Color(ForestEdgeTemplateSupport.inkHex);
  Color get _muted => const Color(ForestEdgeTemplateSupport.mutedHex);
  Color get _soft => const Color(ForestEdgeTemplateSupport.softHex);
  Color get _badge => const Color(ForestEdgeTemplateSupport.badgeHex);

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name = ForestEdgeTemplateSupport.displayName(previewResume);
    final title = ForestEdgeTemplateSupport.displayTitle(previewResume);
    final contactItems = ForestEdgeTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ForestEdgeTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final educationEntries = ForestEdgeTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final experienceEntries = ForestEdgeTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final skillNames = ForestEdgeTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: 3,
    );
    final languageLines = ForestEdgeTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: 1,
    );
    final projectEntries = ForestEdgeTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 1,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries = ForestEdgeTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: 1,
      compactLinks: true,
    );

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.phone,
              label: '+1 (555) 123-4567',
            ),
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.address,
              label: 'Seattle, WA',
            ),
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.email,
              label: 'alex@forest.dev',
            ),
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.linkedin,
              label: 'linkedin.com/in/alexchen',
            ),
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.github,
              label: 'github.com/alexchen',
            ),
            ForestEdgeContactItem(
              kind: ForestEdgeContactKind.website,
              label: 'alexchen.dev',
            ),
          ];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Builds dependable product systems and delivery practices for distributed teams.',
            'Translates ambiguous product requirements into maintainable technical execution.',
            'Combines strong communication, debugging, and release discipline.',
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            ForestEdgeEducationEntry(
              institution: 'University of Washington',
              degreeLine: 'B.Sc. Computer Science',
              dateRange: '2016-2020',
            ),
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            ForestEdgeExperienceEntry(
              company: 'BlueWave Labs',
              title: 'Senior Engineering Manager',
              dateRange: '2022-Present',
              location: 'Remote',
              detailLines: [
                'Led tooling and platform delivery for multiple product teams.',
              ],
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Azure', 'Communication', 'Leadership'];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Native', 'German  |  Professional'];
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
      double size = 1.46,
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

    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            ForestEdgeProjectEntry(
              title: 'Observability Platform',
              detailLines: [
                'Unified telemetry, release health, and service alerting workflows.',
              ],
              links: ['alexchen.dev/observability'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            ForestEdgeCertificationEntry(
              name: 'AWS Solutions Architect',
              detailLines: ['Amazon', 'Issued Jan 2024'],
              links: ['example.com/cert/aws-123'],
            ),
          ];

    Widget card({
      required String title,
      required Widget child,
    }) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 11, 6, 6),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _line),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: child,
            ),
          ),
          Positioned(
            left: 6,
            top: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _headerAccent, width: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: text(
                title,
                size: 1.72,
                color: _ink,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                    child: text(
                      metaParts.join('  |  '),
                      size: 1.3,
                      color: _soft,
                      weight: FontWeight.w600,
                      maxLines: 0,
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
        title: title.isEmpty ? 'CUSTOM SECTION' : title.toUpperCase(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemBlocks
              .expand((widget) => [widget, const SizedBox(height: 1.4)])
              .toList(growable: false),
        ),
      );
    }

    final previewCustomSections = orderedUserCustomSectionsFromList(
      previewResume?.customSections ?? const <CustomSection>[],
    ).map(customSectionBlock).whereType<Widget>().toList(growable: false);

    Widget aboutBullet(String line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 0.1),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 7.2,
                color: Color(ForestEdgeTemplateSupport.inkHex),
              ),
            ),
            const SizedBox(width: 1.6),
            Expanded(
              child: bodyText(
                line,
                size: 1.46,
                maxLines: 2,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    Widget dotBullet(String line, {int maxLines = 2}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.8),
              child: Container(
                width: 3.2,
                height: 3.2,
                decoration: BoxDecoration(
                  color: _soft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 2.2),
            Expanded(
              child: bodyText(
                line,
                size: 1.42,
                maxLines: maxLines,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    Widget headerPanel() {
      return Expanded(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(7, 8, 14, 7),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(
                    name.toUpperCase(),
                    size: 4.4,
                    color: _ink,
                    weight: FontWeight.w900,
                    maxLines: 2,
                  ),
                  text(
                    title.toUpperCase(),
                    size: 1.85,
                    color: _soft,
                    maxLines: 2,
                  ),
                  Container(
                    width: 40,
                    height: 0.6,
                    color: _headerAccent,
                    margin: const EdgeInsets.only(top: 3),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -1,
              right: -5,
              child: Container(
                width: 28,
                height: 16,
                decoration: BoxDecoration(
                  color: _headerTint,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget contactCard() {
      return Container(
        width: 36,
        padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: previewContacts
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: text(
                    item.label,
                    size: 1.48,
                    color: _muted,
                    maxLines: 2,
                  ),
                ),
              )
              .toList(growable: false),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerPanel(),
                const SizedBox(width: 3),
                contactCard(),
              ],
            ),
            const SizedBox(height: 3),
            card(
              title: 'ABOUT ME',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    previewSummary.map(aboutBullet).toList(growable: false),
              ),
            ),
            const SizedBox(height: 3),
            card(
              title: 'EDUCATION',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: previewEducation
                    .map(
                      (entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            entry.institution,
                            size: 1.76,
                            color: _ink,
                            weight: FontWeight.w700,
                            maxLines: 1,
                          ),
                          bodyText(
                            '${entry.degreeLine}  •  ${entry.dateRange}',
                            size: 1.46,
                            maxLines: 2,
                            color: _muted,
                          ),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 3),
            card(
              title: 'WORK EXPERIENCE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: previewExperience
                    .expand(
                      (entry) => [
                        text(
                          entry.company,
                          size: 1.82,
                          color: _ink,
                          weight: FontWeight.w700,
                          maxLines: 1,
                        ),
                        bodyText(
                          '${entry.title}  ${entry.dateRange}',
                          size: 1.48,
                          maxLines: 1,
                          color: _muted,
                        ),
                        if (entry.location.isNotEmpty)
                          text(
                            entry.location,
                            size: 1.42,
                            color: _soft,
                            maxLines: 1,
                          ),
                        ...entry.detailLines.map(dotBullet),
                        if (previewExperience.last != entry)
                          const SizedBox(height: 1.4),
                      ],
                    )
                    .toList(growable: false),
              ),
            ),
            if (previewSkills.isNotEmpty || previewLanguages.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  if (previewSkills.isNotEmpty)
                    Expanded(
                      child: card(
                        title: 'SKILLS',
                        child: Wrap(
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
                                    color: _badge,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: text(
                                    skill,
                                    size: 1.56,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  if (previewSkills.isNotEmpty && previewLanguages.isNotEmpty)
                    const SizedBox(width: 3),
                  if (previewLanguages.isNotEmpty)
                    Expanded(
                      child: card(
                        title: 'LANGUAGES',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: previewLanguages
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: text(
                                    line,
                                    size: 1.48,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (previewProjects.isNotEmpty ||
                previewCertifications.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (previewProjects.isNotEmpty)
                    Expanded(
                      child: card(
                        title: 'PROJECTS',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: previewProjects
                              .expand(
                                (entry) => [
                                  text(
                                    entry.title,
                                    size: 1.62,
                                    color: _ink,
                                    weight: FontWeight.w700,
                                    maxLines: 1,
                                  ),
                                  ...entry.detailLines.map((line) => bodyText(
                                            line,
                                            size: 1.4,
                                            maxLines: 0,
                                            color: _muted,
                                          )),
                                  ...entry.links.map(
                                        (link) => text(
                                          link,
                                          size: 1.34,
                                          color: _ink,
                                          maxLines: 1,
                                        ),
                                      ),
                                  if (previewProjects.last != entry)
                                    const SizedBox(height: 1.2),
                                ],
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  if (previewProjects.isNotEmpty &&
                      previewCertifications.isNotEmpty)
                    const SizedBox(width: 3),
                  if (previewCertifications.isNotEmpty)
                    Expanded(
                      child: card(
                        title: 'CERTIFICATIONS',
                        child: Column(
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
                                        (line) => bodyText(
                                          line,
                                          size: 1.36,
                                          maxLines: 0,
                                          color: _muted,
                                        ),
                                      ),
                                  ...entry.links.map(
                                        (link) => text(
                                          link,
                                          size: 1.32,
                                          color: _ink,
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
                    ),
                ],
              ),
            ],
            if (previewCustomSections.isNotEmpty) ...[
              const SizedBox(height: 3),
              ...previewCustomSections,
            ],
          ],
        ),
      ),
    );
  }
}
