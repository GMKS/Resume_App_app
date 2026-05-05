import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class PinkRoseModernTemplatePreview extends StatelessWidget {
  const PinkRoseModernTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _rose => const Color(0xFFD87093);
  Color get _roseDeep => const Color(0xFF8B4962);
  Color get _paper => const Color(0xFFFCF8FA);
  Color get _ink => const Color(0xFF2E2430);
  Color get _muted => const Color(0xFF6F6570);
  Color get _rule => const Color(0xFFE8D6DE);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<String> get _contactItems {
    final info = resume?.personalInfo;
    final values = <String>[
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

    if (values.isNotEmpty) {
      return values.take(6).toList(growable: false);
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
    final lines = _splitLines(resume?.objective ?? '', maxItems: 6);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven engineer with a strong foundation in reliable delivery, quality engineering, and maintainable product systems.',
      'Builds usable tools, improves team velocity, and keeps polished output aligned with real resume content.',
    ];
  }

  List<_PinkPreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _PinkPreviewExperience(
          title: 'Automation Lead',
          companyLine: 'TechCorp | Hyderabad, India',
          range: 'Feb 2019 - Mar 2025',
          detailLines: [
            'Led automation delivery and improved release confidence across UI and services.',
            'Guided framework evolution and coordinated updates across QA teams.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final detailLines = <String>[];
      for (final line in _splitLines(experience.description, maxItems: 2)) {
        if (!detailLines.contains(line)) {
          detailLines.add(line);
        }
      }
      for (final achievement in experience.achievements) {
        final trimmed = achievement.trim();
        if (trimmed.isNotEmpty && !detailLines.contains(trimmed)) {
          detailLines.add(trimmed);
        }
      }

      final location = (experience.location ?? '').trim();
      final company = experience.company.trim().isNotEmpty
          ? experience.company.trim()
          : 'Company';
      final range =
          '${_monthYear(experience.startDate)} - ${experience.isCurrentlyWorking ? 'Present' : _monthYear(experience.endDate ?? experience.startDate)}';

      return _PinkPreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: location.isNotEmpty ? '$company | $location' : company,
        range: range,
        detailLines: detailLines.take(3).toList(growable: false),
      );
    }).toList(growable: false);
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const ['React', 'JavaScript', 'Communication', 'SQL'];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(8)
        .toList(growable: false);
  }

  List<String> get _languageLines {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const [
        'English (Professional)',
        'German (Professional)',
      ];
    }

    return values
        .map((language) => language.proficiency.trim().isNotEmpty
            ? '${language.name} (${language.proficiency})'
            : language.name)
        .where((line) => line.trim().isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  _PinkPreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _PinkPreviewEducation(
        degree: 'B.Sc. Computer Science',
        institution: 'State University | 2020',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final institution = education.institution.trim().isNotEmpty
        ? education.institution.trim()
        : 'Institution';
    final year = (education.endDate ?? education.startDate).year;

    return _PinkPreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: '$institution | $year',
    );
  }

  List<_PinkPreviewProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _PinkPreviewProject(
          title: 'Resumix AI',
          description:
              'Live preview and export workflow for template-based resumes.',
          url: 'resumebuilder.dev',
        ),
      ];
    }

    return values.take(2).map((project) {
      final description = project.description.trim().isNotEmpty
          ? project.description.trim()
          : project.technologies.join(', ');
      return _PinkPreviewProject(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        description: description,
        url: _compactUrl(project.url ?? ''),
      );
    }).toList(growable: false);
  }

  List<String> get _certifications {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const ['AWS Certified Developer | Amazon'];
    }

    return values
        .map((certification) {
          final issuer = certification.issuer.trim();
          return issuer.isNotEmpty
              ? '${certification.name} | $issuer'
              : certification.name;
        })
        .where((line) => line.trim().isNotEmpty)
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

  String _monthYear(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _cleanMarker(String text) {
    return text.trim().replaceFirst(RegExp(r'^[-•*▪■□✦★☆]+\s*'), '');
  }

  List<String> _splitLines(String text, {int? maxItems}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final values = trimmed
        .split(RegExp(r'\n+|[•▪]+|(?<=[.!?])\s+'))
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
    TextAlign align = TextAlign.left,
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
        height: 1.15,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text(title, size: 3.2, color: _rose, weight: FontWeight.bold),
        const SizedBox(height: 2.2),
        Row(
          children: [
            Expanded(child: Container(height: 0.8, color: _rule)),
            const SizedBox(width: 2),
            Container(width: 1.6, height: 6, color: _accent),
          ],
        ),
      ],
    );
  }

  Widget _summaryBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right_alt_rounded, size: 5.5, color: _rose),
          const SizedBox(width: 1.4),
          Expanded(
            child: _text(
              text,
              size: 2.95,
              color: _muted,
              maxLines: 2,
              align: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.8),
      child: _text(
        text,
        size: 2.72,
        color: _muted,
        maxLines: 2,
        align: TextAlign.justify,
      ),
    );
  }

  Widget _projectBlock(_PinkPreviewProject project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            project.title,
            size: 2.85,
            color: _ink,
            weight: FontWeight.w700,
          ),
          if (project.description.isNotEmpty)
            _text(
              project.description,
              size: 2.68,
              color: _muted,
              maxLines: 2,
              align: TextAlign.justify,
            ),
          if (project.url.isNotEmpty)
            _text(project.url, size: 2.55, color: _roseDeep, maxLines: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 2, width: 34, color: _rose),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _rule, width: 0.9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    _name.toUpperCase(),
                    size: 8.1,
                    color: _ink,
                    weight: FontWeight.w800,
                  ),
                  _text(
                    _title,
                    size: 4,
                    color: _roseDeep,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: _contactItems
                        .map(
                          (item) => _text(
                            item,
                            size: 2.68,
                            color: _muted,
                            maxLines: 1,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            _sectionHeader('PROFILE'),
            const SizedBox(height: 2.2),
            ..._summaryLines.take(5).map(_summaryBullet),
            const SizedBox(height: 3),
            _sectionHeader('EXPERIENCE'),
            const SizedBox(height: 2.2),
            ..._experiences.map(
              (experience) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
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
                                experience.title,
                                size: 4,
                                color: _ink,
                                weight: FontWeight.w700,
                              ),
                              _text(
                                experience.companyLine,
                                size: 2.88,
                                color: _roseDeep,
                                weight: FontWeight.w600,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 34,
                          child: _text(
                            experience.range,
                            size: 2.62,
                            color: _muted,
                            maxLines: 2,
                            align: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1.2),
                    ...experience.detailLines.take(3).map(_detailLine),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            _sectionHeader('SKILLS'),
            const SizedBox(height: 2.2),
            _text(
              _skills.join(' - '),
              size: 2.75,
              color: _muted,
              maxLines: 3,
              align: TextAlign.justify,
            ),
            const SizedBox(height: 3),
            _sectionHeader('LANGUAGES'),
            const SizedBox(height: 2.2),
            _text(
              _languageLines.join(' - '),
              size: 2.75,
              color: _muted,
              maxLines: 3,
              align: TextAlign.justify,
            ),
            const SizedBox(height: 3),
            _sectionHeader('EDUCATION'),
            const SizedBox(height: 2.2),
            _text(
              _education.degree,
              size: 3.08,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 2,
            ),
            _text(
              _education.institution,
              size: 2.72,
              color: _muted,
              maxLines: 2,
            ),
            if (_projects.isNotEmpty) ...[
              const SizedBox(height: 3),
              _sectionHeader('PROJECTS'),
              const SizedBox(height: 2.2),
              ..._projects.map(_projectBlock),
            ],
            if (_certifications.isNotEmpty) ...[
              const SizedBox(height: 3),
              _sectionHeader('CERTIFICATIONS'),
              const SizedBox(height: 2.2),
              ..._certifications.map(
                (line) => _text(
                  line,
                  size: 2.72,
                  color: _muted,
                  maxLines: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinkPreviewExperience {
  const _PinkPreviewExperience({
    required this.title,
    required this.companyLine,
    required this.range,
    required this.detailLines,
  });

  final String title;
  final String companyLine;
  final String range;
  final List<String> detailLines;
}

class _PinkPreviewEducation {
  const _PinkPreviewEducation({
    required this.degree,
    required this.institution,
  });

  final String degree;
  final String institution;
}

class _PinkPreviewProject {
  const _PinkPreviewProject({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}
