import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class EliteResumeTemplatePreview extends StatelessWidget {
  const EliteResumeTemplatePreview({
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

  Color get _accent => templateColor ?? accentColor;
  Color get _headerBg => const Color(0xFF35354A);
  Color get _pageBg => Colors.white;
  Color get _ink => const Color(0xFF2D3142);
  Color get _muted => const Color(0xFF6F7380);
  Color get _rule => _accent.withValues(alpha: 0.26);
  Color get _skillBg => Color.lerp(_accent, Colors.white, 0.92)!;
  Color get _skillBorder => Color.lerp(_accent, Colors.white, 0.76)!;

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

  List<String> get _summaryLines {
    final value = resume?.objective?.trim() ?? '';
    if (value.isEmpty) {
      return const [
        'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      ];
    }
    final lines = _splitLines(value, maxItems: 3);
    return lines.isNotEmpty ? lines : [value];
  }

  List<_EliteExperiencePreviewData> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _EliteExperiencePreviewData(
          title: 'Senior Developer',
          meta: 'TechCorp  •  2021 - Present',
          details: [
            'Led team of 5 to deliver cloud-based platform',
            'Improved release speed with automated pipelines',
          ],
        ),
      ];
    }

    return values.take(1).map((experience) {
      final details = <String>[];
      for (final line in _splitLines(experience.description, maxItems: 2)) {
        if (!details.contains(line)) {
          details.add(line);
        }
      }
      for (final achievement in experience.achievements
          .map(_cleanListMarker)
          .where((line) => line.isNotEmpty)) {
        if (details.length >= 2) {
          break;
        }
        if (!details.contains(achievement)) {
          details.add(achievement);
        }
      }

      final endLabel = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ??
              experience.startDate.year.toString());
      final meta = [
        experience.company.trim(),
        '${experience.startDate.year} - $endLabel',
      ].where((part) => part.isNotEmpty).join('  •  ');

      return _EliteExperiencePreviewData(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        meta: meta.isNotEmpty ? meta : 'Company',
        details: details,
      );
    }).toList(growable: false);
  }

  _EliteEducationPreviewData get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _EliteEducationPreviewData(
        degree: 'B.Sc. Computer Science Software Engineering',
        subtitle: 'State University  •  2019',
      );
    }

    final education = values.first;
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final subtitle = [
      education.institution.trim(),
      education.isCurrentlyStudying
          ? 'Present'
          : (education.endDate?.year.toString() ??
              education.startDate.year.toString()),
    ].where((part) => part.isNotEmpty).join('  •  ');

    return _EliteEducationPreviewData(
      degree: degree.isNotEmpty ? degree : 'Education',
      subtitle: subtitle.isNotEmpty ? subtitle : 'Institution',
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
        .take(6)
        .toList(growable: false);
  }

  List<_EliteProjectPreviewData> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _EliteProjectPreviewData(
          title: 'Portfolio Website',
          details: ['Responsive site showcasing projects and case studies'],
          links: ['johnsmith.dev'],
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

      return _EliteProjectPreviewData(
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
      return const ['AWS Certified Developer  •  Amazon'];
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
            color: _headerBg,
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(_name,
                    size: 8.4, color: _accent, weight: FontWeight.w900),
                const SizedBox(height: 1),
                _text(_title,
                    size: 4.5,
                    color: Colors.white70,
                    weight: FontWeight.w500,
                    maxLines: 2),
                const SizedBox(height: 3),
                ..._contactLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: _text(
                      line,
                      size: 3.1,
                      color: Colors.white60,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 2, color: _accent.withValues(alpha: 0.82)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('SUMMARY'),
                    ..._summaryLines.asMap().entries.map(
                          (entry) => _summaryBullet(entry.key + 1, entry.value),
                        ),
                    const SizedBox(height: 4),
                    _sectionHeader('EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                    const SizedBox(height: 4),
                    _sectionHeader('EDUCATION'),
                    _text(_education.degree,
                        size: 5.0,
                        color: _ink,
                        weight: FontWeight.w700,
                        maxLines: 2),
                    _text(_education.subtitle,
                        size: 4.0, color: _muted, maxLines: 2),
                    const SizedBox(height: 4),
                    _sectionHeader('SKILLS'),
                    Wrap(
                      children: _skills.map(_skillChip).toList(growable: false),
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
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: _text(
                            line,
                            size: 3.9,
                            color: _muted,
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
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(title, size: 4.45, color: _accent, weight: FontWeight.bold),
            const SizedBox(height: 1.5),
            Container(width: double.infinity, height: 1, color: _rule),
          ],
        ),
      );

  Widget _summaryBullet(int index, String line) => Padding(
        padding: const EdgeInsets.only(bottom: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8.5,
              child: _text(
                '$index.',
                size: 4.0,
                color: _headerBg,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2.4),
            Expanded(
              child: _text(
                line,
                size: 4.0,
                color: _ink.withValues(alpha: 0.85),
                align: TextAlign.justify,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );

  Widget _experienceBlock(_EliteExperiencePreviewData experience) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(experience.title,
                size: 5.2, color: _ink, weight: FontWeight.w700),
            _text(experience.meta, size: 4.1, color: _muted, maxLines: 2),
            ...experience.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(top: 0.8),
                child: _text(
                  detail,
                  size: 3.95,
                  color: _ink.withValues(alpha: 0.84),
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _projectBlock(_EliteProjectPreviewData project) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(project.title,
                size: 4.3, color: _ink, weight: FontWeight.w700, maxLines: 2),
            ...project.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(top: 0.6),
                child: _text(
                  detail,
                  size: 3.8,
                  color: _muted,
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ),
            ...project.links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(top: 0.6),
                child: _text(
                  link,
                  size: 3.15,
                  color: _accent,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _skillChip(String label) => Container(
        constraints: const BoxConstraints(maxWidth: 78),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.4),
        margin: const EdgeInsets.only(right: 3, bottom: 2),
        decoration: BoxDecoration(
          color: _skillBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _skillBorder, width: 0.6),
        ),
        child: _text(label,
            size: 4.0,
            color: _ink.withValues(alpha: 0.95),
            weight: FontWeight.w600,
            maxLines: 1),
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
    compact = compact.replaceFirst(RegExp(r'^https?://'), '');
    compact = compact.replaceFirst(RegExp(r'^www\.'), '');
    return compact.replaceAll(RegExp(r'/$'), '');
  }
}

class _EliteEducationPreviewData {
  const _EliteEducationPreviewData({
    required this.degree,
    required this.subtitle,
  });

  final String degree;
  final String subtitle;
}

class _EliteExperiencePreviewData {
  const _EliteExperiencePreviewData({
    required this.title,
    required this.meta,
    required this.details,
  });

  final String title;
  final String meta;
  final List<String> details;
}

class _EliteProjectPreviewData {
  const _EliteProjectPreviewData({
    required this.title,
    this.details = const [],
    this.links = const [],
  });

  final String title;
  final List<String> details;
  final List<String> links;
}
