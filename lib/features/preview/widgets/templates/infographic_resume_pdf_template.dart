part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class InfographicResumePdfTemplate extends PdfTemplate {
  static const PdfColor _canvas =
      PdfColor.fromInt(InfographicTemplateSupport.canvasHex);
  static const PdfColor _panel =
      PdfColor.fromInt(InfographicTemplateSupport.panelHex);
  static const PdfColor _softPanel =
      PdfColor.fromInt(InfographicTemplateSupport.softPanelHex);
  static const PdfColor _warmPanel =
      PdfColor.fromInt(InfographicTemplateSupport.warmPanelHex);
  static const PdfColor _skyPanel =
      PdfColor.fromInt(InfographicTemplateSupport.skyPanelHex);
  static const PdfColor _line =
      PdfColor.fromInt(InfographicTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(InfographicTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(InfographicTemplateSupport.mutedHex);
  static const PdfColor _blendTarget =
      PdfColor.fromInt(InfographicTemplateSupport.accentBlendHex);
  static const double _pageHorizontal = 28;
  static const double _pageTop = 26;
  static const double _pageBottom = 28;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    final accent = _signalAccent(accentColor);
    final accentSoft = _blendPdfWithWhite(accent, 0.18);

    final summaryLines = InfographicTemplateSupport.summaryLines(
      resume.objective,
    );
    final contactItems = InfographicTemplateSupport.contactItems(
      resume.personalInfo,
      maxItems: 4,
    );
    final baseLabel = InfographicTemplateSupport.baseLabel(
      resume.personalInfo,
    );
    final skills = InfographicTemplateSupport.skillEntries(
      resume.skills,
      maxItems: 4,
    );
    final extraSkillNames = InfographicTemplateSupport.skillEntries(
      resume.skills,
      skip: 4,
      maxItems: 6,
    ).map((entry) => entry.name).toList(growable: false);
    final experiences = InfographicTemplateSupport.experienceEntries(
      resume.experience,
    );
    final primaryExperiences = experiences.take(2).toList(growable: false);
    final overflowExperiences = experiences.skip(2).toList(growable: false);
    final educationEntries = InfographicTemplateSupport.educationEntries(
      resume.education,
      maxSupportLines: 2,
    );
    final allEducation = educationEntries;
    final credentialLines = InfographicTemplateSupport.certificationLines(
      resume.certifications,
    );
    final primaryCredentials = credentialLines;
    final projects = InfographicTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
      compactLinks: true,
    );
    final primaryProjects = projects.take(3).toList(growable: false);
    final overflowProjects = projects.skip(3).toList(growable: false);
    final extendedLanguages = InfographicTemplateSupport.languageLines(
      resume.languages,
    );
    final overflowSkillTags =
        extraSkillNames.skip(6).toList(growable: false);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageHorizontal,
            _pageTop,
            _pageHorizontal,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _canvas),
          ),
        ),
        build: (context) => [
          _shell(
            _buildHeader(
              resume: resume,
              accent: accent,
              summaryLines: summaryLines,
              contactItems: contactItems,
              baseLabel: baseLabel,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: _shell(
                  _buildSignalBoard(
                    accent: accent,
                    skills: skills,
                    extraSkillNames: extraSkillNames,
                    languages: const <String>[],
                  ),
                  color: _softPanel,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                flex: 5,
                child: _shell(
                  _buildJourneyMap(
                    accent: accent,
                    entries: primaryExperiences,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _infoCard(
                      'EDUCATION NODE',
                      [
                        if (allEducation.isNotEmpty)
                          ...allEducation.asMap().entries.expand(
                            (entry) => [
                              _educationCardBody(entry.value, accent),
                              if (entry.key != allEducation.length - 1)
                                pw.SizedBox(height: 8),
                            ],
                          )
                        else
                          _emptyLine('Education details appear here.'),
                      ],
                      color: _warmPanel,
                    ),
                    pw.SizedBox(height: 10),
                    _shell(
                      _buildCredentials(
                        accent: accent,
                        lines: primaryCredentials,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                flex: 5,
                child: _shell(
                  _buildProjectSignals(
                    accent: accent,
                    accentSoft: accentSoft,
                    projects: primaryProjects,
                  ),
                  color: _warmPanel,
                ),
              ),
            ],
          ),
          if (overflowExperiences.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _shell(
              _buildJourneyMap(
                accent: accent,
                entries: overflowExperiences,
                title: 'JOURNEY MAP CONTINUED',
              ),
            ),
          ],
          if (overflowProjects.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _shell(
              _buildProjectSignals(
                accent: accent,
                accentSoft: accentSoft,
                projects: overflowProjects,
                title: 'PROJECT SIGNALS CONTINUED',
              ),
              color: _warmPanel,
            ),
          ],
          if (extendedLanguages.isNotEmpty || overflowSkillTags.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Inseparable(
              child: _shell(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (overflowSkillTags.isNotEmpty) ...[
                      _sectionRail('EXTENDED SIGNALS', accent),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: overflowSkillTags
                            .map((label) => _tagChip(label, accent))
                            .toList(growable: false),
                      ),
                    ],
                    if (extendedLanguages.isNotEmpty) ...[
                      if (overflowSkillTags.isNotEmpty) pw.SizedBox(height: 10),
                      _sectionRail('LANGUAGES', accent),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: extendedLanguages
                            .map((label) => _tagChip(label, accent))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          ...orderedUserCustomSections(resume)
              .where((section) => section.items.isNotEmpty)
              .expand(
                (section) => [
                  pw.SizedBox(height: 14),
                  _shell(
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: _buildGenericUserCustomSectionWidgets(
                        section,
                        accentColor: accent,
                        bottomSpacing: 0,
                        headerBuilder: (title) =>
                            _sectionRail(title.toUpperCase(), accent),
                      ),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );

    return pdf;
  }

  PdfColor _signalAccent(PdfColor accentColor) {
    return PdfColor(
      (accentColor.red * 0.38 + _blendTarget.red * 0.62)
          .clamp(0.0, 1.0)
          .toDouble(),
      (accentColor.green * 0.38 + _blendTarget.green * 0.62)
          .clamp(0.0, 1.0)
          .toDouble(),
      (accentColor.blue * 0.38 + _blendTarget.blue * 0.62)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  pw.Widget _buildHeader({
    required ResumeModel resume,
    required PdfColor accent,
    required List<String> summaryLines,
    required List<String> contactItems,
    required String baseLabel,
  }) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim())
        : 'Jordan Smith';
    final title = resume.personalInfo.jobTitle?.trim().isNotEmpty == true
        ? _sanitizePdfText(resume.personalInfo.jobTitle!.trim())
        : 'Product Designer';
    final roleCount = resume.experience.length.toString().padLeft(2, '0');
    final toolCount = resume.skills.length.toString().padLeft(2, '0');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitizePdfText(name),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _sanitizePdfText(title),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.SizedBox(height: 8),
              if (summaryLines.isEmpty)
                _emptyLine('Professional summary appears here.')
              else
                ...summaryLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Container(
                            width: 5,
                            height: 5,
                            decoration: pw.BoxDecoration(
                              color: accent,
                              borderRadius: pw.BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Text(
                            _sanitizePdfText(line),
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              color: _muted,
                              lineSpacing: 1.35,
                            ),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statTile('ROLES', '$roleCount total', _skyPanel),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _statTile('TOOLS', '$toolCount mapped', _softPanel),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              _statTile('BASE', baseLabel, _warmPanel),
              if (contactItems.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: contactItems
                      .map((item) => _contactChip(item))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignalBoard({
    required PdfColor accent,
    required List<InfographicSkillEntry> skills,
    required List<String> extraSkillNames,
    required List<String> languages,
  }) {
    final footerTags = [
      ...extraSkillNames,
      ...languages,
    ].take(6).toList(growable: false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionRail('SIGNAL BOARD', accent),
        pw.SizedBox(height: 8),
        if (skills.isEmpty)
          _emptyLine('Skills appear here.')
        else
          ...skills.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: _skillMeter(entry, accent),
            ),
          ),
        if (footerTags.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: footerTags
                .map((label) => _tagChip(label, accent))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildJourneyMap({
    required PdfColor accent,
    required List<InfographicExperienceEntry> entries,
    String title = 'JOURNEY MAP',
  }) {
    final journeyWidgets = <pw.Widget>[
      for (final entry in entries.asMap().entries)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _journeyEntry(
            entry.value,
            accent,
            isLast: entry.key == entries.length - 1,
          ),
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionRail(title, accent),
        pw.SizedBox(height: 8),
        if (entries.isEmpty)
          _emptyLine('Experience milestones appear here.')
        else
          ...journeyWidgets,
      ],
    );
  }

  pw.Widget _buildCredentials({
    required PdfColor accent,
    required List<String> lines,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionRail('CREDENTIALS', accent),
        pw.SizedBox(height: 8),
        if (lines.isEmpty)
          _emptyLine('No certifications added yet.')
        else
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: _credentialLine(line, accent),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildProjectSignals({
    required PdfColor accent,
    required PdfColor accentSoft,
    required List<InfographicProjectEntry> projects,
    String title = 'PROJECT SIGNALS',
  }) {
    final projectWidgets = <pw.Widget>[
      for (final entry in projects.asMap().entries)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _atlasCard(
            entry.value,
            accent,
            color: entry.key.isOdd ? accentSoft : _panel,
          ),
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionRail(title, accent),
        pw.SizedBox(height: 8),
        if (projects.isEmpty)
          _emptyLine('Project snapshots appear here.')
        else
          ...projectWidgets,
      ],
    );
  }

  pw.Widget _journeyEntry(
    InfographicExperienceEntry entry,
    PdfColor accent, {
    required bool isLast,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 12,
          child: pw.Column(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
              if (!isLast)
                pw.Container(
                  width: 1,
                  height: 28,
                  margin: const pw.EdgeInsets.only(top: 2),
                  color: _line,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(entry.title),
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _blendPdfWithWhite(accent, 0.14),
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: _line),
                    ),
                    child: pw.Text(
                      _sanitizePdfText(entry.dateRange),
                      style: pw.TextStyle(
                        fontSize: 7.8,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _sanitizePdfText(entry.companyLine),
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  color: _muted,
                ),
              ),
              if (entry.detailLines.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                ...entry.detailLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      _sanitizePdfText(line),
                      style: const pw.TextStyle(
                        fontSize: 8.7,
                        color: _muted,
                        lineSpacing: 1.35,
                      ),
                      textAlign: pw.TextAlign.left,
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

  pw.Widget _atlasCard(
    InfographicProjectEntry project,
    PdfColor accent, {
    required PdfColor color,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (project.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...project.detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _sanitizePdfText(line),
                  style: const pw.TextStyle(
                    fontSize: 8.6,
                    color: _muted,
                    lineSpacing: 1.35,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ),
          ],
          if (project.links.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...project.links.map(
              (link) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _sanitizePdfText(link),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _educationCardBody(
    InfographicEducationEntry entry,
    PdfColor accent,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.degree),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _sanitizePdfText(entry.institutionLine),
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: _muted,
            lineSpacing: 1.3,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: accent,
          ),
        ),
        if (entry.supportingLines.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          ...entry.supportingLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.2,
                  color: _muted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _credentialLine(String line, PdfColor accent) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Container(
            width: 5,
            height: 5,
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: _muted,
              lineSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionRail(String label, PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 5,
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(1.5),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          _h(label),
          style: pw.TextStyle(
            fontSize: 9.6,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(height: 0.6, color: _line),
        ),
      ],
    );
  }

  pw.Widget _statTile(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(label),
            style: const pw.TextStyle(
              fontSize: 7.8,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _sanitizePdfText(value),
            style: pw.TextStyle(
              fontSize: 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _contactChip(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _skyPanel,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(
          fontSize: 7.7,
          color: _muted,
        ),
      ),
    );
  }

  pw.Widget _skillMeter(InfographicSkillEntry entry, PdfColor accent) {
    final percent = (entry.progress * 100).round();
    final filledFlex = percent.clamp(35, 94);
    final emptyFlex = 100 - filledFlex;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(entry.name),
                style: pw.TextStyle(
                  fontSize: 8.8,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
            pw.Text(
              '$percent',
              style: const pw.TextStyle(
                fontSize: 7.8,
                color: _muted,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
            color: _blendPdfWithWhite(accent, 0.12),
            borderRadius: pw.BorderRadius.circular(2),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: filledFlex,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
              ),
              if (emptyFlex > 0)
                pw.Expanded(
                  flex: emptyFlex,
                  child: pw.SizedBox(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tagChip(String label, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accent, 0.1),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Text(
        _sanitizePdfText(label),
        style: pw.TextStyle(
          fontSize: 7.6,
          fontWeight: pw.FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }

  pw.Widget _infoCard(String title, List<pw.Widget> children,
      {PdfColor? color}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: pw.BoxDecoration(
        color: color ?? _panel,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: const pw.TextStyle(
              fontSize: 7.8,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _shell(pw.Widget child, {PdfColor? color}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: pw.BoxDecoration(
        color: color ?? _panel,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line),
      ),
      child: child,
    );
  }

  pw.Widget _emptyLine(String text) {
    return pw.Text(
      _sanitizePdfText(text),
      style: const pw.TextStyle(
        fontSize: 8.4,
        color: _muted,
        lineSpacing: 1.3,
      ),
    );
  }
}
