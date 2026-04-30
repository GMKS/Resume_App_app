import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class TwoColumnResumeTemplatePreview extends StatelessWidget {
  const TwoColumnResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _pageBg => const Color(0xFFF3F2F8);
  Color get _sidebarBg => const Color(0xFFE7E5F2);
  Color get _ink => const Color(0xFF1E2D3D);
  Color get _muted => const Color(0xFF6B7280);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const ['Flutter', 'Dart', 'Firebase', 'Testing'];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  List<String> get _contacts {
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
      return lines.take(5).toList(growable: false);
    }

    return const [
      'john.smith@email.com',
      '(555) 123-4567',
      'New York, NY',
      'linkedin.com/in/johnsmith',
      'github.com/johnsmith',
    ];
  }

  List<String> get _languageLines {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const ['English Native', 'German Intermediate'];
    }

    return values
        .map((language) {
          final proficiency = language.proficiency.trim();
          return proficiency.isNotEmpty
              ? '${language.name} $proficiency'
              : language.name;
        })
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  List<String> get _objectiveLines {
    final lines = _splitLines(resume?.objective ?? '', maxItems: 2);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven engineer focused on reliable delivery, accessible UI, and maintainable cross-platform systems.',
    ];
  }

  List<_TwoColumnPreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _TwoColumnPreviewExperience(
          title: 'Senior Developer',
          companyLine: 'TechCorp • 2022 - Present',
          detail: 'Led feature delivery and improved UI performance metrics.',
        ),
        _TwoColumnPreviewExperience(
          title: 'Flutter Engineer',
          companyLine: 'Creative Forge • 2020 - 2021',
          detail: 'Built reusable design-system components and app flows.',
        ),
      ];
    }

    return values.take(2).map((experience) {
      final end = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ?? 'Present');
      final meta = experience.company.trim().isNotEmpty
          ? '${experience.company.trim()} • ${experience.startDate.year} - $end'
          : '${experience.startDate.year} - $end';
      final detailLines = <String>[];
      for (final line in _splitLines(experience.description, maxItems: 1)) {
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

      return _TwoColumnPreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: meta,
        detail: detailLines.isNotEmpty ? detailLines.first : '',
      );
    }).toList(growable: false);
  }

  _TwoColumnPreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _TwoColumnPreviewEducation(
        degree: 'B.Sc. Computer Science',
        institution: 'State University • 2020',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final institution = education.institution.trim().isNotEmpty
        ? education.institution.trim()
        : 'Institution';
    final year = (education.endDate ?? education.startDate).year;

    return _TwoColumnPreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: '$institution • $year',
    );
  }

  List<_TwoColumnPreviewProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _TwoColumnPreviewProject(
          title: 'Resume Builder',
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

      return _TwoColumnPreviewProject(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        description: description,
        url: _compactUrl(project.url ?? ''),
      );
    }).toList(growable: false);
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
        height: 1.12,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return _text(
      title,
      size: 4.0,
      color: _accent,
      weight: FontWeight.bold,
    );
  }

  Widget _buildExperienceCard(_TwoColumnPreviewExperience item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              item.title,
              size: 4.4,
              color: _ink,
              weight: FontWeight.bold,
            ),
            _text(item.companyLine, size: 3.3, color: _accent),
            if (item.detail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _text(
                  item.detail,
                  size: 3.3,
                  color: _muted,
                  maxLines: 2,
                  align: TextAlign.justify,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(_TwoColumnPreviewProject item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            item.title,
            size: 4.1,
            color: _ink,
            weight: FontWeight.bold,
          ),
          if (item.description.isNotEmpty)
            _text(
              item.description,
              size: 3.3,
              color: _muted,
              maxLines: 2,
              align: TextAlign.justify,
            ),
          if (item.url.isNotEmpty)
            _text(item.url, size: 3.1, color: _accent, maxLines: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    _name.toUpperCase(),
                    size: 8,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                  _text(
                    _title,
                    size: 4.9,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 42,
                      color: _sidebarBg,
                      padding: const EdgeInsets.fromLTRB(5, 6, 4, 4),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('SKILLS'),
                            const SizedBox(height: 2),
                            ..._skills.map(
                              (skill) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _text(
                                  '• $skill',
                                  size: 3.3,
                                  color: _muted,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            _sectionTitle('CONTACT'),
                            const SizedBox(height: 2),
                            ..._contacts.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: _text(
                                  line,
                                  size: 3.1,
                                  color: _muted,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            _sectionTitle('LANG'),
                            const SizedBox(height: 2),
                            ..._languageLines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: _text(
                                  line,
                                  size: 3.1,
                                  color: _muted,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('OBJECTIVE'),
                            const SizedBox(height: 1),
                            ..._objectiveLines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: _text(
                                  line,
                                  size: 3.55,
                                  color: _muted,
                                  maxLines: 2,
                                  align: TextAlign.justify,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _sectionTitle('EXPERIENCE'),
                            const SizedBox(height: 1),
                            ..._experiences.map(_buildExperienceCard),
                            const SizedBox(height: 2),
                            _sectionTitle('EDUCATION'),
                            const SizedBox(height: 1),
                            _text(
                              _education.degree,
                              size: 4.1,
                              color: _ink,
                              weight: FontWeight.bold,
                              maxLines: 2,
                            ),
                            _text(
                              _education.institution,
                              size: 3.4,
                              color: _muted,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            _sectionTitle('PROJECTS'),
                            const SizedBox(height: 1),
                            ..._projects.map(_buildProjectItem),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumnPreviewExperience {
  const _TwoColumnPreviewExperience({
    required this.title,
    required this.companyLine,
    required this.detail,
  });

  final String title;
  final String companyLine;
  final String detail;
}

class _TwoColumnPreviewEducation {
  const _TwoColumnPreviewEducation({
    required this.degree,
    required this.institution,
  });

  final String degree;
  final String institution;
}

class _TwoColumnPreviewProject {
  const _TwoColumnPreviewProject({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}
