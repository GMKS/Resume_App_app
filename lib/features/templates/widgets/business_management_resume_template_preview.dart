import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../../core/utils/user_custom_sections.dart';

class BusinessManagementResumeTemplatePreview extends StatelessWidget {
  const BusinessManagementResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _ink => const Color(0xFF111827);
  Color get _muted => const Color(0xFF6B7280);
  Color get _headerBg => const Color(0xFFF2ECE5);
  Color get _divider => const Color(0xFFD1D5DB);
  Color get _headerTitle => const Color(0xFF4B5563);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Manager';
  }

  List<_BusinessManagementPreviewContactItem> get _contactItems {
    final info = resume?.personalInfo;
    final items = <_BusinessManagementPreviewContactItem>[];

    void add(IconData icon, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        items.add(
            _BusinessManagementPreviewContactItem(icon: icon, label: trimmed));
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
      _BusinessManagementPreviewContactItem(
        icon: Icons.email_outlined,
        label: 'john@email.com',
      ),
      _BusinessManagementPreviewContactItem(
        icon: Icons.call_outlined,
        label: '(555) 123-4567',
      ),
      _BusinessManagementPreviewContactItem(
        icon: Icons.location_on_outlined,
        label: 'New York, NY',
      ),
      _BusinessManagementPreviewContactItem(
        icon: Icons.link_outlined,
        label: 'linkedin.com/in/johnsmith',
      ),
      _BusinessManagementPreviewContactItem(
        icon: Icons.language_outlined,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final lines = _splitLines(resume?.objective ?? '', maxItems: 5);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven professional with expertise in delivering high-quality solutions across product, platform, and cloud teams.',
    ];
  }

  List<_BusinessManagementPreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _BusinessManagementPreviewExperience(
          title: 'Senior Developer',
          companyLine: 'TechCorp - New York, NY',
          dateRange: 'Jan 2021 - Present',
          highlights: [
            'Led team delivery for a cloud-based platform with measurable performance gains.',
          ],
        ),
        _BusinessManagementPreviewExperience(
          title: 'Software Engineer',
          companyLine: 'StartupXYZ - Remote',
          dateRange: 'Jun 2019 - Dec 2020',
          highlights: [
            'Built reusable product workflows and supported high-quality releases.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final location = experience.location?.trim() ?? '';
      final companyLine = [
        if (experience.company.trim().isNotEmpty) experience.company.trim(),
        if (location.isNotEmpty) location,
      ].join(' - ');
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

      for (final line in _splitLines(experience.description, maxItems: 3)) {
        if (!highlights.contains(line)) {
          highlights.add(line);
        }
      }

      return _BusinessManagementPreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: '${_monthYear(experience.startDate)} - $end',
        highlights: highlights,
      );
    }).toList(growable: false);
  }

  _BusinessManagementPreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _BusinessManagementPreviewEducation(
        degree: 'B.Sc. Computer Science',
        institution: 'State University',
        dateRange: '2016 - 2020',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final end = education.isCurrentlyStudying
        ? 'Present'
        : (education.endDate?.year.toString() ??
            education.startDate.year.toString());

    return _BusinessManagementPreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
      dateRange: '${education.startDate.year} - $end',
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

  List<_BusinessManagementPreviewProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _BusinessManagementPreviewProject(
          title: 'Resumix AI Platform',
          description:
              'Developed a full resume workflow spanning editing, preview, and export.',
        ),
      ];
    }

    return values.take(1).map((project) {
      final description = project.description.trim().isNotEmpty
          ? project.description.trim()
          : project.technologies.join(', ');
      return _BusinessManagementPreviewProject(
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _text(
            title,
            size: 4.35,
            color: _ink,
            weight: FontWeight.w700,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(height: 0.75, color: _divider),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(width: 1.5, color: _accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerContactItem(_BusinessManagementPreviewContactItem item) {
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          Container(
            width: 7.8,
            height: 7.8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 0.9),
            ),
            child: Icon(item.icon, size: 4.1, color: _accent),
          ),
          const SizedBox(width: 2.6),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.55,
                color: _muted,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<List<_BusinessManagementPreviewContactItem>> get _headerContactRows {
    if (_contactItems.isEmpty) {
      return const [];
    }

    final rows = <List<_BusinessManagementPreviewContactItem>>[];
    for (var index = 0; index < _contactItems.length; index += 3) {
      final end =
          index + 3 < _contactItems.length ? index + 3 : _contactItems.length;
      rows.add(_contactItems.sublist(index, end));
    }
    return rows;
  }

  Widget _buildHeaderContactGrid() {
    final rows = _headerContactRows;
    return Column(
      children: rows
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 2.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < entry.value.length; index++) ...[
                    Expanded(child: _headerContactItem(entry.value[index])),
                    if (index != entry.value.length - 1)
                      const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          )
          .toList(growable: false),
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
              padding: const EdgeInsets.only(bottom: 1.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Container(
                      width: 3.1,
                      height: 3.1,
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

  Widget _experienceBlock(_BusinessManagementPreviewExperience experience) {
    final highlights = experience.highlights.take(1).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  experience.title,
                  size: 4.2,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 46,
                child: _text(
                  experience.dateRange,
                  size: 2.85,
                  color: _muted,
                  align: TextAlign.right,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1.1),
          _text(
            experience.companyLine,
            size: 3.05,
            color: _muted,
            maxLines: 2,
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 1.1),
            _bulletLines(
              highlights,
              size: 2.95,
              color: _muted,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 3, bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4.2, vertical: 2.1),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.22), width: 0.45),
      ),
      child: _text(
        label,
        size: 3.0,
        color: _accent,
        weight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }

  Widget _projectBlock(_BusinessManagementPreviewProject project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            project.title,
            size: 3.65,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 2,
          ),
          if (project.description.trim().isNotEmpty)
            _text(
              project.description.trim(),
              size: 2.95,
              color: _muted,
              align: TextAlign.justify,
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewResume = resume != null && resume!.templateId == 'executive'
        ? resume!.copyWith(
            customSections: ensureProfessionalRoleSections(resume!),
          )
        : resume;
    final previewCustomSections = orderedUserCustomSectionsFromList(
      previewResume?.customSections ?? const <CustomSection>[],
    );

    Widget? customSectionBlock(CustomSection section) {
      final title = displayUserCustomSectionTitle(section);
      final itemBlocks = section.items
          .map((item) {
            final displayItem = buildUserCustomSectionDisplayItem(item);
            final metaParts = <String>[
              if (displayItem.subtitle.isNotEmpty) displayItem.subtitle,
              if (displayItem.date != null)
                DateFormat('MMM yyyy').format(displayItem.date!),
            ];

            if (!displayItem.hasContent) {
              return null;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayItem.heading.isNotEmpty)
                    _text(
                      displayItem.heading,
                      size: 3.2,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 0,
                    ),
                  if (metaParts.isNotEmpty)
                    _text(
                      metaParts.join('  |  '),
                      size: 2.7,
                      color: _muted,
                      maxLines: 0,
                    ),
                  if (displayItem.detailLines.isNotEmpty)
                    _bulletLines(
                      displayItem.detailLines,
                      size: 2.85,
                      color: _muted,
                    ),
                ],
              ),
            );
          })
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title.toUpperCase()),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
              decoration: BoxDecoration(
                color: _headerBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _text(
                          _name,
                          size: 7.4,
                          color: _ink,
                          weight: FontWeight.w800,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: _text(
                          _title,
                          size: 2.85,
                          color: _headerTitle,
                          align: TextAlign.right,
                          weight: FontWeight.w600,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildHeaderContactGrid(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Container(
              height: 0.9,
              color: _divider.withValues(alpha: 0.9),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_summaryLines.isNotEmpty) ...[
                      _sectionHeader('OBJECTIVE'),
                      _bulletLines(
                        _summaryLines,
                        size: 3.05,
                        color: _muted,
                      ),
                    ],
                    _sectionHeader('PROFESSIONAL EXPERIENCE'),
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
                                size: 4.0,
                                color: _ink,
                                weight: FontWeight.w700,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 1.0),
                              _text(
                                _education.institution,
                                size: 3.0,
                                color: _muted,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 35,
                          child: _text(
                            _education.dateRange,
                            size: 2.8,
                            color: _muted,
                            align: TextAlign.right,
                            maxLines: 2,
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
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: _text(
                            certification,
                            size: 2.95,
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
                            size: 2.95,
                            color: _muted,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                    for (final section in previewCustomSections)
                      if (customSectionBlock(section) case final block?) ...[
                        block,
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

class _BusinessManagementPreviewContactItem {
  const _BusinessManagementPreviewContactItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _BusinessManagementPreviewExperience {
  const _BusinessManagementPreviewExperience({
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

class _BusinessManagementPreviewEducation {
  const _BusinessManagementPreviewEducation({
    required this.degree,
    required this.institution,
    required this.dateRange,
  });

  final String degree;
  final String institution;
  final String dateRange;
}

class _BusinessManagementPreviewProject {
  const _BusinessManagementPreviewProject({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
