import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../professional_template_support.dart';

class ProfessionalResumeTemplatePreview extends StatelessWidget {
  const ProfessionalResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _paper => const Color(ProfessionalTemplateSupport.paperHex);
  Color get _card => const Color(ProfessionalTemplateSupport.cardHex);
  Color get _rail => const Color(ProfessionalTemplateSupport.railHex);
  Color get _ink => const Color(ProfessionalTemplateSupport.inkHex);
  Color get _muted => const Color(ProfessionalTemplateSupport.mutedHex);
  Color get _line => const Color(ProfessionalTemplateSupport.lineHex);
  Color get _accent => templateColor ?? accentColor;

  @override
  Widget build(BuildContext context) {
    final name = ProfessionalTemplateSupport.displayName(resume).toUpperCase();
    final title = ProfessionalTemplateSupport.displayTitle(resume);
    final contactItems = ProfessionalTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ProfessionalTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 6,
    );
    final experienceEntries = ProfessionalTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 3,
      yearOnly: true,
    );
    final skillNames = ProfessionalTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 6,
    );
    final educationEntries = ProfessionalTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final projectEntries = ProfessionalTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries = ProfessionalTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final languageLines = ProfessionalTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: null,
    );

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const <ProfessionalContactItem>[
            ProfessionalContactItem(
              kind: ProfessionalContactKind.email,
              label: 'john.smith@email.com',
            ),
            ProfessionalContactItem(
              kind: ProfessionalContactKind.phone,
              label: '(555) 123-4567',
            ),
            ProfessionalContactItem(
              kind: ProfessionalContactKind.address,
              label: 'New York, NY',
            ),
            ProfessionalContactItem(
              kind: ProfessionalContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            ProfessionalContactItem(
              kind: ProfessionalContactKind.github,
              label: 'github.com/johnsmith',
            ),
          ];

    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const <String>[
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
          ];

    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const <ProfessionalExperienceEntry>[
            ProfessionalExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp',
              locationLine: '',
              dateRange: '2021 - Present',
              detailLines: <String>[
                'Led team of 5 to deliver cloud-based platform.',
              ],
            ),
            ProfessionalExperienceEntry(
              title: 'Junior Developer',
              companyLine: 'StartupXYZ',
              locationLine: '',
              dateRange: '2019 - 2020',
              detailLines: <String>[
                'Reduced load time by 40% via code optimization.',
              ],
            ),
          ];

    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const <String>['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];

    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const <ProfessionalEducationEntry>[
            ProfessionalEducationEntry(
              degreeLine: 'B.Sc. Computer Science Software Engineering',
              institutionLine: 'State University',
              dateRange: '2015 - 2019',
            ),
          ];

    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const <ProfessionalProjectEntry>[
            ProfessionalProjectEntry(
              title: 'Portfolio Website',
              detailLines: <String>['Task Management App'],
            ),
          ];

    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const <ProfessionalCertificationEntry>[
            ProfessionalCertificationEntry(
              name: 'AWS Certified Developer',
              detailLines: <String>['Amazon'],
            ),
            ProfessionalCertificationEntry(
              name: 'Scrum Master',
              detailLines: <String>['Scrum Alliance'],
            ),
          ];

    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const <String>['English Professional', 'German Professional'];

    Text text(
      String value, {
      double size = 2.5,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
      double height = 1.16,
      TextDecoration? decoration,
    }) {
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          height: height,
          decoration: decoration,
          fontFamily: 'Helvetica',
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sectionHeader(String label) => Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.2),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: text(
                label,
                size: 2.45,
                color: Colors.white,
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(child: Container(height: 0.5, color: _line)),
            const SizedBox(width: 2),
            Container(
              width: 8,
              height: 1.4,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );

    Widget card(List<Widget> children) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(4.4),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );

    Widget contactChip(String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.3),
            border: Border.all(color: _line),
          ),
          child: text(
            value,
            size: 2.35,
            color: _muted,
            maxLines: 1,
          ),
        );

    Widget squareBulletLine(
      String value, {
      double size = 2.42,
      int? maxLines,
      Color? color,
      bool justify = true,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 2.6,
              height: 2.6,
              margin: const EdgeInsets.only(top: 2.0, right: 2.6),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(0.7),
              ),
            ),
            Expanded(
              child: text(
                value,
                size: size,
                color: color ?? _muted,
                maxLines: maxLines,
                align: justify ? TextAlign.justify : TextAlign.left,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    Widget experienceCard(ProfessionalExperienceEntry entry) => card([
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(
                      entry.title,
                      size: 3.65,
                      color: _ink,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                    text(
                      entry.companyLine,
                      size: 2.42,
                      color: _accent,
                      maxLines: 1,
                    ),
                    if (entry.locationLine.isNotEmpty)
                      text(
                        entry.locationLine,
                        size: 2.2,
                        color: _muted,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3.3),
                  border: Border.all(color: _line),
                ),
                child: text(
                  entry.dateRange,
                  size: 2.18,
                  color: _muted,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (entry.detailLines.isNotEmpty) ...[
            const SizedBox(height: 1.6),
            ...entry.detailLines.map(
              (line) => squareBulletLine(
                line,
                size: 2.32,
                maxLines: 2,
              ),
            ),
          ],
        ]);

    Widget projectCard(ProfessionalProjectEntry entry) => card([
          text(
            entry.title,
            size: 2.55,
            color: _ink,
            weight: FontWeight.w700,
            maxLines: 1,
          ),
          if (entry.detailLines.isNotEmpty) ...[
            const SizedBox(height: 1.0),
            ...entry.detailLines.map(
              (line) => squareBulletLine(
                line,
                size: 2.2,
                justify: true,
              ),
            ),
          ],
          if (entry.links.isNotEmpty) ...[
            const SizedBox(height: 0.4),
            ...entry.links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(top: 0.8),
                child: text(
                  link,
                  size: 2.18,
                  color: _accent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ]);

    Widget certificationCard(List<ProfessionalCertificationEntry> entries) =>
        card(
          entries.take(2).map((entry) {
            final trailing = entry.detailLines.isNotEmpty
                ? ' - ${entry.detailLines.first}'
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 0.8),
              child: text(
                '${entry.name}$trailing',
                size: 2.34,
                color: _muted,
                maxLines: 1,
              ),
            );
          }).toList(),
        );

    Widget languageCard(List<String> lines) => card(
          lines
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 0.8),
                  child: text(
                    line,
                    size: 2.34,
                    color: _muted,
                  ),
                ),
              )
              .toList(),
        );

    return Container(
      color: _paper,
      padding: const EdgeInsets.all(5),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _line),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 7,
              decoration: BoxDecoration(
                color: _rail,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _line),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 8,
                            color: _accent,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  text(
                                    name,
                                    size: 5.65,
                                    color: _ink,
                                    weight: FontWeight.bold,
                                    maxLines: 1,
                                  ),
                                  text(
                                    title,
                                    size: 2.95,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                  if (previewContacts.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 2,
                                      runSpacing: 2,
                                      children: previewContacts
                                          .map(
                                            (item) => contactChip(item.label),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  sectionHeader('PROFILE SNAPSHOT'),
                  const SizedBox(height: 2),
                  card(
                    previewSummary
                        .map(
                          (line) => squareBulletLine(
                            line,
                            maxLines: 2,
                          ),
                        )
                        .toList(),
                  ),
                  sectionHeader('CAREER EXPERIENCE'),
                  const SizedBox(height: 2),
                  ...previewExperience.map(experienceCard),
                  sectionHeader('CORE SKILLS'),
                  const SizedBox(height: 2),
                  card([
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: previewSkills.map(contactChip).toList(),
                    ),
                  ]),
                  sectionHeader('EDUCATION'),
                  const SizedBox(height: 2),
                  ...previewEducation.map(
                    (entry) => card([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  entry.degreeLine,
                                  size: 3.35,
                                  color: _ink,
                                  weight: FontWeight.w700,
                                  maxLines: 2,
                                ),
                                text(
                                  entry.institutionLine,
                                  size: 2.42,
                                  color: _muted,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 3),
                          text(
                            entry.dateRange,
                            size: 2.25,
                            color: _muted,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ]),
                  ),
                  if (previewProjects.isNotEmpty) ...[
                    sectionHeader('PROJECTS'),
                    const SizedBox(height: 2),
                    ...previewProjects.map(projectCard),
                  ],
                  if (previewCertifications.isNotEmpty) ...[
                    sectionHeader('CERTIFICATIONS'),
                    const SizedBox(height: 2),
                    certificationCard(previewCertifications),
                  ],
                  if (previewLanguages.isNotEmpty) ...[
                    sectionHeader('LANGUAGES'),
                    const SizedBox(height: 2),
                    languageCard(previewLanguages),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}