import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class AcademicResumeTemplatePreview extends StatelessWidget {
  const AcademicResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _pageBg => const Color(0xFFFAF8F5);
  Color get _ink => const Color(0xFF2D2D2D);
  Color get _muted => const Color(0xFF555555);
  Color get _rule => _accent.withValues(alpha: 0.38);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value.toUpperCase() : 'JOHN SMITH';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<String> get _contactLines {
    final info = resume?.personalInfo;
    final primary = <String>[];
    final secondary = <String>[];

    void addPrimary(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        primary.add(trimmed);
      }
    }

    void addSecondary(String? value, {bool compact = false}) {
      var trimmed = value?.trim() ?? '';
      if (compact) {
        trimmed = _compactLink(trimmed);
      }
      if (trimmed.isNotEmpty) {
        secondary.add(trimmed);
      }
    }

    addPrimary(info?.email);
    addPrimary(info?.phone);
    addSecondary(info?.address);
    addSecondary(info?.linkedIn, compact: true);
    addSecondary(info?.github, compact: true);
    addSecondary(info?.website, compact: true);

    final lines = <String>[];
    if (primary.isNotEmpty) {
      lines.add(primary.join('  |  '));
    }
    if (secondary.isNotEmpty) {
      lines.add(secondary.join('  |  '));
    }
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'john.smith@email.com  |  (555) 123-4567',
      'linkedin.com/in/johnsmith  |  github.com/johnsmith  |  johnsmith.dev',
    ];
  }

  List<String> get _objectiveLines {
    final values = _splitLines(resume?.objective ?? '').take(4).toList();
    if (values.isNotEmpty) {
      return values;
    }

    return const [
      'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
    ];
  }

  _AcademicEducationPreview get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _AcademicEducationPreview(
        degree: 'B.Sc. Computer Science Software Engineering',
        subtitle: 'State University  ·  2019',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final parts = <String>[];
    if (education.institution.trim().isNotEmpty) {
      parts.add(education.institution.trim());
    }
    if ((education.location ?? '').trim().isNotEmpty) {
      parts.add(education.location!.trim());
    }
    parts.add(
      education.isCurrentlyStudying
          ? 'Present'
          : (education.endDate?.year.toString() ??
              education.startDate.year.toString()),
    );

    return _AcademicEducationPreview(
      degree: degree.isNotEmpty ? degree : 'Education',
      subtitle: parts.join('  ·  '),
    );
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  List<_AcademicExperiencePreview> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _AcademicExperiencePreview(
          title: 'Senior Developer',
          companyLine: 'TechCorp',
          dateRange: '2021 - Present',
          detail: 'Led team of 5 to deliver cloud-based platform',
        ),
      ];
    }

    return values.take(1).map((experience) {
      final company = experience.company.trim();
      final location = experience.location?.trim() ?? '';
      final companyLine = [
        if (company.isNotEmpty) company,
        if (location.isNotEmpty) location,
      ].join('  ·  ');
      final details = <String>[];
      for (final achievement in experience.achievements) {
        final trimmed = achievement.trim();
        if (trimmed.isNotEmpty) {
          details.add(trimmed);
        }
      }
      if (experience.description.trim().isNotEmpty) {
        details.addAll(_splitLines(experience.description));
      }
      final detail = details.isEmpty ? '' : details.first;
      final end = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ??
              experience.startDate.year.toString());

      return _AcademicExperiencePreview(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: '${experience.startDate.year} - $end',
        detail: detail,
      );
    }).toList(growable: false);
  }

  List<String> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const ['Portfolio Website', 'Task Management App'];
    }

    return values
        .map((project) => project.title.trim())
        .where((title) => title.isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  List<String> get _certifications {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const [
        'AWS Certified Developer - Amazon',
        'Scrum Master - Scrum Alliance',
      ];
    }

    return values
        .map((certification) {
          final issuer = certification.issuer.trim();
          return issuer.isNotEmpty
              ? '${certification.name} - $issuer'
              : certification.name;
        })
        .where((label) => label.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
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
              ? '${language.name} $proficiency'
              : language.name;
        })
        .where((label) => label.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3.2, color: _accent),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(
                  _name,
                  size: 8.0,
                  color: _ink,
                  weight: FontWeight.bold,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                _text(
                  _title,
                  size: 4.4,
                  color: _accent,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Container(height: 0.7, color: _ink),
                const SizedBox(height: 1.5),
                Container(height: 0.3, color: const Color(0xFFCCCCCC)),
                const SizedBox(height: 3),
                ..._contactLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 0.7),
                    child: _text(
                      line,
                      size: 3.05,
                      color: _muted,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('OBJECTIVE'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _objectiveLines
                                .map(_objectiveBullet)
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('EDUCATION'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _text(
                                _education.degree,
                                size: 5.0,
                                color: _accent,
                                weight: FontWeight.w700,
                                maxLines: 2,
                              ),
                              _text(
                                _education.subtitle,
                                size: 3.9,
                                color: _muted,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('SKILLS'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Wrap(
                            spacing: 3,
                            runSpacing: 2,
                            children:
                                _skills.map(_skillChip).toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('EXPERIENCE'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            children: _experiences
                                .map(_experienceBlock)
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('PROJECTS'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _projects
                                .map(
                                  (project) => Padding(
                                    padding: const EdgeInsets.only(bottom: 1.2),
                                    child: _text(
                                      project,
                                      size: 3.95,
                                      color: _ink,
                                      weight: FontWeight.w600,
                                      maxLines: 1,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('CERTIFICATIONS'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _certifications
                                .map(
                                  (certification) => Padding(
                                    padding: const EdgeInsets.only(bottom: 1.0),
                                    child: _text(
                                      certification,
                                      size: 3.6,
                                      color: _muted,
                                      maxLines: 2,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _sectionHeader('LANGUAGES'),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _languages
                                .map(
                                  (language) => Padding(
                                    padding: const EdgeInsets.only(bottom: 1.0),
                                    child: _text(
                                      language,
                                      size: 3.6,
                                      color: _muted,
                                      maxLines: 1,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 4, color: _accent),
              const SizedBox(width: 4),
              _text(
                title,
                size: 4.5,
                color: _ink,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 1.5),
          Container(height: 0.5, color: _rule),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.2, vertical: 1.6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _accent, width: 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
      child: _text(
        label,
        size: 3.2,
        color: _ink,
        maxLines: 1,
      ),
    );
  }

  Widget _experienceBlock(_AcademicExperiencePreview experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            experience.title,
            size: 4.35,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 1,
          ),
          const SizedBox(height: 0.7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  experience.companyLine,
                  size: 3.35,
                  color: _accent,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              _text(
                experience.dateRange,
                size: 2.9,
                color: _accent,
                maxLines: 1,
                align: TextAlign.right,
              ),
            ],
          ),
          if (experience.detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0.8),
              child: _text(
                experience.detail,
                size: 3.4,
                color: _muted,
                maxLines: 2,
                align: TextAlign.justify,
              ),
            ),
        ],
      ),
    );
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

  Widget _objectiveBullet(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.1),
            child: _text(
              '✦',
              size: 3.6,
              color: _accent,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2.4),
          Expanded(
            child: _text(
              line,
              size: 3.35,
              color: _muted,
              maxLines: 2,
              align: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _splitLines(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    return trimmed
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(
            (line) => line.replaceFirst(RegExp(r'^[-•*▪■□✦★☆]+\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  String _compactLink(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return '';
    }
    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }
}

class _AcademicEducationPreview {
  const _AcademicEducationPreview({
    required this.degree,
    required this.subtitle,
  });

  final String degree;
  final String subtitle;
}

class _AcademicExperiencePreview {
  const _AcademicExperiencePreview({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    required this.detail,
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final String detail;
}
