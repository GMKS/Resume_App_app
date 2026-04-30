import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../graphite_column_template_support.dart';

class GraphiteColumnResumeTemplatePreview extends StatelessWidget {
  const GraphiteColumnResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _page => const Color(GraphiteColumnTemplateSupport.pageHex);
  Color get _panel => const Color(GraphiteColumnTemplateSupport.panelHex);
  Color get _panelMuted =>
      const Color(GraphiteColumnTemplateSupport.panelMutedHex);
  Color get _ink => const Color(GraphiteColumnTemplateSupport.inkHex);
  Color get _muted => const Color(GraphiteColumnTemplateSupport.mutedHex);
  Color get _line => const Color(GraphiteColumnTemplateSupport.lineHex);
  Color get _photoTint =>
      const Color(GraphiteColumnTemplateSupport.photoTintHex);

  @override
  Widget build(BuildContext context) {
    final name =
        GraphiteColumnTemplateSupport.displayName(resume).toUpperCase();
    final title = GraphiteColumnTemplateSupport.displayTitle(resume);
    final contactItems = GraphiteColumnTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final skillNames = GraphiteColumnTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 5,
    );
    final summaryLines = GraphiteColumnTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 6,
    );
    final experienceEntries = GraphiteColumnTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      yearOnly: true,
    );
    final educationEntries = GraphiteColumnTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final projectEntries = GraphiteColumnTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 2,
      compactLinks: true,
    );
    final certificationEntries =
        GraphiteColumnTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final languageLines = GraphiteColumnTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            GraphiteContactItem(
              kind: GraphiteContactKind.phone,
              label: '+91 9885623465',
            ),
            GraphiteContactItem(
              kind: GraphiteContactKind.email,
              label: 'seenai007@gmail.com',
            ),
            GraphiteContactItem(
              kind: GraphiteContactKind.address,
              label: 'Hyderabad, India',
            ),
            GraphiteContactItem(
              kind: GraphiteContactKind.linkedin,
              label: 'linkedin.com/in/seenai',
            ),
            GraphiteContactItem(
              kind: GraphiteContactKind.github,
              label: 'github.com/gmk',
            ),
            GraphiteContactItem(
              kind: GraphiteContactKind.website,
              label: 'seenaigmk.com',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const [
            'React',
            'JavaScript',
            'Communication',
            'Project Management',
            'Problem Solving',
          ];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven delivery leader with strong experience in automation, reporting, and stakeholder communication.',
            'Builds measurable quality improvements while coordinating engineering and customer-facing teams.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            GraphiteExperienceEntry(
              title: 'Automation Lead',
              metaLine: 'Tata Consultancy Services Limited',
              dateRange: '2019 - 2025',
              detailLines: [
                'Led enterprise automation delivery and status reporting across client programs.',
                'Guided framework development and mentoring for engineering teams.',
              ],
            ),
            GraphiteExperienceEntry(
              title: 'Senior Software Engineer',
              metaLine: 'UST Global Pvt Limited',
              dateRange: '2017 - 2018',
              detailLines: [
                'Implemented automation enhancements for critical release cycles.',
              ],
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            GraphiteEducationEntry(
              degree: 'MCA',
              institutionLine: 'Holy Jesus and Mary PG College',
              dateRange: '2006 - 2009',
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            GraphiteProjectEntry(
              title: 'Finance Reporting Hub',
              detailLines: [
                'Built reporting flows and automation insights for enterprise delivery.',
              ],
              links: ['example.com/reporting-hub'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            GraphiteCertificationEntry(
              name: 'AWS Certified Developer',
              detailLines: ['Amazon', 'Issued Jan 2024  •  Expires Jan 2027'],
              links: ['example.com/cert/aws-123456'],
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'German  |  Basic'];

    Text text(
      String value, {
      double size = 3,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
    }) {
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: 1.18,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sidebarSection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                title,
                size: 3.0,
                color: Colors.white,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.6,
                color: _accent.withValues(alpha: 0.85),
                margin: const EdgeInsets.only(top: 1, bottom: 2),
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
                size: 3.45,
                color: _accent,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.7,
                color: _accent.withValues(alpha: 0.6),
                margin: const EdgeInsets.only(top: 1, bottom: 2),
              ),
            ],
          ),
        );

    Widget bodyFrame(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: _accent.withValues(alpha: 0.42),
                width: 0.8,
              ),
            ),
          ),
          child: child,
        );

    Widget detailBullet(String value, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 1.4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.2, right: 3),
                child: Container(
                  width: 2.8,
                  height: 2.8,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: text(
                  value,
                  size: 2.42,
                  color: color ?? _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(GraphiteExperienceEntry entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: text(
                      entry.title,
                      size: 3.05,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  text(
                    entry.dateRange,
                    size: 2.2,
                    color: _muted,
                    align: TextAlign.right,
                    maxLines: 2,
                  ),
                ],
              ),
              if (entry.metaLine.isNotEmpty)
                text(
                  entry.metaLine,
                  size: 2.45,
                  color: _accent,
                  weight: FontWeight.w600,
                  maxLines: 2,
                ),
              ...entry.detailLines.map(detailBullet),
            ],
          ),
        );

    Widget educationBlock(GraphiteEducationEntry entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: text(
                      entry.degree,
                      size: 2.95,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  text(
                    entry.dateRange,
                    size: 2.2,
                    color: _muted,
                    align: TextAlign.right,
                  ),
                ],
              ),
              text(
                entry.institutionLine,
                size: 2.45,
                color: _muted,
                maxLines: 2,
              ),
            ],
          ),
        );

    Widget projectBlock(GraphiteProjectEntry entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                entry.title,
                size: 2.95,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              ...entry.detailLines.map(detailBullet),
              ...entry.links.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(bottom: 0.8),
                  child: text(
                    link,
                    size: 2.35,
                    color: _accent,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget certificationBlock(GraphiteCertificationEntry entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                entry.name,
                size: 2.85,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              ...entry.detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 0.6, bottom: 0.4),
                  child: text(
                    line,
                    size: 2.35,
                    color: _muted,
                    align: TextAlign.justify,
                    maxLines: 2,
                  ),
                ),
              ),
              ...entry.links.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(top: 0.4),
                  child: text(
                    link,
                    size: 2.3,
                    color: _accent,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _page,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 42,
            color: _panel,
            padding: const EdgeInsets.fromLTRB(5, 6, 4, 5),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 18,
                      height: 24,
                      decoration: BoxDecoration(
                        color: photoBytes == null
                            ? _photoTint.withValues(alpha: 0.45)
                            : null,
                        border: Border.all(color: Colors.white54, width: 1),
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  sidebarSection('CONTACT'),
                  ...previewContacts.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 0.9),
                      child: text(
                        item.label,
                        size: 2.28,
                        color: _panelMuted,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  sidebarSection('SKILLS'),
                  ...previewSkills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: text(
                        skill,
                        size: 2.35,
                        color: _panelMuted,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 5),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text(
                      name,
                      size: 6.3,
                      color: _ink,
                      weight: FontWeight.w800,
                      maxLines: 2,
                    ),
                    text(
                      title,
                      size: 3.65,
                      color: _muted,
                      weight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    Container(
                      height: 0.7,
                      color: _line,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                    mainSection('PROFILE'),
                    bodyFrame(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: previewSummary.map(detailBullet).toList(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    mainSection('WORK EXPERIENCE'),
                    bodyFrame(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:
                            previewExperience.map(experienceBlock).toList(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    mainSection('EDUCATION'),
                    bodyFrame(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: previewEducation.map(educationBlock).toList(),
                      ),
                    ),
                    if (previewProjects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      mainSection('PROJECTS'),
                      bodyFrame(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: previewProjects.map(projectBlock).toList(),
                        ),
                      ),
                    ],
                    if (previewCertifications.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      mainSection('CERTIFICATIONS'),
                      bodyFrame(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: previewCertifications
                              .map(certificationBlock)
                              .toList(),
                        ),
                      ),
                    ],
                    if (previewLanguages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      mainSection('LANGUAGES'),
                      bodyFrame(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: previewLanguages
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.2),
                                  child: text(
                                    line,
                                    size: 2.42,
                                    color: _muted,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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
