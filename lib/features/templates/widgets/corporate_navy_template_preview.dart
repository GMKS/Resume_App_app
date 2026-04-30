import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../corporate_navy_template_support.dart';

class CorporateNavyTemplatePreview extends StatelessWidget {
  const CorporateNavyTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _pageChrome =>
      const Color(CorporateNavyTemplateSupport.pageChromeHex);
  Color get _page => const Color(CorporateNavyTemplateSupport.pageHex);
  Color get _headerStart =>
      const Color(CorporateNavyTemplateSupport.headerStartHex);
  Color get _headerEnd =>
      const Color(CorporateNavyTemplateSupport.headerEndHex);
  Color get _headerText =>
      const Color(CorporateNavyTemplateSupport.headerTextHex);
  Color get _sidebar => const Color(CorporateNavyTemplateSupport.sidebarHex);
  Color get _ink => const Color(CorporateNavyTemplateSupport.inkHex);
  Color get _muted => const Color(CorporateNavyTemplateSupport.mutedHex);
  Color get _line => const Color(CorporateNavyTemplateSupport.lineHex);
  Color get _accent => templateColor ?? accentColor;
  Color get _avatarBorder =>
      const Color(CorporateNavyTemplateSupport.avatarBorderHex);

  @override
  Widget build(BuildContext context) {
    final name = CorporateNavyTemplateSupport.displayName(resume);
    final title = CorporateNavyTemplateSupport.displayTitle(resume);
    final contactItems = CorporateNavyTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = CorporateNavyTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final skillNames = CorporateNavyTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final summaryLines = CorporateNavyTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 3,
    );
    final experienceEntries = CorporateNavyTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final certificationEntries =
        CorporateNavyTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: 2,
      compactLinks: true,
    );
    final projectEntries = CorporateNavyTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 1,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final languageLines = CorporateNavyTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    final photoBytes = _decodePhoto(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            CorporateNavyContactItem(
              kind: CorporateNavyContactKind.phone,
              label: '(555) 123-4567',
            ),
            CorporateNavyContactItem(
              kind: CorporateNavyContactKind.email,
              label: 'john@email.com',
            ),
            CorporateNavyContactItem(
              kind: CorporateNavyContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            CorporateNavyContactItem(
              kind: CorporateNavyContactKind.github,
              label: 'github.com/johnsmith',
            ),
            CorporateNavyContactItem(
              kind: CorporateNavyContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            CorporateNavyEducationEntry(
              degree: 'MBA Business Administration',
              institutionLine: 'State University',
              dateRange: '2018 - 2020',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Leadership', 'Strategy', 'Reporting', 'Operations'];
    final previewSummary = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Operationally focused leader with experience across reporting, delivery, and stakeholder communication.',
            'Aligns business goals with practical execution and measurable outcomes.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            CorporateNavyExperienceEntry(
              title: 'Operations Manager',
              metaLine: 'Acme Corp  |  New York, NY',
              dateRange: '2021 - Present',
              detailLines: ['Led delivery reporting and quality improvements.'],
            ),
            CorporateNavyExperienceEntry(
              title: 'Program Analyst',
              metaLine: 'Northwind  |  Boston, MA',
              dateRange: '2018 - 2021',
              detailLines: ['Built dashboards and process documentation.'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            CorporateNavyCertificationEntry(
              name: 'PMP Certification',
              detailLines: ['PMI', 'Issued Jan 2024'],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            CorporateNavyProjectEntry(
              title: 'Delivery Insights Dashboard',
              detailLines: ['Unified KPI reporting for operations leadership.'],
              links: ['example.com/delivery-insights'],
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Native', 'Spanish  |  Professional'];

    Text text(
      String value, {
      double size = 2.1,
      Color? color,
      FontWeight weight = FontWeight.normal,
      int? maxLines,
      TextAlign align = TextAlign.left,
      double height = 1.18,
    }) {
      return Text(
        value,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink,
          fontWeight: weight,
          fontFamily: 'Helvetica',
          height: height,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sidebarTitle(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                value,
                size: 2.2,
                color: _headerStart,
                weight: FontWeight.bold,
              ),
              Container(
                margin: const EdgeInsets.only(top: 1, bottom: 2),
                height: 0.5,
                color: _line,
              ),
            ],
          ),
        );

    Widget bodyTitle(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                value,
                size: 2.65,
                color: _ink,
                weight: FontWeight.bold,
              ),
              Container(
                margin: const EdgeInsets.only(top: 1.2),
                height: 0.5,
                color: _line,
              ),
            ],
          ),
        );

    Widget bulletLine(String line, {Color? color, double size = 1.8}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.2, right: 2.4),
                child: Container(
                  width: 2.4,
                  height: 2.4,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: text(
                  line,
                  size: size,
                  color: color ?? _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    Widget experienceBlock(CorporateNavyExperienceEntry entry) {
      final dates = entry.dateRange.split(' - ');
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(dates.first, size: 1.58, color: _muted),
                  text(
                    dates.length > 1 ? dates.last : dates.first,
                    size: 1.58,
                    color: _muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2.0),
            Container(
              width: 0.8,
              height: 11 + (entry.detailLines.length * 5.5),
              color: _accent.withOpacity(0.35),
            ),
            const SizedBox(width: 2.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text(
                    entry.title,
                    size: 2.12,
                    color: _ink,
                    weight: FontWeight.bold,
                  ),
                  if (entry.metaLine.isNotEmpty)
                    text(
                      entry.metaLine,
                      size: 1.68,
                      color: _accent,
                      weight: FontWeight.w600,
                      maxLines: 2,
                    ),
                  ...entry.detailLines.map(
                    (line) => bulletLine(line, size: 1.64),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget projectBlock(CorporateNavyProjectEntry entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                entry.title,
                size: 2.05,
                color: _ink,
                weight: FontWeight.bold,
              ),
              ...entry.detailLines.map(
                (line) => bulletLine(line, size: 1.64),
              ),
            ],
          ),
        );

    Widget certificationBlock(CorporateNavyCertificationEntry entry) =>
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                entry.name,
                size: 2.0,
                color: _ink,
                weight: FontWeight.bold,
              ),
              ...entry.detailLines.map(
                (line) => text(
                  line,
                  size: 1.62,
                  color: _muted,
                  align: TextAlign.justify,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _pageChrome,
      padding: const EdgeInsets.all(5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: _page,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const sidebarWidth = 52.0;
                const columnGap = 8.0;
                const headerHeight = 46.0;
                final bodyWidth =
                    constraints.maxWidth - sidebarWidth - columnGap;
                final headerWidth = bodyWidth * 0.58;

                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: sidebarWidth + columnGap),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: headerWidth,
                          height: headerHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_headerStart, _headerEnd],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 7, 42, 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    text(
                                      name.toUpperCase(),
                                      size: 4.15,
                                      color: Colors.white,
                                      weight: FontWeight.w900,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 1.2),
                                    text(
                                      title.toUpperCase(),
                                      size: 1.55,
                                      color: _headerText,
                                      weight: FontWeight.w600,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 8,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: photoBytes == null
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _avatarBorder,
                                      width: 1,
                                    ),
                                    image: photoBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(photoBytes),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: photoBytes == null
                                      ? Icon(
                                          Icons.person,
                                          size: 11,
                                          color: _headerStart,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: sidebarWidth,
                            color: _sidebar,
                            padding: const EdgeInsets.fromLTRB(5, 8, 4, 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sidebarTitle('CONTACT'),
                                ...previewContacts.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 0.9),
                                    child: text(
                                      item.label,
                                      size: 1.5,
                                      color: _muted,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                sidebarTitle('EDUCATION'),
                                ...previewEducation.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 1.7),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        text(
                                          entry.degree,
                                          size: 1.58,
                                          color: _ink,
                                          weight: FontWeight.w700,
                                          maxLines: 2,
                                        ),
                                        text(
                                          entry.institutionLine,
                                          size: 1.48,
                                          color: _muted,
                                          maxLines: 2,
                                        ),
                                        text(
                                          entry.dateRange,
                                          size: 1.48,
                                          color: _accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                sidebarTitle('SKILLS'),
                                ...previewSkills.map(
                                  (skill) => Padding(
                                    padding: const EdgeInsets.only(bottom: 0.9),
                                    child: text(
                                      '- $skill',
                                      size: 1.5,
                                      color: _muted,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: columnGap),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1, right: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  bodyTitle('ABOUT ME'),
                                  ...previewSummary.map(
                                    (line) => bulletLine(line, size: 1.68),
                                  ),
                                  const SizedBox(height: 0.8),
                                  bodyTitle('EXPERIENCE'),
                                  ...previewExperience.map(experienceBlock),
                                  if (previewCertifications.isNotEmpty) ...[
                                    const SizedBox(height: 0.8),
                                    bodyTitle('CERTIFICATIONS'),
                                    ...previewCertifications
                                        .map(certificationBlock),
                                  ],
                                  if (previewProjects.isNotEmpty) ...[
                                    const SizedBox(height: 0.8),
                                    bodyTitle('PROJECTS'),
                                    ...previewProjects.map(projectBlock),
                                  ],
                                  if (previewLanguages.isNotEmpty) ...[
                                    const SizedBox(height: 0.8),
                                    bodyTitle('LANGUAGES'),
                                    ...previewLanguages.map(
                                      (line) => bulletLine(line, size: 1.66),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Uint8List? _decodePhoto(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
