part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class RosewoodPanelResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.pageHex);
  static const PdfColor _sheet =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.sheetHex);
  static const PdfColor _panel =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.panelHex);
  static const PdfColor _accent =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.mutedHex);
  static const PdfColor _panelInk =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.panelInkHex);
  static const PdfColor _line =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.lineHex);
  static const PdfColor _avatar =
      PdfColor.fromInt(RosewoodPanelTemplateSupport.avatarHex);

  PdfColor get _sectionRule => _blendPdfWithWhite(_accent, 0.55);
  PdfColor get _sidebarBorder => _blendPdfWithWhite(_accent, 0.45);
  PdfColor get _avatarFill => _blendPdfWithWhite(_accent, 0.22);

  static const double _pageMargin = 28;
  static const double _pageTop = 26;
  static const double _pageBottom = 26;
  static const double _sheetInset = 12;
  static const double _sidebarWidth = 146;
  static const double _contentGap = 18;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'highlights',
    'projects',
    'certifications',
    'languages',
  ];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: _defaultOrder,
      allowedKeys: _defaultOrder,
    );

    final name = RosewoodPanelTemplateSupport.displayName(resume);
    final title = RosewoodPanelTemplateSupport.displayTitle(resume);
    final contactItems = RosewoodPanelTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = RosewoodPanelTemplateSupport.educationEntries(
      resume.education,
      maxItems: 2,
      yearOnly: true,
    );
    final summaryLines =
        RosewoodPanelTemplateSupport.summaryLines(resume.objective);
    final experienceEntries = RosewoodPanelTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: null,
      yearOnly: true,
    );
    final awardEntries = RosewoodPanelTemplateSupport.awardEntries(
      resume.customSections,
      maxItems: 3,
    );
    final skillNames = RosewoodPanelTemplateSupport.skillNames(resume.skills);
    final projectEntries = RosewoodPanelTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        RosewoodPanelTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = RosewoodPanelTemplateSupport.languageLines(
      resume.languages,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT'),
        ...summaryLines.map(_aboutBullet),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry),
          ),
        ),
      ];
    }

    if (awardEntries.isNotEmpty || skillNames.isNotEmpty) {
      sections['highlights'] = _highlightsSection(awardEntries, skillNames);
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...certificationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: _certificationLine(entry),
          ),
        ),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...languageLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
            ),
          ),
        ),
      ];
    }

    final awardLikeSectionPattern = RegExp(
      r'(award|honou?r|achievement|recognition)',
      caseSensitive: false,
    );
    for (final section in orderedUserCustomSections(resume).where(
      (section) => !awardLikeSectionPattern.hasMatch(section.title),
    )) {
      if (section.items.isEmpty) {
        continue;
      }

      final title = displayUserCustomSectionTitle(
        section,
        fallback: 'SECTION',
      ).toUpperCase();

      sections[section.id] = [
        _sectionHeader(title),
        ...section.items.map(
          (item) {
            final displayItem = buildUserCustomSectionDisplayItem(item);
            final metaParts = <String>[
              if (displayItem.subtitle.isNotEmpty)
                _sanitizePdfText(displayItem.subtitle),
              if (displayItem.date != null)
                DateFormat('MMM yyyy').format(displayItem.date!),
            ];

            if (!displayItem.hasContent) {
              return pw.SizedBox.shrink();
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (displayItem.heading.isNotEmpty)
                    pw.Text(
                      _sanitizePdfText(displayItem.heading),
                      style: pw.TextStyle(
                        fontSize: 8.6,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (metaParts.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        metaParts.join('  |  '),
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: _muted,
                        ),
                      ),
                    ),
                  ...displayItem.detailLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: _muted,
                          lineSpacing: 1.2,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin + _sheetInset + _sidebarWidth + _contentGap,
            _pageTop + _sheetInset,
            _pageMargin + _sheetInset,
            _pageBottom + _sheetInset,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context,
              photoBytes,
              contactItems,
              educationEntries,
            ),
          ),
        ),
        build: (context) => [
          _header(name, title),
          pw.SizedBox(height: 10),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    Uint8List? photoBytes,
    List<RosewoodContactItem> contactItems,
    List<RosewoodEducationEntry> educationEntries,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin,
          right: _pageMargin,
          top: _pageTop,
          bottom: _pageBottom,
          child: pw.Container(color: _sheet),
        ),
        pw.Positioned(
          left: _pageMargin + _sheetInset,
          top: _pageTop + _sheetInset,
          bottom: _pageBottom + _sheetInset,
          child: pw.SizedBox(
            width: _sidebarWidth,
            child: _sidebar(
              photoBytes,
              contactItems,
              educationEntries,
              includeContent: context.pageNumber == 1,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sidebar(
    Uint8List? photoBytes,
    List<RosewoodContactItem> contactItems,
    List<RosewoodEducationEntry> educationEntries, {
    required bool includeContent,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _panel,
        border: pw.Border.all(color: _sidebarBorder, width: 1),
      ),
      padding: const pw.EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: includeContent
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Container(
                    width: 74,
                    height: 74,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: photoBytes == null ? _avatarFill : null,
                      image: photoBytes != null
                          ? pw.DecorationImage(
                              image: pw.MemoryImage(photoBytes),
                              fit: pw.BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoBytes == null
                        ? pw.Center(
                            child: pw.Text(
                              'RP',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: _accent,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                pw.SizedBox(height: 18),
                _sidebarSection('CONTACT'),
                ...contactItems.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      _sanitizePdfText(item.label),
                      style: const pw.TextStyle(
                        fontSize: 8.0,
                        color: _panelInk,
                        lineSpacing: 1.15,
                      ),
                    ),
                  ),
                ),
                if (educationEntries.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  _sidebarSection('EDUCATION'),
                  ...educationEntries.map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(entry.degree),
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            _sanitizePdfText(
                              '${entry.institutionLine} | ${entry.dateRange}',
                            ),
                            style: const pw.TextStyle(
                              fontSize: 7.8,
                              color: _panelInk,
                              lineSpacing: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            )
          : pw.SizedBox.shrink(),
    );
  }

  pw.Widget _header(String name, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(name).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Text(
            _sanitizePdfText(title),
            style: const pw.TextStyle(fontSize: 12, color: _muted),
          ),
      ],
    );
  }

  pw.Widget _sidebarSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.3,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              height: 1,
              color: _sectionRule,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _miniSectionHeader(String title) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9.1,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Container(height: 1, color: _sectionRule),
        ),
      ],
    );
  }

  pw.Widget _experienceBlock(RosewoodExperienceEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 10.4,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          _sanitizePdfText('${entry.metaLine}  |  ${entry.dateRange}'),
          style: const pw.TextStyle(fontSize: 8.5, color: _muted),
        ),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _detailBullet(line, fontSize: 8.6),
          ),
        ),
      ],
    );
  }

  pw.Widget _aboutBullet(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.2),
            child: pw.SizedBox(
              width: 8.6,
              height: 8.6,
              child: pw.CustomPaint(
                size: const PdfPoint(8.6, 8.6),
                painter: (canvas, size) {
                  canvas.setStrokeColor(_accent);
                  canvas.setLineWidth(1.2);
                  canvas.moveTo(size.x * 0.12, size.y * 0.44);
                  canvas.lineTo(size.x * 0.34, size.y * 0.18);
                  canvas.lineTo(size.x * 0.88, size.y * 0.78);
                  canvas.strokePath();
                },
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(value),
              style: const pw.TextStyle(
                fontSize: 9.1,
                color: _muted,
                lineSpacing: 1.35,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _highlightsSection(
    List<RosewoodAwardEntry> awardEntries,
    List<String> skillNames,
  ) {
    final widgets = <pw.Widget>[];

    if (awardEntries.isNotEmpty && skillNames.isNotEmpty) {
      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _awardsColumn(awardEntries)),
            pw.SizedBox(width: 18),
            pw.Expanded(child: _skillsColumn(skillNames)),
          ],
        ),
      );
    } else if (awardEntries.isNotEmpty) {
      widgets.add(_awardsColumn(awardEntries));
    } else if (skillNames.isNotEmpty) {
      widgets.add(_skillsColumn(skillNames));
    }

    widgets.add(pw.SizedBox(height: 8));
    return widgets;
  }

  pw.Widget _awardsColumn(List<RosewoodAwardEntry> awards) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _miniSectionHeader('AWARDS'),
        pw.SizedBox(height: 4),
        ...awards.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _sanitizePdfText(entry.title),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _skillsColumn(List<String> skills) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _miniSectionHeader('SKILLS'),
        pw.SizedBox(height: 4),
        ...skills.map(
          (skill) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: _skillBlock(skill),
          ),
        ),
      ],
    );
  }

  pw.Widget _skillBlock(String skill) {
    final skillFill = _blendPdfWithWhite(_accent, 0.38);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(skill),
            style: const pw.TextStyle(fontSize: 8.3, color: _ink),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          width: 72,
          height: 4,
          color: skillFill,
        ),
      ],
    );
  }

  pw.Widget _detailBullet(String value, {double fontSize = 8.0}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 4, right: 6),
          decoration: const pw.BoxDecoration(
            color: _accent,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(value),
            style: pw.TextStyle(
              fontSize: fontSize,
              color: _muted,
              lineSpacing: 1.25,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _projectBlock(RosewoodProjectEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 8.8,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: _detailBullet(line, fontSize: 8.0),
          ),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(link),
              style: const pw.TextStyle(fontSize: 7.9, color: _accent),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _certificationLine(RosewoodCertificationEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(
            [entry.name, if (entry.metaLine.isNotEmpty) entry.metaLine]
                .join(' - '),
          ),
          style: const pw.TextStyle(fontSize: 8.3, color: _muted),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(link),
              style: const pw.TextStyle(fontSize: 7.8, color: _accent),
            ),
          ),
        ),
      ],
    );
  }
}
