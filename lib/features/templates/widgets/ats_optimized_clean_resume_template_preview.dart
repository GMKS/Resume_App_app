import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../ats_optimized_clean_template_support.dart';

class AtsOptimizedCleanResumeTemplatePreview extends StatelessWidget {
  const AtsOptimizedCleanResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageBg => const Color(AtsOptimizedCleanTemplateSupport.pageHex);
  Color get _ink => const Color(AtsOptimizedCleanTemplateSupport.inkHex);
  Color get _body => const Color(AtsOptimizedCleanTemplateSupport.bodyHex);
  Color get _muted => const Color(AtsOptimizedCleanTemplateSupport.mutedHex);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'MBA, Software Engineering';
  }

  List<AtsOptimizedCleanContactItem> get _contactItems {
    final items = AtsOptimizedCleanTemplateSupport.contactItems(
      resume?.personalInfo,
    );
    if (items.isNotEmpty) {
      return items;
    }

    return const [
      AtsOptimizedCleanContactItem(
        kind: AtsOptimizedCleanContactKind.phone,
        label: '(555) 123-4567',
      ),
      AtsOptimizedCleanContactItem(
        kind: AtsOptimizedCleanContactKind.email,
        label: 'john.smith@email.com',
      ),
      AtsOptimizedCleanContactItem(
        kind: AtsOptimizedCleanContactKind.linkedin,
        label: 'linkedin.com/in/johnsmith',
      ),
    ];
  }

  List<String> get _summaryLines {
    final lines = AtsOptimizedCleanTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 3,
    );
    return lines.isNotEmpty
        ? lines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
          ];
  }

  List<String> get _skillNames {
    final values = AtsOptimizedCleanTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    return values.isNotEmpty
        ? values
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
  }

  List<AtsOptimizedCleanExperienceEntry> get _experiences {
    final values = AtsOptimizedCleanTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            AtsOptimizedCleanExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp  •  Remote',
              dateRange: '2021 - Present',
              detailLines: [
                'Led a cross-functional team to ship a cloud-based platform.',
              ],
            ),
          ];
  }

  List<AtsOptimizedCleanEducationEntry> get _educations {
    final values = AtsOptimizedCleanTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            AtsOptimizedCleanEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateRange: '2020',
            ),
          ];
  }

  List<AtsOptimizedCleanProjectEntry> get _projects {
    final values = AtsOptimizedCleanTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    return values;
  }

  List<String> get _certifications {
    return AtsOptimizedCleanTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
    );
  }

  List<String> get _languages {
    return AtsOptimizedCleanTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    );

    Widget? customSectionItemBlock(CustomSectionItem item) {
      final displayItem = buildUserCustomSectionDisplayItem(item);

      final metaParts = <String>[
        if (displayItem.subtitle.isNotEmpty) displayItem.subtitle,
        if (displayItem.date != null)
          DateFormat('MMM yyyy').format(displayItem.date!),
      ];

      if (!displayItem.hasContent) {
        return null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 2.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayItem.heading.isNotEmpty)
              _text(
                displayItem.heading,
                size: 3.3,
                color: _ink,
                weight: FontWeight.w600,
                maxLines: 0,
              ),
            if (metaParts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.8, bottom: 0.8),
                child: _text(
                  metaParts.join('  |  '),
                  size: 2.85,
                  color: _muted,
                  maxLines: 0,
                ),
              ),
            ...displayItem.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.7),
                child: _text(
                  line,
                  size: 2.95,
                  color: _body,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final title = normalizeUserCustomSectionTitle(section.title);
      final itemBlocks = section.items
          .map(customSectionItemBlock)
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(title.isEmpty ? 'Custom Section' : title),
            const SizedBox(height: 1.2),
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

    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        _name.toUpperCase(),
                        size: 9.0,
                        color: _ink,
                        weight: FontWeight.w900,
                      ),
                      _text(
                        _title,
                        size: 4.0,
                        color: _muted,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 74),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _contactItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 0.6),
                            child: _text(
                              item.label,
                              size: 3.05,
                              color: _body,
                              alignRight: true,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 1.5, width: double.infinity, color: accentColor),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('ABOUT ME'),
                      const SizedBox(height: 2),
                      ..._summaryLines.map(_summaryLine),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Core Skills'),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 1,
                        children: _skillNames
                            .map(
                              (skill) => _text(
                                skill,
                                size: 3.05,
                                color: _body,
                              ),
                            )
                            .toList(growable: false),
                      ),
                      if (_certifications.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _sidebarHeader('Certifications'),
                        const SizedBox(height: 1.2),
                        ..._certifications.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 0.8),
                            child: _text(
                              line,
                              size: 2.9,
                              color: _body,
                              maxLines: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 0.6,
              width: double.infinity,
              color: accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 3),
            _sectionHeader('EXPERIENCE'),
            const SizedBox(height: 1.5),
            ..._experiences.map(_experienceBlock),
            if (_educations.isNotEmpty) ...[
              const SizedBox(height: 1),
              _sectionHeader('EDUCATION'),
              const SizedBox(height: 1.5),
              ..._educations.map(_educationBlock),
            ],
            if (_projects.isNotEmpty) ...[
              const SizedBox(height: 1),
              _sectionHeader('PROJECTS'),
              const SizedBox(height: 1.5),
              ..._projects.map(_projectBlock),
            ],
            if (_languages.isNotEmpty) ...[
              const SizedBox(height: 1),
              _sectionHeader('LANGUAGES'),
              const SizedBox(height: 1.5),
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
            for (final section in previewCustomSections)
              if (customSectionBlock(section) case final block?) ...[
                const SizedBox(height: 1),
                block,
              ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => _text(
        title,
        size: 4.4,
        color: accentColor,
        weight: FontWeight.bold,
      );

  Widget _sidebarHeader(String title) => _text(
        title,
        size: 3.7,
        color: accentColor,
        weight: FontWeight.w600,
      );

  Widget _summaryLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.2,
              height: 3.2,
              margin: const EdgeInsets.only(top: 0.7, right: 3),
              decoration: BoxDecoration(
                color: _ink,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: _text(
                line,
                size: 3.05,
                color: _body,
                maxLines: 0,
                justify: true,
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(AtsOptimizedCleanExperienceEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    entry.title,
                    size: 3.9,
                    color: _ink,
                    weight: FontWeight.w600,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 4),
                _text(
                  entry.dateRange,
                  size: 3.0,
                  color: _muted,
                  alignRight: true,
                ),
              ],
            ),
            _text(
              entry.companyLine,
              size: 3.15,
              color: _body,
              maxLines: 2,
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.8),
                child: _text(
                  line,
                  size: 2.95,
                  color: _body,
                  maxLines: 0,
                  justify: true,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _educationBlock(AtsOptimizedCleanEducationEntry entry) => Padding(
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
                    size: 3.6,
                    color: _ink,
                    weight: FontWeight.w600,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 4),
                _text(
                  entry.dateRange,
                  size: 3.0,
                  color: _muted,
                  alignRight: true,
                ),
              ],
            ),
            _text(
              entry.institutionLine,
              size: 3.05,
              color: _body,
              maxLines: 2,
            ),
            ...entry.supportingLines.map(
              (line) => _text(
                line,
                size: 2.9,
                color: _muted,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );

  Widget _projectBlock(AtsOptimizedCleanProjectEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 3.3,
              color: _ink,
              weight: FontWeight.w600,
              maxLines: 0,
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.7),
                child: _text(
                  line,
                  size: 2.95,
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

  Widget _text(
    String text, {
    double size = 5.0,
    Color? color,
    FontWeight weight = FontWeight.normal,
    bool alignRight = false,
    bool justify = false,
    int maxLines = 1,
  }) {
    return Text(
      text,
      textAlign: alignRight
          ? TextAlign.right
          : (justify ? TextAlign.justify : TextAlign.left),
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _body,
        fontWeight: weight,
        height: 1.15,
      ),
    );
  }
}
