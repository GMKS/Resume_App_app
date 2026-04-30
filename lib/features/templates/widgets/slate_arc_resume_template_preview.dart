import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../slate_arc_template_support.dart';

class SlateArcResumeTemplatePreview extends StatelessWidget {
  const SlateArcResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _page => const Color(SlateArcTemplateSupport.pageHex);
  Color get _header => const Color(SlateArcTemplateSupport.headerHex);
  Color get _headerInk => const Color(SlateArcTemplateSupport.headerInkHex);
  Color get _sectionInk => const Color(SlateArcTemplateSupport.sectionInkHex);
  Color get _bodyMuted => const Color(SlateArcTemplateSupport.bodyMutedHex);
  Color get _divider => const Color(SlateArcTemplateSupport.dividerHex);
  Color get _photoBg => const Color(SlateArcTemplateSupport.photoBgHex);

  @override
  Widget build(BuildContext context) {
    final name = SlateArcTemplateSupport.displayName(resume).toUpperCase();
    final title = SlateArcTemplateSupport.displayTitle(resume);
    final contactItems = SlateArcTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final languageLines = SlateArcTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    final educationEntries = SlateArcTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
    );
    final skillNames = SlateArcTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final summaryLines = SlateArcTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: null,
    );
    final experienceEntries = SlateArcTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
    );
    final projectEntries = SlateArcTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: 2,
      compactLinks: true,
    );
    final certificationEntries = SlateArcTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            SlateArcContactItem(
              kind: SlateArcContactKind.address,
              label: 'San Francisco, CA',
            ),
            SlateArcContactItem(
              kind: SlateArcContactKind.phone,
              label: '(555) 123-4567',
            ),
            SlateArcContactItem(
              kind: SlateArcContactKind.email,
              label: 'john.smith@email.com',
            ),
            SlateArcContactItem(
              kind: SlateArcContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            SlateArcContactItem(
              kind: SlateArcContactKind.github,
              label: 'github.com/johnsmith',
            ),
            SlateArcContactItem(
              kind: SlateArcContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English Professional', 'German Professional'];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            SlateArcEducationEntry(
              degree: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateLabel: '2019',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
            'Builds maintainable delivery workflows while aligning design, engineering, and release quality.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            SlateArcExperienceEntry(
              title: 'Senior Developer',
              metaLine: 'TechCorp',
              dateRange: '2021 - Present',
              detailLines: [
                'Led team of 10 to deliver cloud-based platform',
              ],
            ),
            SlateArcExperienceEntry(
              title: 'Junior Developer',
              metaLine: 'StartupXYZ',
              dateRange: '2019 - 2020',
              detailLines: [
                'Implemented early product workflows and release fixes across the mobile app.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            SlateArcProjectEntry(
              title: 'Portfolio Website',
              detailLines: [
                'Built responsive case-study pages for client work.'
              ],
              links: ['example.com/portfolio'],
            ),
            SlateArcProjectEntry(
              title: 'Task Management App',
              detailLines: [
                'Created collaborative planning flows for distributed teams.'
              ],
              links: ['example.com/task-app'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            SlateArcCertificationEntry(
              name: 'AWS Certified Developer',
              metaLine: 'Amazon',
            ),
            SlateArcCertificationEntry(
              name: 'Scrum Master',
              metaLine: 'Scrum Alliance',
            ),
          ];

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
          color: color ?? _sectionInk,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: 1.18,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sectionTitle(String value, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: text(
            value,
            size: 3.8,
            color: color ?? _sectionInk,
            weight: FontWeight.bold,
          ),
        );

    Widget summaryStarLine(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 7.2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0.7, right: 1.8),
                  child: Icon(
                    Icons.star,
                    size: 5.4,
                    color: _sectionInk,
                  ),
                ),
              ),
              Expanded(
                child: text(
                  value,
                  size: 2.55,
                  color: _bodyMuted,
                  maxLines: 2,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _page,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: 34,
                decoration: BoxDecoration(
                  color: _header,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 8,
                right: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(
                      name,
                      size: 7.1,
                      color: _headerInk,
                      weight: FontWeight.w800,
                      maxLines: 1,
                    ),
                    text(
                      title,
                      size: 3.8,
                      color: _bodyMuted,
                      weight: FontWeight.w600,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: 6,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _photoBg,
                    border: Border.all(color: Colors.white, width: 2),
                    image: photoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(photoBytes),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoBytes == null
                      ? const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 38,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle('CONTACT', color: _accent),
                          ...previewContacts.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 0.8),
                              child: text(
                                item.label,
                                size: 2.55,
                                color: _bodyMuted,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          if (previewLanguages.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            sectionTitle('LANGUAGES', color: _accent),
                            ...previewLanguages.map(
                              (language) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 1.4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _accent.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: text(
                                  language,
                                  size: 2.2,
                                  color: _sectionInk,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ],
                          if (previewEducation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            sectionTitle('EDUCATION', color: _accent),
                            ...previewEducation.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 1.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    text(
                                      entry.degree,
                                      size: 2.6,
                                      color: _sectionInk,
                                      weight: FontWeight.w600,
                                      maxLines: 2,
                                    ),
                                    text(
                                      '${entry.institutionLine} - ${entry.dateLabel}',
                                      size: 2.4,
                                      color: _bodyMuted,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (previewSkills.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            sectionTitle('SKILLS', color: _accent),
                            ...previewSkills.map(
                              (skill) => Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: text(
                                  '- $skill',
                                  size: 2.55,
                                  color: _bodyMuted,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(width: 0.6, color: _divider),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          sectionTitle('PROFILE'),
                          ...previewSummaryLines.map(summaryStarLine),
                          const SizedBox(height: 4),
                          sectionTitle('EXPERIENCE'),
                          ...previewExperience.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  text(
                                    entry.title,
                                    size: 3.8,
                                    color: _sectionInk,
                                    weight: FontWeight.w700,
                                    maxLines: 1,
                                  ),
                                  text(
                                    '${entry.metaLine}  •  ${entry.dateRange}',
                                    size: 2.7,
                                    color: _accent,
                                    weight: FontWeight.w600,
                                    maxLines: 1,
                                  ),
                                  ...entry.detailLines.map(
                                    (detail) => Padding(
                                      padding: const EdgeInsets.only(top: 0.6),
                                      child: text(
                                        detail,
                                        size: 2.6,
                                        color: _bodyMuted,
                                        maxLines: 2,
                                        align: TextAlign.justify,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (previewProjects.isNotEmpty ||
                              previewCertifications.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            if (previewProjects.isNotEmpty) ...[
                              sectionTitle('PROJECTS'),
                              ...previewProjects.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      text(
                                        entry.title,
                                        size: 3.0,
                                        color: _sectionInk,
                                        weight: FontWeight.w600,
                                        maxLines: 1,
                                      ),
                                      ...entry.detailLines.map(
                                        (detail) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 0.5),
                                          child: text(
                                            detail,
                                            size: 2.55,
                                            color: _bodyMuted,
                                            maxLines: 2,
                                            align: TextAlign.justify,
                                          ),
                                        ),
                                      ),
                                      ...entry.links.map(
                                        (link) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 0.4),
                                          child: text(
                                            link,
                                            size: 2.45,
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
                                  padding: const EdgeInsets.only(bottom: 0.6),
                                  child: text(
                                    entry.metaLine.isNotEmpty
                                        ? '${entry.name} - ${entry.metaLine}'
                                        : entry.name,
                                    size: 2.75,
                                    color: _bodyMuted,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
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
