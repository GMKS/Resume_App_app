import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../corporate_template_support.dart';

class CorporateResumeTemplatePreview extends StatelessWidget {
  const CorporateResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _sidebarBg => const Color(CorporateTemplateSupport.sidebarBgHex);
  Color get _sidebarMuted =>
      const Color(CorporateTemplateSupport.sidebarMutedHex);
  Color get _bodyInk => const Color(CorporateTemplateSupport.bodyInkHex);
  Color get _bodyMuted => const Color(CorporateTemplateSupport.bodyMutedHex);
  Color get _line => const Color(CorporateTemplateSupport.lineHex);

  @override
  Widget build(BuildContext context) {
    final name = CorporateTemplateSupport.displayName(resume);
    final title = CorporateTemplateSupport.displayTitle(resume);
    final address = resume?.personalInfo.address.trim() ?? '';
    final contactItems = CorporateTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = CorporateTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = CorporateTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    final languageLines = CorporateTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 4,
    );
    final summaryLines = CorporateTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 4,
    );
    final experienceEntries = CorporateTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      yearOnly: true,
    );
    final projectEntries = CorporateTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 2,
      compactLinks: true,
    );
    final certificationEntries = CorporateTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            CorporateContactItem(
              kind: CorporateContactKind.email,
              label: 'john@email.com',
            ),
            CorporateContactItem(
              kind: CorporateContactKind.phone,
              label: '(555) 123-4567',
            ),
            CorporateContactItem(
              kind: CorporateContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            CorporateContactItem(
              kind: CorporateContactKind.github,
              label: 'github.com/johnsmith',
            ),
            CorporateContactItem(
              kind: CorporateContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            CorporateEducationEntry(
              degree: 'MCA Computer Applications',
              institutionLine: 'Holy Jesus and Mary PG College',
              dateRange: '2006 - 2009',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const [
            'React',
            'JavaScript',
            'Communication',
            'Project Management',
            'SQL',
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const [
            'English  |  Professional',
            'German  |  Basic',
          ];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven delivery leader with strong experience in automation, reporting, and cross-team execution.',
            'Builds measurable quality improvements while aligning engineering and stakeholder communication.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            CorporateExperienceEntry(
              title: 'Automation Lead',
              metaLine: 'TCS  |  Hyderabad, India',
              dateRange: '2019 - 2025',
              detailLines: [
                'Led automation delivery and client-facing execution reporting across enterprise programs.',
                'Guided framework work and mentoring for engineering teams.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            CorporateProjectEntry(
              title: 'Cigna Health Care',
              detailLines: [
                'Built healthcare analytics and automation insights for customer operations.',
              ],
              links: ['example.com/cigna-health-care'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            CorporateCertificationEntry(
              name: 'AWS Certified Developer',
              detailLines: ['Amazon', 'Issued Jan 2024  •  Expires Jan 2027'],
              links: ['example.com/cert/aws-123456'],
            ),
          ];

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
          color: color ?? _bodyInk,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: 1.2,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sideSection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                title,
                size: 3.2,
                color: _accent,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.5,
                color: _accent.withValues(alpha: 0.45),
                margin: const EdgeInsets.only(top: 1, bottom: 2),
              ),
            ],
          ),
        );

    Widget bodySection(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                title,
                size: 3.8,
                color: _bodyInk,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.5,
                color: _line,
                margin: const EdgeInsets.only(top: 1, bottom: 2),
              ),
            ],
          ),
        );

    Widget detailBullet(String line, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.4, right: 3),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: text(
                  line,
                  size: 2.45,
                  color: color ?? _bodyMuted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(CorporateExperienceEntry entry) {
      final dates = entry.dateRange.split(' - ');
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(dates.first, size: 2.45, color: _bodyMuted),
                  text(
                    dates.length > 1 ? dates.last : dates.first,
                    size: 2.45,
                    color: _bodyMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 0.8,
              height: 15 + (entry.detailLines.length * 7),
              color: _accent.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text(
                    entry.title,
                    size: 3.15,
                    color: _bodyInk,
                    weight: FontWeight.bold,
                  ),
                  if (entry.metaLine.isNotEmpty)
                    text(
                      entry.metaLine,
                      size: 2.55,
                      color: _accent,
                      weight: FontWeight.w600,
                      maxLines: 2,
                    ),
                  ...entry.detailLines.map(detailBullet),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget projectBlock(CorporateProjectEntry entry) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text(
              entry.title,
              size: 3.0,
              color: _bodyInk,
              weight: FontWeight.bold,
            ),
            ...entry.detailLines.map(detailBullet),
            ...entry.links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: text(
                  link,
                  size: 2.35,
                  color: _accent,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget certificationBlock(CorporateCertificationEntry entry) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text(
              entry.name,
              size: 2.95,
              color: _bodyInk,
              weight: FontWeight.bold,
            ),
            ...entry.detailLines.map(
              (line) => text(
                line,
                size: 2.35,
                color: _bodyMuted,
                align: TextAlign.justify,
              ),
            ),
            ...entry.links.map(
              (link) => text(
                link,
                size: 2.3,
                color: _accent,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 52,
            color: _sidebarBg,
            padding: const EdgeInsets.fromLTRB(6, 10, 5, 6),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: photoBytes == null
                            ? _accent.withValues(alpha: 0.3)
                            : Colors.transparent,
                        border: Border.all(color: _accent, width: 1.5),
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
                              size: 16,
                              color: Colors.white54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  sideSection('CONTACTS'),
                  ...previewContacts.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 1.5),
                      child: text(
                        item.label,
                        size: 2.25,
                        color: _sidebarMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  sideSection('EDUCATION'),
                  ...previewEducation.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            entry.degree,
                            size: 2.45,
                            color: Colors.white70,
                            weight: FontWeight.w700,
                            maxLines: 2,
                          ),
                          text(
                            entry.institutionLine,
                            size: 2.2,
                            color: _sidebarMuted,
                            maxLines: 2,
                          ),
                          text(
                            entry.dateRange,
                            size: 2.1,
                            color: _sidebarMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  sideSection('SKILLS'),
                  ...previewSkills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 1.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 1, right: 3),
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 2.2,
                                height: 2.2,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: text(
                              skill,
                              size: 2.25,
                              color: _sidebarMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (previewLanguages.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    sideSection('LANGUAGES'),
                    ...previewLanguages.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 1.5),
                        child: text(
                          line,
                          size: 2.15,
                          color: _sidebarMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 9, 7, 5),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text(
                      name.toUpperCase(),
                      size: 7.2,
                      color: _bodyInk,
                      weight: FontWeight.w900,
                    ),
                    text(
                      title.toUpperCase(),
                      size: 3.25,
                      color: _accent,
                      weight: FontWeight.bold,
                    ),
                    if (address.isNotEmpty)
                      text(
                        address,
                        size: 2.35,
                        color: _bodyMuted,
                        maxLines: 1,
                      ),
                    Container(
                      height: 1.4,
                      color: _accent,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                    bodySection('PROFILE'),
                    ...previewSummary.map(detailBullet),
                    if (previewExperience.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      bodySection('WORK EXPERIENCE'),
                      ...previewExperience.map(experienceBlock),
                    ],
                    if (previewProjects.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      bodySection('PROJECTS'),
                      ...previewProjects.map(projectBlock),
                    ],
                    if (previewCertifications.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      bodySection('CERTIFICATIONS'),
                      ...previewCertifications.map(certificationBlock),
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

  Uint8List? _photoBytes(String? base64Image) {
    final value = base64Image?.trim() ?? '';
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