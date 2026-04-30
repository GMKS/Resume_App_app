part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class GraphiteColumnResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.pageHex);
  static const PdfColor _panel =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.panelHex);
  static const PdfColor _panelMuted =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.panelMutedHex);
  static const PdfColor _ink =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.mutedHex);
  static const PdfColor _line =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.lineHex);
  static const PdfColor _photoTint =
      PdfColor.fromInt(GraphiteColumnTemplateSupport.photoTintHex);

  static const double _pageMargin = 24;
  static const double _pageTop = 28;
  static const double _pageBottom = 24;
  static const double _sidebarWidth = 150;
  static const double _sidebarGap = 22;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'education',
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

    final name = GraphiteColumnTemplateSupport.displayName(resume);
    final title = GraphiteColumnTemplateSupport.displayTitle(resume);
    final contactItems = GraphiteColumnTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final skillNames = GraphiteColumnTemplateSupport.skillNames(
      resume.skills,
      maxItems: 8,
    );
    final summaryLines = GraphiteColumnTemplateSupport.summaryLines(
      resume.objective,
    );
    final experienceEntries = GraphiteColumnTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      yearOnly: false,
    );
    final educationEntries = GraphiteColumnTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final projectEntries = GraphiteColumnTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 10,
      compactLinks: true,
    );
    final certificationEntries =
        GraphiteColumnTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = GraphiteColumnTemplateSupport.languageLines(
      resume.languages,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('PROFILE', accentColor),
        ...summaryLines.map((line) => _detailBullet(line, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('WORK EXPERIENCE', accentColor),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry, accentColor),
          ),
        ),
      ];
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION', accentColor),
        ...educationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _educationBlock(entry),
          ),
        ),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS', accentColor),
        ...projectEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _projectBlock(entry, accentColor),
          ),
        ),
      ];
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS', accentColor),
        ...certificationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _certificationBlock(entry, accentColor),
          ),
        ),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES', accentColor),
        ...languageLines.map(_languageLine),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin + _sidebarWidth + _sidebarGap,
            _pageTop,
            _pageMargin,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context,
              accentColor,
              photoBytes,
              contactItems,
              skillNames,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(name, title, accentColor),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    PdfColor accentColor,
    Uint8List? photoBytes,
    List<GraphiteContactItem> contactItems,
    List<String> skillNames,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin,
          top: _pageTop,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: _sidebarWidth,
            child: _buildSidebar(
              accentColor,
              photoBytes,
              contactItems,
              skillNames,
              includeContent: context.pageNumber == 1,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSidebar(
    PdfColor accentColor,
    Uint8List? photoBytes,
    List<GraphiteContactItem> contactItems,
    List<String> skillNames, {
    required bool includeContent,
  }) {
    return pw.Container(
      color: _panel,
      padding: const pw.EdgeInsets.fromLTRB(18, 24, 14, 24),
      child: includeContent
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Container(
                    width: 78,
                    height: 96,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.white, width: 1.5),
                      color: photoBytes == null ? _photoTint : null,
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
                              'PHOTO',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                pw.SizedBox(height: 18),
                if (contactItems.isNotEmpty) ...[
                  _sidebarSectionHeader('CONTACT', accentColor),
                  ...contactItems.map((item) => _sidebarLine(item.label)),
                  pw.SizedBox(height: 14),
                ],
                if (skillNames.isNotEmpty) ...[
                  _sidebarSectionHeader('SKILLS', accentColor),
                  ...skillNames.map(_sidebarLine),
                ],
              ],
            )
          : pw.SizedBox.shrink(),
    );
  }

  pw.Widget _buildHeader(String name, String title, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(name).toUpperCase(),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (title.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(title),
                style: const pw.TextStyle(fontSize: 12, color: _muted),
              ),
            ),
          pw.Container(
            height: 1,
            color: PdfColor(
              accentColor.red,
              accentColor.green,
              accentColor.blue,
              0.55,
            ),
            margin: const pw.EdgeInsets.only(top: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarSectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.1,
            ),
          ),
          pw.Container(
            height: 1,
            color: accentColor,
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(
          fontSize: 8.2,
          color: _panelMuted,
          lineSpacing: 1.25,
        ),
      ),
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.1,
            ),
          ),
          pw.Container(
            height: 1,
            color: PdfColor(
              accentColor.red,
              accentColor.green,
              accentColor.blue,
              0.45,
            ),
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _detailBullet(String value, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4.2, right: 6),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(value),
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(
                fontSize: 8.7,
                color: _muted,
                lineSpacing: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(
    GraphiteExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
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
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 8.2, color: _muted),
              ),
            ],
          ),
          if (entry.metaLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5, bottom: 3),
              child: pw.Text(
                _sanitizePdfText(entry.metaLine),
                style: pw.TextStyle(
                  fontSize: 8.8,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map((line) => _detailBullet(line, accentColor)),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(GraphiteEducationEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.degree),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 8.0, color: _muted),
              ),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(entry.institutionLine),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(
    GraphiteProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...entry.detailLines.map((line) => _detailBullet(line, accentColor)),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(fontSize: 8.1, color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(
    GraphiteCertificationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 8.9,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(
                  fontSize: 8.1,
                  color: _muted,
                  lineSpacing: 1.25,
                ),
              ),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(fontSize: 8.0, color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _languageLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(fontSize: 8.5, color: _muted),
      ),
    );
  }
}
