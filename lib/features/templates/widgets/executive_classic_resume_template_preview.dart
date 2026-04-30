import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../executive_classic_template_support.dart';

class ExecutiveClassicResumeTemplatePreview extends StatelessWidget {
  const ExecutiveClassicResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _headerBg =>
      const Color(ExecutiveClassicTemplateSupport.headerBgHex);
  Color get _headerStripe =>
      const Color(ExecutiveClassicTemplateSupport.headerStripeHex);
  Color get _pageBg => const Color(ExecutiveClassicTemplateSupport.pageHex);
  Color get _ink => const Color(ExecutiveClassicTemplateSupport.inkHex);
  Color get _muted => const Color(ExecutiveClassicTemplateSupport.mutedHex);
  Color get _subtle =>
      const Color(ExecutiveClassicTemplateSupport.subtleHex);
  Color get _line => const Color(ExecutiveClassicTemplateSupport.lineHex);
  Color get _chipBg =>
      const Color(ExecutiveClassicTemplateSupport.chipBgHex);
  Color get _chipBorder =>
      const Color(ExecutiveClassicTemplateSupport.chipBorderHex);
  Color get _accentStripe => Color.lerp(_accent, Colors.black, 0.25)!;

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'JOHN SMITH';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Executive Leader';
  }

  List<ExecutiveClassicContactItem> get _contactItems {
    final items = ExecutiveClassicTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
    );
    if (items.isNotEmpty) {
      return items;
    }

    return const [
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.phone,
        label: '(555) 123-4567',
      ),
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.email,
        label: 'john@email.com',
      ),
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.location,
        label: 'New York, NY',
      ),
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.linkedin,
        label: 'linkedin.com/in/johnsmith',
      ),
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.github,
        label: 'github.com/johnsmith',
      ),
      ExecutiveClassicContactItem(
        kind: ExecutiveClassicContactKind.website,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final values = ExecutiveClassicTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 3,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Results-driven executive with a track record of building high-performing teams and delivering measurable business outcomes.',
            'Aligns strategy, execution, and stakeholder communication to drive sustainable growth.',
          ];
  }

  List<ExecutiveClassicExperienceEntry> get _experiences {
    final values = ExecutiveClassicTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      monthResolution: false,
    );
    return values.isNotEmpty
        ? values
        : const [
            ExecutiveClassicExperienceEntry(
              title: 'Chief Operating Officer',
              metaLine: 'Northwind Partners  •  New York, NY',
              dateRange: '2021 - Present',
              detailLines: [
                'Scaled cross-functional operations and improved delivery efficiency across strategic initiatives.',
              ],
            ),
            ExecutiveClassicExperienceEntry(
              title: 'Director of Strategy',
              metaLine: 'Harbor Group  •  Remote',
              dateRange: '2018 - 2021',
              detailLines: [
                'Led planning, execution, and stakeholder alignment for enterprise transformation programs.',
              ],
            ),
          ];
  }

  List<ExecutiveClassicEducationEntry> get _educations {
    final values = ExecutiveClassicTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      maxSupportingLines: 1,
      monthResolution: false,
    );
    return values.isNotEmpty
        ? values
        : const [
            ExecutiveClassicEducationEntry(
              degree: 'MBA Business Administration',
              institutionLine: 'Columbia University',
              dateRange: '2017',
              supportingLines: ['Graduated with distinction'],
            ),
          ];
  }

  List<String> get _skills {
    final values = ExecutiveClassicTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 5,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Leadership',
            'Operations',
            'Strategy',
            'Stakeholder Management',
            'Program Delivery',
          ];
  }

  List<String> get _certifications {
    final values = ExecutiveClassicTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
    );
    return values.isNotEmpty
        ? values
        : const ['PMP  •  PMI', 'AWS Cloud Practitioner  •  Amazon'];
  }

  List<String> get _languages {
    final values = ExecutiveClassicTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    return values.isNotEmpty
        ? values
        : const ['English  •  Native', 'Spanish  •  Professional'];
  }

  List<CustomSection> get _previewCustomSections {
    return orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    );
  }

  Widget? _customSectionItemBlock(CustomSectionItem item) {
    final displayItem = buildUserCustomSectionDisplayItem(item);

    final metaParts = <String>[];
    if (displayItem.subtitle.isNotEmpty) metaParts.add(displayItem.subtitle);
    if (displayItem.date != null) {
      metaParts.add(DateFormat('MMM yyyy').format(displayItem.date!));
    }

    if (!displayItem.hasContent) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayItem.heading.isNotEmpty)
            _text(
              displayItem.heading,
              size: 3.3,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 0,
            ),
          if (metaParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0.8, bottom: 0.8),
              child: _text(
                metaParts.join('  |  '),
                size: 2.7,
                color: _muted,
                maxLines: 0,
              ),
            ),
          for (final line in displayItem.detailLines)
            Padding(
              padding: const EdgeInsets.only(top: 0.6),
              child: _text(
                line,
                size: 2.8,
                color: _ink,
                maxLines: 0,
                justify: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget? _customSectionBlock(CustomSection section) {
    final title = normalizeUserCustomSectionTitle(section.title);
    final itemBlocks = section.items
        .map(_customSectionItemBlock)
        .whereType<Widget>()
        .toList(growable: false);

    if (itemBlocks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title.isEmpty ? 'Custom Section' : title),
          const SizedBox(height: 1.5),
          _text(
            'No content yet. Add entries to this section to display them here.',
            size: 2.8,
            color: _muted,
            maxLines: 0,
            justify: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title.isEmpty ? 'Custom Section' : title),
        const SizedBox(height: 1.5),
        ...itemBlocks,
      ],
    );
  }

  List<ExecutiveClassicProjectEntry> get _projects {
    final values = ExecutiveClassicTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 2,
      compactLinks: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            ExecutiveClassicProjectEntry(
              title: 'Enterprise Transformation Program',
              detailLines: [
                'Directed a multi-year modernization initiative spanning finance, operations, and reporting workflows.',
              ],
              url: 'example.com/transformation',
            ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Container(height: 3, color: _accentStripe),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('SUMMARY'),
                    ..._summaryLines.map(_summaryLine),
                    if (_experiences.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('WORK EXPERIENCE'),
                      ..._experiences.map(_experienceBlock),
                    ],
                    if (_educations.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('EDUCATION'),
                      ..._educations.map(_educationBlock),
                    ],
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('CORE COMPETENCIES'),
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: _skills.map(_skillChip).toList(growable: false),
                      ),
                    ],
                    if (_certifications.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('CERTIFICATIONS'),
                      ..._certifications.map(_simpleLine),
                    ],
                    if (_languages.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('LANGUAGES'),
                      ..._languages.map(_simpleLine),
                    ],
                    if (_projects.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _sectionHeader('PROJECTS'),
                      ..._projects.map(_projectBlock),
                    ],
                    for (final section in _previewCustomSections)
                      if (_customSectionBlock(section) case final block?) ...[
                        const SizedBox(height: 3),
                        block,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _headerBg,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            _name.toUpperCase(),
            size: 9.6,
            color: Colors.white,
            weight: FontWeight.w900,
          ),
          _text(
            _title.toUpperCase(),
            size: 3.4,
            color: Colors.white70,
            weight: FontWeight.w600,
            maxLines: 2,
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 0,
            runSpacing: 1.2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _contactWrapChildren(),
          ),
          const SizedBox(height: 3),
          Container(height: 3, color: _headerStripe),
        ],
      ),
    );
  }

  List<Widget> _contactWrapChildren() {
    final children = <Widget>[];
    for (var index = 0; index < _contactItems.length; index++) {
      final item = _contactItems[index];
      if (index > 0) {
        children.add(_contactDot());
      }
      children.add(
        _text(
          item.label,
          size: 2.6,
          color: Colors.white70,
          maxLines: 1,
        ),
      );
    }
    return children;
  }

  Widget _contactDot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 2.5,
          height: 2.5,
          decoration: const BoxDecoration(
            color: Colors.white54,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 1.5, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 2.5,
              height: 10,
              color: _accent,
              margin: const EdgeInsets.only(right: 4),
            ),
            Flexible(
              child: _text(
                title,
                size: 4.2,
                color: _accent,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 0.55, color: _line)),
          ],
        ),
      );

  Widget _summaryLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.4, right: 2.6),
              child: Icon(
                Icons.check,
                size: 3.4,
                color: _accent,
              ),
            ),
            Expanded(
              child: _text(
                line,
                size: 2.75,
                color: _muted,
                align: TextAlign.justify,
                maxLines: 0,
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(ExecutiveClassicExperienceEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.8),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _text(
                      entry.title,
                      size: 3.55,
                      color: _ink,
                      weight: FontWeight.bold,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 54),
                    child: _text(
                      entry.dateRange,
                      size: 2.55,
                      color: _subtle,
                      align: TextAlign.right,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              if (entry.metaLine.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0.6),
                  child: _text(
                    entry.metaLine,
                    size: 2.7,
                    color: _accent,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                ),
              ...entry.detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 0.8),
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(
                      line,
                      size: 2.58,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _educationBlock(ExecutiveClassicEducationEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.5),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _text(
                      entry.degree,
                      size: 3.45,
                      color: _ink,
                      weight: FontWeight.bold,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 44),
                    child: _text(
                      entry.dateRange,
                      size: 2.5,
                      color: _subtle,
                      align: TextAlign.right,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              _text(
                entry.institutionLine,
                size: 2.7,
                color: _accent,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              ...entry.supportingLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 0.7),
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(
                      line,
                      size: 2.5,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _skillChip(String label) => Container(
        constraints: const BoxConstraints(maxWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.8),
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _chipBorder, width: 0.7),
        ),
        child: _text(
          label,
          size: 2.7,
          color: _ink,
          weight: FontWeight.w600,
          maxLines: 1,
        ),
      );

  Widget _simpleLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.1),
        child: SizedBox(
          width: double.infinity,
          child: _text(
            line,
            size: 2.6,
            color: _muted,
            align: TextAlign.justify,
            maxLines: 0,
          ),
        ),
      );

  Widget _projectBlock(ExecutiveClassicProjectEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.4),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _text(
                entry.title,
                size: 3.0,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              ...entry.detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 0.8),
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(
                      line,
                      size: 2.55,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: 0,
                    ),
                  ),
                ),
              ),
              if (entry.url.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0.8),
                  child: _text(
                    entry.url,
                    size: 2.45,
                    color: _accent,
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _text(
    String text, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.normal,
    TextAlign align = TextAlign.left,
    bool justify = false,
    int maxLines = 1,
  }) {
    return Text(
      text,
      textAlign: justify ? TextAlign.justify : align,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.17,
      ),
    );
  }

}