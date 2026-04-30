part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class CorporateNavyResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageChrome =
      PdfColor.fromInt(CorporateNavyTemplateSupport.pageChromeHex);
  static const PdfColor _page =
      PdfColor.fromInt(CorporateNavyTemplateSupport.pageHex);
  static const PdfColor _headerStart =
      PdfColor.fromInt(CorporateNavyTemplateSupport.headerStartHex);
  static const PdfColor _headerEnd =
      PdfColor.fromInt(CorporateNavyTemplateSupport.headerEndHex);
  static const PdfColor _headerText =
      PdfColor.fromInt(CorporateNavyTemplateSupport.headerTextHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(CorporateNavyTemplateSupport.sidebarHex);
  static const PdfColor _accent =
      PdfColor.fromInt(CorporateNavyTemplateSupport.accentHex);
  static const PdfColor _avatarBorder =
      PdfColor.fromInt(CorporateNavyTemplateSupport.avatarBorderHex);
  static const PdfColor _line =
      PdfColor.fromInt(CorporateNavyTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(CorporateNavyTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(CorporateNavyTemplateSupport.mutedHex);

  static const double _pageMargin = 20;
  static const double _pageTop = 20;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 142;
  static const double _sidebarGap = 14;
  static const double _headerCardWidth = 220;
  static const double _headerHeight = 86;
  static const double _headerBottomGap = 12;
  static const double _sidebarTopGap = 8;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'certifications',
    'projects',
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

    final name = CorporateNavyTemplateSupport.displayName(resume);
    final title = CorporateNavyTemplateSupport.displayTitle(resume);
    final contactItems = CorporateNavyTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = CorporateNavyTemplateSupport.educationEntries(
      resume.education,
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = CorporateNavyTemplateSupport.skillNames(
      resume.skills,
      maxItems: 8,
    );
    final summaryLines = CorporateNavyTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final experienceEntries = CorporateNavyTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: 6,
      yearOnly: false,
    );
    final certificationEntries =
        CorporateNavyTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final projectEntries = CorporateNavyTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final languageLines = CorporateNavyTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'CN');

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _bodySectionHeader('ABOUT ME'),
        ...summaryLines.map(_bodyBullet),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _bodySectionHeader('EXPERIENCE'),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry),
          ),
        ),
      ];
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _bodySectionHeader('CERTIFICATIONS'),
        ...certificationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _certificationBlock(entry),
          ),
        ),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _bodySectionHeader('PROJECTS'),
        ...projectEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _bodySectionHeader('LANGUAGES'),
        ...languageLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _bodyBullet(line),
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _bodySectionHeader(title.toUpperCase()),
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
              contactItems,
              educationEntries,
              skillNames,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(name, title, photoBytes, initials),
          pw.SizedBox(height: _headerBottomGap),
          ..._applyPdfSectionOrder(sectionOrder, sections).map(_bodyPadding),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    List<CorporateNavyContactItem> contactItems,
    List<CorporateNavyEducationEntry> educationEntries,
    List<String> skillNames,
  ) {
    final sidebarTop = context.pageNumber == 1
        ? _pageTop + _headerHeight + _headerBottomGap
        : _pageTop + 8;

    return pw.Stack(
      children: [
        pw.Container(color: _pageChrome),
        pw.Positioned(
          left: _pageMargin,
          top: _pageTop,
          right: _pageMargin,
          bottom: _pageBottom,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              color: _page,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin,
          top: sidebarTop,
          bottom: _pageBottom,
          child: pw.Container(
            width: _sidebarWidth,
            color: _sidebar,
            padding: const pw.EdgeInsets.fromLTRB(16, 16, 14, 14),
            child: context.pageNumber == 1
                ? _buildSidebarContent(
                    contactItems,
                    educationEntries,
                    skillNames,
                  )
                : pw.SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeader(
    String name,
    String title,
    Uint8List? photoBytes,
    String initials,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: _sidebarWidth + _sidebarGap),
      child: pw.Container(
        width: _headerCardWidth,
        height: _headerHeight,
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
            colors: [_headerStart, _headerEnd],
          ),
        ),
        child: pw.Stack(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(16, 14, 64, 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    _sanitizePdfText(name).toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18.4,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 2,
                  ),
                  if (title.trim().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        _sanitizePdfText(title).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 7.2,
                          color: _headerText,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
            pw.Positioned(
              top: 15,
              right: 14,
              child: _photoTemplateAvatar(
                photoBytes: photoBytes,
                initials: initials,
                size: 56,
                borderColor: _avatarBorder,
                fillColor: PdfColors.white,
                textColor: _headerStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSidebarContent(
    List<CorporateNavyContactItem> contactItems,
    List<CorporateNavyEducationEntry> educationEntries,
    List<String> skillNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: _sidebarTopGap),
        if (contactItems.isNotEmpty) ...[
          _sidebarSectionHeader('CONTACT'),
          ...contactItems.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                _sanitizePdfText(item.label),
                style: const pw.TextStyle(
                  fontSize: 7.8,
                  color: _muted,
                  lineSpacing: 1.28,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        if (educationEntries.isNotEmpty) ...[
          _sidebarSectionHeader('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degree),
                    style: pw.TextStyle(
                      fontSize: 8.0,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(entry.institutionLine),
                      style: const pw.TextStyle(
                        fontSize: 7.4,
                        color: _muted,
                        lineSpacing: 1.2,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(entry.dateRange),
                      style: const pw.TextStyle(
                        fontSize: 7.3,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        if (skillNames.isNotEmpty) ...[
          _sidebarSectionHeader('SKILLS'),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4, right: 6),
                    child: pw.Container(
                      width: 4,
                      height: 4,
                      decoration: const pw.BoxDecoration(
                        color: _accent,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(skill),
                      style: const pw.TextStyle(
                        fontSize: 7.8,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 8.6,
              fontWeight: pw.FontWeight.bold,
              color: _headerStart,
              letterSpacing: 0.8,
            ),
          ),
          pw.Container(
            height: 1,
            color: _line,
            margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodySectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
              letterSpacing: 0.7,
            ),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4),
            height: 1,
            color: _line,
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyBullet(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, right: 6),
          child: pw.Container(
            width: 4,
            height: 4,
            decoration: const pw.BoxDecoration(
              color: _accent,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            style: const pw.TextStyle(
              fontSize: 8.2,
              color: _muted,
              lineSpacing: 1.34,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _experienceBlock(CorporateNavyExperienceEntry entry) {
    final dates = entry.dateRange.split(' - ');

    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 46,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(dates.first),
                  style: const pw.TextStyle(
                    fontSize: 7.6,
                    color: _muted,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(dates.length > 1 ? dates.last : dates.first),
                  style: const pw.TextStyle(
                    fontSize: 7.6,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Container(
            width: 1,
            height: 16 + (entry.detailLines.length * 14),
            color: PdfColor(
              _accent.red,
              _accent.green,
              _accent.blue,
              0.35,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (entry.metaLine.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(entry.metaLine),
                      style: pw.TextStyle(
                        fontSize: 7.8,
                        color: _accent,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 4),
                ...entry.detailLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _bodyBullet(line),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(CorporateNavyProjectEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.3,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 3),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _bodyBullet(line),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 1),
              child: pw.Text(
                _sanitizePdfText(link),
                style: const pw.TextStyle(
                  fontSize: 8.0,
                  color: _accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(CorporateNavyCertificationEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 9.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.0,
                  color: _muted,
                  lineSpacing: 1.24,
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
                style: const pw.TextStyle(
                  fontSize: 8.0,
                  color: _accent,
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
      padding: const pw.EdgeInsets.only(
        left: _sidebarWidth + _sidebarGap,
        right: 6,
      ),
      child: child,
    );
  }
}
