import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../elegant_gold_layout_template_support.dart';

class ElegantGoldLayoutTemplatePreview extends StatelessWidget {
  const ElegantGoldLayoutTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _page => const Color(ElegantGoldTemplateSupport.pageHex);
  Color get _paper => const Color(ElegantGoldTemplateSupport.paperHex);
  Color get _card => const Color(ElegantGoldTemplateSupport.cardHex);
  Color get _headerStart =>
      const Color(ElegantGoldTemplateSupport.headerStartHex);
  Color get _headerEnd => const Color(ElegantGoldTemplateSupport.headerEndHex);
  Color get _headerText =>
      const Color(ElegantGoldTemplateSupport.headerTextHex);
  Color get _accent => const Color(ElegantGoldTemplateSupport.accentHex);
  Color get _border => const Color(ElegantGoldTemplateSupport.borderHex);
  Color get _ink => const Color(ElegantGoldTemplateSupport.inkHex);
  Color get _muted => const Color(ElegantGoldTemplateSupport.mutedHex);

  Uint8List? _photoBytes(String? encoded) {
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

  String _compactSummary(Iterable<String> values) {
    final cleaned = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return cleaned.join('  •  ');
  }

  double _denseFontSize(int itemCount) {
    if (itemCount >= 5) {
      return 1.16;
    }
    if (itemCount >= 4) {
      return 1.24;
    }
    if (itemCount >= 2) {
      return 1.34;
    }
    return 1.42;
  }

  Widget _text(
    String text, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.normal,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
    double height = 1.12,
  }) {
    return Text(
      text,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: height,
      ),
    );
  }

  Widget _sidebarCard(
    String title,
    List<Widget> children, {
    double minHeight = 0,
  }) {
    return Container(
      width: double.infinity,
      constraints: minHeight > 0
          ? BoxConstraints(minHeight: minHeight)
          : null,
      padding: const EdgeInsets.fromLTRB(5.2, 4.6, 5.2, 4.8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(8.6),
        border: Border.all(color: _border, width: 0.55),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3.2,
            offset: const Offset(0, 1.2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.8),
            decoration: BoxDecoration(
              color: _headerEnd,
              borderRadius: BorderRadius.circular(11),
            ),
            child: _text(
              title,
              size: 1.9,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2.5),
          ...children,
        ],
      ),
    );
  }

  Widget _mainCard(
    String? title,
    List<Widget> children, {
    double minHeight = 0,
  }) {
    return Container(
      width: double.infinity,
      constraints: minHeight > 0
          ? BoxConstraints(minHeight: minHeight)
          : null,
      padding: const EdgeInsets.fromLTRB(5.6, 4.8, 5.6, 4.8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(9.2),
        border: Border.all(color: _border, width: 0.55),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3.4,
            offset: const Offset(0, 1.25),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0.4,
            top: 2.2,
            bottom: 2.2,
            child: Container(
              width: 1.45,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((title ?? '').isNotEmpty) ...[
                  _text(
                    title!,
                    size: 2.14,
                    color: _headerEnd,
                    weight: FontWeight.w700,
                  ),
                  Container(
                    height: 0.42,
                    color: _border,
                    margin: const EdgeInsets.symmetric(vertical: 1.35),
                  ),
                ],
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutBullet(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.85),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.05, right: 1.0),
            child: _text(
              '➤',
              size: 1.28,
              color: _accent,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: _text(
              line,
              size: 1.28,
              color: _muted,
              maxLines: 0,
              align: TextAlign.justify,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceBlock(ElegantGoldExperienceEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.75),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 1.62,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 2,
            ),
            _text(
              entry.metaLine,
              size: 1.32,
              color: _muted,
              maxLines: 2,
            ),
            ...entry.detailLines.take(2).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 0.5),
                    child: _text(
                      '• $line',
                      size: 1.27,
                      color: _muted,
                      maxLines: 2,
                      align: TextAlign.justify,
                      height: 1.18,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _projectBlock(ElegantGoldProjectEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              entry.title,
              size: 1.46,
              color: _ink,
              weight: FontWeight.w700,
              maxLines: 2,
            ),
            if (entry.detailLines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.35),
                child: _text(
                  entry.detailLines.first,
                  size: 1.2,
                  color: _muted,
                  maxLines: 2,
                  align: TextAlign.justify,
                  height: 1.17,
                ),
              ),
            if (entry.links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.35),
                child: _text(
                  entry.links.first,
                  size: 1.14,
                  color: _accent,
                  maxLines: 1,
                  height: 1.12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewResume = ElegantGoldTemplateSupport.normalizedResume(resume);
    final name =
        ElegantGoldTemplateSupport.displayName(previewResume).toUpperCase();
    final title = ElegantGoldTemplateSupport.displayTitle(previewResume);
    final contactItems = ElegantGoldTemplateSupport.contactItems(
      previewResume?.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final aboutLines = ElegantGoldTemplateSupport.summaryLines(
      previewResume?.objective,
      maxItems: 4,
    );
    final educationEntries = ElegantGoldTemplateSupport.educationEntries(
      previewResume?.education ?? const <Education>[],
      maxItems: 1,
      yearOnly: true,
    );
    final skillNames = ElegantGoldTemplateSupport.skillNames(
      previewResume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    final languageLines = ElegantGoldTemplateSupport.languageLines(
      previewResume?.languages ?? const <Language>[],
      maxItems: null,
    );
    final experienceEntries = ElegantGoldTemplateSupport.experienceEntries(
      previewResume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
      yearOnly: true,
    );
    final projectEntries = ElegantGoldTemplateSupport.projectEntries(
      previewResume?.projects ?? const <Project>[],
      maxItems: 3,
      maxDetailLines: 1,
      compactLinks: true,
    );
    final photoBytes = _photoBytes(previewResume?.personalInfo.profileImage);

    final previewContacts = contactItems.isNotEmpty
        ? contactItems
        : const [
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.phone,
              label: '(555) 123-4567',
            ),
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.email,
              label: 'john.smith@email.com',
            ),
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.linkedin,
              label: 'linkedin.com/in/johnsmith',
            ),
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.github,
              label: 'github.com/johnsmith',
            ),
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.website,
              label: 'johnsmith.dev',
            ),
            ElegantGoldContactItem(
              kind: ElegantGoldContactKind.address,
              label: 'New York, NY',
            ),
          ];
    final previewAboutLines = aboutLines.isNotEmpty
        ? aboutLines
        : const [
            'Results-driven professional with expertise in delivering high-quality business systems with modern, user-focused workflows.',
          ];
    final previewEducation = educationEntries.isNotEmpty
        ? educationEntries.first
        : const ElegantGoldEducationEntry(
            institution: 'State University',
            degreeLine: 'B.Sc. Computer Science',
            dateRange: '2018 - 2022',
          );
    final previewSkills = skillNames.isNotEmpty
        ? skillNames
        : const ['Flutter', 'Dart', 'Figma', 'REST APIs'];
    final previewLanguages = languageLines.isNotEmpty
        ? languageLines
        : const ['English  |  Professional', 'German  |  Professional'];
    final previewExperiences = experienceEntries.isNotEmpty
        ? experienceEntries
        : const [
            ElegantGoldExperienceEntry(
              title: 'Senior Developer',
              metaLine: 'TechCorp  |  2022 - Present',
              detailLines: [
                'Led UI, services, and automation improvements for shared platforms.',
                'Reduced lead time by 24% via role-specific workflows.',
              ],
            ),
            ElegantGoldExperienceEntry(
              title: 'Flutter Developer',
              metaLine: 'Creative Systems  |  2020 - 2021',
              detailLines: [
                'Implemented reusable UI components for live user dashboards.',
                'Built product features and collaborated with design and QA on reliable releases.',
              ],
            ),
          ];
    final previewProjects = projectEntries.isNotEmpty
        ? projectEntries
        : const [
            ElegantGoldProjectEntry(
              title: 'HR Analytics Portal',
              detailLines: [
                'Unified workforce insights and employee lifecycle reporting.',
              ],
              links: ['portal.example.com/hr'],
            ),
            ElegantGoldProjectEntry(
              title: 'Retention Program Dashboard',
              detailLines: [
                'Tracked structured career framework progress across distributed teams.',
              ],
              links: ['people.example.com/retention'],
            ),
          ];

    final languageSummary = _compactSummary(previewLanguages);
    final languageFontSize = _denseFontSize(previewLanguages.length);

    return Container(
      color: _page,
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_headerStart, _headerEnd],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6.4, 6, 6),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _text(
                                name,
                                size: 4.35,
                                color: Colors.white,
                                weight: FontWeight.w900,
                              ),
                              _text(
                                title,
                                size: 2.08,
                                color: _headerText,
                                weight: FontWeight.w600,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 23.5,
                        height: 23.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFFD7C094), width: 1.0),
                          image: photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(photoBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoBytes == null
                            ? Icon(Icons.person, size: 12.2, color: _accent)
                            : null,
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -1.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 42,
                          child: _sidebarCard(
                            'CONTACT',
                            previewContacts
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 0.7),
                                    child: _text(
                                      item.label,
                                      size: item.kind ==
                                              ElegantGoldContactKind.address
                                          ? 1.34
                                          : 1.42,
                                      color: _muted,
                                      maxLines: item.kind ==
                                              ElegantGoldContactKind.address
                                          ? 2
                                          : 2,
                                      height: 1.15,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            minHeight: 34,
                          ),
                        ),
                        const SizedBox(width: 3.8),
                        Expanded(
                          child: _mainCard(
                            'ABOUT ME',
                            previewAboutLines
                                .map(_aboutBullet)
                                .toList(growable: false),
                            minHeight: 21.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1.4),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 42,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sidebarCard(
                                'EDUCATION',
                                [
                                  _text(
                                    previewEducation.institution,
                                    size: 1.48,
                                    color: _ink,
                                    weight: FontWeight.w700,
                                    maxLines: 2,
                                  ),
                                  _text(
                                    previewEducation.degreeLine,
                                    size: 1.38,
                                    color: _muted,
                                    maxLines: 3,
                                    height: 1.15,
                                  ),
                                  _text(
                                    previewEducation.dateRange,
                                    size: 1.28,
                                    color: _accent,
                                    maxLines: 1,
                                  ),
                                ],
                                minHeight: 15.8,
                              ),
                              const SizedBox(height: 3),
                              _sidebarCard(
                                'SKILLS',
                                previewSkills
                                    .map(
                                      (skill) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 1.05),
                                        child: _text(
                                          '• $skill',
                                          size: 1.42,
                                          color: _muted,
                                          maxLines: 1,
                                          height: 1.14,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                minHeight: 19.8,
                              ),
                              if (previewLanguages.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                _sidebarCard(
                                  'LANGUAGES',
                                  [
                                    _text(
                                      languageSummary,
                                      size: languageFontSize,
                                      color: _muted,
                                      maxLines: 0,
                                      align: TextAlign.justify,
                                      height: 1.16,
                                    ),
                                  ],
                                  minHeight: 12,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 3.8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (previewExperiences.isNotEmpty)
                                _mainCard(
                                  'EXPERIENCE',
                                  previewExperiences
                                      .take(1)
                                      .map(_experienceBlock)
                                      .toList(growable: false),
                                  minHeight: 22,
                                ),
                              if (previewExperiences.length > 1) ...[
                                const SizedBox(height: 3),
                                _mainCard(
                                  null,
                                  previewExperiences
                                      .skip(1)
                                      .map(_experienceBlock)
                                      .toList(growable: false),
                                  minHeight: 19,
                                ),
                              ],
                              if (previewProjects.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Expanded(
                                  child: _mainCard(
                                    'PROJECTS',
                                    previewProjects
                                        .map(_projectBlock)
                                        .toList(growable: false),
                                    minHeight: 26,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
}
