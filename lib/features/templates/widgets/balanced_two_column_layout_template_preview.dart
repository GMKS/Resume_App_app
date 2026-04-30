import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../balanced_two_column_template_support.dart';

class BalancedTwoColumnLayoutTemplatePreview extends StatelessWidget {
  const BalancedTwoColumnLayoutTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(BalancedTwoColumnTemplateSupport.pageHex);
  Color get _paper => const Color(BalancedTwoColumnTemplateSupport.paperHex);
  Color get _sidebar =>
      const Color(BalancedTwoColumnTemplateSupport.sidebarHex);
  Color get _line => const Color(BalancedTwoColumnTemplateSupport.lineHex);
  Color get _gold => const Color(BalancedTwoColumnTemplateSupport.goldHex);
  Color get _goldDark =>
      const Color(BalancedTwoColumnTemplateSupport.goldDarkHex);
  Color get _ink => const Color(BalancedTwoColumnTemplateSupport.inkHex);
  Color get _muted => const Color(BalancedTwoColumnTemplateSupport.mutedHex);
  Color get _avatarFill =>
      const Color(BalancedTwoColumnTemplateSupport.avatarFillHex);

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

  String _compactSummary(Iterable<String> values) {
    final cleaned = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return cleaned.join('  |  ');
  }

  double _summaryFontSize(String value) {
    if (value.length > 140) {
      return 1.2;
    }
    if (value.length > 90) {
      return 1.32;
    }
    if (value.length > 50) {
      return 1.42;
    }
    return 1.5;
  }

  double _profilePointFontSize(List<String> values) {
    final totalChars = values.fold<int>(0, (sum, value) => sum + value.length);
    if (values.length >= 8 || totalChars > 420) {
      return 1.18;
    }
    if (values.length >= 6 || totalChars > 320) {
      return 1.26;
    }
    if (values.length >= 4 || totalChars > 220) {
      return 1.36;
    }
    return 1.48;
  }

  double _experienceDetailFontSize(
    List<BalancedTwoColumnExperienceEntry> values,
  ) {
    final totalChars = values.fold<int>(
      0,
      (sum, entry) =>
          sum +
          entry.detailLines.fold<int>(0, (inner, line) => inner + line.length),
    );
    if (values.length >= 4 || totalChars > 620) {
      return 1.16;
    }
    if (values.length >= 3 || totalChars > 460) {
      return 1.24;
    }
    if (totalChars > 280) {
      return 1.34;
    }
    return 1.42;
  }

  Widget _text(
    String text, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.normal,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
    double height = 1.14,
  }) {
    return Text(
      text,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: height,
      ),
    );
  }

  Widget _justifiedText(
    String text, {
    required double size,
    Color? color,
    int maxLines = 2,
    FontWeight weight = FontWeight.normal,
  }) {
    return SizedBox(
      width: double.infinity,
      child: _text(
        text,
        size: size,
        color: color,
        weight: weight,
        align: TextAlign.justify,
        maxLines: maxLines,
        height: 1.18,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return _text(
      title,
      size: 2.8,
      color: _goldDark,
      weight: FontWeight.bold,
    );
  }

  Widget _markerParagraph(
    String text, {
    required double textSize,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2.2,
            height: 8,
            margin: const EdgeInsets.only(top: 1.2, right: 1.4),
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: _justifiedText(
              text,
              size: textSize,
              color: _muted,
              maxLines: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceBlock(
    BalancedTwoColumnExperienceEntry entry, {
    required double detailSize,
  }) {
    final metaLine = entry.metaLine.isNotEmpty
        ? '${entry.metaLine}  |  ${entry.dateRange}'
        : entry.dateRange;
    final detailSummary = _compactSummary(entry.detailLines);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 2.22,
              color: _ink,
              weight: FontWeight.w700,
            ),
            _text(
              metaLine,
              size: 1.56,
              color: _gold,
              maxLines: 2,
            ),
            if (detailSummary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.45),
                child: _justifiedText(
                  detailSummary,
                  size: detailSize,
                  color: _muted,
                  maxLines: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _projectBlock(BalancedTwoColumnProjectEntry entry) {
    final linkSummary = _compactSummary(entry.links.take(2));

    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 2.1,
              color: _ink,
              weight: FontWeight.w700,
            ),
            if (entry.detailLines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entry.detailLines
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(top: 0.35),
                          child: _justifiedText(
                            line,
                            size: 1.5,
                            color: _muted,
                            maxLines: 0,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            if (linkSummary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.4),
                child: _text(
                  linkSummary,
                  size: 1.42,
                  color: _goldDark,
                  maxLines: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<CustomSection> get _previewCustomSections {
    return orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    );
  }

  Widget? _customSectionItemBlock(CustomSectionItem item) {
    final displayItem = buildUserCustomSectionDisplayItem(item);
    final metaParts = <String>[];

    if (displayItem.subtitle.isNotEmpty) {
      metaParts.add(displayItem.subtitle);
    }

    if (displayItem.date != null) {
      metaParts.add(DateFormat('MMM yyyy').format(displayItem.date!));
    }

    if (!displayItem.hasContent) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayItem.heading.isNotEmpty)
          _text(
            displayItem.heading,
            size: 2.2,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 0,
          ),
        if (metaParts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 0.35),
            child: _text(
              metaParts.join('  |  '),
              size: 1.32,
              color: _gold,
              maxLines: 0,
            ),
          ),
        for (final line in displayItem.detailLines)
          Padding(
            padding: const EdgeInsets.only(top: 0.4),
            child: _justifiedText(
              line,
              size: 1.4,
              color: _muted,
              maxLines: 0,
            ),
          ),
      ],
    );
  }

  Widget? _customSectionBlock(CustomSection section) {
    final title = normalizeUserCustomSectionTitle(section.title);
    final itemBlocks = section.items
        .map(_customSectionItemBlock)
        .whereType<Widget>()
        .toList(growable: false);

    if (itemBlocks.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title.isEmpty ? 'CUSTOM SECTION' : title),
        const SizedBox(height: 1.2),
        ...itemBlocks,
      ],
    );
  }

  Widget _skillChip(String value) {
    return Container(
      margin: const EdgeInsets.only(right: 1.3, bottom: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 3.3, vertical: 1.4),
      decoration: BoxDecoration(
        color: _sidebar,
        borderRadius: BorderRadius.circular(9),
      ),
      child: _text(
        value,
        size: 1.42,
        color: _goldDark,
        weight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name = BalancedTwoColumnTemplateSupport.displayName(previewResume)
        .toUpperCase();
    final title = BalancedTwoColumnTemplateSupport.displayTitle(previewResume);
    final contactItems = BalancedTwoColumnTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = BalancedTwoColumnTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: null,
    );
    final experienceEntries =
        BalancedTwoColumnTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: null,
      maxDetailLines: null,
      yearOnly: true,
    );
    final certificationEntries =
        BalancedTwoColumnTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = BalancedTwoColumnTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final projectEntries = BalancedTwoColumnTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final educationEntries = BalancedTwoColumnTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = BalancedTwoColumnTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.phone,
              label: '+91 9885623465',
            ),
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.email,
              label: 'seenai007@gmail.com',
            ),
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.address,
              label: 'Hyderabad, India',
            ),
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.linkedin,
              label: 'linkedin.com/in/seenai',
            ),
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.github,
              label: 'github.com/gmk',
            ),
            BalancedTwoColumnContactItem(
              kind: BalancedTwoColumnContactKind.website,
              label: 'seenaigmk.com',
            ),
          ];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Leads delivery for cross-functional platform initiatives and dependable release operations.',
            'Builds maintainable systems that balance execution speed, structure, and operational clarity.',
          ];
    final previewExperiences = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            BalancedTwoColumnExperienceEntry(
              title: 'Senior Manager',
              metaLine: 'BlueWave Labs  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Scaled observability, delivery workflows, and platform standards across product teams.',
              ],
            ),
            BalancedTwoColumnExperienceEntry(
              title: 'Engineering Manager',
              metaLine: 'Growth Systems  |  Bengaluru',
              dateRange: '2019 - 2021',
              detailLines: [
                'Aligned engineering roadmaps, hiring, and release metrics with business goals.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            BalancedTwoColumnProjectEntry(
              title: 'Resume Builder',
              detailLines: [
                'Live preview, export, and configurable resume sections for multi-template workflows.',
              ],
              links: ['resumebuilder.dev'],
            ),
            BalancedTwoColumnProjectEntry(
              title: 'Platform Scorecard',
              detailLines: [
                'Unified quality, reliability, and delivery reporting across engineering portfolios.',
              ],
              links: ['platform.example.com/scorecard'],
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            BalancedTwoColumnEducationEntry(
              degreeLine: 'MBA Operations',
              institutionLine: 'Osmania University',
              dateRange: '2016 - 2018',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const [
            'Program Management',
            'Platform Strategy',
            'Flutter',
            'Azure',
            'Kubernetes',
            'Stakeholder Leadership',
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            BalancedTwoColumnCertificationEntry(
                name: 'AWS Solutions Architect'),
            BalancedTwoColumnCertificationEntry(name: 'PMP'),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Native', 'Hindi  |  Professional'];

    final certificationSummary = _compactSummary(
      previewCertifications.map((entry) => entry.name),
    );
    final languageSummary = _compactSummary(previewLanguages);
    final profilePointFontSize = _profilePointFontSize(previewSummaryLines);
    final visibleExperiences =
        previewExperiences.take(3).toList(growable: false);
    final hiddenExperienceCount =
        previewExperiences.length - visibleExperiences.length;
    final experienceDetailSize = _experienceDetailFontSize(visibleExperiences);
    final visibleProjects = previewProjects.take(2).toList(growable: false);
    final hiddenProjectCount = previewProjects.length - visibleProjects.length;
    final visibleSkills = previewSkills.take(6).toList(growable: false);
    final hiddenSkillCount = previewSkills.length - visibleSkills.length;
    final customSectionBlocks = _previewCustomSections
        .map(_customSectionBlock)
        .whereType<Widget>()
        .toList(growable: false);

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
            Expanded(
              flex: 10,
              child: Container(
                color: _sidebar,
                padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('PROFILE'),
                    ...previewSummaryLines.map(
                      (line) => _markerParagraph(
                        line,
                        textSize: profilePointFontSize,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _sectionTitle('EXPERIENCE SUMMARY'),
                    ...visibleExperiences.map(
                      (entry) => _experienceBlock(
                        entry,
                        detailSize: experienceDetailSize,
                      ),
                    ),
                    if (hiddenExperienceCount > 0)
                      _text(
                        '+$hiddenExperienceCount more roles in PDF preview',
                        size: 1.34,
                        color: _goldDark,
                        maxLines: 2,
                      ),
                    if (certificationSummary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _sectionTitle('CERTIFICATIONS'),
                      _justifiedText(
                        certificationSummary,
                        size: _summaryFontSize(certificationSummary),
                        color: _muted,
                        maxLines: 0,
                      ),
                    ],
                    if (previewLanguages.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _sectionTitle('LANGUAGES'),
                      if (previewLanguages.length <= 4)
                        _justifiedText(
                          languageSummary,
                          size: _summaryFontSize(languageSummary),
                          color: _muted,
                          maxLines: 0,
                        )
                      else ...previewLanguages.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: _text(
                            line,
                            size: 1.28,
                            color: _muted,
                            maxLines: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(width: 0.8, color: _line),
            Expanded(
              flex: 14,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 5),
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
                              _text(
                                name,
                                size: 5.15,
                                color: _ink,
                                weight: FontWeight.w900,
                              ),
                              _text(
                                title,
                                size: 2.38,
                                color: _gold,
                                weight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _avatarFill,
                            border: Border.all(color: _gold, width: 1),
                            image: photoBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(photoBytes),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoBytes == null
                              ? Icon(Icons.person, size: 12, color: _gold)
                              : null,
                        ),
                      ],
                    ),
                    Container(
                      height: 0.7,
                      color: _line,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                    _sectionTitle('CONTACT'),
                    ...previewContacts.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.45),
                        child: _text(
                          item.label,
                          size: 1.72,
                          color: _muted,
                          maxLines:
                              item.kind == BalancedTwoColumnContactKind.address
                                  ? 3
                                  : 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    _sectionTitle('SKILLS'),
                    Wrap(
                      children: [
                        ...visibleSkills.map(_skillChip),
                        if (hiddenSkillCount > 0)
                          _skillChip('+$hiddenSkillCount'),
                      ],
                    ),
                    if (previewEducation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _sectionTitle('EDUCATION'),
                      ...previewEducation.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _text(
                                  entry.degreeLine,
                                  size: 1.9,
                                  color: _ink,
                                  weight: FontWeight.w700,
                                  maxLines: 2,
                                ),
                                _text(
                                  entry.institutionLine,
                                  size: 1.6,
                                  color: _muted,
                                  maxLines: 2,
                                ),
                                _text(
                                  entry.dateRange,
                                  size: 1.48,
                                  color: _gold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (visibleProjects.isNotEmpty) ...[
                      const SizedBox(height: 1.4),
                      _sectionTitle('PROJECTS'),
                      ...visibleProjects.map(_projectBlock),
                      if (hiddenProjectCount > 0)
                        _text(
                          '+$hiddenProjectCount more projects in PDF preview',
                          size: 1.34,
                          color: _goldDark,
                          maxLines: 2,
                        ),
                    ],
                    for (final block in customSectionBlocks) ...[
                      const SizedBox(height: 1.4),
                      block,
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
