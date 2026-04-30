import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../classic_ats_template_support.dart';

class ClassicAtsResumeTemplatePreview extends StatelessWidget {
  const ClassicAtsResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _headerBg => const Color(ClassicAtsTemplateSupport.headerHex);
  Color get _pageBg => const Color(ClassicAtsTemplateSupport.pageHex);
  Color get _ink => const Color(ClassicAtsTemplateSupport.inkHex);
  Color get _body => const Color(ClassicAtsTemplateSupport.bodyHex);
  Color get _muted => const Color(ClassicAtsTemplateSupport.mutedHex);
  Color get _dateBg => const Color(ClassicAtsTemplateSupport.dateBgHex);
  Color get _sectionBg => _accent.withValues(alpha: 0.07);
  Color get _chipBg => _accent.withValues(alpha: 0.05);
  Color get _chipBorder => _accent.withValues(alpha: 0.30);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'JOHN SMITH';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  String get _contactLine {
    final value = ClassicAtsTemplateSupport.contactBarText(
      resume?.personalInfo,
      compactLinks: true,
      maxItems: 4,
    );
    return value.isNotEmpty
        ? value
        : 'john.smith@email.com  |  (555) 123-4567  |  New York, NY';
  }

  List<String> get _summaryLines {
    final values = ClassicAtsTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
          ];
  }

  List<ClassicAtsExperienceEntry> get _experiences {
    final values = ClassicAtsTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: 1,
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            ClassicAtsExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp  •  Remote',
              dateRange: '2021 - Present',
              detailLines: [
                'Led a team of 5 to deliver a cloud-based platform.',
              ],
            ),
          ];
  }

  List<String> get _skills {
    final values = ClassicAtsTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 5,
    );
    return values.isNotEmpty
        ? values
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
  }

  List<ClassicAtsEducationEntry> get _educations {
    final values = ClassicAtsTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      maxSupportingLines: 1,
      yearOnly: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            ClassicAtsEducationEntry(
              degree: 'B.Sc. Computer Science Software Engineering',
              institutionLine: 'State University',
              dateRange: '2019',
            ),
          ];
  }

  List<String> get _languages {
    final values = ClassicAtsTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    return values.isNotEmpty
        ? values
        : const ['English Professional', 'German Professional'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('PROFESSIONAL SUMMARY'),
                    const SizedBox(height: 4),
                    ..._summaryLines.map(_summaryLine),
                    const SizedBox(height: 10),
                    _sectionHeader('WORK EXPERIENCE'),
                    const SizedBox(height: 4),
                    ..._experiences.map(_experienceBlock),
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _sectionHeader('SKILLS'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _skills.map(_skillChip).toList(growable: false),
                      ),
                    ],
                    if (_educations.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _sectionHeader('EDUCATION'),
                      const SizedBox(height: 4),
                      ..._educations.map(_educationBlock),
                    ],
                    if (_languages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _sectionHeader('LANGUAGES'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _languages
                            .map(_languageChip)
                            .toList(growable: false),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _headerBg,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              _text(
                _name.toUpperCase(),
                size: 9.4,
                color: Colors.white,
                weight: FontWeight.w900,
                center: true,
                letterSpacing: 0.2,
              ),
              const SizedBox(height: 1),
              _text(
                _title.toUpperCase(),
                size: 4.15,
                color: _accent,
                weight: FontWeight.w800,
                center: true,
              ),
            ],
          ),
        ),
        Container(
          color: _accent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: _text(
            _contactLine,
            size: 3.05,
            color: Colors.white,
            center: true,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
      decoration: BoxDecoration(
        color: _sectionBg,
        border: Border(left: BorderSide(color: _accent, width: 3.2)),
      ),
      child: _text(
        label,
        size: 4.8,
        color: _ink,
        weight: FontWeight.w800,
      ),
    );
  }

  Widget _summaryLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 3, right: 5),
            decoration: BoxDecoration(
              color: _ink,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: _text(
              line,
              size: 3.45,
              color: _body,
              justify: true,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceBlock(ClassicAtsExperienceEntry entry) {
    final detail = entry.detailLines.take(2).join(' ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _text(
                  entry.title,
                  size: 4.45,
                  color: _ink,
                  weight: FontWeight.w800,
                  maxLines: 2,
                ),
                const SizedBox(height: 1),
                _text(
                  entry.companyLine,
                  size: 3.55,
                  color: _accent,
                  weight: FontWeight.w700,
                  maxLines: 1,
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  _text(
                    detail,
                    size: 3.3,
                    color: _body,
                    justify: true,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: _dateBg,
                child: _text(
                  entry.dateRange,
                  size: 2.9,
                  color: _ink,
                  weight: FontWeight.w700,
                  alignRight: true,
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationBlock(ClassicAtsEducationEntry entry) {
    final institutionLine = [
      entry.institutionLine,
      entry.dateRange,
    ].where((part) => part.trim().isNotEmpty).join('  •  ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(
            entry.degree,
            size: 4.45,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 2,
          ),
          const SizedBox(height: 1),
          _text(
            institutionLine,
            size: 3.45,
            color: _accent,
            weight: FontWeight.w700,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _chipBorder, width: 1.1),
      ),
      child: _text(
        skill,
        size: 3.2,
        color: _ink,
        weight: FontWeight.w600,
      ),
    );
  }

  Widget _languageChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: _text(
        value,
        size: 3.15,
        color: Colors.white,
        weight: FontWeight.w700,
      ),
    );
  }

  Widget _text(
    String value, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    bool center = false,
    bool alignRight = false,
    bool justify = false,
    int? maxLines = 1,
    double letterSpacing = 0,
  }) {
    return Text(
      value,
      maxLines: maxLines == 0 ? null : maxLines,
      overflow: maxLines == null || maxLines == 0
          ? TextOverflow.visible
          : TextOverflow.ellipsis,
      textAlign: center
          ? TextAlign.center
          : alignRight
              ? TextAlign.right
              : justify
                  ? TextAlign.justify
                  : TextAlign.left,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.22,
        letterSpacing: letterSpacing,
      ),
    );
  }
}