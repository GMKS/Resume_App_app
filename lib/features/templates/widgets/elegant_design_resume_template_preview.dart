import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../elegant_design_template_support.dart';

class ElegantDesignResumeTemplatePreview extends StatelessWidget {
  const ElegantDesignResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(ElegantDesignTemplateSupport.pageHex);
  Color get _sheet => const Color(ElegantDesignTemplateSupport.sheetHex);
  Color get _sidebar => const Color(ElegantDesignTemplateSupport.sidebarHex);
  Color get _line => const Color(ElegantDesignTemplateSupport.lineHex);
  Color get _heading => const Color(ElegantDesignTemplateSupport.headingHex);
  Color get _accent => const Color(ElegantDesignTemplateSupport.accentHex);
  Color get _ink => const Color(ElegantDesignTemplateSupport.inkHex);
  Color get _muted => const Color(ElegantDesignTemplateSupport.mutedHex);
  Color get _sidebarText =>
      const Color(ElegantDesignTemplateSupport.sidebarTextHex);
  Color get _avatarFill =>
      const Color(ElegantDesignTemplateSupport.avatarFillHex);

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name = ElegantDesignTemplateSupport.displayName(previewResume);
    final title =
        ElegantDesignTemplateSupport.displayTitle(previewResume).toUpperCase();
    final address =
        ElegantDesignTemplateSupport.address(previewResume?.personalInfo);
    final contactItems = ElegantDesignTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final educationEntries = ElegantDesignTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final skillNames = ElegantDesignTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final summaryLines = ElegantDesignTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final experienceEntries = ElegantDesignTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final projectEntries = ElegantDesignTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries =
        ElegantDesignTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = ElegantDesignTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            ElegantDesignContactItem(
              kind: ElegantDesignContactKind.phone,
              label: '(555) 123-4567',
            ),
            ElegantDesignContactItem(
              kind: ElegantDesignContactKind.email,
              label: 'john.smith@email.com',
            ),
            ElegantDesignContactItem(
              kind: ElegantDesignContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            ElegantDesignContactItem(
              kind: ElegantDesignContactKind.github,
              label: 'github.com/johnsmith',
            ),
            ElegantDesignContactItem(
              kind: ElegantDesignContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewAddress = address.isNotEmpty ? address : 'New York, NY';
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            ElegantDesignEducationEntry(
              degreeLine: 'MCA Computer Applications',
              institutionLine: 'Holy Jesus and Mary PG College',
              dateRange: '2006 - 2009',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['React', 'JavaScript', 'Communication', 'SQL'];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Over 13.6 years in software testing, automation, and quality delivery across enterprise platforms.',
            'Designs automation coverage across UI, services, and data workflows with strong delivery ownership.',
            'Collaborates with stakeholders to improve quality, reporting, and release confidence.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            ElegantDesignExperienceEntry(
              title: 'Automation Lead',
              companyLine: 'Tata Consultancy Services Limited  |  Hyderabad, India',
              dateRange: '2019 - 2025',
              detailLines: [
                'Led the automation team in developing and executing test automation scripts.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            ElegantDesignProjectEntry(
              title: 'Cigna Health Care',
              detailLines: [
                'Built analytics around health claims and generated automation insights for customer relationships.',
              ],
              links: ['example.com/cigna-health-care'],
            ),
          ];
    final previewCertificationSummary = certificationEntries.isNotEmpty
        ? _compactSummary(
            certificationEntries.map((entry) => entry.name).toList(),
          )
        : 'AWS Certified Developer';
    final previewLanguageSummary = languageLines.isNotEmpty
        ? _compactSummary(languageLines)
        : 'English  |  Native';

    Text text(
      String value, {
      double size = 2,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
      double height = 1.15,
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
          padding: const EdgeInsets.only(bottom: 1.4),
          child: text(
            title,
            size: 2.55,
            color: _heading,
            weight: FontWeight.bold,
          ),
        );

    Widget mainHeader(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 1.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                title,
                size: 3,
                color: _heading,
                weight: FontWeight.bold,
              ),
              Container(
                height: 0.7,
                color: _line,
                margin: const EdgeInsets.only(top: 0.8),
              ),
            ],
          ),
        );

    Widget justifiedLine(
      String value, {
      double size = 1.72,
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

    Widget sidebarBullet(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 0.7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.4),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 1.5),
              Expanded(
                child: text(
                  value,
                  size: 1.58,
                  color: _sidebarText,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    Widget summaryPoint(int index, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 0.9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 7,
                child: text(
                  '${index + 1}.',
                  size: 1.7,
                  color: _accent,
                  weight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: justifiedLine(
                  value,
                  size: 1.72,
                  color: _muted,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(ElegantDesignExperienceEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.title,
                  size: 2.08,
                  color: Colors.grey.shade900,
                  weight: FontWeight.w700,
                  maxLines: 1,
                ),
                text(
                  entry.companyLine,
                  size: 1.74,
                  color: Colors.grey.shade600,
                  maxLines: 1,
                ),
                if (entry.detailLines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 0.3),
                    child: justifiedLine(
                      entry.detailLines.first,
                      size: 1.58,
                      color: Colors.grey.shade700,
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
          ),
        );

    Widget projectBlock(ElegantDesignProjectEntry entry) => Padding(
          padding: const EdgeInsets.only(bottom: 1.2),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  entry.title,
                  size: 1.86,
                  color: Colors.grey.shade800,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
                if (entry.detailLines.isNotEmpty)
                  justifiedLine(
                    entry.detailLines.first,
                    size: 1.6,
                    color: Colors.grey.shade600,
                    maxLines: 2,
                  ),
                if (entry.links.isNotEmpty)
                  text(
                    entry.links.first,
                    size: 1.58,
                    color: _accent,
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
          color: _sheet,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              color: _sidebar,
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: photoBytes == null ? _avatarFill : null,
                        border: Border.all(color: _accent, width: 1),
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoBytes == null
                          ? Icon(Icons.person, size: 13, color: _accent)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  sidebarHeader('CONTACT'),
                  ...previewContacts.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 0.8),
                      child: text(
                        item.label,
                        size: 1.56,
                        color: _sidebarText,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  if (previewEducation.isNotEmpty) ...[
                    const SizedBox(height: 2.6),
                    sidebarHeader('EDUCATION'),
                    ...previewEducation.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 0.9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(
                              entry.degreeLine,
                              size: 1.56,
                              color: _sidebarText,
                              weight: FontWeight.w700,
                              maxLines: 2,
                            ),
                            text(
                              entry.institutionLine,
                              size: 1.46,
                              color: _sidebarText,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2.6),
                  sidebarHeader('SKILLS'),
                  ...previewSkills.map(sidebarBullet),
                  const SizedBox(height: 2.6),
                  sidebarHeader('CERTIFICATIONS'),
                  justifiedLine(
                    previewCertificationSummary,
                    size: 1.48,
                    color: _sidebarText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 2.6),
                  sidebarHeader('LANGUAGES'),
                  justifiedLine(
                    previewLanguageSummary,
                    size: 1.48,
                    color: _sidebarText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(
                      name,
                      size: 6.15,
                      color: _ink,
                      weight: FontWeight.w500,
                      maxLines: 2,
                    ),
                    text(
                      title,
                      size: 2.7,
                      color: _accent,
                      weight: FontWeight.w700,
                    ),
                    if (previewAddress.isNotEmpty)
                      text(
                        previewAddress,
                        size: 1.88,
                        color: Colors.grey.shade600,
                        maxLines: 1,
                      ),
                    Container(
                      height: 0.7,
                      color: _line,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                    mainHeader('ABOUT ME'),
                    ...previewSummaryLines.asMap().entries.map(
                          (entry) => summaryPoint(entry.key, entry.value),
                        ),
                    const SizedBox(height: 2.6),
                    mainHeader('EXPERIENCE'),
                    ...previewExperience.map(experienceBlock),
                    const SizedBox(height: 2.2),
                    mainHeader('PROJECTS'),
                    ...previewProjects.map(projectBlock),
                  ],
                ),
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
    return values.map((value) => value.trim()).where((value) => value.isNotEmpty).join('  •  ');
  }
}