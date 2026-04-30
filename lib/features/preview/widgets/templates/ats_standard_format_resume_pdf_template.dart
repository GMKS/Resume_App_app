part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class AtsStandardFormatTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(AtsStandardFormatTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(AtsStandardFormatTemplateSupport.inkHex);
  static const PdfColor _body =
      PdfColor.fromInt(AtsStandardFormatTemplateSupport.bodyHex);
  static const PdfColor _muted =
      PdfColor.fromInt(AtsStandardFormatTemplateSupport.mutedHex);
  static const PdfColor _guide =
      PdfColor.fromInt(AtsStandardFormatTemplateSupport.guideHex);
  static const double _pageLeft = 42;
  static const double _pageTop = 30;
  static const double _pageRight = 34;
  static const double _pageBottom = 30;
  static const double _contentRightPadding = 10;
  static const double _dateLaneWidth = 86;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: AtsStandardFormatTemplateSupport.defaultSectionOrder,
      allowedKeys: AtsStandardFormatTemplateSupport.defaultSectionOrder,
    );

    final summaryLines = AtsStandardFormatTemplateSupport.summaryLines(
      resume.objective,
    );
    final educationEntries = AtsStandardFormatTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final experienceEntries =
        AtsStandardFormatTemplateSupport.experienceEntries(
      resume.experience,
      yearOnly: true,
    );
    final skillNames = AtsStandardFormatTemplateSupport.skillNames(
      resume.skills,
    );
    final linkItems = AtsStandardFormatTemplateSupport.linkItems(
      resume.personalInfo,
      compactLinks: false,
    );
    final projectEntries = AtsStandardFormatTemplateSupport.projectEntries(
      resume.projects,
      compactLinks: false,
    );
    final certificationEntries =
        AtsStandardFormatTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: false,
    );
    final languageLines = AtsStandardFormatTemplateSupport.languageLines(
      resume.languages,
    );

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = _sectionWidgets(
        'ABOUT ME',
        accentColor,
        summaryLines.map(_bulletLine).toList(growable: false),
      );
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = _sectionWidgets(
        'EDUCATION',
        accentColor,
        educationEntries.map(_educationBlock).toList(growable: false),
      );
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _sectionWidgets(
        'WORK EXPERIENCE',
        accentColor,
        experienceEntries
            .map(
              (entry) => _experienceBlock(entry, accentColor),
            )
            .toList(growable: false),
      );
    }

    if (skillNames.isNotEmpty) {
      sections['skills'] = _sectionWidgets(
        'SKILLS',
        accentColor,
        [
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: skillNames
                .map(
                  (skill) => pw.Text(
                    '- ${_sanitizePdfText(skill)}',
                    style: const pw.TextStyle(
                      fontSize: 8.8,
                      color: _body,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      );
    }

    if (linkItems.isNotEmpty) {
      sections['links'] = _sectionWidgets(
        'LINKS',
        accentColor,
        linkItems.map(_linkLine).toList(growable: false),
      );
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = _sectionWidgets(
        'PROJECTS',
        accentColor,
        projectEntries
            .map(
              (entry) => _projectBlock(entry, accentColor),
            )
            .toList(growable: false),
      );
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = _sectionWidgets(
        'CERTIFICATIONS',
        accentColor,
        certificationEntries
            .map(
              (entry) => _certificationBlock(entry, accentColor),
            )
            .toList(growable: false),
      );
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = _sectionWidgets(
        'LANGUAGES',
        accentColor,
        languageLines.map(_simpleLine).toList(growable: false),
        trailingSpace: false,
      );
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
            _pageLeft,
            _pageTop,
            _pageRight,
            _pageBottom,
          ),
          buildBackground: (context) => _buildBackground(),
        ),
        build: (context) => [
          _bodyWrap(_buildHeader(resume)),
          pw.SizedBox(height: 8),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Container(color: _pageBg),
          pw.Positioned(
            top: _pageTop - 4,
            bottom: _pageBottom - 4,
            right: _pageRight,
            child: pw.SizedBox(
              width: 1.1,
              child: pw.Container(color: _guide),
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _sectionWidgets(
    String title,
    PdfColor accentColor,
    List<pw.Widget> children, {
    bool trailingSpace = true,
  }) {
    return [
      _bodyWrap(_sectionHeader(title, accentColor)),
      ...children.map(_bodyWrap),
      if (trailingSpace) pw.SizedBox(height: 6),
    ];
  }

  pw.Widget _bodyWrap(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: _contentRightPadding),
      child: pw.Container(
        width: double.infinity,
        child: child,
      ),
    );
  }

  pw.Widget _buildHeader(ResumeModel resume) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim()).toUpperCase()
        : 'JOHN SMITH';
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final contactItems = AtsStandardFormatTemplateSupport.contactItems(
      resume.personalInfo,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 23,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  letterSpacing: 1.2,
                ),
              ),
              if (title.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 10.4,
                      color: _muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (contactItems.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Wrap(
              alignment: pw.WrapAlignment.center,
              spacing: 14,
              runSpacing: 4,
              children: contactItems
                  .map(
                    (item) => pw.Text(
                      _sanitizePdfText(item.label),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8.8,
                        color: _muted,
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

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: double.infinity, height: 1.7, color: accentColor),
        pw.SizedBox(height: 5),
        pw.Text(
          _h(title),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
            letterSpacing: 0.9,
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _bulletLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, right: 5),
            child: pw.Text(
              '-',
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _body,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9,
                color: _body,
                lineSpacing: 1.4,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(AtsStandardEducationEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: _dateLaneWidth,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.4,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: const pw.TextStyle(
              fontSize: 8.9,
              color: _body,
            ),
          ),
          ...entry.supportingLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _muted,
                  lineSpacing: 1.3,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(
    AtsStandardExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
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
              pw.SizedBox(
                width: _dateLaneWidth,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.4,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.companyLine),
            style: pw.TextStyle(
              fontSize: 9,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _body,
                  lineSpacing: 1.42,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _linkLine(AtsStandardLinkItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        '${_linkLabel(item.kind)}: ${_sanitizePdfText(item.label)}',
        style: const pw.TextStyle(
          fontSize: 8.9,
          color: _body,
        ),
      ),
    );
  }

  pw.Widget _projectBlock(
    AtsStandardProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
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
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _body,
                  lineSpacing: 1.38,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.url),
                style: pw.TextStyle(
                  fontSize: 8.6,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(
    AtsStandardCertificationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 9.6,
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
                  fontSize: 8.7,
                  color: _body,
                  lineSpacing: 1.34,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.url),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _simpleLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(
          fontSize: 8.8,
          color: _body,
        ),
      ),
    );
  }

  String _linkLabel(AtsStandardLinkKind kind) {
    switch (kind) {
      case AtsStandardLinkKind.linkedin:
        return 'LinkedIn';
      case AtsStandardLinkKind.github:
        return 'GitHub';
      case AtsStandardLinkKind.website:
        return 'Website';
    }
  }
}
