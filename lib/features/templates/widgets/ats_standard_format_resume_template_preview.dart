import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../ats_standard_format_template_support.dart';

class AtsStandardFormatResumeTemplatePreview extends StatelessWidget {
  const AtsStandardFormatResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageBg => const Color(AtsStandardFormatTemplateSupport.pageHex);
  Color get _ink => const Color(AtsStandardFormatTemplateSupport.inkHex);
  Color get _body => const Color(AtsStandardFormatTemplateSupport.bodyHex);
  Color get _muted => const Color(AtsStandardFormatTemplateSupport.mutedHex);
  Color get _guide => const Color(AtsStandardFormatTemplateSupport.guideHex);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Manager';
  }

  List<AtsStandardContactItem> get _contactItems {
    final items = AtsStandardFormatTemplateSupport.contactItems(
      resume?.personalInfo,
    );
    if (items.isNotEmpty) {
      return items;
    }

    return const [
      AtsStandardContactItem(
        kind: AtsStandardContactKind.phone,
        label: '(555) 123-4567',
      ),
      AtsStandardContactItem(
        kind: AtsStandardContactKind.email,
        label: 'john.smith@email.com',
      ),
      AtsStandardContactItem(
        kind: AtsStandardContactKind.location,
        label: 'New York, NY',
      ),
    ];
  }

  List<AtsStandardLinkItem> get _linkItems {
    final items = AtsStandardFormatTemplateSupport.linkItems(
      resume?.personalInfo,
      compactLinks: true,
    );
    if (items.isNotEmpty) {
      return items;
    }

    return const [
      AtsStandardLinkItem(
        kind: AtsStandardLinkKind.linkedin,
        label: 'linkedin.com/in/johnsmith',
      ),
      AtsStandardLinkItem(
        kind: AtsStandardLinkKind.github,
        label: 'github.com/johnsmith',
      ),
      AtsStandardLinkItem(
        kind: AtsStandardLinkKind.website,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final lines = AtsStandardFormatTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 3,
    );
    return lines.isNotEmpty
        ? lines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across testing, automation, and delivery workflows.',
          ];
  }

  List<AtsStandardEducationEntry> get _educations {
    final entries = AtsStandardFormatTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      maxSupportLines: 1,
      yearOnly: true,
    );
    return entries.isNotEmpty
        ? entries
        : const [
            AtsStandardEducationEntry(
              degree: 'MCA Computer Applications',
              institutionLine: 'Holy Jesus and Mary PG College',
              dateRange: '2006 - 2009',
            ),
          ];
  }

  List<AtsStandardExperienceEntry> get _experiences {
    final entries = AtsStandardFormatTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      yearOnly: true,
    );
    return entries.isNotEmpty
        ? entries
        : const [
            AtsStandardExperienceEntry(
              title: 'Automation Lead',
              companyLine: 'TechCorp  •  Remote',
              dateRange: '2021 - Present',
              detailLines: [
                'Led automation delivery across UI, API, and regression workflows.',
              ],
            ),
          ];
  }

  List<String> get _skills {
    final values = AtsStandardFormatTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 8,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Testing',
            'Automation',
            'Selenium',
            'Core Java',
            'SQL',
          ];
  }

  List<AtsStandardProjectEntry> get _projects {
    final entries = AtsStandardFormatTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 2,
      compactLinks: true,
    );
    return entries.isNotEmpty
        ? entries
        : const [
            AtsStandardProjectEntry(
              title: 'Resumix AI',
              detailLines: [
                'Built a live preview and export workflow for resume templates.',
              ],
              url: 'resume.example.com',
            ),
          ];
  }

  List<AtsStandardCertificationEntry> get _certifications {
    return AtsStandardFormatTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      compactLinks: true,
    );
  }

  List<String> get _languages {
    return AtsStandardFormatTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            bottom: 8,
            right: 3,
            child: Container(
              width: 1.1,
              color: _guide,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        _text(
                          _name.toUpperCase(),
                          size: 8.8,
                          color: _ink,
                          weight: FontWeight.w900,
                          center: true,
                        ),
                        _text(
                          _title,
                          size: 4.0,
                          color: _muted,
                          center: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 1.5,
                      children: _contactItems
                          .map(
                            (item) => _text(
                              item.label,
                              size: 3.05,
                              color: _muted,
                              center: true,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _sectionHeader('ABOUT ME'),
                  ..._summaryLines.map(_bulletLine),
                  if (_educations.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('EDUCATION'),
                    ..._educations.map(_educationBlock),
                  ],
                  if (_experiences.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('WORK EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                  ],
                  if (_skills.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('SKILLS'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 1.6,
                      children: _skills
                          .map(
                            (skill) => _text(
                              '• $skill',
                              size: 3.0,
                              color: _body,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (_linkItems.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('LINKS'),
                    ..._linkItems.map(_linkLine),
                  ],
                  if (_projects.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('PROJECTS'),
                    ..._projects.map(_projectBlock),
                  ],
                  if (_certifications.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('CERTIFICATIONS'),
                    ..._certifications.map(_certificationBlock),
                  ],
                  if (_languages.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _sectionHeader('LANGUAGES'),
                    ..._languages.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 1.0),
                        child: _text(
                          line,
                          size: 3.0,
                          color: _body,
                          maxLines: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1.4, width: double.infinity, color: accentColor),
          const SizedBox(height: 2.5),
          _text(
            title,
            size: 4.6,
            color: accentColor,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: 1.2),
        ],
      );

  Widget _bulletLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.1, right: 3),
              child: _text('•', size: 3.2, color: accentColor),
            ),
            Expanded(
              child: _text(
                line,
                size: 3.0,
                color: _body,
                maxLines: 0,
                justify: true,
              ),
            ),
          ],
        ),
      );

  Widget _educationBlock(AtsStandardEducationEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    entry.degree,
                    size: 3.45,
                    color: _ink,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 42,
                  child: _text(
                    entry.dateRange,
                    size: 2.9,
                    color: _muted,
                    alignRight: true,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            _text(
              entry.institutionLine,
              size: 3.0,
              color: _body,
              maxLines: 2,
            ),
            ...entry.supportingLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.6),
                child: _text(
                  line,
                  size: 2.85,
                  color: _muted,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(AtsStandardExperienceEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    entry.title,
                    size: 3.55,
                    color: _ink,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 42,
                  child: _text(
                    entry.dateRange,
                    size: 2.9,
                    color: _muted,
                    alignRight: true,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            _text(
              entry.companyLine,
              size: 3.0,
              color: accentColor,
              maxLines: 2,
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.7),
                child: _text(
                  line,
                  size: 2.9,
                  color: _body,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _linkLine(AtsStandardLinkItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 1.0),
        child: _text(
          '${_linkLabel(item.kind)}: ${item.label}',
          size: 2.95,
          color: _body,
          maxLines: 0,
        ),
      );

  Widget _projectBlock(AtsStandardProjectEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 3.3,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 0,
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.7),
                child: _text(
                  line,
                  size: 2.9,
                  color: _body,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
            if (entry.url.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.7),
                child: _text(
                  entry.url,
                  size: 2.9,
                  color: accentColor,
                  maxLines: 0,
                ),
              ),
          ],
        ),
      );

  Widget _certificationBlock(AtsStandardCertificationEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.name,
              size: 3.25,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 0,
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.65),
                child: _text(
                  line,
                  size: 2.85,
                  color: _body,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
            if (entry.url.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.65),
                child: _text(
                  entry.url,
                  size: 2.85,
                  color: accentColor,
                  maxLines: 0,
                ),
              ),
          ],
        ),
      );

  String _linkLabel(AtsStandardLinkKind kind) {
    switch (kind) {
      case AtsStandardLinkKind.linkedin:
        return 'LinkedIn';
      case AtsStandardLinkKind.github:
        return 'GitHub';
      case AtsStandardLinkKind.website:
        return 'Website';
    }
  }

  Widget _text(
    String text, {
    double size = 5.0,
    Color? color,
    FontWeight weight = FontWeight.normal,
    bool center = false,
    bool alignRight = false,
    bool justify = false,
    int maxLines = 1,
  }) {
    return Text(
      text,
      textAlign: center
          ? TextAlign.center
          : (alignRight
              ? TextAlign.right
              : (justify ? TextAlign.justify : TextAlign.left)),
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _body,
        fontWeight: weight,
        height: 1.16,
      ),
    );
  }
}
