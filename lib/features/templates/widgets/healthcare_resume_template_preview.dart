import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../healthcare_resume_template_support.dart';

class HealthcareResumeTemplatePreview extends StatelessWidget {
  const HealthcareResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(HealthcareResumeTemplateSupport.pageHex);
  Color get _paper => const Color(HealthcareResumeTemplateSupport.paperHex);
  Color get _sidebar => const Color(HealthcareResumeTemplateSupport.sidebarHex);
  Color get _heading => const Color(HealthcareResumeTemplateSupport.headingHex);
  Color get _accent => const Color(HealthcareResumeTemplateSupport.accentHex);
  Color get _ink => const Color(HealthcareResumeTemplateSupport.inkHex);
  Color get _muted => const Color(HealthcareResumeTemplateSupport.mutedHex);
  Color get _sidebarText =>
      const Color(HealthcareResumeTemplateSupport.sidebarTextHex);
  Color get _line => const Color(HealthcareResumeTemplateSupport.lineHex);
  Color get _avatarFill =>
      const Color(HealthcareResumeTemplateSupport.avatarFillHex);

  @override
  Widget build(BuildContext context) {
    final normalizedResume =
        HealthcareResumeTemplateSupport.normalizeResume(resume);
    final name = HealthcareResumeTemplateSupport.displayName(normalizedResume);
    final title = HealthcareResumeTemplateSupport.displayTitle(normalizedResume)
        .toUpperCase();
    final address =
        HealthcareResumeTemplateSupport.address(normalizedResume?.personalInfo);
    final contactItems = HealthcareResumeTemplateSupport.contactItems(
      normalizedResume?.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final summaryLines = HealthcareResumeTemplateSupport.summaryLines(
      normalizedResume?.objective,
      maxItems: null,
    );
    final skillNames = HealthcareResumeTemplateSupport.skillNames(
      normalizedResume?.skills ?? const <Skill>[],
      customSections:
          normalizedResume?.customSections ?? const <CustomSection>[],
      maxItems: null,
    );
    final certificationEntries =
        HealthcareResumeTemplateSupport.certificationEntries(
      normalizedResume?.certifications ?? const <Certification>[],
      customSections:
          normalizedResume?.customSections ?? const <CustomSection>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = HealthcareResumeTemplateSupport.languageLines(
      normalizedResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final projectEntries = HealthcareResumeTemplateSupport.projectEntries(
      normalizedResume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final experienceEntries = HealthcareResumeTemplateSupport.experienceEntries(
      normalizedResume?.experience ?? const <Experience>[],
      maxItems: null,
      maxDetailLines: null,
      yearOnly: true,
    );
    final educationEntries = HealthcareResumeTemplateSupport.educationEntries(
      normalizedResume?.education ?? const <Education>[],
      maxItems: null,
      yearOnly: true,
    );
    final bodyCustomSections =
        HealthcareResumeTemplateSupport.bodyCustomSections(
      normalizedResume?.customSections ?? const <CustomSection>[],
      maxSections: null,
      maxItemsPerSection: null,
    );
    final sidebarCustomSections = (normalizedResume?.customSections ??
        const <CustomSection>[])
      .where(HealthcareResumeTemplateSupport.isSidebarCustomSection)
      .where(
        (section) =>
          HealthcareResumeTemplateSupport.customSectionLines(section)
            .isNotEmpty,
      )
      .toList(growable: false);
    final sidebarCustomSectionIds = sidebarCustomSections
      .map((section) => section.id)
      .toSet();
    final mainBodyCustomSections = bodyCustomSections
      .where((section) => !sidebarCustomSectionIds.contains(section.id))
      .toList(growable: false);
    final references = normalizedResume?.references ?? const <Reference>[];
    final photoBytes = _photoBytes(normalizedResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            HealthcareResumeContactItem(
              kind: HealthcareResumeContactKind.phone,
              label: '(555) 123-4567',
            ),
            HealthcareResumeContactItem(
              kind: HealthcareResumeContactKind.email,
              label: 'john.smith@email.com',
            ),
            HealthcareResumeContactItem(
              kind: HealthcareResumeContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            HealthcareResumeContactItem(
              kind: HealthcareResumeContactKind.github,
              label: 'github.com/johnsmith',
            ),
            HealthcareResumeContactItem(
              kind: HealthcareResumeContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewAddress = address.isNotEmpty ? address : 'New York, NY';
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Experienced healthcare technologist focused on delivery, quality, and patient-impact workflows.',
            'Builds reliable systems with strong communication and cross-functional execution.',
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const [
            'Acute Care',
            'EMR Integration',
            'Quality Assurance',
            'Clinical Documentation',
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            HealthcareResumeCertificationEntry(
              name: 'BLS Certification',
              detailLines: ['American Heart Association  |  Jan 2025'],
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'Spanish  |  Conversational'];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            HealthcareResumeProjectEntry(
              title: 'Patient Intake Automation',
              detailLines: [
                'Improved healthcare intake and triage workflows across regional clinics.',
              ],
              links: ['example.com/intake-automation'],
            ),
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            HealthcareResumeExperienceEntry(
              title: 'Clinical Systems Lead',
              companyLine: 'Metro Health  |  New York',
              dateRange: '2022 - Present',
              detailLines: [
                'Led implementation work for patient operations, reporting, and training.',
              ],
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            HealthcareResumeEducationEntry(
              degreeLine: 'B.Sc. Nursing',
              institutionLine: 'State University',
              dateRange: '2016 - 2020',
            ),
          ];

    Text text(
      String value, {
      double size = 2.0,
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
          height: 1.16,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sidebarHeader(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.4),
          child: Row(
            children: [
              Expanded(
                child: text(
                  value,
                  size: 2.45,
                  color: _heading,
                  weight: FontWeight.w800,
                ),
              ),
              Container(width: 1.2, height: 5.2, color: _accent),
            ],
          ),
        );

    Widget sidebarBulletLine(
      String line, {
      double size = 1.56,
      Color? color,
      int? maxLines,
    }) => Padding(
          padding: const EdgeInsets.only(bottom: 0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.55),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 1.6),
              Expanded(
                child: text(
                  line,
                  size: size,
                  color: color ?? _sidebarText,
                  maxLines: maxLines,
                ),
              ),
            ],
          ),
        );

    Widget sectionHeader(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.5),
          child: Row(
            children: [
              text(
                value,
                size: 2.8,
                color: _heading,
                weight: FontWeight.w800,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(height: 0.6, color: _line),
              ),
            ],
          ),
        );

    Widget chevronLine(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.9, right: 0.4),
                child: SizedBox(
                  width: 6,
                  height: 8,
                  child: CustomPaint(
                    painter: _PreviewChevronPainter(color: _accent),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: text(
                  line,
                  size: 1.7,
                  color: _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget detailBullet(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 1.6),
              Expanded(
                child: text(
                  line,
                  size: 1.64,
                  color: _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget certificationBlock(HealthcareResumeCertificationEntry entry) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.name,
                size: 1.66,
                color: _sidebarText,
                weight: FontWeight.w700,
              ),
              ...entry.detailLines.map(
                (line) => text(
                  line,
                  size: 1.55,
                  color: _muted,
                ),
              ),
            ],
          ),
        );

    Widget projectBlock(HealthcareResumeProjectEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.title,
                size: 1.92,
                color: _ink,
                weight: FontWeight.w700,
              ),
              if (entry.technologyLine.isNotEmpty)
                text(
                  entry.technologyLine,
                  size: 1.5,
                  color: _accent,
                ),
              ...entry.detailLines.map(detailBullet),
              ...entry.links.map(
                (link) => text(
                  link,
                  size: 1.56,
                  color: _accent,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(HealthcareResumeExperienceEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: text(
                      entry.title,
                      size: 1.96,
                      color: _ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  text(
                    entry.dateRange,
                    size: 1.5,
                    color: _muted,
                    align: TextAlign.right,
                  ),
                ],
              ),
              text(
                entry.companyLine,
                size: 1.62,
                color: _accent,
                weight: FontWeight.w700,
              ),
              ...entry.detailLines.map(detailBullet),
            ],
          ),
        );

    Widget educationBlock(HealthcareResumeEducationEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.degreeLine,
                size: 1.82,
                color: _ink,
                weight: FontWeight.w700,
              ),
              text(
                entry.institutionLine,
                size: 1.58,
                color: _muted,
              ),
              text(
                entry.dateRange,
                size: 1.48,
                color: _muted,
              ),
            ],
          ),
        );

    Widget customSectionBlock(HealthcareResumeBodySection section) => Padding(
          padding: const EdgeInsets.only(bottom: 1.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                section.title.toUpperCase(),
                size: 1.92,
                color: _ink,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 0.8),
              ...section.lines.map(detailBullet),
            ],
          ),
        );

    Widget referenceBlock(Reference reference) {
      final roleLine = [
        reference.position.trim(),
        reference.company.trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');
      final contactLine = [
        reference.email.trim(),
        reference.phone.trim(),
      ].where((part) => part.isNotEmpty).join('  |  ');
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(
              reference.name,
              size: 1.82,
              color: _ink,
              weight: FontWeight.w700,
            ),
            if (roleLine.isNotEmpty) text(roleLine, size: 1.56, color: _muted),
            if (contactLine.isNotEmpty)
              text(contactLine, size: 1.48, color: _muted),
          ],
        ),
      );
    }

    return Container(
      color: _page,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 46,
              color: _sidebar,
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: photoBytes == null ? _avatarFill : null,
                          border: Border.all(color: _accent, width: 1),
                          image: photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(photoBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoBytes == null
                            ? Icon(Icons.person, size: 13, color: _accent)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    sidebarHeader('CONTACT'),
                    ...previewContacts.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.8),
                        child: text(
                          item.label,
                          size: 1.56,
                          color: _sidebarText,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.4),
                    sidebarHeader('SKILLS'),
                    ...previewSkills.map(
                      (skill) => sidebarBulletLine(
                        skill,
                        size: 1.5,
                        color: _sidebarText,
                        maxLines: 2,
                      ),
                    ),
                    if (previewCertifications.isNotEmpty) ...[
                      const SizedBox(height: 2.4),
                      sidebarHeader('CERTIFICATIONS'),
                      ...previewCertifications.map(certificationBlock),
                    ],
                    if (sidebarCustomSections.isNotEmpty) ...[
                      ...sidebarCustomSections.expand((section) {
                        final lines = HealthcareResumeTemplateSupport
                            .customSectionLines(section, maxItems: 3);
                        if (lines.isEmpty) {
                          return const <Widget>[];
                        }
                        return [
                          const SizedBox(height: 2.4),
                          sidebarHeader(section.title.toUpperCase()),
                          ...lines.map(
                            (line) => sidebarBulletLine(
                              line,
                              size: 1.48,
                              color: _sidebarText,
                              maxLines: 2,
                            ),
                          ),
                        ];
                      }),
                    ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text(
                        name,
                        size: 5.5,
                        color: _ink,
                        weight: FontWeight.w700,
                      ),
                      text(
                        title,
                        size: 2.1,
                        color: _accent,
                        weight: FontWeight.w700,
                      ),
                      if (previewAddress.isNotEmpty)
                        text(
                          previewAddress,
                          size: 1.7,
                          color: _muted,
                          maxLines: 1,
                        ),
                      Container(
                        height: 0.7,
                        color: _line,
                        margin: const EdgeInsets.only(top: 2.5, bottom: 2.5),
                      ),
                      sectionHeader('ABOUT ME'),
                      ...previewSummaryLines.map(chevronLine),
                      if (previewExperience.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        sectionHeader('EXPERIENCE'),
                        ...previewExperience.map(experienceBlock),
                      ],
                      if (previewEducation.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        sectionHeader('EDUCATION'),
                        ...previewEducation.map(educationBlock),
                      ],
                      if (previewProjects.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        sectionHeader('PROJECTS'),
                        ...previewProjects.map(projectBlock),
                      ],
                      if (previewLanguages.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        sectionHeader('LANGUAGES'),
                        ...previewLanguages.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 0.8),
                            child: text(
                              line,
                              size: 1.62,
                              color: _muted,
                            ),
                          ),
                        ),
                      ],
                      if (mainBodyCustomSections.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        ...mainBodyCustomSections.map(customSectionBlock),
                      ],
                      if (references.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        sectionHeader('REFERENCES'),
                        ...references.take(2).map(referenceBlock),
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
}

class _PreviewChevronPainter extends CustomPainter {
  const _PreviewChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(size.width - 1, size.height / 2)
      ..lineTo(1, size.height - 1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PreviewChevronPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
