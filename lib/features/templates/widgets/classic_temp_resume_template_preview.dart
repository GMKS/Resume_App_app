import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../classic_temp_template_support.dart';

class ClassicTempResumeTemplatePreview extends StatelessWidget {
  const ClassicTempResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent =>
      templateColor ?? const Color(ClassicTempTemplateSupport.accentHex);
  Color get _ink => const Color(ClassicTempTemplateSupport.inkHex);
  Color get _muted => const Color(ClassicTempTemplateSupport.mutedHex);
  Color get _subtle => const Color(ClassicTempTemplateSupport.subtleHex);
  Color get _pageBg => const Color(ClassicTempTemplateSupport.pageHex);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'Jordan Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Software Engineer';
  }

  List<String> get _contactLines {
    final values =
        ClassicTempTemplateSupport.contactLines(resume?.personalInfo);
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      '+1 555 0100  |  jordan@example.com',
      'Seattle, WA',
      'linkedin.com/in/jordansmith  |  github.com/jordansmith  |  jordansmith.dev',
    ];
  }

  List<String> get _summaryLines {
    final values = ClassicTempTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      'Results-driven engineer who improves resume output fidelity, rendering consistency, and template isolation across web and PDF flows.',
    ];
  }

  List<ClassicTempExperienceEntry> get _experiences {
    final values = ClassicTempTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 1,
      maxDetailLines: 1,
      yearOnly: true,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      ClassicTempExperienceEntry(
        title: 'Senior Flutter Developer',
        companyLine: 'Bluewave Labs - Remote',
        dateRange: '2022 - 2026',
        detailLines: [
          'Aligned resume previews with exported PDF layouts without breaking existing templates.',
        ],
      ),
    ];
  }

  List<ClassicTempEducationEntry> get _education {
    final values = ClassicTempTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      maxDetailLines: 1,
      yearOnly: true,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      ClassicTempEducationEntry(
        degree: 'B.Sc. Computer Science',
        institutionLine: 'State University',
        dateRange: '2016 - 2020',
      ),
    ];
  }

  List<String> get _skills {
    final values = ClassicTempTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const ['Flutter', 'Dart', 'Firebase', 'Testing', 'CI/CD'];
  }

  List<ClassicTempProjectEntry> get _projects {
    final values = ClassicTempTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 1,
      maxDetailLines: 1,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      ClassicTempProjectEntry(
        title: 'Resume Builder',
        detailLines: [
          'Maintains preview and export parity for resume layouts.'
        ],
        links: ['example.com/resume-builder'],
      ),
    ];
  }

  List<ClassicTempCertificationEntry> get _certifications {
    final values = ClassicTempTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 1,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      ClassicTempCertificationEntry(
        title: 'AWS Certified Developer',
        supportingLines: ['Amazon'],
      ),
    ];
  }

  List<String> get _languages {
    final values = ClassicTempTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    if (values.isNotEmpty) {
      return values;
    }

    return const ['English - Native'];
  }

  Widget _text(
    String text, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.normal,
    TextAlign align = TextAlign.left,
    int maxLines = 1,
  }) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: 1.18,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.2, bottom: 1.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _text(
            title,
            size: 4.1,
            color: _accent,
            weight: FontWeight.w700,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 0.8,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBulletLines(List<String> lines, {int maxLines = 2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 0.9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.1),
                    child: _text(
                      '\u2192',
                      size: 3.15,
                      color: _accent,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2.6),
                  Expanded(
                    child: _text(
                      line,
                      size: 2.85,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: maxLines,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _bulletLines(List<String> lines, {int maxLines = 2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 0.8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.4),
                    child: Container(
                      width: 2.5,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2.6),
                  Expanded(
                    child: _text(
                      line,
                      size: 2.72,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: maxLines,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _experienceBlock(ClassicTempExperienceEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.2),
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
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: _text(
                  entry.dateRange,
                  size: 2.55,
                  color: _subtle,
                  align: TextAlign.right,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 0.8),
          _text(
            entry.companyLine,
            size: 2.9,
            color: _subtle,
            maxLines: 1,
          ),
          if (entry.detailLines.isNotEmpty) ...[
            const SizedBox(height: 0.8),
            _bulletLines(entry.detailLines, maxLines: 2),
          ],
        ],
      ),
    );
  }

  Widget _educationBlock(ClassicTempEducationEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  entry.degree,
                  size: 3.5,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 34,
                child: _text(
                  entry.dateRange,
                  size: 2.5,
                  color: _subtle,
                  align: TextAlign.right,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 0.8),
          _text(
            entry.institutionLine,
            size: 2.82,
            color: _subtle,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _projectBlock(ClassicTempProjectEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            entry.title,
            size: 3.4,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 1,
          ),
          if (entry.links.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0.5),
              child: _text(
                entry.links.first,
                size: 2.55,
                color: _accent,
                maxLines: 1,
              ),
            ),
          if (entry.detailLines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0.6),
              child: _text(
                entry.detailLines.first,
                size: 2.72,
                color: _muted,
                align: TextAlign.justify,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(
            _name.toUpperCase(),
            size: 9.35,
            color: _ink,
            weight: FontWeight.w900,
            align: TextAlign.center,
          ),
          const SizedBox(height: 1.2),
          _text(
            _title,
            size: 4.0,
            color: _subtle,
            align: TextAlign.center,
          ),
          const SizedBox(height: 2.4),
          ..._contactLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 0.8),
              child: _text(
                line,
                size: 2.7,
                color: _subtle,
                align: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 2.2),
          Container(height: 1.0, color: _accent),
          _sectionHeader('PROFILE'),
          _summaryBulletLines(
            _summaryLines,
            maxLines: _summaryLines.length == 1 ? 4 : 2,
          ),
          _sectionHeader('EXPERIENCE'),
          ..._experiences.map(_experienceBlock),
          _sectionHeader('EDUCATION'),
          ..._education.map(_educationBlock),
          _sectionHeader('SKILLS'),
          _text(
            _skills.join('  |  '),
            size: 2.75,
            color: _muted,
            align: TextAlign.justify,
            maxLines: 2,
          ),
          _sectionHeader('PROJECTS'),
          ..._projects.map(_projectBlock),
          if (_certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS'),
            _text(
              _certifications.first.title,
              size: 2.72,
              color: _muted,
              maxLines: 1,
            ),
          ],
          if (_languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES'),
            _text(
              _languages.join('  |  '),
              size: 2.7,
              color: _muted,
              align: TextAlign.justify,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}
