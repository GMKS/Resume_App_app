import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';

class MinimalResumeTemplatePreview extends StatelessWidget {
  const MinimalResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _pageBg => const Color(0xFFF6F2E8);
  Color get _ink => const Color(0xFF243B53);
  Color get _muted => const Color(0xFF6B7280);

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'John Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  String get _phone {
    final value = resume?.personalInfo.phone.trim() ?? '';
    return value.isNotEmpty ? value : '(555) 123-4567';
  }

  String get _emailOnly {
    final value = resume?.personalInfo.email.trim() ?? '';
    return value.isNotEmpty ? value : 'john.smith@email.com';
  }

  String get _address {
    final value = resume?.personalInfo.address.trim() ?? '';
    return value.isNotEmpty ? value : 'New York, NY';
  }

  String get _linkedin {
    final value = _compactUrl(resume?.personalInfo.linkedIn ?? '');
    return value.isNotEmpty ? value : 'linkedin.com/in/johnsmith';
  }

  String get _github {
    final value = _compactUrl(resume?.personalInfo.github ?? '');
    return value.isNotEmpty ? value : 'github.com/johnsmith';
  }

  String get _website {
    final value = _compactUrl(resume?.personalInfo.website ?? '');
    return value.isNotEmpty ? value : 'johnsmith.dev';
  }

  List<String> get _aboutLines {
    final lines = _splitLines(resume?.objective ?? '', maxItems: 2);
    if (lines.isNotEmpty) {
      return lines;
    }

    return const [
      'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
    ];
  }

  List<_MinimalPreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _MinimalPreviewExperience(
          title: 'Senior Developer',
          companyLine: 'TechCorp • 2021 - Present',
          detail:
              'Led team of 5 to deliver cloud-based platform with measurable improvements.',
        ),
        _MinimalPreviewExperience(
          title: 'Junior Developer',
          companyLine: 'StartupXYZ • 2019 - 2020',
          detail: '',
        ),
      ];
    }

    return values.take(2).map((experience) {
      final years = '${experience.startDate.year} - '
          '${experience.isCurrentlyWorking ? 'Present' : (experience.endDate?.year.toString() ?? 'Present')}';
      final company = experience.company.trim().isNotEmpty
          ? experience.company.trim()
          : 'Company';

      final detailCandidates = <String>[];
      for (final achievement in experience.achievements) {
        final trimmed = achievement.trim();
        if (trimmed.isNotEmpty && !detailCandidates.contains(trimmed)) {
          detailCandidates.add(trimmed);
        }
      }
      for (final line in _splitLines(experience.description, maxItems: 2)) {
        if (!detailCandidates.contains(line)) {
          detailCandidates.add(line);
        }
      }

      return _MinimalPreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        companyLine: '$company • $years',
        detail: detailCandidates.isNotEmpty ? detailCandidates.first : '',
      );
    }).toList(growable: false);
  }

  _MinimalPreviewEducation get _education {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const _MinimalPreviewEducation(
        degree: 'B.Sc. Computer Science Software Engineering',
        institution: 'State University • 2019',
      );
    }

    final education = values.first;
    final degree = '${education.degree} ${education.fieldOfStudy}'.trim();
    final year = (education.endDate ?? education.startDate).year;
    final institution = education.institution.trim().isNotEmpty
        ? education.institution.trim()
        : 'Institution';

    return _MinimalPreviewEducation(
      degree: degree.isNotEmpty ? degree : 'Education',
      institution: '$institution • $year',
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

  List<_MinimalPreviewProject> get _projects {
    final values = resume?.projects ?? const <Project>[];
    if (values.isEmpty) {
      return const [
        _MinimalPreviewProject(
          title: 'Portfolio Website',
          description:
              'Developed a responsive portfolio site showcasing projects and skills.',
          url: '',
        ),
        _MinimalPreviewProject(
          title: 'Task Management App',
          description:
              'Built a productivity-focused app with authentication and offline sync.',
          url: '',
        ),
      ];
    }

    return values.take(2).map((project) {
      final description = project.description.trim().isNotEmpty
          ? project.description.trim()
          : project.technologies.join(', ');
      return _MinimalPreviewProject(
        title:
            project.title.trim().isNotEmpty ? project.title.trim() : 'Project',
        description: description,
        url: _compactUrl(project.url ?? ''),
      );
    }).toList(growable: false);
  }

  List<String> get _certificationLines {
    final values = resume?.certifications ?? const <Certification>[];
    if (values.isEmpty) {
      return const [
        'AWS Certified Developer • Amazon',
        'Scrum Master • Scrum Alliance',
      ];
    }

    return values
        .map((certification) {
          final issuer = certification.issuer.trim();
          return issuer.isNotEmpty
              ? '${certification.name} • $issuer'
              : certification.name;
        })
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  List<String> get _languageLines {
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
    bool justify = false,
  }) {
    return Text(
      text,
      textAlign: justify ? TextAlign.justify : align,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: 1.14,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _text(
        title,
        size: 5.0,
        color: _accent,
        weight: FontWeight.bold,
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
              width: 4.4,
              height: 4.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _muted.withValues(alpha: 0.55), width: 0.6),
              ),
              child: Center(
                child: Container(
                  width: 1.5,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: _muted.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _text(
              line,
              size: 3.85,
              color: _muted,
              justify: true,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      margin: const EdgeInsets.only(right: 3, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4.4, vertical: 1.9),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: _text(
        skill,
        size: 3.4,
        color: _accent,
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(_phone, size: 3.75, color: _muted, maxLines: 1),
                      _text(_emailOnly, size: 3.75, color: _muted, maxLines: 1),
                      _text(_address, size: 3.75, color: _muted, maxLines: 2),
                      _text(_linkedin, size: 3.75, color: _muted, maxLines: 1),
                      _text(_github, size: 3.75, color: _muted, maxLines: 1),
                      _text(_website, size: 3.75, color: _muted, maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _text(
                          _name.toUpperCase(),
                          size: 7.6,
                          color: _ink,
                          weight: FontWeight.bold,
                          maxLines: 2,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _text(
                          _title,
                          size: 4.8,
                          color: _muted,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(height: 0.8, color: _accent.withValues(alpha: 0.30)),
            const SizedBox(height: 5),
            if (_aboutLines.isNotEmpty) ...[
              _sectionTitle('PROFESSIONAL SUMMARY'),
              ..._aboutLines.map(_summaryBullet),
              const SizedBox(height: 4),
            ],
            _sectionTitle('EXPERIENCE'),
            if (_experiences.isNotEmpty) ...[
              _text(
                _experiences.first.title,
                size: 5.5,
                color: Colors.grey.shade800,
                weight: FontWeight.w600,
                maxLines: 1,
              ),
              _text(
                _experiences.first.companyLine,
                size: 4.5,
                color: Colors.grey.shade500,
                maxLines: 1,
              ),
              if (_experiences.first.detail.isNotEmpty)
                _text(
                  _experiences.first.detail,
                  size: 4.5,
                  color: Colors.grey.shade700,
                  justify: true,
                  maxLines: 2,
                ),
            ],
            if (_experiences.length > 1) ...[
              const SizedBox(height: 3),
              _text(
                _experiences[1].title,
                size: 5.0,
                color: Colors.grey.shade800,
                weight: FontWeight.w600,
                maxLines: 1,
              ),
              _text(
                _experiences[1].companyLine,
                size: 4.0,
                color: Colors.grey.shade500,
                maxLines: 1,
              ),
            ],
            const SizedBox(height: 4),
            _sectionTitle('EDUCATION'),
            _text(
              _education.degree,
              size: 5.5,
              color: Colors.grey.shade800,
              weight: FontWeight.w600,
              maxLines: 2,
            ),
            _text(
              _education.institution,
              size: 4.5,
              color: Colors.grey.shade500,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            _sectionTitle('SKILLS'),
            Wrap(
              children: _skills.map(_skillChip).toList(growable: false),
            ),
            const SizedBox(height: 4),
            _sectionTitle('PROJECTS'),
            ..._projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(
                      project.title,
                      size: 4.6,
                      color: Colors.grey.shade800,
                      weight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    if (project.description.trim().isNotEmpty)
                      _text(
                        project.description,
                        size: 3.55,
                        color: Colors.grey.shade700,
                        maxLines: 2,
                        justify: true,
                      ),
                    if (project.url.isNotEmpty)
                      _text(
                        project.url,
                        size: 3.35,
                        color: _accent,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            _sectionTitle('CERTIFICATIONS'),
            ..._certificationLines.map(
              (line) => _text(
                line,
                size: 4.0,
                color: Colors.grey.shade700,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            _sectionTitle('LANGUAGES'),
            ..._languageLines.map(
              (line) => _text(
                line,
                size: 4.0,
                color: Colors.grey.shade700,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalPreviewExperience {
  const _MinimalPreviewExperience({
    required this.title,
    required this.companyLine,
    required this.detail,
  });

  final String title;
  final String companyLine;
  final String detail;
}

class _MinimalPreviewEducation {
  const _MinimalPreviewEducation({
    required this.degree,
    required this.institution,
  });

  final String degree;
  final String institution;
}

class _MinimalPreviewProject {
  const _MinimalPreviewProject({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}
