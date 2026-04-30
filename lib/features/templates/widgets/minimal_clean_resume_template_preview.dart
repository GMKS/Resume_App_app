import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../minimal_clean_template_support.dart';

class MinimalCleanResumeTemplatePreview extends StatelessWidget {
  const MinimalCleanResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _background =>
      const Color(MinimalCleanTemplateSupport.backgroundHex);
  Color get _card => const Color(MinimalCleanTemplateSupport.cardHex);
  Color get _blue => const Color(MinimalCleanTemplateSupport.blueHex);
  Color get _blueDark => const Color(MinimalCleanTemplateSupport.blueDarkHex);
  Color get _ink => const Color(MinimalCleanTemplateSupport.inkHex);
  Color get _muted => const Color(MinimalCleanTemplateSupport.mutedHex);
  Color get _sand => const Color(MinimalCleanTemplateSupport.sandHex);
  Color get _divider => const Color(MinimalCleanTemplateSupport.dividerHex);

  @override
  Widget build(BuildContext context) {
    final name = MinimalCleanTemplateSupport.displayName(resume);
    final title = MinimalCleanTemplateSupport.displayTitle(resume);
    final address = resume?.personalInfo.address.trim() ?? '';
    final contactItems = MinimalCleanTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final summaryLines = MinimalCleanTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 3,
    );
    final experienceEntries = MinimalCleanTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final projectEntries = MinimalCleanTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final skillNames = MinimalCleanTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final educationEntries = MinimalCleanTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 2,
      yearOnly: true,
    );
    final certificationEntries =
        MinimalCleanTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final languageLines = MinimalCleanTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            MinimalCleanContactItem(
              kind: MinimalCleanContactKind.phone,
              label: '(555) 123-4567',
            ),
            MinimalCleanContactItem(
              kind: MinimalCleanContactKind.email,
              label: 'john.smith@email.com',
            ),
            MinimalCleanContactItem(
              kind: MinimalCleanContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            MinimalCleanContactItem(
              kind: MinimalCleanContactKind.github,
              label: 'github.com/johnsmith',
            ),
            MinimalCleanContactItem(
              kind: MinimalCleanContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Builds polished digital products with structured delivery and calm execution.',
            'Turns dense requirements into clear launch plans and reliable output.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            MinimalCleanExperienceEntry(
              title: 'Senior Product Designer',
              companyLine: 'Studio North  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Led product-system updates and shipped cleaner onboarding flows.',
              ],
            ),
            MinimalCleanExperienceEntry(
              title: 'Product Designer',
              companyLine: 'Foundry Labs  |  NYC',
              dateRange: '2019 - 2022',
              detailLines: [
                'Improved launch readiness across research, design, and engineering handoff.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            MinimalCleanProjectEntry(
              title: 'Platform Refresh',
              detailLines: [
                'Delivered a cleaner account setup and onboarding journey.',
              ],
              links: ['platform.example.com'],
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase', 'Figma'];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            MinimalCleanEducationEntry(
              degreeLine: 'B.Des. Product Design',
              institutionLine: 'State University',
              dateRange: '2016 - 2020',
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            MinimalCleanCertificationEntry(
              name: 'Google UX Design Certificate',
              metaLine: 'Google  |  Jan 2025',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'French  |  Conversational'];

    Text text(
      String value, {
      double size = 2.4,
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

    Widget sectionHeader(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              text(
                value,
                size: 3.0,
                color: _blueDark,
                weight: FontWeight.w800,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 0.7,
                  color: _divider,
                ),
              ),
            ],
          ),
        );

    Widget arrowBulletLine(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.6),
                child: Icon(
                  Icons.arrow_right_alt_rounded,
                  size: 8,
                  color: _blueDark,
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: text(
                  line,
                  size: 2.05,
                  color: _muted,
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    Widget detailLine(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.2),
                child: Container(
                  width: 2.2,
                  height: 2.2,
                  decoration: BoxDecoration(
                    color: _blueDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: text(
                  line,
                  size: 1.98,
                  color: _muted,
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _background,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: photoBytes == null ? _sand : null,
                      border: Border.all(color: Colors.white, width: 1.2),
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
                              size: 4.4,
                              color: _blueDark,
                              weight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text(
                          name.toUpperCase(),
                          size: 5.9,
                          color: _ink,
                          weight: FontWeight.w900,
                          maxLines: 1,
                        ),
                        text(
                          title,
                          size: 2.55,
                          color: _muted,
                          weight: FontWeight.w600,
                          maxLines: 1,
                        ),
                        if (address.isNotEmpty)
                          text(
                            address,
                            size: 1.95,
                            color: _muted,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB7CBE4), Color(0xFF8FB0D6)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 1.4,
                  children: previewContacts
                      .map(
                        (item) => text(
                          item.label,
                          size: 1.7,
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      padding: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: _divider, width: 0.8),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(
                              'Education',
                              size: 2.85,
                              color: _blueDark,
                              weight: FontWeight.w800,
                            ),
                            const SizedBox(height: 1.2),
                            for (final entry in previewEducation)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    text(
                                      entry.degreeLine,
                                      size: 2.02,
                                      color: _ink,
                                      weight: FontWeight.w700,
                                      maxLines: 2,
                                    ),
                                    text(
                                      entry.institutionLine,
                                      size: 1.85,
                                      color: _muted,
                                      maxLines: 2,
                                    ),
                                    text(
                                      entry.dateRange,
                                      size: 1.8,
                                      color: _muted,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            if (previewCertifications.isNotEmpty) ...[
                              text(
                                'Certifications',
                                size: 2.85,
                                color: _blueDark,
                                weight: FontWeight.w800,
                              ),
                              const SizedBox(height: 1.2),
                              for (final entry in previewCertifications)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1.6),
                                  child: text(
                                    entry.name,
                                    size: 1.9,
                                    color: _muted,
                                    maxLines: 2,
                                  ),
                                ),
                            ],
                            if (previewSkills.isNotEmpty) ...[
                              const SizedBox(height: 1.2),
                              text(
                                'Skills',
                                size: 2.85,
                                color: _blueDark,
                                weight: FontWeight.w800,
                              ),
                              const SizedBox(height: 1.2),
                              for (final skill in previewSkills)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: text(
                                    skill,
                                    size: 1.92,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionHeader('About Me'),
                            for (final line in previewSummaryLines)
                              arrowBulletLine(line),
                            if (previewExperience.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              sectionHeader('Experience'),
                              for (final entry in previewExperience)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: text(
                                              entry.title,
                                              size: 2.55,
                                              color: _ink,
                                              weight: FontWeight.w800,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          text(
                                            entry.dateRange,
                                            size: 1.84,
                                            color: _muted,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                      text(
                                        entry.companyLine,
                                        size: 2.0,
                                        color: _blueDark,
                                        weight: FontWeight.w700,
                                        maxLines: 1,
                                      ),
                                      for (final line in entry.detailLines)
                                        detailLine(line),
                                    ],
                                  ),
                                ),
                            ],
                            if (previewProjects.isNotEmpty) ...[
                              sectionHeader('Projects'),
                              for (final entry in previewProjects)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.2),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      text(
                                        entry.title,
                                        size: 2.35,
                                        color: _ink,
                                        weight: FontWeight.w800,
                                        maxLines: 1,
                                      ),
                                      if (entry.technologyLine.isNotEmpty)
                                        text(
                                          entry.technologyLine,
                                          size: 1.86,
                                          color: _blueDark,
                                          maxLines: 1,
                                        ),
                                      for (final line in entry.detailLines)
                                        detailLine(line),
                                      for (final link in entry.links)
                                        text(
                                          link,
                                          size: 1.9,
                                          color: _blueDark,
                                          weight: FontWeight.w700,
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                ),
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
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _sand.withValues(alpha: 0.85),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: text(
                                          line,
                                          size: 1.85,
                                          color: _blueDark,
                                          weight: FontWeight.w700,
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
                  ],
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
    return parts.isEmpty ? 'MC' : parts.join();
  }
}
