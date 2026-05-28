import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../designer_profile_template_support.dart';

class DesignerProfileResumeTemplatePreview extends StatelessWidget {
  const DesignerProfileResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(DesignerProfileTemplateSupport.pageHex);
  Color get _sheet => const Color(DesignerProfileTemplateSupport.sheetHex);
  Color get _sidebarTop =>
      const Color(DesignerProfileTemplateSupport.sidebarTopHex);
  Color get _sidebarBottom =>
      const Color(DesignerProfileTemplateSupport.sidebarBottomHex);
  Color get _heading => const Color(DesignerProfileTemplateSupport.headingHex);
  Color get _ink => const Color(DesignerProfileTemplateSupport.inkHex);
  Color get _muted => const Color(DesignerProfileTemplateSupport.mutedHex);
  Color get _divider => const Color(DesignerProfileTemplateSupport.dividerHex);
  Color get _sidebarText =>
      const Color(DesignerProfileTemplateSupport.sidebarTextHex);
  Color get _profileTint =>
      const Color(DesignerProfileTemplateSupport.profileTintHex);

  @override
  Widget build(BuildContext context) {
    final previewResume =
        resume != null && resume!.templateId == 'designer_profile'
            ? resume!.copyWith(
                customSections: ensureProfessionalRoleSections(resume!),
              )
            : resume;

    final name =
        DesignerProfileTemplateSupport.displayName(previewResume).toUpperCase();
    final title = DesignerProfileTemplateSupport.displayTitle(previewResume);
    final contactItems = DesignerProfileTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = DesignerProfileTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = DesignerProfileTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      customSections: previewResume?.customSections ?? const <CustomSection>[],
      maxItems: 4,
    );
    final summaryLines = DesignerProfileTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final experienceEntries = DesignerProfileTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final referenceEntries = DesignerProfileTemplateSupport.referenceEntries(
      previewResume?.references ?? const <Reference>[],
      maxItems: 2,
    );
    final projectEntries = DesignerProfileTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      customSections: previewResume?.customSections ?? const <CustomSection>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries =
        DesignerProfileTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      customSections: previewResume?.customSections ?? const <CustomSection>[],
      maxItems: 2,
      compactLinks: true,
    );
    final languageLines = DesignerProfileTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);
    final initials = _initials(name);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            DesignerProfileContactItem(
              kind: DesignerProfileContactKind.phone,
              label: '(555) 123-4567',
            ),
            DesignerProfileContactItem(
              kind: DesignerProfileContactKind.email,
              label: 'hello@portfolio.dev',
            ),
            DesignerProfileContactItem(
              kind: DesignerProfileContactKind.address,
              label: 'New York, NY',
            ),
            DesignerProfileContactItem(
              kind: DesignerProfileContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            DesignerProfileContactItem(
              kind: DesignerProfileContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            DesignerProfileEducationEntry(
              degree: 'B.Des. Visual Design',
              institutionLine: 'Parsons School of Design',
              dateRange: '2016 - 2020',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Figma', 'Brand Systems', 'Illustration', 'Adobe CC'];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Creative design lead shaping brand systems, digital experiences, and polished campaign storytelling across web and product touchpoints.',
            'Translates strategy into polished launch-ready brand and interface experiences.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            DesignerProfileExperienceEntry(
              title: 'Senior Designer',
              companyLine: 'North Studio  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
              ],
            ),
          ];
    final previewReferences = referenceEntries.isNotEmpty
        ? referenceEntries
        : const [
            DesignerProfileReferenceEntry(
              name: 'Avery Brooks',
              roleLine: 'Creative Director  |  North Studio',
              contactLine: 'avery@northstudio.com',
            ),
            DesignerProfileReferenceEntry(
              name: 'Jordan Lee',
              roleLine: 'Brand Lead  |  Atelier House',
              contactLine: 'jordan@atelier.house',
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            DesignerProfileProjectEntry(
              title: 'Brand Campaign System',
              detailLines: [
                'Refined launch storytelling for web, social, and print assets.'
              ],
              technologyLine: 'Figma  |  Adobe CC',
              links: ['example.com/case-study'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            DesignerProfileCertificationEntry(
              name: 'Adobe Certified Professional',
              detailLines: ['Adobe', 'Issued Jan 2025'],
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Native', 'Spanish  |  Professional'];
    final previewCustomSections = orderedUserCustomSectionsFromList(
      previewResume?.customSections ?? const <CustomSection>[],
    )
        .where((section) => !isProfessionalRoleOptionalSectionKey(
            'designer_profile', section.id))
        .toList(growable: false);

    Text text(
      String value, {
      double size = 3,
      Color? color,
      FontWeight weight = FontWeight.normal,
      TextAlign align = TextAlign.left,
      int? maxLines,
      double height = 1.15,
    }) {
      final normalizedMaxLines =
          maxLines != null && maxLines <= 0 ? null : maxLines;
      return Text(
        value,
        textAlign: align,
        maxLines: normalizedMaxLines,
        overflow: normalizedMaxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
      );
    }

    Widget sidebarSection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 2.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                title,
                size: 2.9,
                color: Colors.white,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.6,
                color: Colors.white.withValues(alpha: 0.32),
                margin: const EdgeInsets.only(top: 1.2),
              ),
            ],
          ),
        );

    Widget mainSection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                title,
                size: 3.55,
                color: _heading,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.7,
                color: _divider,
                margin: const EdgeInsets.only(top: 1.2),
              ),
            ],
          ),
        );

    Widget bodyFrame(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.only(right: 1.5),
          child: child,
        );

    Widget justifiedLine(
      String value, {
      double size = 2.45,
      Color? color,
      int maxLines = 2,
      FontWeight weight = FontWeight.normal,
    }) {
      return text(
        value,
        size: size,
        color: color,
        weight: weight,
        align: TextAlign.justify,
        maxLines: maxLines,
        height: 1.22,
      );
    }

    Widget summaryPoint(String line) => bodyFrame(
          Padding(
            padding: const EdgeInsets.only(bottom: 1.2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0.3),
                  child: Icon(
                    Icons.star,
                    size: 3.2,
                    color: _sidebarTop,
                  ),
                ),
                const SizedBox(width: 2.1),
                Expanded(
                  child: justifiedLine(
                    line,
                    size: 2.34,
                    color: _muted,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget experienceBlock(DesignerProfileExperienceEntry entry) => bodyFrame(
          Padding(
            padding: const EdgeInsets.only(bottom: 2.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: text(
                        entry.title,
                        size: 2.95,
                        color: _ink,
                        weight: FontWeight.w700,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    text(
                      entry.dateRange,
                      size: 2.1,
                      color: _muted,
                      align: TextAlign.right,
                      maxLines: 1,
                    ),
                  ],
                ),
                if (entry.companyLine.isNotEmpty)
                  text(
                    entry.companyLine,
                    size: 2.3,
                    color: _heading,
                    weight: FontWeight.w600,
                    maxLines: 2,
                  ),
                ...entry.detailLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 0.8),
                    child: justifiedLine(
                      line,
                      size: 2.32,
                      color: _muted,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    Widget referenceBlock(DesignerProfileReferenceEntry entry) => bodyFrame(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.name,
                size: 2.45,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              if (entry.roleLine.isNotEmpty)
                text(
                  entry.roleLine,
                  size: 2.12,
                  color: _muted,
                  maxLines: 2,
                ),
              if (entry.contactLine.isNotEmpty)
                text(
                  entry.contactLine,
                  size: 2.0,
                  color: _heading,
                  maxLines: 2,
                ),
            ],
          ),
        );

    Widget projectBlock(DesignerProfileProjectEntry entry) => bodyFrame(
          Padding(
            padding: const EdgeInsets.only(bottom: 2.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.title,
                  size: 2.55,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
                if (entry.technologyLine.isNotEmpty)
                  text(
                    entry.technologyLine,
                    size: 2.08,
                    color: _heading,
                    maxLines: 1,
                  ),
                if (entry.detailLines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 0.8),
                    child: justifiedLine(
                      entry.detailLines.first,
                      size: 2.18,
                      color: _muted,
                      maxLines: 2,
                    ),
                  ),
                if (entry.links.isNotEmpty)
                  text(
                    entry.links.first,
                    size: 2.04,
                    color: _heading,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        );

    Widget certificationBlock(DesignerProfileCertificationEntry entry) =>
        bodyFrame(
          Padding(
            padding: const EdgeInsets.only(bottom: 1.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.name,
                  size: 2.36,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
                if (entry.detailLines.isNotEmpty)
                  text(
                    entry.detailLines.take(2).join('  |  '),
                    size: 2.02,
                    color: _muted,
                    maxLines: 2,
                  ),
                if (entry.links.isNotEmpty)
                  text(
                    entry.links.first,
                    size: 1.98,
                    color: _heading,
                    maxLines: 1,
                  ),
              ],
            ),
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

            return bodyFrame(
              Padding(
                padding: const EdgeInsets.only(bottom: 2.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayItem.heading.isNotEmpty)
                      text(
                        displayItem.heading,
                        size: 2.55,
                        color: _ink,
                        weight: FontWeight.w700,
                        maxLines: 0,
                      ),
                    if (metaParts.isNotEmpty)
                      text(
                        metaParts.join('  |  '),
                        size: 2.08,
                        color: _heading,
                        maxLines: 0,
                      ),
                    ...displayItem.detailLines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(top: 0.8),
                        child: justifiedLine(
                          line,
                          size: 2.18,
                          color: _muted,
                          maxLines: 0,
                        ),
                      ),
                    ),
                  ],
                ),
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
          mainSection(title),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: _page,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: _sheet,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 43,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_sidebarTop, _sidebarBottom],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _profileTint,
                        border: Border.all(color: Colors.white70, width: 1),
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
                                initials,
                                size: 5.2,
                                color: _heading,
                                weight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4.8),
                  sidebarSection('Education'),
                  ...previewEducation.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            entry.degree,
                            size: 2.08,
                            color: Colors.white,
                            weight: FontWeight.w600,
                            maxLines: 2,
                          ),
                          text(
                            entry.institutionLine,
                            size: 1.86,
                            color: _sidebarText,
                            maxLines: 2,
                          ),
                          text(
                            entry.dateRange,
                            size: 1.84,
                            color: _sidebarText,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  sidebarSection('Skills'),
                  ...previewSkills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 1.8, right: 2.2),
                            width: 2.6,
                            height: 2.6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: text(
                              skill,
                              size: 1.94,
                              color: _sidebarText,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 6, 6, 5),
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
                                  size: 6.45,
                                  color: _heading,
                                  weight: FontWeight.w900,
                                  maxLines: 2,
                                ),
                                text(
                                  title,
                                  size: 3.3,
                                  color: _muted,
                                  weight: FontWeight.w600,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 58),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: previewContacts
                                  .map(
                                    (item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 0.3),
                                      child: text(
                                        item.label,
                                        size:
                                            item.kind.index <= 2 ? 2.22 : 2.02,
                                        color: _muted,
                                        align: TextAlign.right,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 0.7,
                        color: _divider,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                      ),
                      mainSection('About me'),
                      ...previewSummaryLines.map(summaryPoint),
                      const SizedBox(height: 3),
                      mainSection('Experience'),
                      ...previewExperience.map(experienceBlock),
                      const SizedBox(height: 1),
                      mainSection('References'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: previewReferences
                            .take(2)
                            .toList(growable: false)
                            .asMap()
                            .entries
                            .map(
                              (entry) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: entry.key == 0 ? 4 : 0,
                                    left: entry.key == 0 ? 0 : 4,
                                  ),
                                  child: referenceBlock(entry.value),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      if (previewProjects.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        mainSection('Projects'),
                        ...previewProjects.take(2).map(projectBlock),
                      ],
                      if (previewCertifications.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        mainSection('Certifications'),
                        ...previewCertifications
                            .take(2)
                            .map(certificationBlock),
                      ],
                      if (previewLanguages.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        mainSection('Languages'),
                        ...previewLanguages.take(3).map(
                              (line) => bodyFrame(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1.2),
                                  child: text(
                                    line,
                                    size: 2.1,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                      ],
                      for (final section in previewCustomSections)
                        if (customSectionBlock(section) case final block?) ...[
                          const SizedBox(height: 2),
                          block,
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Uint8List? _photoBytes(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'DP';
    }
    return parts.map((part) => part[0]).join();
  }
}
