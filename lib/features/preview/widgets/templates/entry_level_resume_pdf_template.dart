part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class EntryLevelResumePdfTemplate extends PdfTemplate {
  static const PdfColor _accent =
      PdfColor.fromInt(EntryLevelTemplateSupport.accentHex);
  static const PdfColor _pageBg =
      PdfColor.fromInt(EntryLevelTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(EntryLevelTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(EntryLevelTemplateSupport.mutedHex);
  static const PdfColor _subtle =
      PdfColor.fromInt(EntryLevelTemplateSupport.subtleHex);
  static const PdfColor _chipBg =
      PdfColor.fromInt(EntryLevelTemplateSupport.chipBgHex);
  static const PdfColor _chipBorder =
      PdfColor.fromInt(EntryLevelTemplateSupport.chipBorderHex);
  static const double _pageHorizontal = 34;
  static const double _pageTop = 28;
  static const double _pageBottom = 30;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'education',
    'skills',
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
    final sections = <String, List<pw.Widget>>{};

    final summaryLines = EntryLevelTemplateSupport.summaryLines(
      resume.objective,
    );
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('PROFILE'),
        ...summaryLines.map(_summaryLine),
        pw.SizedBox(height: 8),
      ];
    }

    final experienceEntries = EntryLevelTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      yearOnly: true,
    );
    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.map(_experienceBlock),
        pw.SizedBox(height: 4),
      ];
    }

    final educationEntries = EntryLevelTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...educationEntries.map(_educationBlock),
        pw.SizedBox(height: 4),
      ];
    }

    final skillNames = EntryLevelTemplateSupport.skillNames(resume.skills);
    if (skillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skillNames
              .map((skill) => _skillChip(_sanitizePdfText(skill)))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    final projectEntries = EntryLevelTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 6,
      compactLinks: true,
    );
    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.map(_projectBlock),
        pw.SizedBox(height: 4),
      ];
    }

    final certificationLines = EntryLevelTemplateSupport.certificationLines(
      resume.certifications,
    );
    if (certificationLines.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...certificationLines.map(_simpleLine),
        pw.SizedBox(height: 4),
      ];
    }

    final languageLines = EntryLevelTemplateSupport.languageLines(
      resume.languages,
    );
    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...languageLines.map(_simpleLine),
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
            _pageHorizontal,
            _pageTop,
            _pageHorizontal,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildHeader(resume),
          pw.SizedBox(height: 12),
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
    final contactItems = EntryLevelTemplateSupport.contactItems(
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
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                  letterSpacing: 1.3,
                ),
              ),
              if (title.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: _muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(width: double.infinity, height: 1.2, color: _accent),
        if (contactItems.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Wrap(
              spacing: 10,
              runSpacing: 3,
              alignment: pw.WrapAlignment.center,
              children: contactItems
                  .map(
                    (item) => pw.Text(
                      _sanitizePdfText(item.label),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: _isLinkKind(item.kind) ? 8.0 : 8.2,
                        color: _isLinkKind(item.kind) ? _subtle : _muted,
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

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _h(title),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 0.8,
        ),
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
            padding: const pw.EdgeInsets.only(top: 3, right: 5),
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
                fontSize: 9.2,
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

  pw.Widget _experienceBlock(EntryLevelExperienceEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.companyLine),
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _muted,
                  ),
                ),
              ),
              if (entry.dateRange.trim().isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 8.4,
                    color: _subtle,
                  ),
                ),
              ],
            ],
          ),
          if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 3),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _muted,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(EntryLevelEducationEntry entry) {
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
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              if (entry.dateRange.trim().isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 8.4,
                    color: _subtle,
                  ),
                ),
              ],
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: const pw.TextStyle(
              fontSize: 8.8,
              color: _muted,
            ),
          ),
          ...entry.supportingLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.4,
                  color: _subtle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _skillChip(String skill) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _chipBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _chipBorder, width: 0.8),
      ),
      child: pw.Text(
        skill,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _projectBlock(EntryLevelProjectEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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
          if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 3),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Text(
              _sanitizePdfText(entry.url),
              style: const pw.TextStyle(
                fontSize: 8.4,
                color: _accent,
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
          fontSize: 8.9,
          color: _muted,
          lineSpacing: 1.4,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  bool _isLinkKind(EntryLevelContactKind kind) {
    return kind == EntryLevelContactKind.linkedin ||
        kind == EntryLevelContactKind.github ||
        kind == EntryLevelContactKind.website;
  }
}