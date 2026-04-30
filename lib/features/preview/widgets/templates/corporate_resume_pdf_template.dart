part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class CorporateResumePdfTemplate extends PdfTemplate {
  static const PdfColor _sidebarBg =
      PdfColor.fromInt(CorporateTemplateSupport.sidebarBgHex);
  static const PdfColor _sidebarMuted =
      PdfColor.fromInt(CorporateTemplateSupport.sidebarMutedHex);
  static const PdfColor _bodyInk =
      PdfColor.fromInt(CorporateTemplateSupport.bodyInkHex);
  static const PdfColor _bodyMuted =
      PdfColor.fromInt(CorporateTemplateSupport.bodyMutedHex);
  static const PdfColor _line =
      PdfColor.fromInt(CorporateTemplateSupport.lineHex);
  static const double _pageMargin = 24;
  static const double _pageTop = 28;
  static const double _pageBottom = 28;
  static const double _sidebarWidth = 146;
  static const double _sidebarGap = 18;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'certifications',
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

    final name = CorporateTemplateSupport.displayName(resume);
    final title = CorporateTemplateSupport.displayTitle(resume);
    final address = _sanitizePdfText(resume.personalInfo.address).trim();
    final contactItems = CorporateTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = CorporateTemplateSupport.educationEntries(
      resume.education,
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = CorporateTemplateSupport.skillNames(
      resume.skills,
      maxItems: 8,
    );
    final languageLines = CorporateTemplateSupport.languageLines(
      resume.languages,
      maxItems: 5,
    );
    final summaryLines = CorporateTemplateSupport.summaryLines(resume.objective);
    final experienceEntries = CorporateTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 10,
      yearOnly: false,
    );
    final projectEntries = CorporateTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 10,
      compactLinks: true,
    );
    final certificationEntries = CorporateTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _bodySectionHeader('PROFILE', accentColor),
        ...summaryLines.map((line) => _bodyBullet(line, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _bodySectionHeader('WORK EXPERIENCE', accentColor),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry, accentColor),
          ),
        ),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _bodySectionHeader('PROJECTS', accentColor),
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
        _bodySectionHeader('CERTIFICATIONS', accentColor),
        ...certificationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _certificationBlock(entry, accentColor),
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) =>
          _bodySectionHeader(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin,
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
              educationEntries,
              skillNames,
              languageLines,
            ),
          ),
        ),
        build: (context) => [
          _bodyPadding(_buildHeader(name, title, address, accentColor)),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(sectionOrder, sections)
              .map(_bodyPadding),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    PdfColor accentColor,
    Uint8List? photoBytes,
    List<CorporateContactItem> contactItems,
    List<CorporateEducationEntry> educationEntries,
    List<String> skillNames,
    List<String> languageLines,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: PdfColors.white),
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
              educationEntries,
              skillNames,
              languageLines,
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
    List<CorporateContactItem> contactItems,
    List<CorporateEducationEntry> educationEntries,
    List<String> skillNames,
    List<String> languageLines, {
    required bool includeContent,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 20, 12, 18),
      color: _sidebarBg,
      child: includeContent
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: photoBytes == null
                          ? PdfColor(
                              accentColor.red,
                              accentColor.green,
                              accentColor.blue,
                              0.35,
                            )
                          : null,
                      border: pw.Border.all(color: accentColor, width: 2.5),
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
                              'YN',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                pw.SizedBox(height: 20),
                if (contactItems.isNotEmpty) ...[
                  _sidebarSectionHeader('CONTACTS', accentColor),
                  ...contactItems.map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        _sanitizePdfText(item.label),
                        style: const pw.TextStyle(
                          fontSize: 8.4,
                          color: _sidebarMuted,
                          lineSpacing: 1.35,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
                if (educationEntries.isNotEmpty) ...[
                  _sidebarSectionHeader('EDUCATION', accentColor),
                  ...educationEntries.map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(entry.degree),
                            style: pw.TextStyle(
                              fontSize: 8.7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 1),
                            child: pw.Text(
                              _sanitizePdfText(entry.institutionLine),
                              style: pw.TextStyle(
                                fontSize: 8.0,
                                color: accentColor,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 1),
                            child: pw.Text(
                              _sanitizePdfText(entry.dateRange),
                              style: const pw.TextStyle(
                                fontSize: 7.8,
                                color: _sidebarMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
                if (skillNames.isNotEmpty) ...[
                  _sidebarSectionHeader('SKILLS', accentColor),
                  ...skillNames.map(
                    (skill) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            margin: const pw.EdgeInsets.only(top: 0.5, right: 8),
                            decoration: pw.BoxDecoration(
                              color: accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Container(
                                width: 3.6,
                                height: 3.6,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              _sanitizePdfText(skill),
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: _sidebarMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (languageLines.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _sidebarSectionHeader('LANGUAGES', accentColor),
                  ...languageLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: _sidebarMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : pw.SizedBox.expand(),
    );
  }

  pw.Widget _buildHeader(
    String name,
    String title,
    String address,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          _sanitizePdfText(name).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _bodyInk,
            letterSpacing: 1.2,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              _sanitizePdfText(title).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                color: accentColor,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        if (address.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              address,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: _bodyMuted,
              ),
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2.5, color: accentColor),
      ],
    );
  }

  pw.Widget _sidebarSectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          pw.Container(
            height: 1,
            color: PdfColor(
              accentColor.red,
              accentColor.green,
              accentColor.blue,
              0.5,
            ),
            margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodySectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _bodyInk,
              letterSpacing: 0.8,
            ),
          ),
          pw.Container(
            height: 1,
            color: _line,
            margin: const pw.EdgeInsets.only(top: 4),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyBullet(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 6),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(
                color: accentColor,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _bodyMuted,
                lineSpacing: 1.45,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(
    CorporateExperienceEntry entry,
    PdfColor accentColor,
  ) {
    final dates = entry.dateRange.split(' - ');
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 58,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(dates.first),
                  style: const pw.TextStyle(
                    fontSize: 8.3,
                    color: _bodyMuted,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(dates.length > 1 ? dates.last : dates.first),
                  style: const pw.TextStyle(
                    fontSize: 8.3,
                    color: _bodyMuted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 1.2,
            height: 18 + (entry.detailLines.length * 16),
            color: PdfColor(
              accentColor.red,
              accentColor.green,
              accentColor.blue,
              0.35,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _bodyInk,
                  ),
                ),
                if (entry.metaLine.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(entry.metaLine),
                      style: pw.TextStyle(
                        fontSize: 8.8,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 4),
                ...entry.detailLines.map(
                  (line) => _bodyBullet(line, accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(
    CorporateProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _bodyInk,
            ),
          ),
          pw.SizedBox(height: 3),
          ...entry.detailLines.map(
            (line) => _bodyBullet(line, accentColor),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 1),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 8.6,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(
    CorporateCertificationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 9.8,
              fontWeight: pw.FontWeight.bold,
              color: _bodyInk,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.7,
                  color: _bodyMuted,
                  lineSpacing: 1.34,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyPadding(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: _sidebarWidth + _sidebarGap),
      child: child,
    );
  }
}