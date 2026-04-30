part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class MinimalCleanAtsResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.paperHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.sidebarHex);
  static const PdfColor _banner =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.bannerHex);
  static const PdfColor _bannerDark =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.bannerDarkHex);
  static const PdfColor _photoFill =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.photoFillHex);
  static const PdfColor _ink =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.mutedHex);
  static const PdfColor _line =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.lineHex);
  static const PdfColor _bannerText =
      PdfColor.fromInt(MinimalCleanAtsTemplateSupport.bannerTextHex);

  static const double _pageMargin = 24;
  static const double _pageTop = 24;
  static const double _pageBottom = 24;
  static const double _sidebarWidth = 144;
  static const double _contentGap = 18;
  static const double _topRowHeight = 74;
  static const double _headerSpacer = 100;
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

    final name = MinimalCleanAtsTemplateSupport.displayName(resume);
    final title = MinimalCleanAtsTemplateSupport.displayTitle(resume);
    final address = resume.personalInfo.address.trim();
    final contactItems = MinimalCleanAtsTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = MinimalCleanAtsTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final experienceEntries = MinimalCleanAtsTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );
    final educationEntries = MinimalCleanAtsTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final projectEntries = MinimalCleanAtsTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        MinimalCleanAtsTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = MinimalCleanAtsTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final skillNames = MinimalCleanAtsTemplateSupport.skillNames(
      resume.skills,
      maxItems: null,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    final summaryWidgets = <pw.Widget>[
      for (final entry in summaryLines.asMap().entries)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _numberedSummaryLine(entry.key, entry.value),
        ),
    ];

    final sections = <String, List<pw.Widget>>{};
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryWidgets,
        pw.SizedBox(height: 8),
      ];
    }
    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.expand(_experienceWidgets),
      ];
    }
    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...educationEntries.expand(_educationWidgets),
      ];
    }
    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.expand(_projectWidgets),
      ];
    }
    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...certificationEntries.expand(_certificationWidgets),
      ];
    }
    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...languageLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(fontSize: 8.2, color: _muted),
            ),
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
            child: _buildBackground(
              pageNumber: context.pageNumber,
              name: name,
              title: title,
              address: address,
              photoBytes: photoBytes,
              contactItems: contactItems,
              skillNames: skillNames,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox(height: _headerSpacer)
            : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground({
    required int pageNumber,
    required String name,
    required String title,
    required String address,
    required Uint8List? photoBytes,
    required List<MinimalCleanAtsContactItem> contactItems,
    required List<String> skillNames,
  }) {
    final sidebarTop =
        pageNumber == 1 ? _pageTop + _headerSpacer - 6 : _pageTop - 4;

    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin - 4,
          right: _pageMargin - 4,
          top: _pageTop - 4,
          bottom: _pageBottom - 4,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              color: _paper,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin - 4,
          top: sidebarTop,
          bottom: _pageBottom - 4,
          child: pw.Container(
            width: _sidebarWidth,
            decoration: const pw.BoxDecoration(
              color: _sidebar,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(12),
              ),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin + _sidebarWidth + (_contentGap / 2),
          top: sidebarTop,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1,
            child: pw.Container(color: _line),
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + 6,
            top: _pageTop + 2,
            child: _photoBlock(photoBytes),
          ),
          pw.Positioned(
            left: _pageMargin + 78,
            right: _pageMargin + 6,
            top: _pageTop + 2,
            child: _headerBanner(name, title, address),
          ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + _headerSpacer + 6,
            child: pw.SizedBox(
              width: _sidebarWidth - 18,
              child: _sidebarContent(contactItems, skillNames),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _photoBlock(Uint8List? photoBytes) {
    return pw.Container(
      width: 62,
      height: _topRowHeight,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: _sidebar,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Center(
        child: pw.Container(
          width: 42,
          height: 42,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: photoBytes == null ? _photoFill : null,
            border: pw.Border.all(color: _banner, width: 1),
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
                    width: 20,
                    height: 20,
                    child: pw.CustomPaint(
                      size: const PdfPoint(20, 20),
                      painter: (canvas, size) {
                        canvas.setFillColor(_banner);
                        canvas.drawEllipse(size.x / 2, 5.0, 3.0, 3.0);
                        canvas.fillPath();
                        canvas.drawEllipse(size.x / 2, 14.0, 7.0, 4.0);
                        canvas.fillPath();
                      },
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  pw.Widget _headerBanner(String name, String title, String address) {
    return pw.Container(
      height: _topRowHeight,
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_banner, _bannerDark],
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            _sanitizePdfText(name).toUpperCase(),
            style: pw.TextStyle(
              fontSize: 21,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (title.trim().isNotEmpty)
            pw.Text(
              _sanitizePdfText(title),
              style: const pw.TextStyle(
                fontSize: 10,
                color: _bannerText,
              ),
            ),
          if (address.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(address),
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _bannerText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _sidebarContent(
    List<MinimalCleanAtsContactItem> contactItems,
    List<String> skillNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sidebarHeader('CONTACT'),
        ...contactItems.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(item.label),
              style: const pw.TextStyle(
                fontSize: 7.7,
                color: _muted,
                lineSpacing: 1.15,
              ),
            ),
          ),
        ),
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _sidebarHeader('SKILLS'),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(skill),
                style: const pw.TextStyle(fontSize: 7.7, color: _muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9.0,
              color: _banner,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.9,
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

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10,
              color: _banner,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.9,
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

  pw.Widget _numberedSummaryLine(int index, String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 12,
          child: pw.Text(
            '${index + 1}.',
            style: pw.TextStyle(
              fontSize: 8.8,
              color: _banner,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
              lineSpacing: 1.28,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _detailBulletLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 4.2, right: 6),
          decoration: const pw.BoxDecoration(
            color: _banner,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 8.3,
              color: _muted,
              lineSpacing: 1.24,
            ),
          ),
        ),
      ],
    );
  }

  Iterable<pw.Widget> _experienceWidgets(
    MinimalCleanAtsExperienceEntry entry,
  ) sync* {
    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.3,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          textAlign: pw.TextAlign.right,
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      ],
    );
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
      child: pw.Text(
        _sanitizePdfText(entry.companyLine),
        style: pw.TextStyle(
          fontSize: 8.3,
          color: _bannerDark,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: _detailBulletLine(line),
      );
    }
    yield pw.SizedBox(height: 7);
  }

  Iterable<pw.Widget> _educationWidgets(
    MinimalCleanAtsEducationEntry entry,
  ) sync* {
    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitizePdfText(entry.degreeLine),
                style: pw.TextStyle(
                  fontSize: 9.0,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _sanitizePdfText(entry.institutionLine),
                style: const pw.TextStyle(fontSize: 8.0, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      ],
    );
    yield pw.SizedBox(height: 7);
  }

  Iterable<pw.Widget> _projectWidgets(
    MinimalCleanAtsProjectEntry entry,
  ) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.title),
      style: pw.TextStyle(
        fontSize: 9.0,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    if (entry.technologyLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
        child: pw.Text(
          _sanitizePdfText(entry.technologyLine),
          style: const pw.TextStyle(fontSize: 7.8, color: _bannerDark),
        ),
      );
    }
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: _detailBulletLine(line),
      );
    }
    for (final link in entry.links) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          _sanitizePdfText(link),
          style: pw.TextStyle(
            fontSize: 8.0,
            color: _banner,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _certificationWidgets(
    MinimalCleanAtsCertificationEntry entry,
  ) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.name),
      style: pw.TextStyle(
        fontSize: 8.9,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    if (entry.metaLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(entry.metaLine),
          style: const pw.TextStyle(
            fontSize: 7.8,
            color: _muted,
            lineSpacing: 1.2,
          ),
        ),
      );
    }
    for (final link in entry.links) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(link),
          style: pw.TextStyle(
            fontSize: 7.8,
            color: _banner,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }
}
