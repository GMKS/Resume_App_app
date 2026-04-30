import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/utils/user_custom_sections.dart';

class VividProResumeTemplatePreview extends StatelessWidget {
  const VividProResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'JOHN SMITH';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Software Engineer';
  }

  String get _email {
    final value = resume?.personalInfo.email.trim() ?? '';
    return value.isNotEmpty ? value : 'john@email.com';
  }

  String get _phone {
    final value = resume?.personalInfo.phone.trim() ?? '';
    return value.isNotEmpty ? value : '(555) 123-4567';
  }

  String get _linkedin {
    final value = resume?.personalInfo.linkedIn?.trim() ?? '';
    return value.isNotEmpty ? value : 'linkedin.com/in/js';
  }

  String get _github {
    final value = resume?.personalInfo.github?.trim() ?? '';
    return value.isNotEmpty ? value : 'github.com/jsmith';
  }

  String get _website {
    final value = resume?.personalInfo.website?.trim() ?? '';
    return value.isNotEmpty ? value : 'johnsmith.dev';
  }

  String get _objective {
    final value = resume?.objective?.trim() ?? '';
    return value.isNotEmpty
        ? value
        : 'Results-driven professional with expertise in delivering high-quality solutions.';
  }

  Experience? get _experience =>
      resume != null && resume!.experience.isNotEmpty ? resume!.experience.first : null;

  Education? get _education =>
      resume != null && resume!.education.isNotEmpty ? resume!.education.first : null;

  List<String> get _skills {
    final values = resume?.skills.map((skill) => skill.name.trim()).where((skill) => skill.isNotEmpty).toList(growable: false) ?? const <String>[];
    return values.isNotEmpty
        ? values
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
  }

  List<String> get _projectTitles {
    final values = resume?.projects
            .map((project) => project.title.trim())
            .where((title) => title.isNotEmpty)
            .take(2)
            .toList(growable: false) ??
        const <String>[];
    return values.isNotEmpty
        ? values
        : const ['Portfolio Website', 'Task Management App'];
  }

  List<String> get _languageLines {
    final values = resume?.languages
            .map((language) => '${language.name} ${language.proficiency}'.trim())
            .where((line) => line.isNotEmpty)
            .take(3)
            .toList(growable: false) ??
        const <String>[];
    return values.isNotEmpty
        ? values
        : const ['English Professional', 'German Professional'];
  }

  List<String> get _certificationLines {
    final values = resume?.certifications
            .map(
              (certification) => certification.issuer.isNotEmpty
                  ? '${certification.name}  •  ${certification.issuer}'
                  : certification.name,
            )
            .where((line) => line.trim().isNotEmpty)
            .take(2)
            .toList(growable: false) ??
        const <String>[];
    return values.isNotEmpty
        ? values
        : const [
            'AWS Certified Developer  •  Amazon',
            'Scrum Master  •  Scrum Alliance',
          ];
  }

  String get _experienceTitle {
    final value = _experience?.position.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Developer';
  }

  String get _experienceMeta {
    final experience = _experience;
    if (experience == null) {
      return 'TechCorp  •  2021 - Present';
    }

    final end = experience.isCurrentlyWorking
        ? 'Present'
        : (experience.endDate?.year.toString() ?? 'Present');
    return '${experience.company}  •  ${experience.startDate.year} - $end';
  }

  String get _experienceSummary {
    final experience = _experience;
    if (experience == null) {
      return 'Led team of 5 to deliver cloud-based platform.';
    }
    if (experience.achievements.isNotEmpty) {
      return experience.achievements.first.trim();
    }
    final value = experience.description.trim();
    return value.isNotEmpty
        ? value
        : 'Led team of 5 to deliver cloud-based platform.';
  }

  String get _educationLine {
    final education = _education;
    if (education == null) {
      return 'B.Sc. Computer Science';
    }
    return '${education.degree} ${education.fieldOfStudy}'.trim();
  }

  String get _educationMeta {
    final education = _education;
    if (education == null) {
      return 'State University  •  2019';
    }
    final year = education.endDate?.year ?? education.startDate.year;
    return '${education.institution}  •  $year';
  }

  @override
  Widget build(BuildContext context) {
    final previewCustomSections = orderedUserCustomSectionsFromList(
      resume?.customSections ?? const <CustomSection>[],
    ).where((section) => section.items.isNotEmpty).toList(growable: false);

    Widget text(
      String value, {
      double size = 4.0,
      Color? color,
      FontWeight weight = FontWeight.normal,
      bool justify = false,
      int maxLines = 1,
    }) {
      return Text(
        value,
        maxLines: maxLines <= 0 ? null : maxLines,
        overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
        textAlign: justify ? TextAlign.justify : TextAlign.left,
        style: TextStyle(
          fontSize: size,
          color: color ?? Colors.grey.shade700,
          fontWeight: weight,
          height: 1.15,
        ),
      );
    }

    Widget sectionHeader(String title) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(
              title,
              size: 4.5,
              color: accentColor,
              weight: FontWeight.bold,
            ),
            Container(
              height: 0.8,
              color: accentColor,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
          ],
        );

    Widget skillChip(String label, Color color) => Container(
          margin: const EdgeInsets.only(right: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: color, width: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: text(
            label,
            size: 3.45,
            color: Colors.grey.shade900,
            weight: FontWeight.w600,
          ),
        );

    Widget detailLine(String line, {double size = 3.6}) => Padding(
          padding: const EdgeInsets.only(bottom: 1.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3.4,
                height: 3.4,
                margin: const EdgeInsets.only(top: 0.9, right: 3),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: text(
                  line,
                  size: size,
                  color: Colors.grey.shade700,
                  justify: true,
                  maxLines: 0,
                ),
              ),
            ],
          ),
        );

    Widget? customSectionItemBlock(CustomSectionItem item) {
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
        padding: const EdgeInsets.only(bottom: 2.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayItem.heading.isNotEmpty)
              text(
                displayItem.heading,
                size: 4.1,
                color: Colors.grey.shade800,
                weight: FontWeight.w700,
                maxLines: 0,
              ),
            if (metaParts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.6, bottom: 1.2),
                child: text(
                  metaParts.join('  |  '),
                  size: 3.45,
                  color: accentColor,
                  weight: FontWeight.w600,
                  maxLines: 0,
                ),
              ),
            ...displayItem.detailLines.map((line) => detailLine(line)),
          ],
        ),
      );
    }

    Widget? customSectionBlock(CustomSection section) {
      final title = normalizeUserCustomSectionTitle(section.title);
      final itemBlocks = section.items
          .map(customSectionItemBlock)
          .whereType<Widget>()
          .toList(growable: false);

      if (itemBlocks.isEmpty) {
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(title.isEmpty ? 'Custom Section' : title),
          ...itemBlocks,
        ],
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: accentColor,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  _name,
                  size: 8.5,
                  color: Colors.white,
                  weight: FontWeight.bold,
                ),
                text(
                  _title,
                  size: 5.0,
                  color: Colors.white70,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    text(_email, size: 3.6, color: Colors.white70),
                    text(_phone, size: 3.6, color: Colors.white70),
                    if (_linkedin.isNotEmpty)
                      text(_linkedin, size: 3.6, color: Colors.white70),
                    if (_github.isNotEmpty)
                      text(_github, size: 3.6, color: Colors.white70),
                    if (_website.isNotEmpty)
                      text(_website, size: 3.6, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionHeader('PROFESSIONAL SUMMARY'),
                    text(
                      _objective,
                      size: 3.9,
                      color: Colors.grey.shade700,
                      justify: true,
                      maxLines: 0,
                    ),
                    const SizedBox(height: 3),
                    sectionHeader('EXPERIENCE'),
                    text(
                      _experienceTitle,
                      size: 4.4,
                      color: Colors.grey.shade800,
                      weight: FontWeight.w600,
                      maxLines: 2,
                    ),
                    text(
                      _experienceMeta,
                      size: 3.9,
                      color: Colors.grey.shade600,
                      maxLines: 2,
                    ),
                    text(
                      _experienceSummary,
                      size: 3.9,
                      color: Colors.grey.shade700,
                      justify: true,
                      maxLines: 0,
                    ),
                    const SizedBox(height: 3),
                    sectionHeader('EDUCATION'),
                    text(
                      _educationLine,
                      size: 4.4,
                      color: Colors.grey.shade800,
                      weight: FontWeight.w600,
                      maxLines: 2,
                    ),
                    text(
                      _educationMeta,
                      size: 3.9,
                      color: Colors.grey.shade500,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    sectionHeader('SKILLS'),
                    Wrap(
                      children: _skills.take(4).toList().asMap().entries.map((entry) {
                        const chipColors = [
                          Color(0xFF7C3AED),
                          Color(0xFFEC4899),
                          Color(0xFFF59E0B),
                          Color(0xFF10B981),
                        ];
                        return skillChip(
                          entry.value,
                          chipColors[entry.key % chipColors.length],
                        );
                      }).toList(growable: false),
                    ),
                    if (_languageLines.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      sectionHeader('LANGUAGES'),
                      ..._languageLines.map(
                        (line) => text(
                          line,
                          size: 3.9,
                          color: Colors.grey.shade700,
                          maxLines: 0,
                        ),
                      ),
                    ],
                    if (_projectTitles.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      sectionHeader('PROJECTS'),
                      ..._projectTitles.map(
                        (title) => text(
                          title,
                          size: 4.1,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600,
                          maxLines: 0,
                        ),
                      ),
                    ],
                    if (_certificationLines.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      sectionHeader('CERTIFICATIONS'),
                      ..._certificationLines.map(
                        (line) => text(
                          line,
                          size: 4.0,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600,
                          maxLines: 0,
                        ),
                      ),
                    ],
                    for (final section in previewCustomSections)
                      if (customSectionBlock(section) case final block?) block,
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