import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class ModernNovaTemplatePreview extends StatelessWidget {
  const ModernNovaTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _headerEnd => Color.lerp(_accent, Colors.white, 0.16)!;
  Color get _muted => const Color(0xFF6B7280);
  Color get _ink => const Color(0xFF1F2937);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  String get _objective {
    final value = resume?.objective?.trim() ?? '';
    return value.isNotEmpty
        ? value
        : 'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.';
  }

  List<_ModernNovaContactItem> get _contactItems {
    final items = <_ModernNovaContactItem>[];
    final info = resume?.personalInfo;

    void add(IconData icon, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        items.add(_ModernNovaContactItem(icon: icon, label: trimmed));
      }
    }

    add(Icons.email_outlined, info?.email);
    add(Icons.call_outlined, info?.phone);
    add(Icons.location_on_outlined, info?.address);
    add(Icons.link_outlined, info?.linkedIn);
    add(Icons.code_outlined, info?.github);
    add(Icons.language_outlined, info?.website);

    if (items.isNotEmpty) {
      return items;
    }

    return const [
      _ModernNovaContactItem(
        icon: Icons.email_outlined,
        label: 'john.smith@email.com',
      ),
      _ModernNovaContactItem(
        icon: Icons.call_outlined,
        label: '(555) 123-4567',
      ),
      _ModernNovaContactItem(
        icon: Icons.location_on_outlined,
        label: 'New York, NY',
      ),
      _ModernNovaContactItem(
        icon: Icons.link_outlined,
        label: 'linkedin.com/in/johnsmith',
      ),
      _ModernNovaContactItem(
        icon: Icons.language_outlined,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final lines = _splitLines(_objective, maxItems: 8);
    if (lines.isNotEmpty) {
      return lines;
    }
    return const [
      'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
    ];
  }

  List<_ModernNovaExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _ModernNovaExperience(
          title: 'Automation Lead',
          companyLine: 'Tata Consultancy Services Limited - Hyderabad, India',
          dateRange: 'Feb 2019 - Mar 2025',
          highlights: [
            'Led the automation team in developing and executing test automation scripts.',
          ],
        ),
        _ModernNovaExperience(
          title: 'Senior Software Engineer',
          companyLine: 'UST Global Pvt Limited - Hyderabad, India',
          dateRange: 'Feb 2017 - Mar 2018',
          highlights: [
            'Developed and maintained automation test scripts using Selenium and Core Java.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final end = experience.isCurrentlyWorking
          ? 'Present'
          : _monthYear(experience.endDate);
      final location = experience.location?.trim() ?? '';
      final companyLine = location.isNotEmpty
          ? '${experience.company} - $location'
          : experience.company;
      final highlights = <String>[];
      for (final achievement in experience.achievements) {
        final trimmed = achievement.trim();
        if (trimmed.isNotEmpty && !highlights.contains(trimmed)) {
          highlights.add(trimmed);
        }
      }
      for (final line in _splitLines(experience.description, maxItems: 3)) {
        if (!highlights.contains(line)) {
          highlights.add(line);
        }
      }

      return _ModernNovaExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine:
            companyLine.trim().isNotEmpty ? companyLine.trim() : 'Company',
        dateRange: '${_monthYear(experience.startDate)} - $end',
        highlights: highlights,
      );
    }).toList(growable: false);
  }

  _ModernNovaEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _ModernNovaEducation(
        degree: 'B.Sc. Computer Science Software Engineering',
        institution: 'State University',
        year: '2019',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    return _ModernNovaEducation(
      degree: degree.isNotEmpty ? degree : 'Degree',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
      year: (education.endDate ?? education.startDate).year.toString(),
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
        .take(8)
        .toList(growable: false);
  }

  List<_ModernNovaProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _ModernNovaProject(
          title: 'Portfolio Website',
          description:
              'Developed a responsive portfolio site showcasing projects and skills.',
        ),
        _ModernNovaProject(
          title: 'Task Management App',
          description:
              'Built a productivity-focused app with authentication and offline sync.',
        ),
      ];
    }

    return values.take(2).map((project) {
      final description = project.description.trim().isNotEmpty
          ? project.description.trim()
          : project.technologies.join(', ');
      return _ModernNovaProject(
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
        .take(3)
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
        .take(3)
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

  Widget _sectionHeader(String title) {
    final ruleWidth = (title.length * 3.4).clamp(34.0, 82.0);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            title,
            size: 4.45,
            color: _accent,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 1.4),
          Container(
            width: ruleWidth,
            height: 1.2,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactPill(_ModernNovaContactItem item) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(bottom: 2.2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 5.8, color: Colors.white),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.8,
                color: _accent,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletLines(
    List<String> lines, {
    required double size,
    required Color color,
    int maxLines = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 1.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.8),
                    child: Container(
                      width: 3.2,
                      height: 3.2,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _text(
                      line,
                      size: size,
                      color: color,
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

  Widget _experienceBlock(_ModernNovaExperience experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  experience.title,
                  size: 4.45,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: _text(
                  experience.dateRange,
                  size: 2.9,
                  color: _muted,
                  align: TextAlign.right,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1.2),
          _text(
            experience.companyLine,
            size: 3.2,
            color: _accent,
            maxLines: 2,
          ),
          if (experience.highlights.isNotEmpty) ...[
            const SizedBox(height: 1.2),
            _bulletLines(
              experience.highlights.take(1).toList(growable: false),
              size: 3.0,
              color: _muted,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _projectBlock(_ModernNovaProject project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            project.title,
            size: 3.85,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 2,
          ),
          if (project.description.trim().isNotEmpty)
            _text(
              project.description.trim(),
              size: 3.05,
              color: _muted,
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 3, bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4.2, vertical: 2.2),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: _text(
        label,
        size: 3.2,
        color: _accent,
        weight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent, _headerEnd]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _text(
                            _name,
                            size: 7.9,
                            color: Colors.white,
                            weight: FontWeight.w800,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          _text(
                            _title,
                            size: 4.7,
                            color: Colors.white.withValues(alpha: 0.92),
                            weight: FontWeight.w500,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:
                        _contactItems.map(_contactPill).toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('PROFESSIONAL SUMMARY'),
                    _bulletLines(
                      _summaryLines,
                      size: 3.25,
                      color: _muted,
                    ),
                    _sectionHeader('WORK EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                    _sectionHeader('EDUCATION'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _text(
                                _education.degree,
                                size: 4.15,
                                color: _ink,
                                weight: FontWeight.w700,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 1.2),
                              _text(
                                _education.institution,
                                size: 3.15,
                                color: _accent,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          child: _text(
                            _education.year,
                            size: 2.9,
                            color: _muted,
                            align: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    _sectionHeader('SKILLS'),
                    Wrap(
                      children: _skills.map(_skillChip).toList(growable: false),
                    ),
                    if (_projects.isNotEmpty) ...[
                      _sectionHeader('PROJECTS'),
                      ..._projects.map(_projectBlock),
                    ],
                    if (_certifications.isNotEmpty) ...[
                      _sectionHeader('CERTIFICATIONS'),
                      ..._certifications.map(
                        (certification) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.4),
                          child: _text(
                            certification,
                            size: 3.1,
                            color: _muted,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                    if (_languages.isNotEmpty) ...[
                      _sectionHeader('LANGUAGES'),
                      ..._languages.map(
                        (language) => Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: _text(
                            language,
                            size: 3.1,
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
}

class _ModernNovaContactItem {
  const _ModernNovaContactItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ModernNovaExperience {
  const _ModernNovaExperience({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    required this.highlights,
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> highlights;
}

class _ModernNovaEducation {
  const _ModernNovaEducation({
    required this.degree,
    required this.institution,
    required this.year,
  });

  final String degree;
  final String institution;
  final String year;
}

class _ModernNovaProject {
  const _ModernNovaProject({required this.title, required this.description});

  final String title;
  final String description;
}
