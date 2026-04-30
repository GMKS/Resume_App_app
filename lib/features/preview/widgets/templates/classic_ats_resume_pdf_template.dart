part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ClassicAtsResumePdfTemplate extends PdfTemplate {
  static const PdfColor _headerBg =
      PdfColor.fromInt(ClassicAtsTemplateSupport.headerHex);
  static const PdfColor _pageBg =
      PdfColor.fromInt(ClassicAtsTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ClassicAtsTemplateSupport.inkHex);
  static const PdfColor _body =
      PdfColor.fromInt(ClassicAtsTemplateSupport.bodyHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ClassicAtsTemplateSupport.mutedHex);
  static const PdfColor _dateBg =
      PdfColor.fromInt(ClassicAtsTemplateSupport.dateBgHex);
  static const double _bodyHorizontal = 42;
  static const double _dateLaneWidth = 112;
  static const List<String> _defaultOrder = [
    'summary',
    'experience',
    'skills',
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
    final sections = <String, List<pw.Widget>>{};

    final summaryLines = ClassicAtsTemplateSupport.summaryLines(resume.objective);
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _bodyPadding(_sectionHeader('PROFESSIONAL SUMMARY', accentColor)),
        _bodyPadding(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: summaryLines.map(_summaryLine).toList(growable: false),
          ),
          bottom: 12,
        ),
      ];
    }

    final experiences = ClassicAtsTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 8,
      yearOnly: true,
    );
    if (experiences.isNotEmpty) {
      sections['experience'] = [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.NewPage(
              freeSpace: 90 + (experiences.length * 24),
            ),
            _bodyPadding(
              _sectionHeader('WORK EXPERIENCE', accentColor),
              top: 2,
            ),
            ...experiences.map(
              (entry) => _bodyPadding(
                _experienceBlock(entry, accentColor),
                bottom: 10,
              ),
            ),
          ],
        ),
      ];
    }

    final skillNames = ClassicAtsTemplateSupport.skillNames(resume.skills);
    if (skillNames.isNotEmpty) {
      sections['skills'] = [
        _bodyPadding(
          _sectionHeader('SKILLS', accentColor),
          top: 2,
        ),
        _bodyPadding(
          pw.Wrap(
            spacing: 7,
            runSpacing: 7,
            children: skillNames
                .map((skill) => _skillChip(skill, accentColor))
                .toList(growable: false),
          ),
          bottom: 12,
        ),
      ];
    }

    final educations = ClassicAtsTemplateSupport.educationEntries(
      resume.education,
      maxSupportingLines: 2,
      yearOnly: true,
    );
    if (educations.isNotEmpty) {
      sections['education'] = [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.NewPage(
              freeSpace: 75 + (educations.length * 22),
            ),
            _bodyPadding(
              _sectionHeader('EDUCATION', accentColor),
              top: 2,
            ),
            ...educations.map(
              (entry) => _bodyPadding(
                _educationBlock(entry, accentColor),
                bottom: 10,
              ),
            ),
          ],
        ),
      ];
    }

    final projects = ClassicAtsTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 5,
      compactLinks: true,
    );
    if (projects.isNotEmpty) {
      sections['projects'] = [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.NewPage(
              freeSpace: 80 + (projects.length * 24),
            ),
            _bodyPadding(
              _sectionHeader('PROJECTS', accentColor),
              top: 2,
            ),
            ...projects.map(
              (entry) => _bodyPadding(
                _projectBlock(entry, accentColor),
                bottom: 10,
              ),
            ),
          ],
        ),
      ];
    }

    final certifications = ClassicAtsTemplateSupport.certificationLines(
      resume.certifications,
    );
    if (certifications.isNotEmpty) {
      sections['certifications'] = [
        _bodyPadding(
          _sectionHeader('CERTIFICATIONS', accentColor),
          top: 2,
        ),
        _bodyPadding(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: certifications
                .map(_simpleLine)
                .toList(growable: false),
          ),
          bottom: 12,
        ),
      ];
    }

    final languages = ClassicAtsTemplateSupport.languageLines(resume.languages);
    if (languages.isNotEmpty) {
      sections['languages'] = [
        _bodyPadding(
          _sectionHeader('LANGUAGES', accentColor),
          top: 2,
        ),
        _bodyPadding(
          pw.Wrap(
            spacing: 7,
            runSpacing: 7,
            children: languages.map(_languageChip).toList(growable: false),
          ),
          bottom: 12,
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase(), accentColor),
      sectionWrapper: (children) => _bodyPadding(
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
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 18),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim()).toUpperCase()
        : 'JOHN SMITH';
    final title = (resume.personalInfo.jobTitle ?? '').trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.jobTitle!.trim()).toUpperCase()
        : 'SOFTWARE ENGINEER';
    final contactText = ClassicAtsTemplateSupport.contactBarText(
      resume.personalInfo,
      compactLinks: true,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          width: double.infinity,
          color: _headerBg,
          padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  name,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  title,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Container(
          width: double.infinity,
          color: accentColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 8),
          child: pw.Text(
            _sanitizePdfText(
              contactText.isNotEmpty
                  ? contactText
                  : 'john.smith@email.com  |  (555) 123-4567  |  New York, NY',
            ),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 8.8,
              color: PdfColors.white,
              lineSpacing: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accentColor, 0.08),
        border: pw.Border(
          left: pw.BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
      ),
      child: pw.Text(
        _sanitizePdfText(title),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
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
          pw.Container(
            width: 5,
            height: 5,
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            decoration: const pw.BoxDecoration(
              color: _ink,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.3,
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

  pw.Widget _experienceBlock(
    ClassicAtsExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _sanitizePdfText(entry.companyLine),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                if (entry.detailLines.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ...entry.detailLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _body,
                          lineSpacing: 1.35,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: _dateLaneWidth,
            child: pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: _dateBg,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.4,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(
    ClassicAtsEducationEntry entry,
    PdfColor accentColor,
  ) {
    final institutionLine = [
      entry.institutionLine,
      entry.dateRange,
    ].where((part) => part.trim().isNotEmpty).join('  •  ');

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.degree),
            style: pw.TextStyle(
              fontSize: 10.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (institutionLine.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _sanitizePdfText(institutionLine),
              style: pw.TextStyle(
                fontSize: 9.2,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
          if (entry.supportingLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...entry.supportingLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _sanitizePdfText(line),
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _muted,
                    lineSpacing: 1.3,
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

  pw.Widget _projectBlock(
    ClassicAtsProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...entry.detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _sanitizePdfText(line),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: _body,
                    lineSpacing: 1.35,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),
          ],
          if (entry.url.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _sanitizePdfText(entry.url.trim()),
              style: pw.TextStyle(
                fontSize: 8.8,
                color: accentColor,
              ),
            ),
          ],
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
          fontSize: 9,
          color: _body,
          lineSpacing: 1.35,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  pw.Widget _skillChip(String skill, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accentColor, 0.05),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(
          color: _blendPdfWithWhite(accentColor, 0.32),
          width: 1,
        ),
      ),
      child: pw.Text(
        _sanitizePdfText(skill),
        style: pw.TextStyle(
          fontSize: 8.6,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _languageChip(String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        _sanitizePdfText(value),
        style: pw.TextStyle(
          fontSize: 8.5,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _bodyPadding(
    pw.Widget child, {
    double top = 0,
    double bottom = 0,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(_bodyHorizontal, top, _bodyHorizontal, bottom),
      child: child,
    );
  }
}