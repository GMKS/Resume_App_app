part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class FlexColorSidebarPdfTemplate extends PdfTemplate {
  static const PdfColor _pageTint =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.pageHex);
  static const PdfColor _panel =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.panelHex);
  static const PdfColor _line =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.mutedHex);
  static const PdfColor _cardFill =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.cardFillHex);
  static const PdfColor _chipFill =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.chipFillHex);
  static const PdfColor _chipFillAlt =
      PdfColor.fromInt(FlexColorSidebarTemplateSupport.chipFillAltHex);

  static const double _pageOuter = 28;
  static const double _sheetTop = 52;
  static const double _sheetBottom = 32;
  static const double _sheetRadius = 18;
  static const double _railWidth = 32;
  static const double _sidebarWidth = 118;
  static const double _innerPadding = 18;
  static const double _columnGap = 18;
  static const double _mastheadTop = 28;
  static const double _mastheadInsetLeft = 58;
  static const double _mastheadInsetRight = 26;
  static const double _sidebarTop = 92;
  static const double _contentTop = 132;
  static const double _contentRight = 38;
  static const double _contentBottom = 54;

  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'skills',
    'projects',
    'certifications',
    'education',
    'references',
  ];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    await initPdfSettings(resume);
    final pdf = _buildDocument();
    final photoBytes =
        FlexColorSidebarTemplateSupport.photoBytes(resume.personalInfo);
    final initials = FlexColorSidebarTemplateSupport.initials(
      FlexColorSidebarTemplateSupport.displayName(resume),
    );
    final softAccent = _blendPdfWithWhite(accentColor, 0.12);
    final accentBorder = _scalePdfColor(accentColor, 1.0, 0.28);
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: _defaultOrder,
      allowedKeys: _defaultOrder,
    );
    final sections = _buildSections(
      resume,
      accentColor,
      softAccent,
      accentBorder,
    );

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionTag(
        title.toUpperCase(),
        accentColor,
        softAccent,
        accentBorder,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(
          resume,
          photoBytes,
          initials,
          accentColor,
          softAccent,
          accentBorder,
        ),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.PageTheme _buildPageTheme(
    ResumeModel resume,
    Uint8List? photoBytes,
    String initials,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(
        _pageOuter + _railWidth + _innerPadding + _sidebarWidth + _columnGap,
        _contentTop,
        _contentRight,
        _contentBottom,
      ),
      buildBackground: (context) => _buildBackground(
        context,
        resume,
        photoBytes,
        initials,
        accentColor,
        softAccent,
        accentBorder,
      ),
    );
  }

  pw.Widget _buildBackground(
    pw.Context context,
    ResumeModel resume,
    Uint8List? photoBytes,
    String initials,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    final pageWidth = PdfPageFormat.a4.width;
    final sheetWidth = pageWidth - (_pageOuter * 2);

    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Container(
            width: double.infinity,
            height: double.infinity,
            color: _pageTint,
          ),
          pw.Positioned(
            left: _pageOuter,
            right: _pageOuter,
            top: _sheetTop,
            bottom: _sheetBottom,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: _panel,
                borderRadius: pw.BorderRadius.circular(_sheetRadius),
                border: pw.Border.all(color: _line, width: 0.9),
              ),
            ),
          ),
          pw.Positioned(
            left: _pageOuter,
            top: _sheetTop,
            bottom: _sheetBottom,
            child: pw.Container(
              width: _railWidth,
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(_sheetRadius),
                  bottomLeft: pw.Radius.circular(_sheetRadius),
                ),
              ),
            ),
          ),
          if (context.pageNumber == 1)
            pw.Positioned(
              left: _pageOuter + _mastheadInsetLeft,
              top: _mastheadTop,
              child: pw.SizedBox(
                width: sheetWidth - _mastheadInsetLeft - _mastheadInsetRight,
                child: _buildMasthead(
                  resume,
                  accentColor,
                  softAccent,
                  accentBorder,
                ),
              ),
            ),
          if (context.pageNumber == 1)
            pw.Positioned(
              left: _pageOuter + _railWidth + _innerPadding,
              top: _sidebarTop,
              child: pw.SizedBox(
                width: _sidebarWidth,
                child: _buildSidebarPane(
                  resume,
                  photoBytes,
                  initials,
                  accentColor,
                  softAccent,
                  accentBorder,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<pw.Widget>> _buildSections(
    ResumeModel resume,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    final sections = <String, List<pw.Widget>>{};
    final hasSummary = (resume.objective ?? '').trim().isNotEmpty;
    final summaryLines = hasSummary
        ? FlexColorSidebarTemplateSupport.summaryLines(resume.objective)
        : const <String>[];

    sections['summary'] = [
      _sectionTag('PROFILE', accentColor, softAccent, accentBorder),
      pw.SizedBox(height: 7),
      if (summaryLines.isEmpty)
        _buildProfileLine(
          'Add a professional summary to highlight your strongest outcomes and domain focus.',
          accentColor,
        )
      else
        ...summaryLines.map(
          (line) => _buildProfileLine(line, accentColor),
        ),
      pw.SizedBox(height: 12),
    ];

    sections['experience'] = [
      _sectionTag('EXPERIENCE', accentColor, softAccent, accentBorder),
      pw.SizedBox(height: 7),
      if (resume.experience.isEmpty)
        _buildExperiencePlaceholder(accentColor)
      else
        ...FlexColorSidebarTemplateSupport.experienceEntries(
          resume.experience,
          yearOnly: true,
        ).map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _buildExperienceCard(entry, accentColor),
          ),
        ),
      pw.SizedBox(height: 10),
    ];

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionTag('SKILL GRID', accentColor, softAccent, accentBorder),
        pw.SizedBox(height: 7),
        _buildSkillGrid(
          FlexColorSidebarTemplateSupport.skillNames(resume.skills),
          softAccent,
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionTag('PROJECTS', accentColor, softAccent, accentBorder),
        pw.SizedBox(height: 7),
        ...FlexColorSidebarTemplateSupport.projectEntries(
          resume.projects,
          compactLinks: true,
        ).map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _buildProjectItem(entry, accentColor),
          ),
        ),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionTag('CERTIFICATIONS', accentColor, softAccent, accentBorder),
        pw.SizedBox(height: 7),
        ...FlexColorSidebarTemplateSupport.certificationEntries(
          resume.certifications,
          compactLinks: true,
        ).map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: _buildCertificationItem(entry, accentColor),
          ),
        ),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionTag('EDUCATION', accentColor, softAccent, accentBorder),
        pw.SizedBox(height: 7),
        ...FlexColorSidebarTemplateSupport.educationEntries(
          resume.education,
          yearOnly: true,
        ).map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _buildEducationItem(entry, accentColor),
          ),
        ),
      ];
    }

    if (resume.references.isNotEmpty) {
      sections['references'] = [
        _sectionTag('REFERENCES', accentColor, softAccent, accentBorder),
        pw.SizedBox(height: 7),
        ...FlexColorSidebarTemplateSupport.referenceEntries(
          resume.references,
        ).map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: _buildReferenceItem(entry, accentColor),
          ),
        ),
      ];
    }

    return sections;
  }

  pw.Widget _buildSidebarPane(
    ResumeModel resume,
    Uint8List? photoBytes,
    String initials,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    final hasContact = _hasAnyContact(resume.personalInfo);
    final contactLines = hasContact
        ? FlexColorSidebarTemplateSupport.contactLines(
            resume.personalInfo,
            maxItems: 6,
          )
        : const <String>[];
    final languageLines = resume.languages.isNotEmpty
        ? FlexColorSidebarTemplateSupport.languageLines(
            resume.languages,
            maxItems: 4,
          )
        : const <String>[];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildIdentityTile(
          photoBytes,
          initials,
          accentColor,
          softAccent,
          accentBorder,
        ),
        pw.SizedBox(height: 10),
        _sidebarCard(
          'CONTACT',
          hasContact
              ? contactLines.map(_sidebarText).toList(growable: false)
              : [_sidebarText('Add contact details')],
          accentColor,
          softAccent,
        ),
        if (languageLines.isNotEmpty)
          _sidebarCard(
            'LANG',
            languageLines.map(_sidebarText).toList(growable: false),
            accentColor,
            softAccent,
          ),
      ],
    );
  }

  bool _hasAnyContact(PersonalInfo info) {
    return info.email.trim().isNotEmpty ||
        info.phone.trim().isNotEmpty ||
        info.address.trim().isNotEmpty ||
        (info.linkedIn ?? '').trim().isNotEmpty ||
        (info.github ?? '').trim().isNotEmpty ||
        (info.website ?? '').trim().isNotEmpty;
  }

  pw.Widget _buildIdentityTile(
    Uint8List? photoBytes,
    String initials,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    return pw.Container(
      height: 104,
      decoration: pw.BoxDecoration(
        color: softAccent,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: accentBorder, width: 0.8),
      ),
      child: photoBytes == null
          ? pw.Center(
              child: pw.Text(
                initials.isEmpty ? 'JS' : initials,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
            )
          : pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Image(
                pw.MemoryImage(photoBytes),
                fit: pw.BoxFit.cover,
              ),
            ),
    );
  }

  pw.Widget _sidebarCard(
    String title,
    List<pw.Widget> children,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(9, 9, 9, 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line, width: 0.85),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: softAccent,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              _h(title),
              style: pw.TextStyle(
                fontSize: 7.4,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.9,
              ),
            ),
          ),
          pw.SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _sidebarText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(
          fontSize: 7.9,
          color: _ink,
          lineSpacing: 1.35,
        ),
      ),
    );
  }

  pw.Widget _buildMasthead(
    ResumeModel resume,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    final name = _sanitizePdfText(
      FlexColorSidebarTemplateSupport.displayName(resume).toUpperCase(),
    );
    final title = _sanitizePdfText(
      FlexColorSidebarTemplateSupport.displayTitle(resume),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                    letterSpacing: 0.9,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTag(
    String title,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor accentBorder,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: pw.BoxDecoration(
            color: softAccent,
            borderRadius: pw.BorderRadius.circular(7),
            border: pw.Border.all(color: accentBorder, width: 0.8),
          ),
          child: pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 7.8,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.9,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            height: 1,
            color: _line,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProfileLine(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 0.2, right: 6),
            child: pw.Text(
              '>',
              style: pw.TextStyle(
                fontSize: 9.4,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          pw.Expanded(
            child: _fullWidthText(
              line,
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _muted,
                lineSpacing: 1.4,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExperiencePlaceholder(PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: pw.BoxDecoration(
        color: _cardFill,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line, width: 0.85),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            height: 3,
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
          ),
          pw.Text(
            'Add experience to populate the modular role cards.',
            style: const pw.TextStyle(
              fontSize: 8.2,
              color: _muted,
              lineSpacing: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExperienceCard(
    FlexColorSidebarExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: pw.BoxDecoration(
        color: _cardFill,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line, width: 0.85),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            height: 3,
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(entry.title),
                      style: pw.TextStyle(
                        fontSize: 9.8,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _sanitizePdfText(entry.companyLine),
                      style: pw.TextStyle(
                        fontSize: 8.4,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.dateRange.trim().isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 7.9,
                    color: _muted,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ],
          ),
          if (entry.locationLine.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.locationLine),
                style: const pw.TextStyle(
                  fontSize: 7.8,
                  color: _muted,
                ),
              ),
            ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            ...entry.detailLines.map(
              (detail) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: _fullWidthText(
                  _sanitizePdfText(detail),
                  style: const pw.TextStyle(
                    fontSize: 8.0,
                    color: _muted,
                    lineSpacing: 1.35,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSkillGrid(List<String> skills, PdfColor softAccent) {
    final fills = <PdfColor>[softAccent, _chipFill, _chipFillAlt];
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: skills.asMap().entries.map((entry) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: fills[entry.key % fills.length],
            borderRadius: pw.BorderRadius.circular(7),
            border: pw.Border.all(color: _line, width: 0.75),
          ),
          child: pw.Text(
            _sanitizePdfText(entry.value),
            style: const pw.TextStyle(
              fontSize: 7.7,
              color: _ink,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  pw.Widget _buildProjectItem(
    FlexColorSidebarProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 9.1,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        if (entry.detailLines.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.detailLines.map((detail) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: _fullWidthText(
                    _sanitizePdfText(detail),
                    style: const pw.TextStyle(
                      fontSize: 8.2,
                      color: _muted,
                      lineSpacing: 1.35,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        if (entry.links.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.links.map((link) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1),
                  child: pw.Text(
                    _sanitizePdfText(link),
                    style: pw.TextStyle(
                      fontSize: 7.9,
                      color: accentColor,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildCertificationItem(
    FlexColorSidebarCertificationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Column(
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
        if (entry.metaLine.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(entry.metaLine),
              style: const pw.TextStyle(
                fontSize: 7.9,
                color: _muted,
              ),
            ),
          ),
        if (entry.links.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.links.map((link) {
                return pw.Text(
                  _sanitizePdfText(link),
                  style: pw.TextStyle(
                    fontSize: 7.8,
                    color: accentColor,
                    decoration: pw.TextDecoration.underline,
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildEducationItem(
    FlexColorSidebarEducationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.degreeLine),
          style: pw.TextStyle(
            fontSize: 9.1,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: const pw.TextStyle(
              fontSize: 8.1,
              color: _muted,
            ),
          ),
        ),
        if (entry.metaLine.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(entry.metaLine),
              style: pw.TextStyle(
                fontSize: 7.8,
                color: accentColor,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildReferenceItem(
    FlexColorSidebarReferenceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.name),
          style: pw.TextStyle(
            fontSize: 8.8,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        if (entry.metaLine.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(entry.metaLine),
              style: pw.TextStyle(
                fontSize: 7.9,
                color: accentColor,
              ),
            ),
          ),
        if (entry.contactLines.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.contactLines.map((line) {
                return pw.Text(
                  _sanitizePdfText(line),
                  style: const pw.TextStyle(
                    fontSize: 7.8,
                    color: _muted,
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _fullWidthText(
    String text, {
    required pw.TextStyle style,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
