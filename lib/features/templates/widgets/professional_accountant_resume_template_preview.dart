import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../professional_accountant_template_support.dart';

class ProfessionalAccountantResumeTemplatePreview extends StatelessWidget {
  const ProfessionalAccountantResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  static const double _headerContactWidth = 90;

  Color get _accent => templateColor ?? accentColor;
  Color get _pageBg => Colors.white;
  Color get _ink => const Color(0xFF26282D);
  Color get _muted => const Color(0xFF6B7280);
  Color get _rule => Color.lerp(_accent, Colors.white, 0.7)!;
  Color get _headerIconBg => Color.lerp(_accent, Colors.white, 0.54)!;

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Accountant';
  }

  List<_ProfessionalAccountantContactItem> get _contactItems {
    final items = ProfessionalAccountantTemplateSupport.contactItems(
      resume?.personalInfo,
    )
        .map(
          (item) => _ProfessionalAccountantContactItem(
            icon: _contactIcon(item.kind),
            label: item.label,
          ),
        )
        .toList(growable: false);

    if (items.isNotEmpty) {
      return items;
    }

    return const [
      _ProfessionalAccountantContactItem(
        icon: Icons.email_outlined,
        label: 'john.smith@email.com',
      ),
      _ProfessionalAccountantContactItem(
        icon: Icons.call_outlined,
        label: '(555) 123-4567',
      ),
      _ProfessionalAccountantContactItem(
        icon: Icons.location_on_outlined,
        label: 'New York, NY',
      ),
      _ProfessionalAccountantContactItem(
        icon: Icons.link_outlined,
        label: 'linkedin.com/in/johnsmith',
      ),
      _ProfessionalAccountantContactItem(
        icon: Icons.language_outlined,
        label: 'johnsmith.dev',
      ),
    ];
  }

  List<String> get _summaryLines {
    final value = resume?.objective?.trim() ?? '';
    if (value.isEmpty) {
      return const [
        'Results-driven professional with expertise in delivering high-quality solutions across finance, operations, and stakeholder-facing delivery.',
      ];
    }

    return _splitLines(value, maxItems: 6);
  }

  List<_ProfessionalAccountantExperienceData> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _ProfessionalAccountantExperienceData(
          title: 'Automation Lead',
          companyLine: 'TechCorp | New York, NY',
          dateRange: 'Jan 2021 - Present',
          details: [
            'Led delivery planning, release validation, and measurable reporting across distributed teams.',
            'Improved operational quality through structured testing and execution tracking.',
          ],
        ),
        _ProfessionalAccountantExperienceData(
          title: 'Senior Software Engineer',
          companyLine: 'Studio Foundry | Remote',
          dateRange: 'Jun 2019 - Dec 2020',
          details: [
            'Built repeatable automation workflows and supported reliable production releases.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final details = <String>[];

      for (final line in _splitLines(experience.description, maxItems: 3)) {
        if (!details.contains(line)) {
          details.add(line);
        }
      }

      for (final achievement in experience.achievements
          .map(_cleanListMarker)
          .where((line) => line.isNotEmpty)) {
        if (details.length >= 3) {
          break;
        }
        if (!details.contains(achievement)) {
          details.add(achievement);
        }
      }

      final companyParts = <String>[];
      if (experience.company.trim().isNotEmpty) {
        companyParts.add(experience.company.trim());
      }
      final location = (experience.location ?? '').trim();
      if (location.isNotEmpty) {
        companyParts.add(location);
      }
      final endLabel = experience.isCurrentlyWorking
          ? 'Present'
          : (experience.endDate?.year.toString() ??
              experience.startDate.year.toString());

      return _ProfessionalAccountantExperienceData(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine:
            companyParts.isNotEmpty ? companyParts.join(' | ') : 'Company',
        dateRange: '${_monthLabel(experience.startDate)} - $endLabel',
        details: details,
      );
    }).toList(growable: false);
  }

  _ProfessionalAccountantEducationData get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _ProfessionalAccountantEducationData(
        degree: 'B.Sc. Accounting',
        institution: 'State University',
        year: '2019',
      );
    }

    final education = values.first;
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');

    return _ProfessionalAccountantEducationData(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: education.institution.trim().isNotEmpty
          ? education.institution.trim()
          : 'Institution',
      year: education.isCurrentlyStudying
          ? 'Present'
          : (education.endDate?.year.toString() ??
              education.startDate.year.toString()),
    );
  }

  List<String> get _skills {
    final values = resume?.skills ?? const <Skill>[];
    if (values.isEmpty) {
      return const [
        'Financial Reporting',
        'Audit',
        'Forecasting',
        'Project Management',
        'Spreadsheet Modeling',
        'SQL',
      ];
    }

    return values
        .map((skill) => skill.name.trim())
        .where((skill) => skill.isNotEmpty)
        .take(6)
        .toList(growable: false);
  }

  List<_ProfessionalAccountantProjectData> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _ProfessionalAccountantProjectData(
          title: 'Finance Dashboard Refresh',
          details: [
            'Built reporting workflows and summary views that aligned operational updates with executive visibility.',
          ],
          links: ['finance.example.com'],
        ),
      ];
    }

    return values.take(2).map((project) {
      final content = ProfessionalAccountantTemplateSupport.projectContent(
        project,
        maxSummaryLines: 2,
      );
      return _ProfessionalAccountantProjectData(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        details: content.details,
        links: content.links,
      );
    }).toList(growable: false);
  }

  List<String> get _certifications {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const [
        'CPA',
        'PMP Certification',
      ];
    }

    return values
        .map((certification) {
          final name = certification.name.trim();
          final issuer = certification.issuer.trim();
          if (issuer.isEmpty) {
            return name;
          }
          return '$name | $issuer';
        })
        .where((value) => value.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  List<String> get _languages {
    final values = resume?.languages ?? const <Language>[];
    if (values.isEmpty) {
      return const [
        'English | Professional',
        'French | Professional',
      ];
    }

    return values
        .map((language) {
          final proficiency = language.proficiency.trim();
          final name = language.name.trim();
          return proficiency.isEmpty ? name : '$name | $proficiency';
        })
        .where((value) => value.isNotEmpty)
        .take(4)
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                      const SizedBox(height: 1),
                      _text(
                        _title,
                        size: 4.35,
                        color: Colors.white70,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: _headerContactWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _contactItems
                        .map(_headerContactItem)
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_summaryLines.isNotEmpty) ...[
                            _sectionHeader('PROFESSIONAL SUMMARY'),
                            ..._summaryLines.map(_summaryBullet),
                            const SizedBox(height: 4),
                          ],
                          if (_projects.isNotEmpty) ...[
                            _sectionHeader('PROJECTS'),
                            ..._projects.map(_projectBlock),
                            const SizedBox(height: 4),
                          ],
                          if (_experiences.isNotEmpty) ...[
                            _sectionHeader('EXPERIENCE'),
                            ..._experiences.map(_experienceBlock),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1.15,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: _rule,
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_skills.isNotEmpty) ...[
                            _sectionHeader('SKILLS'),
                            ..._skills.map(_sidebarBullet),
                            const SizedBox(height: 4),
                          ],
                          _sectionHeader('EDUCATION'),
                          _text(
                            _education.degree,
                            size: 4.35,
                            color: _ink,
                            weight: FontWeight.w700,
                            maxLines: 2,
                          ),
                          _text(
                            _education.institution,
                            size: 3.75,
                            color: _muted,
                            maxLines: 2,
                          ),
                          _text(_education.year, size: 3.6, color: _muted),
                          if (_certifications.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _sectionHeader('CERTIFICATIONS'),
                            ..._certifications.map(_sidebarLine),
                          ],
                          if (_languages.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _sectionHeader('LANGUAGES'),
                            ..._languages.map(_sidebarLine),
                          ],
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
    );
  }

  Widget _headerContactItem(_ProfessionalAccountantContactItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _text(
              item.label,
              size: 3.0,
              color: Colors.white70,
              align: TextAlign.right,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _headerIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 6.2, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(title, size: 4.35, color: _accent, weight: FontWeight.bold),
          const SizedBox(height: 1.2),
          Container(width: double.infinity, height: 1, color: _rule),
        ],
      ),
    );
  }

  Widget _summaryBullet(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.1),
            child: Container(
              width: 4.8,
              height: 4.8,
              decoration: BoxDecoration(
                color: _pageBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _accent.withValues(alpha: 0.78), width: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 3.2),
          Expanded(
            child: _text(
              line,
              size: 3.95,
              color: _ink.withValues(alpha: 0.88),
              align: TextAlign.justify,
              maxLines: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceBlock(_ProfessionalAccountantExperienceData experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  experience.title,
                  size: 4.9,
                  color: _ink,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              _text(
                experience.dateRange,
                size: 3.45,
                color: _muted,
                align: TextAlign.right,
                maxLines: 1,
              ),
            ],
          ),
          _text(
            experience.companyLine,
            size: 3.85,
            color: _muted,
            maxLines: 2,
          ),
          ...experience.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(top: 0.9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.2),
                    child: Container(
                      width: 3.4,
                      height: 3.4,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _text(
                      detail,
                      size: 3.8,
                      color: _ink.withValues(alpha: 0.86),
                      align: TextAlign.justify,
                      maxLines: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectBlock(_ProfessionalAccountantProjectData project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.2),
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
              padding: const EdgeInsets.only(top: 0.7),
              child: _text(
                detail,
                size: 3.75,
                color: _muted,
                align: TextAlign.justify,
                maxLines: 0,
              ),
            ),
          ),
          ...project.links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(top: 0.6),
              child: _text(
                link,
                size: 3.12,
                color: _accent,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarBullet(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.3),
            child: Container(
              width: 3.4,
              height: 3.4,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(child: _text(label, size: 3.78, color: _ink, maxLines: 2)),
        ],
      ),
    );
  }

  Widget _sidebarLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.4),
      child: _text(line, size: 3.72, color: _muted, maxLines: 2),
    );
  }

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

  List<String> _splitLines(String text, {int? maxItems}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final parts = raw
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (maxItems == null) {
      return parts;
    }

    return parts.take(maxItems).toList(growable: false);
  }

  String _cleanListMarker(String value) {
    return value.trim().replaceFirst(RegExp(r'^[-*•▪■□✪✦★☆➣◦○]+\s*'), '');
  }

  IconData _contactIcon(ProfessionalAccountantContactKind kind) {
    switch (kind) {
      case ProfessionalAccountantContactKind.email:
        return Icons.email_outlined;
      case ProfessionalAccountantContactKind.phone:
        return Icons.call_outlined;
      case ProfessionalAccountantContactKind.location:
        return Icons.location_on_outlined;
      case ProfessionalAccountantContactKind.linkedin:
        return Icons.link_outlined;
      case ProfessionalAccountantContactKind.github:
        return Icons.code_outlined;
      case ProfessionalAccountantContactKind.website:
        return Icons.language_outlined;
    }
  }

  String _monthLabel(DateTime value) {
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
    return '${months[value.month - 1]} ${value.year}';
  }
}

class _ProfessionalAccountantContactItem {
  const _ProfessionalAccountantContactItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _ProfessionalAccountantExperienceData {
  const _ProfessionalAccountantExperienceData({
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

class _ProfessionalAccountantEducationData {
  const _ProfessionalAccountantEducationData({
    required this.degree,
    required this.institution,
    required this.year,
  });

  final String degree;
  final String institution;
  final String year;
}

class _ProfessionalAccountantProjectData {
  const _ProfessionalAccountantProjectData({
    required this.title,
    this.details = const [],
    this.links = const [],
  });

  final String title;
  final List<String> details;
  final List<String> links;
}
