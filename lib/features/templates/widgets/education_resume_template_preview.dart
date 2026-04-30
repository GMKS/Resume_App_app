import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class EducationResumeTemplatePreview extends StatelessWidget {
  const EducationResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _header => const Color(0xFF333C4D);
  Color get _cream => const Color(0xFFD4B896);
  Color get _pageBg => const Color(0xFFFAF6F0);
  Color get _ink => const Color(0xFF383838);
  Color get _muted => const Color(0xFF7A7A82);
  Color get _rule => Color.lerp(_cream, Colors.white, 0.38)!;
  Color get _skillBg => Color.lerp(_cream, Colors.white, 0.74)!;
  Color get _skillBorder => Color.lerp(_cream, Colors.white, 0.46)!;
  Color get _linkInk => _header;
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

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
    final lines = <String>[];
    final primary = <String>[];

    void addPrimary(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        primary.add(trimmed);
      }
    }

    addPrimary(info?.email);
    addPrimary(info?.phone);
    if (primary.isNotEmpty) {
      lines.add(primary.join('  •  '));
    }

    final address = info?.address.trim() ?? '';
    if (address.isNotEmpty) {
      lines.add(address);
    }

    final links = <String>[];
    for (final value in [info?.linkedIn, info?.github, info?.website]) {
      final compact = _compactLink(value ?? '');
      if (compact.isNotEmpty) {
        links.add(compact);
      }
    }
    if (links.isNotEmpty) {
      lines.add(links.join('  •  '));
    }

    return lines.isNotEmpty
        ? lines
        : const [
            'john.smith@email.com  •  (555) 123-4567',
            'linkedin.com/in/johnsmith  •  github.com/johnsmith',
          ];
  }

  _EducationPreviewData get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _EducationPreviewData(
        degree: 'B.Sc. Computer Science Software Engineering',
        institution: 'State University',
        year: '2019',
        gradeLine: 'GPA: 3.8/4.0  •  Dean\'s List',
      );
    }

    final education = values.first;
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final year = education.isCurrentlyStudying
        ? 'Present'
        : (education.endDate?.year.toString() ??
            education.startDate.year.toString());

    return _EducationPreviewData(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
      year: year,
      gradeLine: education.grade?.trim() ?? '',
    );
  }

  List<_ExperiencePreviewData> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _ExperiencePreviewData(
          title: 'Senior Developer',
          companyLine: 'TechCorp',
          dateRange: '2021 - Present',
          details: ['Led team of 5 to deliver cloud-based platform'],
        ),
      ];
    }

    return values.take(1).map((experience) {
      final detailLines = <String>[];
      if (experience.description.trim().isNotEmpty) {
        detailLines.addAll(_splitLines(experience.description, maxItems: 2));
      }
      if (detailLines.isEmpty) {
        detailLines.addAll(
          experience.achievements
              .map((item) => _cleanListMarker(item))
              .where((item) => item.isNotEmpty)
              .take(2),
        );
      }
      final endLabel = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ??
              experience.startDate.year.toString());
      final companyLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  •  ');

      return _ExperiencePreviewData(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: '${experience.startDate.year} - $endLabel',
        details: detailLines,
      );
    }).toList(growable: false);
  }

  String get _objective {
    final value = resume?.objective?.trim() ?? '';
    return value.isNotEmpty
        ? value
        : 'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.';
  }

  List<String> get _objectiveLines {
    final values = _splitLines(_objective, maxItems: 3);
    return values.isNotEmpty ? values : [_objective];
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

  List<_ProjectPreviewData> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _ProjectPreviewData(title: 'Portfolio Website'),
        _ProjectPreviewData(title: 'Task Management App'),
      ];
    }

    return values.take(2).map((project) {
      final details = project.description.trim().isNotEmpty
          ? _splitLines(project.description, maxItems: 2)
              .where((line) => !_isStandaloneLink(line))
              .toList(growable: false)
          : project.technologies
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .take(2)
              .toList(growable: false);

      return _ProjectPreviewData(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        links: _projectLinks(project),
        details: details,
      );
    }).toList(growable: false);
  }

  List<String> get _certifications {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const [
        'AWS Certified Developer  •  Amazon',
        'Scrum Master  •  Scrum Alliance',
      ];
    }

    return values
        .map((certification) {
          final issuer = certification.issuer.trim();
          return issuer.isNotEmpty
              ? '${certification.name.trim()}  •  $issuer'
              : certification.name.trim();
        })
        .where((value) => value.isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  List<String> get _languages {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const ['English Professional', 'German Professional'];
    }

    return values
        .map((language) =>
            '${language.name.trim()} ${language.proficiency.trim()}'.trim())
        .where((value) => value.isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            color: _header,
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(_name,
                          size: 8.4,
                          color: Colors.white,
                          weight: FontWeight.bold),
                      const SizedBox(height: 1),
                      _text(
                        _title,
                        size: 4.6,
                        color: _cream,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _contactLines.asMap().entries.map((entry) {
                      final lineColor = entry.key == 0
                          ? Colors.white.withValues(alpha: 0.84)
                          : Color.lerp(_cream, Colors.white, 0.18)!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: _text(
                          entry.value,
                          size: 2.9,
                          color: lineColor,
                          align: TextAlign.right,
                          maxLines: 2,
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('EDUCATION'),
                    _educationBlock(),
                    const SizedBox(height: 4),
                    _sectionHeader('EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                    const SizedBox(height: 4),
                    _sectionHeader('OBJECTIVE'),
                    ..._objectiveLines.map(_objectiveBullet),
                    const SizedBox(height: 4),
                    _sectionHeader('SKILLS'),
                    Wrap(
                      children: _skills
                          .map((skill) => _skillChip(skill))
                          .toList(growable: false),
                    ),
                    if (_projects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('PROJECTS'),
                      ..._projects.map(_projectBlock),
                    ],
                    if (_certifications.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('CERTIFICATIONS'),
                      ..._certifications.map(
                        (line) =>
                            _text(line, size: 4.0, color: _muted, maxLines: 2),
                      ),
                    ],
                    if (_languages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('LANGUAGES'),
                      ..._languages.map(
                        (line) =>
                            _text(line, size: 4.0, color: _muted, maxLines: 1),
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

  Widget _educationBlock() => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(_education.degree,
                      size: 5.5,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 2),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: _text(
                    _education.year,
                    size: 4.2,
                    color: _muted,
                    align: TextAlign.right,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            _text(_education.institution,
                size: 4.3, color: _muted, maxLines: 2),
            if (_education.gradeLine.isNotEmpty)
              _text(_education.gradeLine,
                  size: 4.1, color: _muted, maxLines: 2),
          ],
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(title, size: 4.5, color: _header, weight: FontWeight.bold),
            const SizedBox(height: 1.5),
            Container(width: double.infinity, height: 1, color: _rule),
          ],
        ),
      );

  Widget _experienceBlock(_ExperiencePreviewData experience) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _text(experience.title,
                        size: 5.3, color: _ink, weight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: _text(
                      experience.dateRange,
                      size: 4.0,
                      color: _muted,
                      align: TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              _text(experience.companyLine,
                  size: 4.2, color: _muted, maxLines: 2),
              ...experience.details.map(
                (detail) => _text(detail,
                    size: 4.1,
                    color: _ink.withValues(alpha: 0.86),
                    align: TextAlign.justify,
                    maxLines: 2),
              ),
            ],
          ),
        ),
      );

  Widget _objectiveBullet(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child:
                  _text('➣', size: 4.2, color: _cream, weight: FontWeight.w700),
            ),
            Expanded(
              child: _text(line,
                  size: 4.0,
                  color: _ink.withValues(alpha: 0.85),
                  align: TextAlign.justify,
                  maxLines: 2),
            ),
          ],
        ),
      );

  Widget _projectBlock(_ProjectPreviewData project) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text(project.title,
                  size: 4.3, color: _ink, weight: FontWeight.w700, maxLines: 2),
              ...project.details.map(
                (detail) => _text(detail,
                    size: 3.8,
                    color: _muted,
                    align: TextAlign.justify,
                    maxLines: 2),
              ),
              ...project.links.map(
                (link) => _text(link, size: 3.2, color: _linkInk, maxLines: 2),
              ),
            ],
          ),
        ),
      );

  Widget _skillChip(String label) => Container(
        constraints: const BoxConstraints(maxWidth: 74),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.4),
        margin: const EdgeInsets.only(right: 3, bottom: 2),
        decoration: BoxDecoration(
          color: _skillBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _skillBorder, width: 0.6),
        ),
        child: _text(label,
            size: 4.2, color: _header, weight: FontWeight.w600, maxLines: 1),
      );

  Widget _text(
    String text, {
    required double size,
    required Color color,
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
        color: color,
        fontWeight: weight,
        height: 1.15,
      ),
    );
  }

  List<String> _splitLines(String text, {int? maxItems = 2}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }
    final parts = raw
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList();
    if (maxItems == null) {
      return parts;
    }
    return parts.take(maxItems).toList(growable: false);
  }

  String _cleanListMarker(String value) {
    return value.trim().replaceFirst(RegExp(r'^[-•*▪■□✪✦★☆➣◦○]+\s*'), '');
  }

  List<String> _projectLinks(Project project) {
    final links = <String>[];
    final seen = <String>{};

    void collectFrom(String source) {
      for (final match in _linkPattern.allMatches(source)) {
        final compact = _compactLink(match.group(0) ?? '');
        final key = compact.toLowerCase();
        if (compact.isEmpty || !seen.add(key)) {
          continue;
        }
        links.add(compact);
      }
    }

    collectFrom(project.url ?? '');
    collectFrom(project.description);
    return links;
  }

  bool _isStandaloneLink(String value) {
    final trimmed = value.trim();
    final matches = _linkPattern.allMatches(trimmed).toList(growable: false);
    return matches.length == 1 &&
        (matches.first.group(0) ?? '').trim() == trimmed;
  }

  String _compactLink(String value) {
    var compact = value.trim();
    if (compact.isEmpty) {
      return '';
    }
    compact = compact.replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    compact = compact.replaceFirst(
      RegExp(r'^www\.+', caseSensitive: false),
      '',
    );
    compact = compact.replaceFirst(RegExp(r'^[./\s]+'), '');
    return compact.replaceAll(RegExp(r'/$'), '');
  }
}

class _EducationPreviewData {
  const _EducationPreviewData({
    required this.degree,
    required this.institution,
    required this.year,
    required this.gradeLine,
  });

  final String degree;
  final String institution;
  final String year;
  final String gradeLine;
}

class _ExperiencePreviewData {
  const _ExperiencePreviewData({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    required this.details,
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> details;
}

class _ProjectPreviewData {
  const _ProjectPreviewData({
    required this.title,
    this.links = const [],
    this.details = const [],
  });

  final String title;
  final List<String> links;
  final List<String> details;
}
