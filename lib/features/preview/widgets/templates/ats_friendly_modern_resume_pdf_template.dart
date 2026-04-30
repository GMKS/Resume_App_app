part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class AtsFriendlyModernResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.inkHex);
  static const PdfColor _body =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.bodyHex);
  static const PdfColor _muted =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.mutedHex);
  static const PdfColor _divider =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.dividerHex);
  static const PdfColor _tag =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.tagHex);
  static const PdfColor _rule =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.ruleHex);
  static const PdfColor _accent =
      PdfColor.fromInt(AtsFriendlyModernTemplateSupport.accentHex);

  static const double _pageLeft = 38;
  static const double _pageTop = 34;
  static const double _pageRight = 38;
  static const double _pageBottom = 34;
  static const double _contentRightPadding = 4;
  static const double _dateLaneWidth = 92;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: AtsFriendlyModernTemplateSupport.defaultSectionOrder,
      allowedKeys: AtsFriendlyModernTemplateSupport.defaultSectionOrder,
    );

    final summaryLines = AtsFriendlyModernTemplateSupport.summaryLines(
      resume.objective,
    );
    final skillNames = AtsFriendlyModernTemplateSupport.skillNames(
      resume.skills,
    );
    final experienceEntries =
        AtsFriendlyModernTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 4,
    );
    final educationEntries = AtsFriendlyModernTemplateSupport.educationEntries(
      resume.education,
    );
    final projectEntries = AtsFriendlyModernTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
    );
    final certificationLines =
        AtsFriendlyModernTemplateSupport.certificationLines(
      resume.certifications,
    );
    final languageLabels = AtsFriendlyModernTemplateSupport.languageLabels(
      resume.languages,
    );

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = _sectionWidgets(
        'SUMMARY',
        summaryLines.map(_summaryLine).toList(growable: false),
      );
    }

    if (skillNames.isNotEmpty) {
      sections['skills'] = _sectionWidgets(
        'SKILLS',
        [
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: skillNames
                .map(
                  (skill) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: _accent,
                      borderRadius: pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      _sanitizePdfText(skill),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      );
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _sectionWidgets(
        'EXPERIENCE',
        experienceEntries.map(_experienceBlock).toList(growable: false),
      );
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = _sectionWidgets(
        'EDUCATION',
        educationEntries.map(_educationBlock).toList(growable: false),
      );
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = _sectionWidgets(
        'PROJECTS',
        projectEntries.map(_projectBlock).toList(growable: false),
      );
    }

    if (certificationLines.isNotEmpty) {
      sections['certifications'] = _sectionWidgets(
        'CERTIFICATIONS',
        certificationLines.map(_simpleLine).toList(growable: false),
      );
    }

    if (languageLabels.isNotEmpty) {
      sections['languages'] = _sectionWidgets(
        'LANGUAGES',
        [
          pw.Text(
            _sanitizePdfText(languageLabels.join(', ')),
            style: const pw.TextStyle(
              fontSize: 9.2,
              color: _body,
            ),
          ),
        ],
        trailingSpace: false,
      );
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
            _pageLeft,
            _pageTop,
            _pageRight,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
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

  List<pw.Widget> _sectionWidgets(
    String title,
    List<pw.Widget> children, {
    bool trailingSpace = true,
  }) {
    return [
      _bodyWrap(_sectionHeader(title)),
      ...children.map(_bodyWrap),
      if (trailingSpace) pw.SizedBox(height: 8),
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
        : 'YOUR NAME';
    final title = (resume.personalInfo.jobTitle ?? '').trim();
    final primaryContacts =
        AtsFriendlyModernTemplateSupport.primaryContactItems(
      resume.personalInfo,
    );
    final secondaryContacts =
        AtsFriendlyModernTemplateSupport.secondaryContactItems(
      resume.personalInfo,
      compactLinks: true,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.7, width: double.infinity, color: _divider),
        pw.SizedBox(height: 5),
        if (title.isNotEmpty)
          pw.Text(
            _sanitizePdfText(title),
            style: const pw.TextStyle(
              fontSize: 10.8,
              color: _body,
            ),
          ),
        if (primaryContacts.isNotEmpty)
          pw.Text(
            _sanitizePdfText(primaryContacts.join('  •  ')),
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
            ),
          ),
        if (secondaryContacts.isNotEmpty)
          pw.Text(
            _sanitizePdfText(secondaryContacts.join('  •  ')),
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
            ),
          ),
      ],
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: _tag,
            child: pw.Text(
              _h(title),
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 2.4,
              color: _rule,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 6),
            child: pw.CustomPaint(
              size: const PdfPoint(6, 6),
              painter: (canvas, size) {
                final centerX = size.x / 2;
                final centerY = size.y / 2;
                canvas.setFillColor(_accent);
                canvas.moveTo(centerX, 0);
                canvas.lineTo(size.x, centerY);
                canvas.lineTo(centerX, size.y);
                canvas.lineTo(0, centerY);
                canvas.closePath();
                canvas.fillPath();
              },
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.1,
                color: _body,
                lineSpacing: 1.35,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(AtsFriendlyModernExperienceEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
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
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(
                width: _dateLaneWidth,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 8.7,
                    color: _muted,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.companyLine),
            style: const pw.TextStyle(
              fontSize: 8.9,
              color: _accent,
            ),
          ),
          ...entry.detailLines.map(_detailLine),
        ],
      ),
    );
  }

  pw.Widget _detailLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '- ',
            style: const pw.TextStyle(
              fontSize: 8.9,
              color: _body,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 8.9,
                color: _body,
                lineSpacing: 1.3,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(AtsFriendlyModernEducationEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
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
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(
                width: _dateLaneWidth,
                child: pw.Text(
                  _sanitizePdfText(entry.yearLabel),
                  style: const pw.TextStyle(
                    fontSize: 8.7,
                    color: _muted,
                  ),
                  textAlign: pw.TextAlign.right,
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
        ],
      ),
    );
  }

  pw.Widget _projectBlock(AtsFriendlyModernProjectEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10,
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
                  fontSize: 8.9,
                  color: _body,
                  lineSpacing: 1.3,
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
                  fontSize: 8.4,
                  color: _accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _simpleLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(
          fontSize: 8.9,
          color: _body,
          lineSpacing: 1.25,
        ),
      ),
    );
  }
}
