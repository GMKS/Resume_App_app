import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class CreativeResumeTemplatePreview extends StatelessWidget {
  const CreativeResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _ink => const Color(0xFF2D3142);
  Color get _muted => const Color(0xFF6B7280);
  Color get _pageBg => const Color(0xFFFFF8F1);
  Color get _softCard => const Color(0xFFFFFBF5);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'JOHN SMITH';
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
      if ((info?.linkedIn ?? '').trim().isNotEmpty) info!.linkedIn!.trim(),
      if ((info?.github ?? '').trim().isNotEmpty) info!.github!.trim(),
      if ((info?.website ?? '').trim().isNotEmpty) info!.website!.trim(),
      if ((info?.address ?? '').trim().isNotEmpty) info!.address.trim(),
    ];

    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'john@email.com',
      '(555) 123-4567',
      'linkedin.com/in/johnsmith',
      'github.com/johnsmith',
      'johnsmith.dev',
      'New York, NY',
    ];
  }

  List<String> get _summaryLines {
    final lines = _splitLines(resume?.objective ?? '', maxItems: 5);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven professional with expertise in delivering high-quality solutions.',
      'Builds polished interfaces and reliable workflows across mobile and web products.',
    ];
  }

  List<_CreativePreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _CreativePreviewExperience(
          title: 'Senior Developer',
          company: 'TechCorp',
          dateRange: '2021 - Present',
          location: 'Remote',
          highlights: [
            'Led delivery for customer-facing product workflows and polished UI systems.',
          ],
        ),
        _CreativePreviewExperience(
          title: 'Software Engineer',
          company: 'StartupXYZ',
          dateRange: '2019 - 2021',
          location: 'Portland, OR',
          highlights: [
            'Built reusable design components and shipped product improvements on schedule.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final end = experience.isCurrentlyWorking
          ? 'Present'
          : _monthYear(experience.endDate);
      final highlights = <String>[];

      for (final achievement in experience.achievements) {
        final trimmed = achievement.trim();
        if (trimmed.isNotEmpty && !highlights.contains(trimmed)) {
          highlights.add(trimmed);
        }
      }

      for (final line in _splitLines(experience.description, maxItems: 2)) {
        if (!highlights.contains(line)) {
          highlights.add(line);
        }
      }

      return _CreativePreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        company: experience.company.trim().isNotEmpty
            ? experience.company.trim()
            : 'Company',
        dateRange: '${_monthYear(experience.startDate)} - $end',
        location: experience.location?.trim() ?? '',
        highlights: highlights,
      );
    }).toList(growable: false);
  }

  _CreativePreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _CreativePreviewEducation(
        degree: 'B.Sc. Computer Science',
        institution: 'State University',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    return _CreativePreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
    );
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const ['Flutter', 'Dart', 'Testing', 'Firebase'];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  List<_CreativePreviewProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _CreativePreviewProject(
          title: 'Resume Builder',
          description: 'Cross-platform editor with live preview and export.',
        ),
      ];
    }

    return values.take(1).map((project) {
      final description = project.description.trim().isNotEmpty
          ? project.description.trim()
          : project.technologies.join(', ');
      return _CreativePreviewProject(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        description: description,
      );
    }).toList(growable: false);
  }

  List<String> get _certifications {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const ['AWS Certified Developer - Amazon'];
    }

    return values
        .map((certification) {
          final issuer = certification.issuer.trim();
          return issuer.isNotEmpty
              ? '${certification.name} - $issuer'
              : certification.name;
        })
        .where((certification) => certification.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  List<String> get _languages {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const ['English - Professional'];
    }

    return values
        .map((language) {
          final proficiency = language.proficiency.trim();
          return proficiency.isNotEmpty
              ? '${language.name} - $proficiency'
              : language.name;
        })
        .where((language) => language.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  String _monthYear(DateTime? date) {
    if (date == null) {
      return 'Present';
    }

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
    return text.trim().replaceFirst(
          RegExp(r'^[-•*▪■□✦★☆]+\s*'),
          '',
        );
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

  Widget _sectionPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _text(
        title,
        size: 4.0,
        color: Colors.white,
        weight: FontWeight.w700,
      ),
    );
  }

  Widget _profileBullets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _summaryLines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 1.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.2),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 6.0,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _text(
                      line,
                      size: 3.1,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _experienceCard(_CreativePreviewExperience experience) {
    final highlights = experience.highlights.take(1).toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _softCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.18)),
      ),
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
                      size: 4.1,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 2,
                    ),
                    _text(
                      experience.company,
                      size: 3.25,
                      color: _accent,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _text(
                      experience.dateRange,
                      size: 2.65,
                      color: _muted,
                      align: TextAlign.right,
                      maxLines: 2,
                    ),
                    if (experience.location.isNotEmpty)
                      _text(
                        experience.location,
                        size: 2.45,
                        color: _muted,
                        align: TextAlign.right,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 1.2),
            ...highlights.map(
              (line) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 5.4, color: _accent),
                  Expanded(
                    child: _text(
                      line,
                      size: 2.95,
                      color: _muted,
                      align: TextAlign.justify,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 2, bottom: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 4.2, vertical: 2.1),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _text(
        label,
        size: 3.0,
        color: Colors.white,
        weight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }

  Widget _projectBlock(_CreativePreviewProject project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text(
          project.title,
          size: 3.45,
          color: _ink,
          weight: FontWeight.w700,
          maxLines: 1,
        ),
        _text(
          project.description,
          size: 2.95,
          color: _muted,
          align: TextAlign.justify,
          maxLines: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
              decoration: const BoxDecoration(
                color: Color(0xFF2D3142),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    _name,
                    size: 7.4,
                    color: Colors.white,
                    weight: FontWeight.w800,
                    maxLines: 2,
                  ),
                  _text(
                    _title,
                    size: 4.25,
                    color: _accent.withValues(alpha: 0.95),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  ..._contactLines.map(
                    (line) => _text(
                      line,
                      size: 3.0,
                      color: Colors.white.withValues(alpha: 0.76),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionPill('PROFILE'),
                      const SizedBox(height: 3),
                      _profileBullets(),
                      const SizedBox(height: 3),
                      _sectionPill('EXPERIENCE'),
                      const SizedBox(height: 3),
                      ..._experiences.map(_experienceCard),
                      _sectionPill('EDUCATION'),
                      const SizedBox(height: 3),
                      _text(
                        _education.degree,
                        size: 4.0,
                        color: _ink,
                        weight: FontWeight.w700,
                        maxLines: 1,
                      ),
                      _text(
                        _education.institution,
                        size: 3.1,
                        color: _muted,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      _sectionPill('SKILLS'),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 2,
                        runSpacing: 1.5,
                        children:
                            _skills.map(_skillChip).toList(growable: false),
                      ),
                      if (_projects.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _sectionPill('PROJECTS'),
                        const SizedBox(height: 3),
                        ..._projects.map(_projectBlock),
                      ],
                      if (_certifications.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _sectionPill('CERTIFICATIONS'),
                        const SizedBox(height: 3),
                        ..._certifications.map(
                          (certification) => Padding(
                            padding: const EdgeInsets.only(bottom: 1.2),
                            child: _text(
                              certification,
                              size: 3.0,
                              color: _muted,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                      if (_languages.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _sectionPill('LANGUAGES'),
                        const SizedBox(height: 3),
                        ..._languages.map(
                          (language) => Padding(
                            padding: const EdgeInsets.only(bottom: 1.2),
                            child: _text(
                              language,
                              size: 3.0,
                              color: _muted,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
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

class _CreativePreviewExperience {
  const _CreativePreviewExperience({
    required this.title,
    required this.company,
    required this.dateRange,
    required this.location,
    required this.highlights,
  });

  final String title;
  final String company;
  final String dateRange;
  final String location;
  final List<String> highlights;
}

class _CreativePreviewEducation {
  const _CreativePreviewEducation({
    required this.degree,
    required this.institution,
  });

  final String degree;
  final String institution;
}

class _CreativePreviewProject {
  const _CreativePreviewProject(
      {required this.title, required this.description});

  final String title;
  final String description;
}
