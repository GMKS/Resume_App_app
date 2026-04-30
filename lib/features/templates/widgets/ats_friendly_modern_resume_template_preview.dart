import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../ats_friendly_modern_template_support.dart';

class AtsFriendlyModernResumeTemplatePreview extends StatelessWidget {
  const AtsFriendlyModernResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  static const double _dateLaneWidth = 38;

  Color get _pageBg => const Color(AtsFriendlyModernTemplateSupport.pageHex);
  Color get _ink => const Color(AtsFriendlyModernTemplateSupport.inkHex);
  Color get _body => const Color(AtsFriendlyModernTemplateSupport.bodyHex);
  Color get _muted => const Color(AtsFriendlyModernTemplateSupport.mutedHex);
  Color get _divider =>
      const Color(AtsFriendlyModernTemplateSupport.dividerHex);
  Color get _tag => const Color(AtsFriendlyModernTemplateSupport.tagHex);
  Color get _rule => const Color(AtsFriendlyModernTemplateSupport.ruleHex);
  Color get _accent => const Color(AtsFriendlyModernTemplateSupport.accentHex);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<String> get _primaryContacts {
    final values = AtsFriendlyModernTemplateSupport.primaryContactItems(
      resume?.personalInfo,
    );
    return values.isNotEmpty
        ? values
        : const ['john.smith@email.com', '(555) 123-4567', 'New York, NY'];
  }

  List<String> get _secondaryContacts {
    final values = AtsFriendlyModernTemplateSupport.secondaryContactItems(
      resume?.personalInfo,
    );
    return values.isNotEmpty
        ? values
        : const [
            'linkedin.com/in/johnsmith',
            'github.com/johnsmith',
            'johnsmith.dev',
          ];
  }

  List<String> get _summaryLines {
    final values = AtsFriendlyModernTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
          ];
  }

  List<String> get _skills {
    final values = AtsFriendlyModernTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    return values.isNotEmpty
        ? values
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
  }

  List<AtsFriendlyModernExperienceEntry> get _experiences {
    final values = AtsFriendlyModernTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
    );
    return values.isNotEmpty
        ? values
        : const [
            AtsFriendlyModernExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp, Inc.',
              dateRange: 'Jan 2021 - Present',
              detailLines: [
                'Led team of 5 to deliver cloud-based platform.',
                'Reduced load time by 40% through code optimization.',
              ],
            ),
          ];
  }

  List<AtsFriendlyModernEducationEntry> get _educations {
    final values = AtsFriendlyModernTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
    );
    return values.isNotEmpty
        ? values
        : const [
            AtsFriendlyModernEducationEntry(
              degree: 'B.Sc. Computer Science Software Engineering',
              institutionLine: 'State University',
              yearLabel: '2020',
            ),
          ];
  }

  List<AtsFriendlyModernProjectEntry> get _projects {
    final values = AtsFriendlyModernTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 1,
      maxDetailLines: null,
    );
    return values.isNotEmpty
        ? values
        : const [
            AtsFriendlyModernProjectEntry(
              title: 'Portfolio Website',
              detailLines: [
                'Developed a responsive portfolio site showcasing projects and skills.',
              ],
              links: ['johnsmith.dev/portfolio'],
            ),
          ];
  }

  List<String> get _certifications {
    final values = AtsFriendlyModernTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: 1,
    );
    return values.isNotEmpty
        ? values
        : const ['AWS Certified Developer  •  Amazon'];
  }

  List<String> get _languageLabels {
    final values = AtsFriendlyModernTemplateSupport.languageLabels(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    return values.isNotEmpty
        ? values
      : const ['English - Professional', 'German - Professional'];
  }

  @override
  Widget build(BuildContext context) {
    final project = _projects.first;
    final education = _educations.first;

    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              _name.toUpperCase(),
              size: 8.5,
              color: _ink,
              weight: FontWeight.w900,
            ),
            const SizedBox(height: 1.5),
            Container(height: 0.45, width: double.infinity, color: _divider),
            const SizedBox(height: 2),
            _text(_title, size: 4.45, color: _body, maxLines: 2),
            if (_primaryContacts.isNotEmpty)
              _text(
                _primaryContacts.join('  ·  '),
                size: 2.85,
                color: _muted,
                maxLines: 2,
              ),
            if (_secondaryContacts.isNotEmpty)
              _text(
                _secondaryContacts.join('  ·  '),
                size: 2.85,
                color: _muted,
                maxLines: 2,
              ),
            const SizedBox(height: 5),
            _sectionHeader('SUMMARY'),
            ..._summaryLines.map(_summaryLine),
            const SizedBox(height: 4),
            _sectionHeader('SKILLS'),
            Wrap(
              spacing: 3,
              runSpacing: 2,
              children: _skills.map(_skillChip).toList(growable: false),
            ),
            const SizedBox(height: 4),
            _sectionHeader('EXPERIENCE'),
            ..._experiences.map(_experienceBlock),
            const SizedBox(height: 1),
            _sectionHeader('EDUCATION'),
            _educationBlock(education),
            const SizedBox(height: 4),
            _sectionHeader('PROJECTS'),
            _projectBlock(project),
            const SizedBox(height: 4),
            _sectionHeader('CERTIFICATIONS'),
            ..._certifications.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 0.8),
                child: _text(
                  line,
                  size: 3.05,
                  color: _ink,
                  weight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 3),
            _sectionHeader('LANGUAGES'),
            _text(
              _languageLabels.join(', '),
              size: 3.0,
              color: _body,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: _tag,
            child: _text(
              title,
              size: 3.45,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _rule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              margin: const EdgeInsets.only(top: 1.2, right: 3.4),
              width: 3.2,
              height: 3.2,
              color: _accent,
            ),
          ),
          Expanded(
            child: _text(
              line,
              size: 2.88,
              color: _body,
              maxLines: 0,
              justify: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _text(
        skill,
        size: 2.8,
        color: Colors.white,
        weight: FontWeight.w700,
      ),
    );
  }

  Widget _experienceBlock(AtsFriendlyModernExperienceEntry entry) {
    return Padding(
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
                  size: 3.7,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              SizedBox(
                width: _dateLaneWidth,
                child: _text(
                  entry.dateRange,
                  size: 2.7,
                  color: _muted,
                  alignRight: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          _text(entry.companyLine, size: 2.95, color: _accent, maxLines: 2),
          ...entry.detailLines.map(_detailLine),
        ],
      ),
    );
  }

  Widget _detailLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('-', size: 2.85, color: _body),
          const SizedBox(width: 2),
          Expanded(
            child: _text(
              line,
              size: 2.78,
              color: _body,
              maxLines: 0,
              justify: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationBlock(AtsFriendlyModernEducationEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  entry.degree,
                  size: 3.65,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              SizedBox(
                width: _dateLaneWidth,
                child: _text(
                  entry.yearLabel,
                  size: 2.7,
                  color: _muted,
                  alignRight: true,
                ),
              ),
            ],
          ),
          _text(entry.institutionLine, size: 2.95, color: _body, maxLines: 2),
        ],
      ),
    );
  }

  Widget _projectBlock(AtsFriendlyModernProjectEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            entry.title,
            size: 3.45,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 2,
          ),
          ...entry.detailLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 0.4),
              child: _text(
                line,
                size: 2.8,
                color: _body,
                maxLines: 0,
                justify: true,
              ),
            ),
          ),
          ...entry.links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(top: 0.4),
              child: _text(
                link,
                size: 2.7,
                color: _accent,
                maxLines: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(
    String text, {
    double size = 5,
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
