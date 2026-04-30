import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class DeveloperResumeTemplatePreview extends StatelessWidget {
  const DeveloperResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _hero => const Color(0xFF0F172A);
  Color get _panel => const Color(0xFFF8FAFC);
  Color get _ink => const Color(0xFF111827);
  Color get _muted => const Color(0xFF64748B);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<String> get _contactLines {
    final info = resume?.personalInfo;
    final lines = <String>[
      if ((info?.email ?? '').trim().isNotEmpty) info!.email.trim(),
      if ((info?.phone ?? '').trim().isNotEmpty) info!.phone.trim(),
      if ((info?.address ?? '').trim().isNotEmpty) info!.address.trim(),
      if ((info?.linkedIn ?? '').trim().isNotEmpty)
        _compactUrl(info!.linkedIn!.trim()),
      if ((info?.github ?? '').trim().isNotEmpty)
        _compactUrl(info!.github!.trim()),
      if ((info?.website ?? '').trim().isNotEmpty)
        _compactUrl(info!.website!.trim()),
    ];

    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'john.smith@email.com',
      '(555) 123-4567',
      'New York, NY',
      'linkedin.com/in/johnsmith',
      'github.com/johnsmith',
      'johnsmith.dev',
    ];
  }

  List<String> get _summaryLines {
    final lines = _splitLines(resume?.objective ?? '', maxItems: 2);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
    ];
  }

  _DeveloperPreviewExperience get _experience {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const _DeveloperPreviewExperience(
        title: 'Senior Developer',
        companyLine: 'TechCorp',
        range: '2021 - Present',
        detail: 'Led team of 5 to deliver cloud-based platform',
      );
    }

    final experience = values.first;
    final details = <String>[];
    for (final achievement in experience.achievements) {
      final trimmed = achievement.trim();
      if (trimmed.isNotEmpty && !details.contains(trimmed)) {
        details.add(trimmed);
      }
    }
    for (final line in _splitLines(experience.description, maxItems: 2)) {
      if (!details.contains(line)) {
        details.add(line);
      }
    }

    final end = experience.isCurrentlyWorking
        ? 'Present'
        : (experience.endDate?.year.toString() ?? 'Present');

    return _DeveloperPreviewExperience(
      title: experience.position.trim().isNotEmpty
          ? experience.position.trim()
          : 'Role',
      companyLine: experience.company.trim().isNotEmpty
          ? experience.company.trim()
          : 'Company',
      range: '${experience.startDate.year} - $end',
      detail: details.isNotEmpty ? details.first : '',
    );
  }

  _DeveloperPreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _DeveloperPreviewEducation(
        degree: 'B.Sc. Computer Science Engineering',
        institution: 'State University • 2019',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final institution = education.institution.trim().isNotEmpty
        ? education.institution.trim()
        : 'Institution';
    final year = (education.endDate ?? education.startDate).year;

    return _DeveloperPreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: '$institution • $year',
    );
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const ['Flutter', 'Dart', 'Firebase'];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  _DeveloperPreviewProject get _project {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const _DeveloperPreviewProject(
        title: 'Portfolio Website',
        description:
            'Developed a responsive portfolio site showcasing projects and skills.',
      );
    }

    final project = values.first;
    final description = project.description.trim().isNotEmpty
        ? project.description.trim()
        : project.technologies.join(', ');

    return _DeveloperPreviewProject(
      title: project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
      description: description,
    );
  }

  String get _certification {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return 'AWS Certified Developer • Amazon';
    }

    final certification = values.first;
    final issuer = certification.issuer.trim();
    return issuer.isNotEmpty
        ? '${certification.name} • $issuer'
        : certification.name;
  }

  List<String> get _languages {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const ['English Professional', 'German Professional'];
    }

    return values
        .map((language) {
          final proficiency = language.proficiency.trim();
          return proficiency.isNotEmpty
              ? '${language.name} ${language.proficiency}'
              : language.name;
        })
        .where((language) => language.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  String _compactUrl(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return '';
    }

    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  String _cleanMarker(String text) {
    return text.trim().replaceFirst(RegExp(r'^[-*]+\s*'), '');
  }

  List<String> _splitLines(String text, {int? maxItems}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final values = trimmed
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanMarker)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return values;
    }

    return values.take(maxItems).toList(growable: false);
  }

  Widget _text(
    String text, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.normal,
    int maxLines = 1,
  }) {
    return Text(
      text,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: 1.12,
      ),
    );
  }

  Widget _sectionTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _hero,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _text(
        '[ $text ]',
        size: 3.5,
        color: Colors.white,
        weight: FontWeight.bold,
      ),
    );
  }

  Widget _summaryPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _summaryLines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 1.2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text('>',
                        size: 3.1, color: _accent, weight: FontWeight.w700),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _text(
                        line,
                        size: 3.2,
                        color: Colors.grey.shade700,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
              decoration: BoxDecoration(
                color: _hero,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    _name,
                    size: 7.4,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 1),
                  _text(
                    '< ${_title.toUpperCase()} />',
                    size: 3.8,
                    color: _accent,
                    weight: FontWeight.w600,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 1.5),
                  ..._contactLines.map(
                    (line) => _text(
                      line,
                      size: 3.0,
                      color: Colors.white.withValues(alpha: 0.78),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTag('SUMMARY'),
                      const SizedBox(height: 2),
                      _summaryPanel(),
                      const SizedBox(height: 3),
                      _sectionTag('EXPERIENCE'),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _panel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _text(
                                    _experience.title,
                                    size: 4.0,
                                    color: Colors.grey.shade900,
                                    weight: FontWeight.bold,
                                    maxLines: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _hero,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: _text(
                                    _experience.range,
                                    size: 2.9,
                                    color: Colors.white,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            _text(
                              _experience.companyLine,
                              size: 3.3,
                              color: _accent,
                              weight: FontWeight.w600,
                              maxLines: 1,
                            ),
                            if (_experience.detail.isNotEmpty)
                              _text(
                                '> ${_experience.detail}',
                                size: 3.1,
                                color: Colors.grey.shade700,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      _sectionTag('EDUCATION'),
                      const SizedBox(height: 2),
                      _text(
                        _education.degree,
                        size: 4.0,
                        color: Colors.grey.shade900,
                        weight: FontWeight.bold,
                        maxLines: 1,
                      ),
                      _text(
                        _education.institution,
                        size: 3.1,
                        color: Colors.grey.shade700,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      _sectionTag('TECH STACK'),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: _skills
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _hero,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _text(
                                  skill,
                                  size: 3.5,
                                  color: Colors.white,
                                  weight: FontWeight.bold,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 3),
                      _sectionTag('PROJECTS'),
                      const SizedBox(height: 2),
                      _text(
                        _project.title,
                        size: 3.4,
                        color: Colors.grey.shade900,
                        weight: FontWeight.w600,
                        maxLines: 1,
                      ),
                      _text(
                        _project.description,
                        size: 3.0,
                        color: Colors.grey.shade700,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      _sectionTag('CERTIFICATIONS'),
                      const SizedBox(height: 2),
                      _text(
                        _certification,
                        size: 3.0,
                        color: Colors.grey.shade700,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      _sectionTag('LANGUAGES'),
                      const SizedBox(height: 2),
                      ..._languages.map(
                        (language) => _text(
                          language,
                          size: 3.0,
                          color: Colors.grey.shade700,
                          maxLines: 1,
                        ),
                      ),
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
}

class _DeveloperPreviewExperience {
  const _DeveloperPreviewExperience({
    required this.title,
    required this.companyLine,
    required this.range,
    required this.detail,
  });

  final String title;
  final String companyLine;
  final String range;
  final String detail;
}

class _DeveloperPreviewEducation {
  const _DeveloperPreviewEducation({
    required this.degree,
    required this.institution,
  });

  final String degree;
  final String institution;
}

class _DeveloperPreviewProject {
  const _DeveloperPreviewProject({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
