import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../editorial_frame_template_support.dart';

class EditorialFrameResumeTemplatePreview extends StatelessWidget {
  const EditorialFrameResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _paper => const Color(EditorialFrameTemplateSupport.paperHex);
  Color get _accent => const Color(EditorialFrameTemplateSupport.accentHex);
  Color get _ink => const Color(EditorialFrameTemplateSupport.inkHex);
  Color get _muted => const Color(EditorialFrameTemplateSupport.mutedHex);
  Color get _line => const Color(EditorialFrameTemplateSupport.lineHex);
  Color get _photoTint => const Color(EditorialFrameTemplateSupport.photoTintHex);

  @override
  Widget build(BuildContext context) {
    final name = EditorialFrameTemplateSupport.displayName(resume).toUpperCase();
    final title = EditorialFrameTemplateSupport.displayTitle(resume);
    final address = EditorialFrameTemplateSupport.displayAddress(resume);
    final contactItems = EditorialFrameTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
    );
    final skillNames = EditorialFrameTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 5,
    );
    final summaryLines = EditorialFrameTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 2,
    );
    final experienceEntries = EditorialFrameTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxDetailLines: 1,
    );
    final educationEntries = EditorialFrameTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
    );
    final projectEntries = EditorialFrameTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries = EditorialFrameTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
    );
    final languageLines = EditorialFrameTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 3,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            EditorialFrameContactItem(
              kind: EditorialFrameContactKind.phone,
              label: '(555) 123-4567',
            ),
            EditorialFrameContactItem(
              kind: EditorialFrameContactKind.email,
              label: 'john.smith@email.com',
            ),
            EditorialFrameContactItem(
              kind: EditorialFrameContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            EditorialFrameContactItem(
              kind: EditorialFrameContactKind.github,
              label: 'github.com/johnsmith',
            ),
            EditorialFrameContactItem(
              kind: EditorialFrameContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional with expertise in shipping polished digital products.',
            'Brings strong communication, delivery ownership, and structured execution.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            EditorialFrameExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp',
              dateRange: 'Jan 2021 - Present',
              detailLines: [
                'Led migration work and delivery planning for customer-facing applications.',
              ],
            ),
            EditorialFrameExperienceEntry(
              title: 'Junior Developer',
              companyLine: 'StartupXYZ',
              dateRange: 'Jun 2019 - Dec 2020',
              detailLines: [
                'Implemented product improvements and release fixes across the mobile app.',
              ],
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            EditorialFrameEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateLabel: '2019',
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            EditorialFrameProjectEntry(
              title: 'Portfolio Website',
              detailLines: ['Built a responsive case-study portfolio for client work.'],
              links: ['example.com/portfolio'],
            ),
            EditorialFrameProjectEntry(
              title: 'Task Management App',
              detailLines: ['Created collaborative planning flows for distributed teams.'],
              links: ['example.com/task-app'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            EditorialFrameCertificationEntry(
              name: 'AWS Certified Developer',
              metaLine: 'Amazon',
            ),
            EditorialFrameCertificationEntry(
              name: 'Scrum Master',
              metaLine: 'Scrum Alliance',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  •  Professional', 'German  •  Basic'];

    Text text(
      String value, {
      double size = 3,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
    }) {
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: 1.18,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sectionTitle(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.8),
          child: text(
            value,
            size: 3.75,
            color: _accent,
            weight: FontWeight.bold,
          ),
        );

    Widget bulletLine(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.2, right: 2.5),
                child: Container(
                  width: 2.8,
                  height: 2.8,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: text(
                  value,
                  size: 2.55,
                  color: _muted,
                  maxLines: 2,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _paper,
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: _line)),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _photoTint,
                      border: Border.all(color: _accent, width: 1),
                      image: photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(photoBytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoBytes == null
                        ? Icon(Icons.person, size: 14, color: _accent.withValues(alpha: 0.75))
                        : null,
                  ),
                  const SizedBox(height: 3),
                  text('CONTACT', size: 3.1, color: _accent, weight: FontWeight.bold),
                  const SizedBox(height: 1.4),
                  ...previewContacts.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 0.8),
                      child: text(
                        item.label,
                        size: 2.35,
                        color: _muted,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3.2),
                  text('EXPERTISE', size: 3.1, color: _accent, weight: FontWeight.bold),
                  const SizedBox(height: 1.4),
                  ...previewSkills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 0.8),
                      child: text(skill, size: 2.35, color: _muted, maxLines: 1),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text(name, size: 6.6, color: _accent, weight: FontWeight.w800, maxLines: 1),
                  text(title, size: 3.8, color: _muted, weight: FontWeight.w500, maxLines: 1),
                  if (address.isNotEmpty)
                    text(address, size: 2.55, color: _muted, maxLines: 1),
                  Container(
                    height: 0.7,
                    color: _line,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                  ),
                  sectionTitle('PERSONAL PROFILE'),
                  ...previewSummary.map(bulletLine),
                  const SizedBox(height: 3),
                  sectionTitle('WORK EXPERIENCE'),
                  ...previewExperience.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: text(
                                  entry.title,
                                  size: 3.45,
                                  color: _ink,
                                  weight: FontWeight.w700,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 3),
                              text(
                                entry.dateRange,
                                size: 2.2,
                                color: _muted,
                                maxLines: 1,
                                align: TextAlign.right,
                              ),
                            ],
                          ),
                          text(
                            entry.companyLine,
                            size: 2.55,
                            color: _muted,
                            weight: FontWeight.w600,
                            maxLines: 1,
                          ),
                          ...entry.detailLines.map(bulletLine),
                        ],
                      ),
                    ),
                  ),
                  if (previewEducation.isNotEmpty) ...[
                    const SizedBox(height: 1.5),
                    sectionTitle('EDUCATION'),
                    ...previewEducation.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            text(entry.degree, size: 3.1, color: _ink, weight: FontWeight.w700),
                            text(
                              '${entry.institutionLine}  •  ${entry.dateLabel}',
                              size: 2.5,
                              color: _muted,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (previewProjects.isNotEmpty) ...[
                    const SizedBox(height: 1.5),
                    sectionTitle('PROJECTS'),
                    ...previewProjects.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            text(entry.title, size: 2.95, color: _ink, weight: FontWeight.w600),
                            ...entry.detailLines.map(bulletLine),
                            ...entry.links.map(
                              (link) => Padding(
                                padding: const EdgeInsets.only(top: 0.2),
                                child: text(
                                  link,
                                  size: 2.35,
                                  color: _accent,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (previewCertifications.isNotEmpty) ...[
                    const SizedBox(height: 1.2),
                    sectionTitle('CERTIFICATIONS'),
                    ...previewCertifications.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.8),
                        child: text(
                          entry.metaLine.isNotEmpty
                              ? '${entry.name} - ${entry.metaLine}'
                              : entry.name,
                          size: 2.5,
                          color: _muted,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                  if (previewLanguages.isNotEmpty) ...[
                    const SizedBox(height: 1.2),
                    sectionTitle('LANGUAGES'),
                    ...previewLanguages.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.6),
                        child: text(line, size: 2.45, color: _muted, maxLines: 1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _photoBytes(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}