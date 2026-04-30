part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class CreativeProfessionalResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.paperHex);
  static const PdfColor _header =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.headerHex);
  static const PdfColor _headerText =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.headerTextHex);
  static const PdfColor _accent =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.accentHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.sidebarHex);
  static const PdfColor _line =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.mutedHex);
  static const PdfColor _sidebarText =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.sidebarTextHex);
  static const PdfColor _avatarFill =
      PdfColor.fromInt(CreativeProfessionalTemplateSupport.avatarFillHex);

  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 160;
  static const double _contentGap = 16;
  static const double _headerHeight = 78;
  static const double _avatarSize = 64;
  static const int _maxSidebarEducationItems = 2;

  static const List<String> _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'education',
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

    final name = CreativeProfessionalTemplateSupport.displayName(resume);
    final title = CreativeProfessionalTemplateSupport.displayTitle(resume);
    final address = CreativeProfessionalTemplateSupport.address(resume.personalInfo);
    final contactItems = CreativeProfessionalTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final educationEntries = CreativeProfessionalTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final skillNames = CreativeProfessionalTemplateSupport.skillNames(
      resume.skills,
    );
    final summaryLines = CreativeProfessionalTemplateSupport.summaryLines(
      resume.objective,
    );
    final experienceEntries =
        CreativeProfessionalTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      yearOnly: false,
    );
    final projectEntries = CreativeProfessionalTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 8,
      compactLinks: true,
    );
    final certificationEntries =
        CreativeProfessionalTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = CreativeProfessionalTemplateSupport.languageLines(
      resume.languages,
    );
    final photoBytes =
        (resume.personalInfo.profileImage?.isNotEmpty ?? false)
            ? base64Decode(resume.personalInfo.profileImage!)
            : null;

    final sidebarEducationEntries = educationEntries
        .take(_maxSidebarEducationItems)
        .toList(growable: false);
    final overflowEducationEntries = educationEntries
        .skip(sidebarEducationEntries.length)
        .toList(growable: false);
    final sidebarSkillNames = skillNames.toList(growable: false);
    final sidebarCertificationEntries =
      certificationEntries.toList(growable: false);
    final sidebarLanguageLines = languageLines.toList(growable: false);

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT'),
        ...summaryLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _diamondBulletLine(line),
          ),
        ),
        pw.SizedBox(height: 8),
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

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }

    if (overflowEducationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...overflowEducationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _educationBlock(entry),
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase()),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin + _sidebarWidth + _contentGap,
            _pageTop,
            _pageMargin,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _background(
              pageNumber: context.pageNumber,
              photoBytes: photoBytes,
              name: name,
              title: title,
              address: address,
              contactItems: contactItems,
              sidebarEducationEntries: sidebarEducationEntries,
              sidebarSkillNames: sidebarSkillNames,
              sidebarCertificationEntries: sidebarCertificationEntries,
              sidebarLanguageLines: sidebarLanguageLines,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox(height: _headerHeight + 10)
            : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _background({
    required int pageNumber,
    required Uint8List? photoBytes,
    required String name,
    required String title,
    required String address,
    required List<CreativeProfessionalContactItem> contactItems,
    required List<CreativeProfessionalEducationEntry> sidebarEducationEntries,
    required List<String> sidebarSkillNames,
    required List<CreativeProfessionalCertificationEntry>
        sidebarCertificationEntries,
    required List<String> sidebarLanguageLines,
  }) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin - 2,
          right: _pageMargin - 2,
          top: _pageTop - 2,
          bottom: _pageBottom - 2,
          child: pw.Container(color: _paper),
        ),
        pw.Positioned(
          left: _pageMargin - 2,
          right: _pageMargin - 2,
          top: _pageTop - 2,
          child: pw.Container(
            height: _headerHeight,
            color: pageNumber == 1 ? _header : _paper,
          ),
        ),
        pw.Positioned(
          left: _pageMargin - 2,
          top: _pageTop + (pageNumber == 1 ? _headerHeight - 2 : -2),
          bottom: _pageBottom - 2,
          child: pw.Container(
            width: _sidebarWidth,
            color: _sidebar,
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + 18,
            top: _pageTop + 6,
            child: _avatar(photoBytes),
          ),
          pw.Positioned(
            left: _pageMargin + 92,
            right: _pageMargin + 10,
            top: _pageTop + 12,
            child: _headerBlock(name, title, address),
          ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + _headerHeight + 8,
            child: pw.SizedBox(
              width: _sidebarWidth - 20,
              child: _sidebarContent(
                contactItems,
                sidebarEducationEntries,
                sidebarSkillNames,
                sidebarCertificationEntries,
                sidebarLanguageLines,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _avatar(Uint8List? photoBytes) {
    return pw.Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: photoBytes == null ? _avatarFill : null,
        border: pw.Border.all(color: PdfColors.white, width: 1.2),
        image: photoBytes != null
            ? pw.DecorationImage(
                image: pw.MemoryImage(photoBytes),
                fit: pw.BoxFit.cover,
              )
            : null,
      ),
      child: photoBytes == null
          ? pw.Center(
              child: pw.SizedBox(
                width: 24,
                height: 24,
                child: pw.CustomPaint(
                  size: const PdfPoint(24, 24),
                  painter: (canvas, size) {
                    canvas.setFillColor(_header);
                    canvas.drawEllipse(size.x / 2, 6, 4, 4);
                    canvas.fillPath();
                    canvas.drawEllipse(size.x / 2, 17, 8, 5);
                    canvas.fillPath();
                  },
                ),
              ),
            )
          : null,
    );
  }

  pw.Widget _headerBlock(String name, String title, String address) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(name).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(title),
              style: const pw.TextStyle(
                fontSize: 10,
                color: _headerText,
              ),
            ),
          ),
        if (address.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(address),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _headerText,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _sidebarContent(
    List<CreativeProfessionalContactItem> contactItems,
    List<CreativeProfessionalEducationEntry> educationEntries,
    List<String> skillNames,
    List<CreativeProfessionalCertificationEntry> certifications,
    List<String> languageLines,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (educationEntries.isNotEmpty) ...[
          _sidebarHeader('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degreeLine),
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 7.2,
                      color: _sidebarText,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.dateRange),
                    style: const pw.TextStyle(
                      fontSize: 7.2,
                      color: _sidebarText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (skillNames.isNotEmpty) ...[
          _sidebarHeader('SKILLS'),
          pw.Text(
            _sanitizePdfText(skillNames.join('  •  ')),
            style: const pw.TextStyle(
              fontSize: 7.3,
              color: _sidebarText,
              lineSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (contactItems.isNotEmpty) ...[
          _sidebarHeader('CONTACT'),
          ...contactItems.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(item.label),
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: _sidebarText,
                  lineSpacing: 1.15,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (languageLines.isNotEmpty) ...[
          _sidebarHeader('LANGUAGES'),
          ...languageLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 7.3,
                  color: _sidebarText,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (certifications.isNotEmpty) ...[
          _sidebarHeader('CERTIFICATIONS'),
          ...certifications.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.name),
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: _sidebarText,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  ...entry.detailLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 7.1,
                          color: _sidebarText,
                        ),
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

  pw.Widget _sidebarHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8.7,
          color: _header,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(height: 1, color: _line),
          ),
        ],
      ),
    );
  }

  pw.Widget _mainFrame(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(right: 2),
      child: child,
    );
  }

  pw.Widget _bodyText(
    String value, {
    double size = 8.3,
    PdfColor color = _muted,
  }) {
    return pw.Text(
      _sanitizePdfText(value),
      textAlign: pw.TextAlign.justify,
      style: pw.TextStyle(
        fontSize: size,
        color: color,
        lineSpacing: 1.22,
      ),
    );
  }

  pw.Widget _diamondBulletLine(String line) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, right: 6),
            child: pw.SizedBox(
              width: 6,
              height: 6,
              child: pw.CustomPaint(
                size: const PdfPoint(6, 6),
                painter: (canvas, size) {
                  canvas.setFillColor(_accent);
                  canvas.moveTo(size.x / 2, 0);
                  canvas.lineTo(size.x, size.y / 2);
                  canvas.lineTo(size.x / 2, size.y);
                  canvas.lineTo(0, size.y / 2);
                  canvas.closePath();
                  canvas.fillPath();
                },
              ),
            ),
          ),
          pw.Expanded(
            child: _bodyText(line),
          ),
        ],
      ),
    );
  }

  pw.Widget _detailBullet(String line) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4.1, right: 6),
            decoration: const pw.BoxDecoration(
              color: _header,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: _bodyText(line, size: 8.1),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(CreativeProfessionalExperienceEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                style: const pw.TextStyle(
                  fontSize: 7.8,
                  color: _accent,
                ),
              ),
            ],
          ),
          if (entry.companyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
              child: pw.Text(
                _sanitizePdfText(entry.companyLine),
                style: pw.TextStyle(
                  fontSize: 8.4,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _detailBullet(line),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(CreativeProfessionalProjectEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.1,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (entry.technologyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
              child: pw.Text(
                _sanitizePdfText(entry.technologyLine),
                style: const pw.TextStyle(
                  fontSize: 7.7,
                  color: _accent,
                ),
              ),
            ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _bodyText(line),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 7.9,
                  color: _header,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(CreativeProfessionalEducationEntry entry) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.degreeLine),
                  style: pw.TextStyle(
                    fontSize: 8.9,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(entry.institutionLine),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            _sanitizePdfText(entry.dateRange),
            style: const pw.TextStyle(
              fontSize: 7.6,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(CreativeProfessionalCertificationEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 8.7,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: _bodyText(line, size: 7.8),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 7.8,
                  color: _header,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}