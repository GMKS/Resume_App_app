import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../infographic_template_support.dart';

class InfographicResumeTemplatePreview extends StatelessWidget {
  const InfographicResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _canvas => const Color(InfographicTemplateSupport.canvasHex);
  Color get _panel => const Color(InfographicTemplateSupport.panelHex);
  Color get _softPanel => const Color(InfographicTemplateSupport.softPanelHex);
  Color get _warmPanel => const Color(InfographicTemplateSupport.warmPanelHex);
  Color get _skyPanel => const Color(InfographicTemplateSupport.skyPanelHex);
  Color get _line => const Color(InfographicTemplateSupport.lineHex);
  Color get _ink => const Color(InfographicTemplateSupport.inkHex);
  Color get _muted => const Color(InfographicTemplateSupport.mutedHex);
  Color get _accent =>
      Color.lerp(
        accentColor,
        const Color(InfographicTemplateSupport.accentBlendHex),
        0.62,
      ) ??
      accentColor;
  Color get _accentSoft => Color.lerp(_accent, Colors.white, 0.82) ?? _panel;

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'Jordan Smith';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Product Designer';
  }

  List<String> get _summaryLines {
    final values = InfographicTemplateSupport.summaryLines(
      resume?.objective,
      maxItems: 4,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Designs clear, outcome-focused experiences across digital products.',
            'Brings systems thinking, visual storytelling, and strong delivery discipline.',
          ];
  }

  List<String> get _contactItems {
    final values = InfographicTemplateSupport.contactItems(
      resume?.personalInfo,
      maxItems: 4,
    );
    return values.isNotEmpty
        ? values
        : const [
            '+1 555 123 4567',
            'jordan@example.com',
            'linkedin.com/in/jordansmith',
            'jordansmith.dev',
          ];
  }

  String get _baseLabel => InfographicTemplateSupport.baseLabel(
        resume?.personalInfo,
      );

  List<InfographicSkillEntry> get _primarySkills {
    final values = InfographicTemplateSupport.skillEntries(
      resume?.skills ?? const <Skill>[],
      maxItems: 4,
    );
    return values.isNotEmpty
        ? values
        : const [
            InfographicSkillEntry(name: 'UX Systems', progress: 0.92),
            InfographicSkillEntry(name: 'Figma', progress: 0.88),
            InfographicSkillEntry(name: 'Research', progress: 0.81),
            InfographicSkillEntry(name: 'Prototyping', progress: 0.76),
          ];
  }

  List<String> get _extraSkillNames {
    final values = InfographicTemplateSupport.skillEntries(
      resume?.skills ?? const <Skill>[],
      skip: 4,
      maxItems: 4,
    );
    return values.map((entry) => entry.name).toList(growable: false);
  }

  List<InfographicExperienceEntry> get _experiences {
    final values = InfographicTemplateSupport.experienceEntries(
      resume?.experience ?? const <Experience>[],
      maxItems: 2,
      maxDetailLines: 2,
    );
    return values.isNotEmpty
        ? values
        : const [
            InfographicExperienceEntry(
              title: 'Lead Product Designer',
              companyLine: 'Northstar Studio  •  Remote',
              dateRange: '2022 - Present',
              detailLines: [
                'Shaped product direction for multi-surface design systems and launch initiatives.',
              ],
            ),
            InfographicExperienceEntry(
              title: 'Senior UX Designer',
              companyLine: 'Atlas Works  •  New York, NY',
              dateRange: '2019 - 2022',
              detailLines: [
                'Led research-backed redesigns that improved adoption and reduced task friction.',
              ],
            ),
          ];
  }

  List<InfographicEducationEntry> get _educationEntries {
    final values = InfographicTemplateSupport.educationEntries(
      resume?.education ?? const <Education>[],
      maxItems: null,
      maxSupportLines: 1,
    );
    return values.isNotEmpty
        ? values
        : const [
            InfographicEducationEntry(
              degree: 'B.Des. Interaction Design',
              institutionLine: 'School of Visual Arts',
              dateRange: '2018',
              supportingLines: ['Design Systems Focus'],
            ),
          ];
  }

  List<String> get _credentials {
    final values = InfographicTemplateSupport.certificationLines(
      resume?.certifications ?? const <Certification>[],
      maxItems: null,
    );
    return values.isNotEmpty
        ? values
        : const [
            'Google UX Design  •  Google',
            'Design Systems Mastery  •  InVision',
          ];
  }

  List<InfographicProjectEntry> get _projects {
    final values = InfographicTemplateSupport.projectEntries(
      resume?.projects ?? const <Project>[],
      maxItems: 3,
      maxDetailLines: null,
      compactLinks: true,
    );
    return values.isNotEmpty
        ? values
        : const [
            InfographicProjectEntry(
              title: 'Signal Dashboard',
              detailLines: [
                'Built a product health dashboard that aligned research insights and roadmap signals.',
              ],
              links: ['signal.example.com'],
            ),
            InfographicProjectEntry(
              title: 'Workflow Atlas',
              detailLines: [
                'Mapped complex ops flows into modular, reusable experience patterns for delivery teams.',
              ],
              links: ['atlas.example.com'],
            ),
          ];
  }

  List<String> get _languages {
    final values = InfographicTemplateSupport.languageLines(
      resume?.languages ?? const <Language>[],
      maxItems: 2,
    );
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: _canvas,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 210,
            height: 297,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shell(_buildHeader()),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 9,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _shell(
                                  _buildSignalBoard(),
                                  color: _softPanel,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 5,
                                child: _shell(
                                  _buildJourneyMap(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          flex: 10,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _infoCard(
                                        'EDUCATION NODE',
                                        [
                                          ..._educationEntries.asMap().entries.expand(
                                            (entry) => [
                                              _text(
                                                entry.value.degree,
                                                size: 2.05,
                                                color: _ink,
                                                weight: FontWeight.w800,
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 0.8),
                                              _text(
                                                entry.value.institutionLine,
                                                size: 1.74,
                                                color: _muted,
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 0.8),
                                              _text(
                                                entry.value.dateRange,
                                                size: 1.66,
                                                color: _accent,
                                                weight: FontWeight.w700,
                                                maxLines: 1,
                                              ),
                                              if (entry.value.supportingLines.isNotEmpty) ...[
                                                const SizedBox(height: 0.8),
                                                _text(
                                                  entry.value.supportingLines.first,
                                                  size: 1.64,
                                                  color: _muted,
                                                  maxLines: 2,
                                                ),
                                              ],
                                              if (entry.key != _educationEntries.length - 1)
                                                const SizedBox(height: 2),
                                            ],
                                          ),
                                        ],
                                        color: _warmPanel,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: _shell(
                                        _buildCredentials(),
                                        color: _panel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 5,
                                child: _shell(
                                  _buildProjectSignals(),
                                  color: _warmPanel,
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final roleCount = (resume?.experience.length ?? _experiences.length)
        .toString()
        .padLeft(2, '0');
    final toolCount = (resume?.skills.length ?? _primarySkills.length)
        .toString()
        .padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    _name,
                    size: 7.2,
                    color: _ink,
                    weight: FontWeight.w900,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 1),
                  _text(
                    _title,
                    size: 3.55,
                    color: _accent,
                    weight: FontWeight.w700,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2.6),
                  ..._summaryLines.map(_summaryBullet),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            _statTile('ROLES', '$roleCount total', _skyPanel),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child:
                            _statTile('TOOLS', '$toolCount mapped', _softPanel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _statTile('BASE', _baseLabel, _warmPanel),
                  if (_contactItems.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: _contactItems
                          .map((item) => _contactChip(item))
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignalBoard() {
    final footerTags = [
      ..._extraSkillNames,
      ..._languages,
    ].take(4).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRail('SIGNAL BOARD'),
        const SizedBox(height: 2.2),
        ..._primarySkills.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == _primarySkills.length - 1 ? 0 : 2.2,
                ),
                child: _skillMeter(entry.value),
              ),
            ),
        if (footerTags.isNotEmpty) ...[
          const SizedBox(height: 2.6),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: footerTags
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3.3,
                      vertical: 1.6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _line),
                    ),
                    child: _text(
                      label,
                      size: 1.56,
                      color: _accent,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _buildJourneyMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRail('JOURNEY MAP'),
        const SizedBox(height: 2.2),
        ..._experiences.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == _experiences.length - 1 ? 0 : 2.6,
                ),
                child: _journeyCard(
                  entry.value,
                  isLast: entry.key == _experiences.length - 1,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRail('CREDENTIALS'),
        const SizedBox(height: 2.2),
        ..._credentials.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 1.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3.4,
                  height: 3.4,
                  margin: const EdgeInsets.only(top: 0.7),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(0.9),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _text(
                    line,
                    size: 1.72,
                    color: _muted,
                    weight: FontWeight.w600,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectSignals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRail('PROJECT SIGNALS'),
        const SizedBox(height: 2.2),
        ..._projects.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == _projects.length - 1 ? 0 : 3,
                ),
                child: _atlasCard(
                  entry.value,
                  color: entry.key.isOdd ? _accentSoft : _panel,
                ),
              ),
            ),
      ],
    );
  }

  Widget _summaryBullet(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.6,
            height: 3.6,
            margin: const EdgeInsets.only(top: 0.8),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(0.9),
            ),
          ),
          const SizedBox(width: 2.4),
          Expanded(
            child: _text(
              line,
              size: 1.94,
              color: _muted,
              maxLines: 3,
              align: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyCard(
    InfographicExperienceEntry entry, {
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 8,
          child: Column(
            children: [
              Container(
                width: 4.8,
                height: 4.8,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1.2),
                  color: _line,
                ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _text(
                      entry.title,
                      size: 2.14,
                      color: _ink,
                      weight: FontWeight.w800,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2.6,
                      vertical: 1.2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _line),
                    ),
                    child: _text(
                      entry.dateRange,
                      size: 1.46,
                      color: _accent,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0.7),
              _text(
                entry.companyLine,
                size: 1.7,
                color: _muted,
                weight: FontWeight.w700,
                maxLines: 2,
              ),
              if (entry.detailLines.isNotEmpty) ...[
                const SizedBox(height: 1.1),
                ...entry.detailLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 0.9),
                    child: _text(
                      line,
                      size: 1.68,
                      color: _muted,
                      maxLines: 2,
                      align: TextAlign.justify,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _atlasCard(
    InfographicProjectEntry project, {
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4.2, 4, 4.2, 3.8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            project.title,
            size: 2.02,
            color: _ink,
            weight: FontWeight.w800,
            maxLines: 2,
          ),
          if (project.detailLines.isNotEmpty) ...[
            const SizedBox(height: 1.2),
            ...project.detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 0.9),
                child: _text(
                  line,
                  size: 1.7,
                  color: _muted,
                  maxLines: 3,
                  align: TextAlign.justify,
                ),
              ),
            ),
          ],
          if (project.links.isNotEmpty) ...[
            const SizedBox(height: 0.7),
            ...project.links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 0.6),
                child: _text(
                  link,
                  size: 1.58,
                  color: _accent,
                  weight: FontWeight.w700,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionRail(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(1.1),
          ),
        ),
        const SizedBox(width: 2.5),
        _text(
          label,
          size: 2.08,
          color: _ink,
          weight: FontWeight.w800,
          maxLines: 1,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Container(height: 0.5, color: _line),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4.2, 4, 4.2, 3.8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            label,
            size: 2.0,
            color: _muted,
            weight: FontWeight.w800,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          _text(
            value,
            size: 2.75,
            color: _ink,
            weight: FontWeight.w800,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _contactChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3.4, vertical: 1.8),
      decoration: BoxDecoration(
        color: _skyPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line),
      ),
      child: _text(
        text,
        size: 1.58,
        color: _muted,
        weight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }

  Widget _skillMeter(InfographicSkillEntry entry) {
    final percent = (entry.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _text(
                entry.name,
                size: 1.92,
                color: _ink,
                weight: FontWeight.w700,
                maxLines: 1,
              ),
            ),
            _text(
              '$percent',
              size: 1.64,
              color: _muted,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 1.1),
        Container(
          height: 2.1,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: entry.progress.clamp(0.35, 0.94),
            child: Container(
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> children, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4.2, 4.1, 4.2, 3.8),
      decoration: BoxDecoration(
        color: color ?? _panel,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            title,
            size: 2.0,
            color: _muted,
            weight: FontWeight.w800,
            maxLines: 1,
          ),
          const SizedBox(height: 1.6),
          ...children,
        ],
      ),
    );
  }

  Widget _shell(Widget child, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
      decoration: BoxDecoration(
        color: color ?? _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }

  Widget _text(
    String text, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w500,
    int? maxLines,
    TextAlign? align,
  }) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.clip,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        height: 1.22,
        color: color,
        fontWeight: weight,
      ),
    );
  }
}
