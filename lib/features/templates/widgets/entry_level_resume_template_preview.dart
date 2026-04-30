import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../entry_level_template_support.dart';

class EntryLevelResumeTemplatePreview extends StatelessWidget {
  const EntryLevelResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => const Color(EntryLevelTemplateSupport.accentHex);
  Color get _pageBg => const Color(EntryLevelTemplateSupport.pageHex);
  Color get _ink => const Color(EntryLevelTemplateSupport.inkHex);
  Color get _muted => const Color(EntryLevelTemplateSupport.mutedHex);
  Color get _subtle => const Color(EntryLevelTemplateSupport.subtleHex);
  Color get _chipBg => const Color(EntryLevelTemplateSupport.chipBgHex);
  Color get _chipBorder => const Color(EntryLevelTemplateSupport.chipBorderHex);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<EntryLevelContactItem> get _contactItems {
    final items = EntryLevelTemplateSupport.contactItems(resume?.personalInfo);
    if (items.isNotEmpty) {
      return items;
    }

    return const [
      EntryLevelContactItem(
        kind: EntryLevelContactKind.email,
        label: 'john.smith@email.com',
      ),
      EntryLevelContactItem(
        kind: EntryLevelContactKind.phone,
        label: '(555) 123-4567',
      ),
      EntryLevelContactItem(
        kind: EntryLevelContactKind.location,
        label: 'New York, NY',
      ),
      EntryLevelContactItem(
        kind: EntryLevelContactKind.linkedin,
        label: 'linkedin.com/in/johnsmith',
      ),
      EntryLevelContactItem(
        kind: EntryLevelContactKind.github,
        label: 'github.com/johnsmith',
      ),
      EntryLevelContactItem(
        kind: EntryLevelContactKind.website,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final lines = EntryLevelTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 4,
    );
    return lines.isNotEmpty
        ? lines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions.',
            'Builds reliable user experiences with clear communication and strong execution.',
          ];
  }

  List<EntryLevelExperienceEntry> get _experiences {
    final values = EntryLevelTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxDetailLines: 12,
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            EntryLevelExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp  •  Remote',
              dateRange: '2021 - Present',
              detailLines: [
                'Led a cross-functional team to ship a cloud-based platform.',
              ],
            ),
          ];
  }

  List<EntryLevelEducationEntry> get _educations {
    final values = EntryLevelTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            EntryLevelEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateRange: '2020',
              supportingLines: ['GPA: 3.8/4.0'],
            ),
          ];
  }

  List<String> get _skills {
    final values = EntryLevelTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
    );
    return values.isNotEmpty
        ? values
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
  }

  List<EntryLevelProjectEntry> get _projects {
    final values = EntryLevelTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxDetailLines: 6,
      compactLinks: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            EntryLevelProjectEntry(
              title: 'Portfolio Website',
              detailLines: [
                'Built a responsive portfolio and resume showcase.',
              ],
              url: 'portfolio.example.com',
            ),
          ];
  }

  List<String> get _certifications {
    final values = EntryLevelTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
    );
    return values.isNotEmpty
        ? values
        : const ['AWS Certified Developer  •  Amazon'];
  }

  List<String> get _languages {
    final values = EntryLevelTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
    );
    return values.isNotEmpty
        ? values
        : const ['English  •  Professional', 'German  •  Professional'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                    size: 8.2,
                    color: _accent,
                    weight: FontWeight.w900,
                    center: true,
                  ),
                  _text(
                    _title,
                    size: 4.2,
                    color: _muted,
                    center: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(height: 1.2, color: _accent),
            const SizedBox(height: 2),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 1,
                children: _contactItems
                    .map(
                      (item) => _text(
                        item.label,
                        size: item.kind == EntryLevelContactKind.linkedin ||
                                item.kind == EntryLevelContactKind.github ||
                                item.kind == EntryLevelContactKind.website
                            ? 2.8
                            : 3.0,
                        color: item.kind == EntryLevelContactKind.linkedin ||
                                item.kind == EntryLevelContactKind.github ||
                                item.kind == EntryLevelContactKind.website
                            ? _subtle
                            : _muted,
                        center: true,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 4),
            _sectionHeader('PROFILE'),
            const SizedBox(height: 1),
            ..._summaryLines.map(_summaryLine),
            const SizedBox(height: 4),
            _sectionHeader('EXPERIENCE'),
            ..._experiences.map(_experienceBlock),
            const SizedBox(height: 4),
            _sectionHeader('SKILLS'),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _skills
                  .map(
                    (skill) => Container(
                      constraints: const BoxConstraints(maxWidth: 84),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.4,
                      ),
                      decoration: BoxDecoration(
                        color: _chipBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _chipBorder),
                      ),
                      child: _text(
                        skill,
                        size: 3.7,
                        color: _ink,
                        weight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 4),
            _sectionHeader('EDUCATION'),
            ..._educations.map(_educationBlock),
            if (_projects.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sectionHeader('PROJECTS'),
              ..._projects.map(_projectBlock),
            ],
            if (_certifications.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sectionHeader('CERTIFICATIONS'),
              ..._certifications.map(
                (line) => _text(
                  line,
                  size: 3.2,
                  color: _muted,
                  maxLines: 0,
                ),
              ),
            ],
            if (_languages.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sectionHeader('LANGUAGES'),
              ..._languages.map(
                (line) => _text(
                  line,
                  size: 3.2,
                  color: _muted,
                  maxLines: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => _text(
        title,
        size: 4.4,
        color: _accent,
        weight: FontWeight.bold,
      );

  Widget _summaryLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.2, right: 3),
              child: _text('✦', size: 3.2, color: _accent),
            ),
            Expanded(
              child: _text(
                line,
                size: 3.15,
                color: _muted,
                maxLines: 2,
                justify: true,
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(EntryLevelExperienceEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 4.2,
              color: _ink,
              weight: FontWeight.w700,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    entry.companyLine,
                    size: 3.2,
                    color: _muted,
                    maxLines: 1,
                  ),
                ),
                if (entry.dateRange.trim().isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _text(
                    entry.dateRange,
                    size: 3.0,
                    color: _subtle,
                  ),
                ],
              ],
            ),
            ...entry.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 0.8),
                child: _text(
                  line,
                  size: 3.0,
                  color: _muted,
                  maxLines: 2,
                  justify: true,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _educationBlock(EntryLevelEducationEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    entry.degree,
                    size: 4.2,
                    color: _ink,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                ),
                if (entry.dateRange.trim().isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _text(
                    entry.dateRange,
                    size: 3.0,
                    color: _subtle,
                  ),
                ],
              ],
            ),
            _text(entry.institutionLine, size: 3.2, color: _muted, maxLines: 2),
            ...entry.supportingLines.map(
              (line) => _text(
                line,
                size: 3.0,
                color: _subtle,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );

  Widget _projectBlock(EntryLevelProjectEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 2.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 3.4,
              color: _ink,
              weight: FontWeight.w600,
              maxLines: 0,
            ),
            if (entry.detailLines.isNotEmpty) ...[
              const SizedBox(height: 0.8),
              ...entry.detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 0.8),
                  child: _text(
                    line,
                    size: 3.0,
                    color: _muted,
                    maxLines: 0,
                    justify: true,
                  ),
                ),
              ),
            ],
            if (entry.url.trim().isNotEmpty)
              _text(
                entry.url,
                size: 2.9,
                color: _accent,
                maxLines: 0,
              ),
          ],
        ),
      );

  Widget _text(
    String text, {
    double size = 5.0,
    Color? color,
    FontWeight weight = FontWeight.normal,
    bool center = false,
    int maxLines = 1,
    bool justify = false,
  }) {
    return Text(
      text,
      textAlign: center
          ? TextAlign.center
          : (justify ? TextAlign.justify : TextAlign.left),
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: 1.15,
      ),
    );
  }
}