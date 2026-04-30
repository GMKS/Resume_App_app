import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../minimal_clean_ats_template_support.dart';

class MinimalCleanAtsResumeTemplatePreview extends StatelessWidget {
  const MinimalCleanAtsResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(MinimalCleanAtsTemplateSupport.pageHex);
  Color get _paper => const Color(MinimalCleanAtsTemplateSupport.paperHex);
  Color get _sidebar => const Color(MinimalCleanAtsTemplateSupport.sidebarHex);
  Color get _banner => const Color(MinimalCleanAtsTemplateSupport.bannerHex);
  Color get _bannerDark =>
      const Color(MinimalCleanAtsTemplateSupport.bannerDarkHex);
  Color get _photoFill =>
      const Color(MinimalCleanAtsTemplateSupport.photoFillHex);
  Color get _ink => const Color(MinimalCleanAtsTemplateSupport.inkHex);
  Color get _muted => const Color(MinimalCleanAtsTemplateSupport.mutedHex);
  Color get _line => const Color(MinimalCleanAtsTemplateSupport.lineHex);
  Color get _bannerText =>
      const Color(MinimalCleanAtsTemplateSupport.bannerTextHex);

  @override
  Widget build(BuildContext context) {
    final name = MinimalCleanAtsTemplateSupport.displayName(resume);
    final title = MinimalCleanAtsTemplateSupport.displayTitle(resume);
    final address = resume?.personalInfo.address.trim() ?? '';
    final contactItems = MinimalCleanAtsTemplateSupport.contactItems(
      resume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = MinimalCleanAtsTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: null,
    );
    final experienceEntries = MinimalCleanAtsTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: null,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final educationEntries = MinimalCleanAtsTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: null,
      yearOnly: true,
    );
    final projectEntries = MinimalCleanAtsTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        MinimalCleanAtsTemplateSupport.certificationEntries(
      resume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = MinimalCleanAtsTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final skillNames = MinimalCleanAtsTemplateSupport.skillNames(
      resume?.skills ?? const <Skill>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(resume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.phone,
              label: '(555) 123-4567',
            ),
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.email,
              label: 'john.smith@email.com',
            ),
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.address,
              label: 'New York, NY',
            ),
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.github,
              label: 'github.com/johnsmith',
            ),
            MinimalCleanAtsContactItem(
              kind: MinimalCleanAtsContactKind.website,
              label: 'johnsmith.dev',
            ),
          ];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions.',
            'Builds dependable products through structured planning and execution.',
            'Brings strong communication and launch discipline to cross-functional teams.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            MinimalCleanAtsExperienceEntry(
              title: 'Senior Developer',
              companyLine: 'TechCorp  |  Remote',
              dateRange: '2021 - Present',
              detailLines: [
                'Led a cross-functional team to deliver a cloud-based platform.',
              ],
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            MinimalCleanAtsEducationEntry(
              degreeLine: 'B.Sc. Computer Science',
              institutionLine: 'State University',
              dateRange: '2016 - 2019',
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            MinimalCleanAtsProjectEntry(
              title: 'Portfolio Website',
              detailLines: [
                'Developed a portfolio profile site showcasing projects and skills.',
              ],
              links: ['example.com/portfolio'],
            ),
          ];
    final previewCertifications = certificationEntries.isNotEmpty
        ? certificationEntries
        : const [
            MinimalCleanAtsCertificationEntry(
              name: 'AWS Certified Developer',
              metaLine: 'Amazon  |  Jan 2025',
            ),
          ];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'German  |  Conversational'];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Firebase', 'REST APIs'];

    Text text(
      String value, {
      double size = 2,
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
          height: 1.16,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: align,
      );
    }

    Widget sectionHeader(String value) => Padding(
          padding: const EdgeInsets.only(bottom: 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                value,
                size: 2.9,
                color: _banner,
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 0.6),
              Container(height: 0.5, color: _line),
            ],
          ),
        );

    Widget numberedSummaryLine(int index, String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 4.6,
                child: text(
                  '${index + 1}.',
                  size: 1.82,
                  color: _banner,
                  weight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: text(
                  line,
                  size: 1.82,
                  color: _muted,
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    Widget detailLine(String line) => Padding(
          padding: const EdgeInsets.only(bottom: 0.7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _banner,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 1.8),
              Expanded(
                child: text(
                  line,
                  size: 1.74,
                  color: _muted,
                  align: TextAlign.justify,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: _page,
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _sidebar,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: photoBytes == null ? _photoFill : null,
                          border: Border.all(color: _banner, width: 0.8),
                          image: photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(photoBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoBytes == null
                            ? Icon(Icons.person, size: 12, color: _banner)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_banner, _bannerDark],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          text(
                            name.toUpperCase(),
                            size: 4.8,
                            color: Colors.white,
                            weight: FontWeight.w900,
                            maxLines: 1,
                          ),
                          text(
                            title,
                            size: 2.25,
                            color: _bannerText,
                            weight: FontWeight.w600,
                            maxLines: 1,
                          ),
                          if (address.isNotEmpty)
                            text(
                              address,
                              size: 1.72,
                              color: _bannerText,
                              maxLines: 1,
                            ),
                        ],
                      ),
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
                    width: 40,
                    margin: const EdgeInsets.fromLTRB(5, 4, 0, 5),
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    decoration: BoxDecoration(
                      color: _sidebar,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            'CONTACT',
                            size: 2.45,
                            color: _banner,
                            weight: FontWeight.w800,
                          ),
                          const SizedBox(height: 1),
                          ...previewContacts.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 0.8),
                              child: text(
                                item.label,
                                size: 1.62,
                                color: _muted,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2.2),
                          text(
                            'SKILLS',
                            size: 2.45,
                            color: _banner,
                            weight: FontWeight.w800,
                          ),
                          const SizedBox(height: 1),
                          ...previewSkills.map(
                            (skill) => Padding(
                              padding: const EdgeInsets.only(bottom: 0.7),
                              child: text(
                                skill,
                                size: 1.62,
                                color: _muted,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionHeader('ABOUT ME'),
                            ...previewSummaryLines.asMap().entries.map(
                                  (entry) => numberedSummaryLine(
                                    entry.key,
                                    entry.value,
                                  ),
                                ),
                            const SizedBox(height: 2),
                            if (previewExperience.isNotEmpty) ...[
                              sectionHeader('EXPERIENCE'),
                              ...previewExperience.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2.1),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: text(
                                              entry.title,
                                              size: 2.25,
                                              color: _ink,
                                              weight: FontWeight.w800,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          text(
                                            entry.dateRange,
                                            size: 1.6,
                                            color: _muted,
                                            maxLines: 1,
                                            align: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                      text(
                                        entry.companyLine,
                                        size: 1.78,
                                        color: _banner,
                                        weight: FontWeight.w700,
                                        maxLines: 1,
                                      ),
                                      ...entry.detailLines.map(detailLine),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (previewEducation.isNotEmpty) ...[
                              sectionHeader('EDUCATION'),
                              ...previewEducation.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      text(
                                        entry.degreeLine,
                                        size: 2.0,
                                        color: _ink,
                                        weight: FontWeight.w700,
                                        maxLines: 2,
                                      ),
                                      text(
                                        entry.institutionLine,
                                        size: 1.72,
                                        color: _muted,
                                        maxLines: 2,
                                      ),
                                      text(
                                        entry.dateRange,
                                        size: 1.62,
                                        color: _muted,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (previewProjects.isNotEmpty) ...[
                              sectionHeader('PROJECTS'),
                              ...previewProjects.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      text(
                                        entry.title,
                                        size: 2.0,
                                        color: _ink,
                                        weight: FontWeight.w700,
                                        maxLines: 1,
                                      ),
                                      if (entry.technologyLine.isNotEmpty)
                                        text(
                                          entry.technologyLine,
                                          size: 1.65,
                                          color: _banner,
                                          maxLines: 2,
                                        ),
                                      ...entry.detailLines.map(detailLine),
                                      ...entry.links.map(
                                        (link) => text(
                                          link,
                                          size: 1.65,
                                          color: _banner,
                                          weight: FontWeight.w700,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (previewCertifications.isNotEmpty) ...[
                              sectionHeader('CERTIFICATIONS'),
                              ...previewCertifications.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1.4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      text(
                                        entry.name,
                                        size: 1.92,
                                        color: _ink,
                                        weight: FontWeight.w700,
                                        maxLines: 2,
                                      ),
                                      if (entry.metaLine.isNotEmpty)
                                        text(
                                          entry.metaLine,
                                          size: 1.62,
                                          color: _muted,
                                          maxLines: 2,
                                        ),
                                      ...entry.links.map(
                                        (link) => text(
                                          link,
                                          size: 1.58,
                                          color: _banner,
                                          weight: FontWeight.w700,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (previewLanguages.isNotEmpty) ...[
                              sectionHeader('LANGUAGES'),
                              ...previewLanguages.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 0.8),
                                  child: text(
                                    line,
                                    size: 1.72,
                                    color: _muted,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
}
