part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class BluewaveTechResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(BluewaveTechTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(BluewaveTechTemplateSupport.paperHex);
  static const PdfColor _headerStart =
      PdfColor.fromInt(BluewaveTechTemplateSupport.headerStartHex);
  static const PdfColor _headerEnd =
      PdfColor.fromInt(BluewaveTechTemplateSupport.headerEndHex);
  static const PdfColor _headerText =
      PdfColor.fromInt(BluewaveTechTemplateSupport.headerTextHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(BluewaveTechTemplateSupport.sidebarHex);
  static const PdfColor _line =
      PdfColor.fromInt(BluewaveTechTemplateSupport.lineHex);
  static const PdfColor _accent =
      PdfColor.fromInt(BluewaveTechTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(BluewaveTechTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(BluewaveTechTemplateSupport.mutedHex);
  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 170;
  static const double _contentGap = 16;
  static const double _headerHeight = 82;
  static const double _avatarSize = 70;
  static const int _maxSidebarEducationItems = 2;
  static const int _maxSidebarSkillItems = 10;

  static const List<String> _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'education',
    'skills',
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

    final name = BluewaveTechTemplateSupport.displayName(resume);
    final title = BluewaveTechTemplateSupport.displayTitle(resume);
    final contactItems = BluewaveTechTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = BluewaveTechTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final skillNames = BluewaveTechTemplateSupport.skillNames(resume.skills);
    final summaryLines = BluewaveTechTemplateSupport.summaryLines(
      resume.objective,
    );
    final experienceEntries = BluewaveTechTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      yearOnly: false,
    );
    final projectEntries = BluewaveTechTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 8,
      compactLinks: true,
    );
    final certificationEntries =
        BluewaveTechTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = BluewaveTechTemplateSupport.languageLines(
      resume.languages,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    final sidebarEducationEntries = educationEntries
        .take(_maxSidebarEducationItems)
        .toList(growable: false);
    final overflowEducationEntries = educationEntries
        .skip(sidebarEducationEntries.length)
        .toList(growable: false);
    final sidebarSkillNames =
        skillNames.take(_maxSidebarSkillItems).toList(growable: false);
    final overflowSkillNames =
        skillNames.skip(sidebarSkillNames.length).toList(growable: false);
    final sidebarCertificationEntries = certificationEntries.toList(growable: false);
    final sidebarLanguageLines = languageLines.toList(growable: false);

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: _contentCardDecoration(),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: summaryLines
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _triangleBulletLine(line, fontSize: 8),
                  ),
                )
                .toList(growable: false),
          ),
        ),
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

    if (overflowSkillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: _contentCardDecoration(),
          child: _bodyText(
            overflowSkillNames.join('  |  '),
            fontSize: 8,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
        pw.SizedBox(height: 10),
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
              initials: initials.isEmpty ? 'BW' : initials,
              name: name,
              title: title,
              contactItems: contactItems,
              sidebarEducationEntries: sidebarEducationEntries,
              sidebarSkillNames: sidebarSkillNames,
              sidebarCertificationEntries: sidebarCertificationEntries,
              sidebarLanguageLines: sidebarLanguageLines,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox(height: _headerHeight + 12)
            : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _background({
    required int pageNumber,
    required Uint8List? photoBytes,
    required String initials,
    required String name,
    required String title,
    required List<BluewaveTechContactItem> contactItems,
    required List<BluewaveTechEducationEntry> sidebarEducationEntries,
    required List<String> sidebarSkillNames,
    required List<BluewaveTechCertificationEntry> sidebarCertificationEntries,
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
        if (pageNumber == 1)
          pw.Positioned(
            left: _pageMargin - 2,
            right: _pageMargin - 2,
            top: _pageTop - 2,
            child: pw.Container(
              height: _headerHeight,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                  colors: [_headerStart, _headerEnd],
                ),
              ),
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
            right: _pageMargin + 14,
            top: _pageTop + 8,
            child: _avatar(photoBytes, initials),
          ),
          pw.Positioned(
            left: _pageMargin + 18,
            right: _pageMargin + _avatarSize + 30,
            top: _pageTop + 14,
            child: _headerBlock(name, title),
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

  pw.BoxDecoration _contentCardDecoration() {
    return pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _line, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );
  }

  pw.Widget _avatar(Uint8List? photoBytes, String initials) {
    return pw.Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: photoBytes == null ? PdfColors.white : null,
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
              child: pw.Text(
                initials,
                style: pw.TextStyle(
                  fontSize: 20,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  pw.Widget _headerBlock(String name, String title) {
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
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              _sanitizePdfText(title).toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 10,
                color: _headerText,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _sidebarContent(
    List<BluewaveTechContactItem> contactItems,
    List<BluewaveTechEducationEntry> educationEntries,
    List<String> skillNames,
    List<BluewaveTechCertificationEntry> certifications,
    List<String> languageLines,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (educationEntries.isNotEmpty) ...[
          _sidebarCard(
            'EDUCATION',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: educationEntries
                  .map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(entry.institutionLine),
                            style: pw.TextStyle(
                              fontSize: 7.8,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            _sanitizePdfText(entry.degreeLine),
                            style: const pw.TextStyle(
                              fontSize: 7.1,
                              color: _muted,
                            ),
                          ),
                          pw.Text(
                            _sanitizePdfText(entry.dateRange),
                            style: const pw.TextStyle(
                              fontSize: 7.1,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        _sidebarCard(
          'CONTACT',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: contactItems
                .map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      _sanitizePdfText(item.label),
                      style: const pw.TextStyle(
                        fontSize: 7.3,
                        color: _muted,
                        lineSpacing: 1.15,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _sidebarCard(
            'SKILLS',
            pw.Text(
              _sanitizePdfText(skillNames.join('  |  ')),
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(
                fontSize: 7.2,
                color: _muted,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ],
        if (certifications.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _sidebarCard(
            'CERTIFICATIONS',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: certifications
                  .map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(entry.name),
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          ...entry.detailLines.map(
                            (line) => pw.Text(
                              _sanitizePdfText(line),
                              style: const pw.TextStyle(
                                fontSize: 6.9,
                                color: _muted,
                              ),
                            ),
                          ),
                          ...entry.links.map(
                            (link) => pw.Text(
                              _sanitizePdfText(link),
                              style: const pw.TextStyle(
                                fontSize: 6.9,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        if (languageLines.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _sidebarCard(
            'LANGUAGES',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: languageLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 7.2,
                          color: _muted,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarCard(String title, pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: _contentCardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8.6,
              color: _accent,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          pw.Container(
            height: 1,
            color: _line,
            margin: const pw.EdgeInsets.only(top: 3, bottom: 5),
          ),
          child,
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              color: _accent,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
          pw.Container(
            height: 1,
            color: _line,
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyText(
    String value, {
    double fontSize = 8.2,
    PdfColor color = _muted,
    pw.TextAlign align = pw.TextAlign.left,
    pw.FontWeight? weight,
  }) {
    return pw.Text(
      _sanitizePdfText(value),
      textAlign: align,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        lineSpacing: 1.25,
      ),
    );
  }

  pw.Widget _triangleBulletLine(String value, {double fontSize = 7.6}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2.1, right: 5),
          child: _triangleBulletMarker(),
        ),
        pw.Expanded(
          child: _bodyText(
            value,
            fontSize: fontSize,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _triangleBulletMarker() {
    const width = 5.6;
    const height = 6.6;
    return pw.SizedBox(
      width: width,
      height: height,
      child: pw.CustomPaint(
        size: const PdfPoint(width, height),
        painter: (canvas, size) {
          canvas.setFillColor(_accent);
          canvas.moveTo(0.4, 0.4);
          canvas.lineTo(size.x - 0.4, size.y / 2);
          canvas.lineTo(0.4, size.y - 0.4);
          canvas.closePath();
          canvas.fillPath();
        },
      ),
    );
  }

  pw.Widget _experienceBlock(BluewaveTechExperienceEntry entry) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: _contentCardDecoration(),
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
                    fontSize: 9.5,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                style: const pw.TextStyle(
                  fontSize: 7.2,
                  color: _muted,
                ),
              ),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.companyLine),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _accent,
              ),
            ),
          ),
          if (entry.detailLines.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: entry.detailLines
                    .map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: _triangleBulletLine(line),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(BluewaveTechProjectEntry entry) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: _contentCardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.3,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (entry.technologyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.technologyLine),
                style: const pw.TextStyle(
                  fontSize: 7.2,
                  color: _accent,
                ),
              ),
            ),
          if (entry.detailLines.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: entry.detailLines
                    .map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: _bodyText(
                          line,
                          fontSize: 8,
                          color: _muted,
                          align: pw.TextAlign.justify,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          if (entry.links.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: entry.links
                    .map(
                      (link) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          _sanitizePdfText(link),
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: _accent,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(BluewaveTechEducationEntry entry) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: _contentCardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: pw.TextStyle(
              fontSize: 9,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.degreeLine),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _muted,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.dateRange),
              style: const pw.TextStyle(
                fontSize: 7.3,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
