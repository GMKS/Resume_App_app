import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../bluewave_tech_template_support.dart';

class BluewaveTechResumeTemplatePreview extends StatelessWidget {
  const BluewaveTechResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(BluewaveTechTemplateSupport.pageHex);
  Color get _paper => const Color(BluewaveTechTemplateSupport.paperHex);
  Color get _headerStart =>
      const Color(BluewaveTechTemplateSupport.headerStartHex);
  Color get _headerEnd => const Color(BluewaveTechTemplateSupport.headerEndHex);
  Color get _headerText =>
      const Color(BluewaveTechTemplateSupport.headerTextHex);
  Color get _sidebar => const Color(BluewaveTechTemplateSupport.sidebarHex);
  Color get _line => const Color(BluewaveTechTemplateSupport.lineHex);
  Color get _accent => const Color(BluewaveTechTemplateSupport.accentHex);
  Color get _ink => const Color(BluewaveTechTemplateSupport.inkHex);
  Color get _muted => const Color(BluewaveTechTemplateSupport.mutedHex);
  Color get _avatarFill =>
      const Color(BluewaveTechTemplateSupport.avatarFillHex);

  @override
  Widget build(BuildContext context) {
    final previewResume = resume;
    final name =
        BluewaveTechTemplateSupport.displayName(previewResume).toUpperCase();
    final title = BluewaveTechTemplateSupport.displayTitle(previewResume);
    final contactItems = BluewaveTechTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = BluewaveTechTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final skillNames = BluewaveTechTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: null,
    );
    final summaryLines = BluewaveTechTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 3,
    );
    final experienceEntries = BluewaveTechTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 1,
      yearOnly: true,
    );
    final projectEntries = BluewaveTechTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 2,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final certificationEntries =
        BluewaveTechTemplateSupport.certificationEntries(
      previewResume?.certifications ?? const <Certification>[],
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = BluewaveTechTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.phone,
              label: '+1 (555) 123-4567',
            ),
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.email,
              label: 'alex@bluewave.dev',
            ),
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.address,
              label: 'Seattle, WA',
            ),
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.linkedin,
              label: 'linkedin.com/in/alexchen',
            ),
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.github,
              label: 'github.com/alexchen',
            ),
            BluewaveTechContactItem(
              kind: BluewaveTechContactKind.website,
              label: 'alexchen.dev',
            ),
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries
        : const [
            BluewaveTechEducationEntry(
              degreeLine: 'B.Tech Computer Science',
              institutionLine: 'University of Washington',
              dateRange: '2016 - 2020',
            ),
          ];
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Azure', 'Kubernetes', 'System Design'];
    final previewSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Builds scalable platform experiences for enterprise products and distributed teams.',
            'Aligns engineering delivery, architecture quality, and measurable business outcomes.',
            'Translates ambiguous initiatives into dependable systems, tooling, and execution plans.',
          ];
    final previewExperience = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            BluewaveTechExperienceEntry(
              title: 'Senior Engineering Manager',
              companyLine: 'BlueWave Labs  |  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Scaled product infrastructure and developer tooling across multiple platform teams.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            BluewaveTechProjectEntry(
              title: 'Observability Platform',
              detailLines: [
                'Unified service telemetry, alerting, and release health dashboards.',
              ],
              links: ['alexchen.dev/observability'],
            ),
          ];
    final skillSummary = _compactSummary(previewSkills);
    final certificationSummary = certificationEntries.isNotEmpty
        ? _compactSummary(
            certificationEntries.map((entry) => entry.name).toList(),
          )
        : 'AWS Solutions Architect  |  CKA';
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
      double height = 1.16,
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

    Widget justifiedText(
      String value, {
      double size = 1.56,
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

    Widget card({
      required String title,
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(4, 3, 4, 3),
    }) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _line, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(
              title,
              size: 2.15,
              color: _accent,
              weight: FontWeight.bold,
            ),
            Container(
              height: 0.6,
              margin: const EdgeInsets.only(top: 1.1, bottom: 1.6),
              color: _line,
            ),
            child,
          ],
        ),
      );
    }

    Widget sidebarSummary(String value, {int maxLines = 4}) {
      return text(
        value,
        size: 1.42,
        color: _muted,
        maxLines: maxLines,
        height: 1.2,
      );
    }

    Widget contactBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: previewContacts
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: text(
                  item.label,
                  size: 1.42,
                  color: _muted,
                  maxLines:
                      item.kind == BluewaveTechContactKind.address ? 2 : 1,
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    Widget summaryPoint(String line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 0.7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.3),
              child: SizedBox(
                width: 3.4,
                height: 4.2,
                child: CustomPaint(
                  painter: _BluewaveTechPreviewTrianglePainter(color: _accent),
                ),
              ),
            ),
            const SizedBox(width: 1.3),
            Expanded(
              child: justifiedText(
                line,
                size: 1.56,
                color: _muted,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    }

    Widget experienceBlock(BluewaveTechExperienceEntry entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 1.25),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                entry.title,
                size: 1.95,
                color: Colors.grey.shade900,
                weight: FontWeight.w700,
                maxLines: 1,
              ),
              text(
                entry.companyLine,
                size: 1.64,
                color: _accent,
                maxLines: 1,
              ),
              text(
                entry.dateRange,
                size: 1.52,
                color: _muted,
                maxLines: 1,
              ),
              if (entry.detailLines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0.35),
                  child: justifiedText(
                    entry.detailLines.first,
                    size: 1.5,
                    color: _muted,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget projectBlock(BluewaveTechProjectEntry entry) {
      return Padding(
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
                weight: FontWeight.w700,
                maxLines: 1,
              ),
              if (entry.detailLines.isNotEmpty)
                justifiedText(
                  entry.detailLines.first,
                  size: 1.5,
                  color: _muted,
                  maxLines: 2,
                ),
              if (entry.links.isNotEmpty)
                text(
                  entry.links.first,
                  size: 1.48,
                  color: _headerStart,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      );
    }

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
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 7, 34, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_headerStart, _headerEnd],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text(
                        name,
                        size: 5.3,
                        color: Colors.white,
                        weight: FontWeight.w900,
                      ),
                      text(
                        title,
                        size: 2.38,
                        color: _headerText,
                        weight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: photoBytes == null ? Colors.white : null,
                      border: Border.all(color: Colors.white, width: 1),
                      image: photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(photoBytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoBytes == null
                        ? Icon(Icons.person, size: 12, color: _headerStart)
                        : null,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 42,
                    color: _sidebar,
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        card(
                          title: 'EDUCATION',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: previewEducation
                                .map(
                                  (entry) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      text(
                                        entry.institutionLine,
                                        size: 1.5,
                                        color: Colors.grey.shade700,
                                        maxLines: 2,
                                      ),
                                      text(
                                        entry.degreeLine,
                                        size: 1.42,
                                        color: _muted,
                                        maxLines: 2,
                                      ),
                                      text(
                                        entry.dateRange,
                                        size: 1.38,
                                        color: _muted,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 3),
                        card(title: 'CONTACT', child: contactBlock()),
                        const SizedBox(height: 3),
                        card(
                          title: 'SKILLS',
                          child: sidebarSummary(skillSummary, maxLines: 5),
                        ),
                        if (certificationSummary.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          card(
                            title: 'CERTIFICATIONS',
                            child: sidebarSummary(certificationSummary,
                                maxLines: 4),
                          ),
                        ],
                        if (languageSummary.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          card(
                            title: 'LANGUAGES',
                            child: sidebarSummary(languageSummary, maxLines: 4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          card(
                            title: 'ABOUT ME',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: previewSummaryLines
                                  .map(summaryPoint)
                                  .toList(growable: false),
                            ),
                          ),
                          const SizedBox(height: 3),
                          card(
                            title: 'EXPERIENCE',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: previewExperience
                                  .map(experienceBlock)
                                  .toList(growable: false),
                            ),
                          ),
                          if (previewProjects.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            card(
                              title: 'PROJECTS',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: previewProjects
                                    .map(projectBlock)
                                    .toList(growable: false),
                              ),
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
        ),
      ),
    );
  }

  String _compactSummary(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('  |  ');
  }

  Uint8List? _photoBytes(String? encoded) {
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

class _BluewaveTechPreviewTrianglePainter extends CustomPainter {
  const _BluewaveTechPreviewTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(0.4, 0.4)
      ..lineTo(size.width - 0.4, size.height / 2)
      ..lineTo(0.4, size.height - 0.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
      covariant _BluewaveTechPreviewTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
