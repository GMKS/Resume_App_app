part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class MinimalCleanResumePdfTemplate extends PdfTemplate {
  static const PdfColor _bg =
      PdfColor.fromInt(MinimalCleanTemplateSupport.backgroundHex);
  static const PdfColor _card =
      PdfColor.fromInt(MinimalCleanTemplateSupport.cardHex);
  static const PdfColor _blue =
      PdfColor.fromInt(MinimalCleanTemplateSupport.blueHex);
  static const PdfColor _blueDark =
      PdfColor.fromInt(MinimalCleanTemplateSupport.blueDarkHex);
  static const PdfColor _ink =
      PdfColor.fromInt(MinimalCleanTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(MinimalCleanTemplateSupport.mutedHex);
  static const PdfColor _sand =
      PdfColor.fromInt(MinimalCleanTemplateSupport.sandHex);
  static const PdfColor _divider =
      PdfColor.fromInt(MinimalCleanTemplateSupport.dividerHex);

  static const double _pageMargin = 30;
  static const double _pageTop = 24;
  static const double _pageBottom = 24;
  static const double _sidebarWidth = 126;
  static const double _contentGap = 18;
  static const double _photoSize = 58;
  static const double _headerSpacer = 112;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
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

    final name = MinimalCleanTemplateSupport.displayName(resume);
    final title = MinimalCleanTemplateSupport.displayTitle(resume);
    final address = resume.personalInfo.address.trim();
    final contactItems = MinimalCleanTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final summaryLines = MinimalCleanTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final experienceEntries = MinimalCleanTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );
    final projectEntries = MinimalCleanTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final skillNames = MinimalCleanTemplateSupport.skillNames(
      resume.skills,
      maxItems: null,
    );
    final educationEntries = MinimalCleanTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final certificationEntries =
        MinimalCleanTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = MinimalCleanTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _arrowBulletLine(line),
          ),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.expand(_experienceWidgets),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.expand(_projectWidgets),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: languageLines.map(_languageChip).toList(growable: false),
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
              educationEntries: educationEntries,
              certificationEntries: certificationEntries,
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

  pw.Widget _background({
    required int pageNumber,
    required Uint8List? photoBytes,
    required String name,
    required String title,
    required String address,
    required List<MinimalCleanContactItem> contactItems,
    required List<MinimalCleanEducationEntry> educationEntries,
    required List<MinimalCleanCertificationEntry> certificationEntries,
    required List<String> skillNames,
  }) {
    return pw.Stack(
      children: [
        pw.Container(color: _bg),
        pw.Positioned(
          left: _pageMargin - 4,
          right: _pageMargin - 4,
          top: _pageTop - 4,
          bottom: _pageBottom - 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: _card,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
              border: pw.Border.all(color: PdfColors.white, width: 1.2),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin + _sidebarWidth + (_contentGap / 2),
          top: pageNumber == 1 ? _pageTop + _headerSpacer - 10 : _pageTop,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1,
            child: pw.Container(color: _divider),
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + 8,
            top: _pageTop + 6,
            child: _photoFrame(photoBytes, name),
          ),
          pw.Positioned(
            left: _pageMargin + 82,
            right: _pageMargin + 12,
            top: _pageTop + 6,
            child: _headerBlock(name, title, address),
          ),
          if (contactItems.isNotEmpty)
            pw.Positioned(
              left: _pageMargin + 10,
              right: _pageMargin + 10,
              top: _pageTop + 66,
              child: _contactStrip(contactItems),
            ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + _headerSpacer - 6,
            child: pw.SizedBox(
              width: _sidebarWidth - 12,
              child: _sidebar(
                educationEntries: educationEntries,
                certificationEntries: certificationEntries,
                skillNames: skillNames,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _photoFrame(Uint8List? photoBytes, String name) {
    return pw.Container(
      width: _photoSize,
      height: _photoSize,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: photoBytes == null ? _sand : null,
        border: pw.Border.all(color: PdfColors.white, width: 2),
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
                _initials(name),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _blueDark,
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
            fontSize: 22,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Text(
            _sanitizePdfText(title),
            style: const pw.TextStyle(
              fontSize: 10,
              color: _muted,
            ),
          ),
        if (address.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(address),
              style: const pw.TextStyle(
                fontSize: 8.1,
                color: _muted,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _contactStrip(List<MinimalCleanContactItem> contactItems) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const pw.BoxDecoration(
        color: _blue,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 3,
        children: contactItems
            .map(
              (item) => pw.Text(
                _sanitizePdfText(item.label),
                style: const pw.TextStyle(
                  fontSize: 7.4,
                  color: PdfColors.white,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _sidebar({
    required List<MinimalCleanEducationEntry> educationEntries,
    required List<MinimalCleanCertificationEntry> certificationEntries,
    required List<String> skillNames,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (educationEntries.isNotEmpty) ...[
          _sidebarSectionHeader('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degreeLine),
                    style: pw.TextStyle(
                      fontSize: 8.1,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 7.6,
                      color: _muted,
                      lineSpacing: 1.15,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.dateRange),
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (certificationEntries.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _sidebarSectionHeader('CERTIFICATIONS'),
          ...certificationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.name),
                    style: pw.TextStyle(
                      fontSize: 7.9,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (entry.metaLine.isNotEmpty)
                    pw.Text(
                      _sanitizePdfText(entry.metaLine),
                      style: const pw.TextStyle(
                        fontSize: 7.3,
                        color: _muted,
                        lineSpacing: 1.15,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _sidebarSectionHeader('SKILLS'),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(skill),
                style: const pw.TextStyle(fontSize: 7.8, color: _muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.0,
          color: _blueDark,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: _blueDark,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.9,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(height: 1, color: _divider),
          ),
        ],
      ),
    );
  }

  pw.Widget _arrowBulletLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1.8),
          child: pw.SizedBox(
            width: 10,
            height: 8,
            child: pw.CustomPaint(
              size: const PdfPoint(10, 8),
              painter: (canvas, size) {
                final midY = size.y / 2;
                canvas.setFillColor(_blueDark);
                canvas.setStrokeColor(_blueDark);
                canvas.setLineWidth(1.2);
                canvas.moveTo(0.5, midY);
                canvas.lineTo(5.4, midY);
                canvas.strokePath();
                canvas.moveTo(5.1, 0.8);
                canvas.lineTo(9.0, midY);
                canvas.lineTo(5.1, size.y - 0.8);
                canvas.closePath();
                canvas.fillPath();
              },
            ),
          ),
        ),
        pw.SizedBox(width: 4),
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
            color: _blueDark,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 8.4,
              color: _muted,
              lineSpacing: 1.24,
            ),
          ),
        ),
      ],
    );
  }

  Iterable<pw.Widget> _experienceWidgets(
    MinimalCleanExperienceEntry entry,
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
      padding: const pw.EdgeInsets.only(top: 1.5, bottom: 3),
      child: pw.Text(
        _sanitizePdfText(entry.companyLine),
        style: pw.TextStyle(
          fontSize: 8.3,
          color: _blueDark,
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

  Iterable<pw.Widget> _projectWidgets(MinimalCleanProjectEntry entry) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.title),
      style: pw.TextStyle(
        fontSize: 9.1,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    if (entry.technologyLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
        child: pw.Text(
          _sanitizePdfText(entry.technologyLine),
          style: const pw.TextStyle(fontSize: 7.8, color: _blueDark),
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
            fontSize: 8,
            color: _blueDark,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  pw.Widget _languageChip(String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: _sand,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(
          fontSize: 7.9,
          color: _blueDark,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .toList(growable: false);
    return parts.isEmpty ? 'MC' : parts.join();
  }
}
