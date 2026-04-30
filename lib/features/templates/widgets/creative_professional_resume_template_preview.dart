import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../creative_professional_template_support.dart';

class CreativeProfessionalResumeTemplatePreview extends StatelessWidget {
  const CreativeProfessionalResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(CreativeProfessionalTemplateSupport.pageHex);
  Color get _paper =>
      const Color(CreativeProfessionalTemplateSupport.paperHex);
  Color get _header =>
      const Color(CreativeProfessionalTemplateSupport.headerHex);
  Color get _headerText =>
      const Color(CreativeProfessionalTemplateSupport.headerTextHex);
  Color get _accent =>
      const Color(CreativeProfessionalTemplateSupport.accentHex);
  Color get _sidebar =>
      const Color(CreativeProfessionalTemplateSupport.sidebarHex);
  Color get _line => const Color(CreativeProfessionalTemplateSupport.lineHex);
  Color get _ink => const Color(CreativeProfessionalTemplateSupport.inkHex);
  Color get _muted =>
      const Color(CreativeProfessionalTemplateSupport.mutedHex);
  Color get _sidebarText =>
      const Color(CreativeProfessionalTemplateSupport.sidebarTextHex);
  Color get _avatarFill =>
      const Color(CreativeProfessionalTemplateSupport.avatarFillHex);

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name =
        CreativeProfessionalTemplateSupport.displayName(previewResume).toUpperCase();
    final title =
        CreativeProfessionalTemplateSupport.displayTitle(previewResume);
    final address =
        CreativeProfessionalTemplateSupport.address(previewResume?.personalInfo);
    final contactItems = CreativeProfessionalTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final educationEntries =
        CreativeProfessionalTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final skillNames = CreativeProfessionalTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: null,
    );
    final summaryLines = CreativeProfessionalTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final experienceEntries =
        CreativeProfessionalTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final projectEntries = CreativeProfessionalTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries =
        CreativeProfessionalTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = CreativeProfessionalTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            CreativeProfessionalContactItem(
              kind: CreativeProfessionalContactKind.phone,
              label: '(555) 123-4567',
            ),
            CreativeProfessionalContactItem(
              kind: CreativeProfessionalContactKind.email,
              label: 'hello@portfolio.dev',
            ),
            CreativeProfessionalContactItem(
              kind: CreativeProfessionalContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            CreativeProfessionalContactItem(
              kind: CreativeProfessionalContactKind.github,
              label: 'github.com/johnsmith',
            ),
            CreativeProfessionalContactItem(
              kind: CreativeProfessionalContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewAddress = address.isNotEmpty ? address : 'New York, NY';
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            CreativeProfessionalEducationEntry(
              degreeLine: 'B.Des. Visual Design',
              institutionLine: 'Parsons School of Design',
              dateRange: '2016 - 2020',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Figma', 'Brand Systems', 'Illustration', 'Adobe CC'];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Creative lead shaping campaign storytelling, product launches, and polished digital experiences.',
            'Translates strategy into launch-ready visuals, cross-channel systems, and measurable brand direction.',
            'Partners with marketing and product teams to deliver consistent, high-quality creative execution.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            CreativeProfessionalExperienceEntry(
              title: 'Senior Designer',
              companyLine: 'North Studio  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            CreativeProfessionalProjectEntry(
              title: 'Brand Campaign System',
              detailLines: [
                'Refined launch storytelling for web, social, and print assets.',
              ],
              links: ['example.com/case-study'],
            ),
          ];
    final certificationSummary = certificationEntries.isNotEmpty
        ? _compactSummary(
            certificationEntries.map((entry) => entry.name).toList(),
          )
        : 'Adobe Certified Professional';
    final skillSummary = previewSkills.isNotEmpty
      ? _compactSummary(previewSkills)
      : 'Figma  •  Brand Systems  •  Illustration  •  Adobe CC';
    final languageSummary = languageLines.isNotEmpty
        ? _compactSummary(languageLines)
        : 'English  |  Native';

    Text text(
      String value, {
      double size = 2,
      Color? color,
      FontWeight weight = FontWeight.normal,
      TextAlign align = TextAlign.left,
      int? maxLines,
      double height = 1.14,
    }) {
      return Text(
        value,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
      );
    }

    Widget sidebarHeader(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: text(
            title,
            size: 2.7,
            color: _accent,
            weight: FontWeight.bold,
          ),
        );

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                title,
                size: 3,
                color: const Color(0xFF2C403F),
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.65,
                color: _line,
                margin: const EdgeInsets.only(top: 0.7),
              ),
            ],
          ),
        );

    Widget justifiedText(
      String value, {
      double size = 1.66,
      Color? color,
      int maxLines = 2,
      FontWeight weight = FontWeight.normal,
    }) {
      return SizedBox(
        width: double.infinity,
        child: text(
          value,
          size: size,
          color: color,
          weight: weight,
          align: TextAlign.justify,
          maxLines: maxLines,
          height: 1.18,
        ),
      );
    }

    Widget summaryPoint(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.1),
                child: text(
                  '◆',
                  size: 1.95,
                  color: _accent,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 1.4),
              Expanded(
                child: justifiedText(
                  line,
                  size: 1.66,
                  color: Colors.grey.shade700,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(CreativeProfessionalExperienceEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.15),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.title,
                  size: 2.05,
                  color: Colors.grey.shade900,
                  weight: FontWeight.w700,
                  maxLines: 1,
                ),
                text(
                  entry.companyLine,
                  size: 1.72,
                  color: Colors.grey.shade600,
                  maxLines: 1,
                ),
                if (entry.detailLines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 0.35),
                    child: justifiedText(
                      entry.detailLines.first,
                      size: 1.56,
                      color: Colors.grey.shade700,
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
          ),
        );

    Widget projectBlock(CreativeProfessionalProjectEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.title,
                  size: 1.74,
                  color: Colors.grey.shade800,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
                if (entry.detailLines.isNotEmpty)
                  justifiedText(
                    entry.detailLines.first,
                    size: 1.58,
                    color: Colors.grey.shade700,
                    maxLines: 2,
                  ),
                if (entry.links.isNotEmpty)
                  text(
                    entry.links.first,
                    size: 1.56,
                    color: _header,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        );

    return Container(
      color: _page,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              decoration: BoxDecoration(
                color: _header,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: photoBytes == null ? _avatarFill : null,
                      border: Border.all(color: Colors.white, width: 1),
                      image: photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(photoBytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoBytes == null
                        ? Icon(Icons.person, size: 12, color: _header)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text(
                          name,
                          size: 5.45,
                          color: Colors.white,
                          weight: FontWeight.w900,
                        ),
                        text(
                          title,
                          size: 2.45,
                          color: _headerText,
                          weight: FontWeight.w600,
                        ),
                        if (previewAddress.isNotEmpty)
                          text(
                            previewAddress,
                            size: 1.78,
                            color: _headerText,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 42,
                    color: _sidebar,
                    padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sidebarHeader('EDUCATION'),
                        ...previewEducation.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 1.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  entry.degreeLine,
                                  size: 1.76,
                                  color: Colors.grey.shade800,
                                  weight: FontWeight.w700,
                                  maxLines: 2,
                                ),
                                text(
                                  '${entry.institutionLine}  •  ${entry.dateRange}',
                                  size: 1.58,
                                  color: Colors.grey.shade700,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2.6),
                        sidebarHeader('SKILLS'),
                        justifiedText(
                          skillSummary,
                          size: 1.56,
                          color: Colors.grey.shade700,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 2.6),
                        sidebarHeader('CONTACT'),
                        ...previewContacts.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 0.8),
                            child: text(
                              item.label,
                              size: 1.66,
                              color: Colors.grey.shade700,
                              maxLines: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2.6),
                        sidebarHeader('LANGUAGES'),
                        justifiedText(
                          languageSummary,
                          size: 1.56,
                          color: Colors.grey.shade700,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 2.6),
                        sidebarHeader('CERTIFICATIONS'),
                        justifiedText(
                          certificationSummary,
                          size: 1.52,
                          color: Colors.grey.shade700,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionHeader('ABOUT'),
                          ...previewSummaryLines.map(summaryPoint),
                          const SizedBox(height: 2.4),
                          sectionHeader('EXPERIENCE'),
                          ...previewExperience.map(experienceBlock),
                          const SizedBox(height: 2.2),
                          sectionHeader('PROJECTS'),
                          ...previewProjects.map(projectBlock),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Uint8List? _photoBytes(String? encoded) {
    final value = encoded?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static String _compactSummary(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('  •  ');
  }
}