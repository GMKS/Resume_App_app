import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class OnePageResumeTemplatePreview extends StatelessWidget {
  const OnePageResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );
  static final RegExp _leadingBulletPattern = RegExp(
    r'^[-•*▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );
  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );

  Color get _accent => templateColor ?? accentColor;
  Color get _pageBg => const Color(0xFFF8FAFC);
  Color get _ink => const Color(0xFF253243);
  Color get _muted => const Color(0xFF667085);
  Color get _rule => Color.lerp(_accent, Colors.white, 0.72)!;
  Color get _softChipBg => Color.lerp(_accent, Colors.white, 0.9)!;
  Color get _softChipBorder => Color.lerp(_accent, Colors.white, 0.72)!;

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  String get _address {
    final value = resume?.personalInfo.address.trim() ?? '';
    return value.isNotEmpty ? value : 'New York, NY';
  }

  List<String> get _topStripItems {
    final info = resume?.personalInfo;
    final items = <String>[];

    void addValue(String value, {bool compact = false}) {
      final normalized = compact ? _compactLink(value) : value.trim();
      if (normalized.isNotEmpty && !items.contains(normalized)) {
        items.add(normalized);
      }
    }

    addValue(info?.email ?? '');
    addValue(info?.phone ?? '');
    addValue(info?.linkedIn ?? '', compact: true);
    addValue(info?.github ?? '', compact: true);
    addValue(info?.website ?? '', compact: true);

    return items.isNotEmpty
        ? items
        : const [
            'john@email.com',
            '(555) 123-4567',
            'linkedin.com/in/js',
            'github.com/jsmith',
            'johnsmith.dev',
          ];
  }

  List<String> get _objectiveLines {
    final value = resume?.objective?.trim() ?? '';
    final fallback = value.isNotEmpty
        ? value
        : 'Results-driven professional with expertise in delivering high-quality solutions.';
    final lines = _splitLines(fallback, maxItems: 2);
    return lines.isNotEmpty ? lines : [fallback];
  }

  List<_PreviewExperienceData> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _PreviewExperienceData(
          title: 'Senior Developer',
          companyLine: 'TechCorp  •  Remote',
          dateRange: '2021 - Present',
          details: [
            'Led a cross-functional team to ship a cloud-based platform.'
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final details = <String>[];
      details.addAll(
        experience.achievements
            .map(_cleanListMarker)
            .where((line) => line.isNotEmpty)
            .take(2),
      );
      if (details.isEmpty && experience.description.trim().isNotEmpty) {
        details.addAll(_splitLines(experience.description, maxItems: 2));
      }

      final endLabel = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ??
              experience.startDate.year.toString());
      final companyLine = [
        experience.company.trim(),
        (experience.location ?? '').trim(),
      ].where((part) => part.isNotEmpty).join('  •  ');

      return _PreviewExperienceData(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: '${experience.startDate.year} - $endLabel',
        details: details,
      );
    }).toList(growable: false);
  }

  _PreviewEducationData get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _PreviewEducationData(
        degree: 'B.Sc. Computer Science',
        institution: 'State University',
        year: '2020',
        supportingLine: 'GPA: 3.8/4.0',
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

    return _PreviewEducationData(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
      year: year,
      supportingLine: education.grade?.trim() ?? '',
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

  List<_PreviewProjectData> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _PreviewProjectData(
          title: 'Portfolio Website',
          details: ['Built a responsive portfolio and resume showcase.'],
          links: ['portfolio.example.com'],
        ),
        _PreviewProjectData(
          title: 'Task Management App',
          details: ['Created a productivity app with offline sync.'],
        ),
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

      return _PreviewProjectData(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        details: details,
        links: _projectLinks(project),
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
          final name = certification.name.trim();
          final issuer = certification.issuer.trim();
          if (name.isEmpty) {
            return '';
          }
          return issuer.isNotEmpty ? '$name  •  $issuer' : name;
        })
        .where((line) => line.isNotEmpty)
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
        .where((line) => line.isNotEmpty)
        .take(3)
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
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 6,
              runSpacing: 1.5,
              children: _topStripItems
                  .map(
                    (item) => _text(
                      item,
                      size: 3.8,
                      color: Colors.white,
                      weight: FontWeight.w500,
                      maxLines: 1,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _text(
                        _name,
                        size: 9.8,
                        color: _ink,
                        weight: FontWeight.w900,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 70),
                      child: _text(
                        _address,
                        size: 4.0,
                        color: _muted,
                        align: TextAlign.right,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                _text(
                  _title,
                  size: 5.1,
                  color: _accent,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Container(width: double.infinity, height: 2, color: _accent),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 5),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('OBJECTIVE'),
                    ..._objectiveLines.map(_objectiveLine),
                    const SizedBox(height: 4),
                    _sectionHeader('EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                    const SizedBox(height: 1),
                    _sectionHeader('EDUCATION'),
                    _educationBlock(),
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('SKILLS'),
                      Wrap(
                        children: _skills
                            .map((skill) => _skillChip(skill))
                            .toList(growable: false),
                      ),
                    ],
                    if (_projects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('PROJECTS'),
                      ..._projects.map(_projectBlock),
                    ],
                    if (_certifications.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('CERTIFICATIONS'),
                      ..._certifications.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: _text(
                            line,
                            size: 3.9,
                            color: _ink.withValues(alpha: 0.82),
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                    if (_languages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _sectionHeader('LANGUAGES'),
                      ..._languages.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: _text(
                            line,
                            size: 3.9,
                            color: _ink.withValues(alpha: 0.82),
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
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(title, size: 4.5, color: _accent, weight: FontWeight.bold),
            const SizedBox(height: 1.5),
            Container(width: double.infinity, height: 1, color: _rule),
          ],
        ),
      );

  Widget _objectiveLine(String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.1),
              child: _text(
                '\u2192',
                size: 4.25,
                color: _accent,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _text(
                  line,
                  size: 4.05,
                  color: _ink.withValues(alpha: 0.88),
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(_PreviewExperienceData experience) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _text(
                      experience.title,
                      size: 5.2,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 56),
                    child: _text(
                      experience.dateRange,
                      size: 3.9,
                      color: _muted,
                      align: TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              _text(
                experience.companyLine,
                size: 4.05,
                color: _accent,
                weight: FontWeight.w600,
                maxLines: 2,
              ),
              ...experience.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(top: 1.2),
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(
                      detail,
                      size: 3.95,
                      color: _ink.withValues(alpha: 0.86),
                      align: TextAlign.justify,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _educationBlock() => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _text(
                    _education.degree,
                    size: 5.2,
                    color: _ink,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 44),
                  child: _text(
                    _education.year,
                    size: 3.9,
                    color: _muted,
                    align: TextAlign.right,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            _text(_education.institution, size: 4.05, color: _accent),
            if (_education.supportingLine.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1.2),
                child: _text(
                  _education.supportingLine,
                  size: 3.9,
                  color: _muted,
                  maxLines: 2,
                ),
              ),
          ],
        ),
      );

  Widget _projectBlock(_PreviewProjectData project) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _text(
                project.title,
                size: 4.2,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              ...project.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(top: 1.2),
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(
                      detail,
                      size: 3.75,
                      color: _ink.withValues(alpha: 0.84),
                      align: TextAlign.justify,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              ...project.links.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: _text(
                    link,
                    size: 3.3,
                    color: _accent,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _skillChip(String label) => Container(
        constraints: const BoxConstraints(maxWidth: 74),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        margin: const EdgeInsets.only(right: 3, bottom: 2),
        decoration: BoxDecoration(
          color: _softChipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _softChipBorder, width: 0.6),
        ),
        child: _text(
          label,
          size: 4.0,
          color: _ink,
          weight: FontWeight.w600,
          maxLines: 1,
        ),
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
        height: 1.16,
      ),
    );
  }

  List<String> _splitLines(String text, {int? maxItems = 2}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final parts = raw
        .split(RegExp(r'\n+'))
        .expand(_splitInlineBulletSegments)
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length > 1) {
      if (maxItems == null) {
        return parts;
      }
      return parts.take(maxItems).toList(growable: false);
    }

    final sentenceParts = raw
        .split(RegExp(r'(?<=[.!?])\s+'))
        .expand(_splitInlineBulletSegments)
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (maxItems == null) {
      return sentenceParts;
    }
    return sentenceParts.take(maxItems).toList(growable: false);
  }

  String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingBulletPattern, '');
  }

  Iterable<String> _splitInlineBulletSegments(String value) sync* {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    for (final segment in trimmed.split(_inlineBulletSeparatorPattern)) {
      final normalized = segment.trim();
      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
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

    compact = compact.replaceFirst(RegExp(r'^https?://'), '');
    compact = compact.replaceFirst(RegExp(r'^www\.'), '');
    return compact.replaceAll(RegExp(r'/$'), '');
  }
}

class _PreviewExperienceData {
  const _PreviewExperienceData({
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

class _PreviewEducationData {
  const _PreviewEducationData({
    required this.degree,
    required this.institution,
    required this.year,
    required this.supportingLine,
  });

  final String degree;
  final String institution;
  final String year;
  final String supportingLine;
}

class _PreviewProjectData {
  const _PreviewProjectData({
    required this.title,
    this.details = const [],
    this.links = const [],
  });

  final String title;
  final List<String> details;
  final List<String> links;
}
