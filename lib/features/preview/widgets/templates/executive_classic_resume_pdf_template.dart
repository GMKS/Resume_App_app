part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ExecutiveClassicResumePdfTemplate extends PdfTemplate {
  static const PdfColor _headerBg =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.headerBgHex);
  static const PdfColor _headerStripe =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.headerStripeHex);
  static const PdfColor _pageBg =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.mutedHex);
  static const PdfColor _subtle =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.subtleHex);
  static const PdfColor _line =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.lineHex);
  static const PdfColor _chipBg =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.chipBgHex);
  static const PdfColor _chipBorder =
      PdfColor.fromInt(ExecutiveClassicTemplateSupport.chipBorderHex);
  static const double _pageHorizontal = 44;
  static const double _headerHorizontal = 44;
  static const double _rightMetaWidth = 120;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'education',
    'skills',
    'certifications',
    'languages',
    'projects',
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
    final sections = <String, List<pw.Widget>>{};

    final summaryLines = ExecutiveClassicTemplateSupport.summaryLines(
      resume.objective,
    );
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionPadding(_sectionHeader('SUMMARY', accentColor), bottom: 6),
        _sectionPadding(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: summaryLines
                .map((line) => _summaryLine(line, accentColor))
                .toList(growable: false),
          ),
          bottom: 8,
        ),
      ];
    }

    final experienceEntries = ExecutiveClassicTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      monthResolution: true,
    );
    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionPadding(
          _sectionHeader('WORK EXPERIENCE', accentColor),
          top: 2,
          bottom: 6,
        ),
        ...experienceEntries.map(
          (entry) => _sectionPadding(
            _experienceBlock(entry, accentColor),
            bottom: 10,
          ),
        ),
      ];
    }

    final educationEntries = ExecutiveClassicTemplateSupport.educationEntries(
      resume.education,
      maxSupportingLines: 3,
      monthResolution: false,
    );
    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionPadding(
          _sectionHeader('EDUCATION', accentColor),
          top: 2,
          bottom: 6,
        ),
        ...educationEntries.map(
          (entry) => _sectionPadding(
            _educationBlock(entry, accentColor),
            bottom: 9,
          ),
        ),
      ];
    }

    final skillNames = ExecutiveClassicTemplateSupport.skillNames(resume.skills);
    if (skillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionPadding(
          _sectionHeader('CORE COMPETENCIES', accentColor),
          top: 2,
          bottom: 6,
        ),
        _sectionPadding(
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skillNames
                .map((skill) => _skillChip(_sanitizePdfText(skill)))
                .toList(growable: false),
          ),
          bottom: 8,
        ),
      ];
    }

    final certificationLines = ExecutiveClassicTemplateSupport.certificationLines(
      resume.certifications,
    );
    if (certificationLines.isNotEmpty) {
      sections['certifications'] = [
        _sectionPadding(
          _sectionHeader('CERTIFICATIONS', accentColor),
          top: 2,
          bottom: 6,
        ),
        _sectionPadding(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: certificationLines
                .map(_simpleLine)
                .toList(growable: false),
          ),
          bottom: 8,
        ),
      ];
    }

    final languageLines = ExecutiveClassicTemplateSupport.languageLines(
      resume.languages,
    );
    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionPadding(
          _sectionHeader('LANGUAGES', accentColor),
          top: 2,
          bottom: 6,
        ),
        _sectionPadding(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children:
                languageLines.map(_simpleLine).toList(growable: false),
          ),
          bottom: 8,
        ),
      ];
    }

    final projectEntries = ExecutiveClassicTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 8,
      compactLinks: true,
    );
    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionPadding(
          _sectionHeader('PROJECTS', accentColor),
          top: 2,
          bottom: 6,
        ),
        ...projectEntries.map(
          (entry) => _sectionPadding(
            _projectBlock(entry, accentColor),
            bottom: 10,
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase(), accentColor),
      sectionWrapper: (children) => _sectionPadding(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
        bottom: 8,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildHeader(resume),
          pw.Container(height: 3, color: _darkenAccent(accentColor)),
          pw.SizedBox(height: 14),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim()).toUpperCase()
        : 'JOHN SMITH';
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final contactItems = ExecutiveClassicTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
    );

    return pw.Container(
      width: double.infinity,
      color: _headerBg,
      padding: const pw.EdgeInsets.fromLTRB(
        _headerHorizontal,
        32,
        _headerHorizontal,
        22,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 2.0,
            ),
          ),
          if (title.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                title.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor(1, 1, 1, 0.72),
                  letterSpacing: 2.5,
                ),
              ),
            ),
          if (contactItems.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 0,
              runSpacing: 4,
              children: _contactWidgets(contactItems),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Container(height: 4, color: _headerStripe),
        ],
      ),
    );
  }

  List<pw.Widget> _contactWidgets(
    List<ExecutiveClassicContactItem> items,
  ) {
    final widgets = <pw.Widget>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (index > 0) {
        widgets.add(_contactDot());
      }
      widgets.add(
        pw.Text(
          _sanitizePdfText(item.label),
          style: const pw.TextStyle(
            fontSize: 8.6,
            color: PdfColor(1, 1, 1, 0.78),
          ),
        ),
      );
    }
    return widgets;
  }

  pw.Widget _contactDot() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
        child: pw.Container(
          width: 4,
          height: 4,
          decoration: const pw.BoxDecoration(
            color: PdfColor(1, 1, 1, 0.5),
            shape: pw.BoxShape.circle,
          ),
        ),
      );

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 4,
            height: 18,
            color: accentColor,
            margin: const pw.EdgeInsets.only(right: 10),
          ),
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(height: 0.8, color: _line)),
        ],
      ),
    );
  }

  pw.Widget _summaryLine(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.5, right: 6),
            child: pw.CustomPaint(
              size: const PdfPoint(9, 9),
              painter: (canvas, size) {
                canvas.setStrokeColor(accentColor);
                canvas.setLineWidth(1.4);
                // PDF canvas coordinates are vertically inverted relative to
                // Flutter screen painting, so the check path must be flipped
                // to keep the tick leaning in the correct direction.
                canvas.moveTo(1.3, 4.4);
                canvas.lineTo(3.4, 2.1);
                canvas.lineTo(7.8, 7.3);
                canvas.strokePath();
              },
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.4,
                color: _muted,
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
    ExecutiveClassicExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _fullWidthText(
                  entry.title,
                  style: pw.TextStyle(
                    fontSize: 11.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _rightMetaWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.6,
                    color: _subtle,
                  ),
                ),
              ),
            ],
          ),
          if (entry.metaLine.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                entry.metaLine,
                style: pw.TextStyle(
                  fontSize: 9.8,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: _fullWidthText(
                line,
                style: const pw.TextStyle(
                  fontSize: 9.1,
                  color: _muted,
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

  pw.Widget _educationBlock(
    ExecutiveClassicEducationEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _fullWidthText(
                  entry.degree,
                  style: pw.TextStyle(
                    fontSize: 11.2,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _rightMetaWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.6,
                    color: _subtle,
                  ),
                ),
              ),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _fullWidthText(
              entry.institutionLine,
              style: pw.TextStyle(
                fontSize: 9.8,
                color: accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          ...entry.supportingLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: _fullWidthText(
                line,
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _muted,
                  lineSpacing: 1.4,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _skillChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _chipBg,
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(color: _chipBorder, width: 0.8),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 8.8,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _simpleLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(
          fontSize: 9.0,
          color: _muted,
          lineSpacing: 1.4,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  pw.Widget _projectBlock(
    ExecutiveClassicProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _fullWidthText(
            entry.title,
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: _fullWidthText(
                line,
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _muted,
                  lineSpacing: 1.42,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: _fullWidthText(
                entry.url,
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

  pw.Widget _fullWidthText(
    String text, {
    required pw.TextStyle style,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        _sanitizePdfText(text),
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  pw.Widget _sectionPadding(
    pw.Widget child, {
    double top = 0,
    double bottom = 0,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(_pageHorizontal, top, _pageHorizontal, bottom),
      child: child,
    );
  }

  PdfColor _darkenAccent(PdfColor color) {
    return PdfColor(
      color.red * 0.75,
      color.green * 0.75,
      color.blue * 0.75,
      1,
    );
  }

}