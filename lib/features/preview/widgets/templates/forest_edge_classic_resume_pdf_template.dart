part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ForestEdgeClassicResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.pageBgHex);
  static const PdfColor _paper =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.paperHex);
  static const PdfColor _card =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.cardHex);
  static const PdfColor _headerFill =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.headerHex);
  static const PdfColor _headerCard =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.headerCardHex);
  static const PdfColor _accent =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.accentHex);
  static const PdfColor _line =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.mutedHex);
  static const PdfColor _cream =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.creamHex);
  static const PdfColor _tag =
      PdfColor.fromInt(ForestEdgeClassicTemplateSupport.tagHex);

  static const List<String> _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'education',
    'skills',
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

    final name = ForestEdgeClassicTemplateSupport.displayName(resume);
    final title = ForestEdgeClassicTemplateSupport.displayTitle(resume);
    final contactItems = ForestEdgeClassicTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ForestEdgeClassicTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final educationEntries = ForestEdgeClassicTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final experienceEntries =
        ForestEdgeClassicTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: true,
    );
    final skillNames = ForestEdgeClassicTemplateSupport.skillNames(
      resume.skills,
      maxItems: null,
    );
    final projectEntries = ForestEdgeClassicTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        ForestEdgeClassicTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = ForestEdgeClassicTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );

    final headerContacts = List<ForestEdgeClassicContactItem>.unmodifiable(
      contactItems,
    );

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionGroup(
          'PROFILE',
          _baseCard(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: summaryLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: _profileBullet(line),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _experienceSectionWidgets(experienceEntries);
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionGroup(
          'PROJECTS',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: projectEntries
                .map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: _projectCard(entry),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionGroup(
          'EDUCATION',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: educationEntries
                .map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: _educationRow(entry),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (skillNames.isNotEmpty ||
        languageLines.isNotEmpty ||
        certificationEntries.isNotEmpty) {
      sections['skills'] = [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (skillNames.isNotEmpty)
              pw.Expanded(
                flex: 11,
                child: _sectionGroup(
                  'SKILLS',
                  _baseCard(
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skillNames
                          .map(
                            (skill) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const pw.BoxDecoration(
                                color: _tag,
                                borderRadius: pw.BorderRadius.all(
                                  pw.Radius.circular(10),
                                ),
                              ),
                              child: pw.Text(
                                _sanitizePdfText(skill),
                                style: const pw.TextStyle(
                                  fontSize: 7.2,
                                  color: _ink,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            if (skillNames.isNotEmpty &&
                (languageLines.isNotEmpty || certificationEntries.isNotEmpty))
              pw.SizedBox(width: 12),
            if (languageLines.isNotEmpty || certificationEntries.isNotEmpty)
              pw.Expanded(
                flex: 10,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (languageLines.isNotEmpty)
                      _sectionGroup(
                        'LANGUAGES',
                        _baseCard(_languageColumn(languageLines)),
                      ),
                    if (languageLines.isNotEmpty &&
                        certificationEntries.isNotEmpty)
                      pw.SizedBox(height: 10),
                    if (certificationEntries.isNotEmpty)
                      _sectionGroup(
                        'CERTIFICATIONS',
                        _baseCard(
                          _certificationColumn(certificationEntries),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _ribbon(title.toUpperCase()),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: _pageBg,
              padding: const pw.EdgeInsets.all(18),
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  color: _paper,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
                ),
              ),
            ),
          ),
        ),
        build: (context) => [
          _header(name, title, headerContacts),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _header(
    String name,
    String title,
    List<ForestEdgeClassicContactItem> contactItems,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const pw.BoxDecoration(
        color: _headerFill,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(24)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6,
            height: 62,
            decoration: const pw.BoxDecoration(
              color: _accent,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(name).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    _sanitizePdfText(title),
                    style: const pw.TextStyle(
                      fontSize: 8.8,
                      color: _cream,
                    ),
                  ),
                ),
                pw.Container(
                  width: 110,
                  height: 1,
                  color: _accent,
                  margin: const pw.EdgeInsets.only(top: 8),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 160,
            padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 7),
            decoration: const pw.BoxDecoration(
              color: _headerCard,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: contactItems.isEmpty
                  ? [
                      pw.Text(
                        'Add contact details',
                        style: const pw.TextStyle(
                          fontSize: 7.2,
                          color: PdfColors.white,
                        ),
                      ),
                    ]
                  : contactItems
                      .map(
                        (item) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: _headerContactLine(item.label),
                        ),
                      )
                      .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerContactLine(String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 5,
          height: 11,
          decoration: const pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(value),
            style: const pw.TextStyle(
              fontSize: 7.1,
              color: PdfColors.white,
              lineSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionGroup(String title, pw.Widget child) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _ribbon(title),
        pw.SizedBox(height: 6),
        child,
      ],
    );
  }

  List<pw.Widget> _experienceSectionWidgets(
    List<ForestEdgeClassicExperienceEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const <pw.Widget>[];
    }

    final widgets = <pw.Widget>[
      pw.NewPage(freeSpace: _experienceLeadFreeSpace(entries.first)),
      _ribbon('EXPERIENCE'),
      pw.SizedBox(height: 6),
    ];

    for (var index = 0; index < entries.length; index++) {
      if (index > 0) {
        widgets.add(pw.SizedBox(height: 8));
      }
      widgets.add(_experienceRow(entries[index]));
    }

    widgets.add(pw.SizedBox(height: 10));
    return widgets;
  }

  double _experienceLeadFreeSpace(ForestEdgeClassicExperienceEntry entry) {
    final locationAllowance = entry.location.isNotEmpty ? 10.0 : 0.0;
    final detailAllowance = entry.detailLines.length * 14.0;
    return 88.0 + locationAllowance + detailAllowance;
  }

  pw.Widget _ribbon(String title) {
    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.only(
              topRight: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 8.2,
              color: _paper,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            height: 0.8,
            color: _line,
          ),
        ),
      ],
    );
  }

  pw.Widget _baseCard(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(color: _line, width: 1.2),
      ),
      child: child,
    );
  }

  pw.Widget _experienceRow(ForestEdgeClassicExperienceEntry entry) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _yearPill(entry.dateRange, dark: true),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _baseCard(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    _sanitizePdfText(entry.company),
                    style: pw.TextStyle(
                      fontSize: 8.6,
                      color: _accent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (entry.location.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(entry.location),
                      style: const pw.TextStyle(
                        fontSize: 7.6,
                        color: _muted,
                      ),
                    ),
                  ),
                ...entry.detailLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: _goldBarBullet(line),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _projectCard(ForestEdgeClassicProjectEntry entry) {
    return _baseCard(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10.4,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: _goldBarBullet(line),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 7.8,
                  color: _headerFill,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationRow(ForestEdgeClassicEducationEntry entry) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _yearPill(entry.dateRange, dark: false),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _baseCard(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.institution),
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: _bodyText(
                    entry.degreeLine,
                    fontSize: 8.1,
                    color: _muted,
                    align: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _languageColumn(List<String> languageLines) {
    final children = <pw.Widget>[];

    for (final line in languageLines) {
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
            _sanitizePdfText(line),
            style: const pw.TextStyle(
              fontSize: 7.8,
              color: _muted,
            ),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _certificationColumn(
    List<ForestEdgeClassicCertificationEntry> certificationEntries,
  ) {
    final children = <pw.Widget>[];

    for (final entry in certificationEntries) {
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _goldBarBullet(entry.name, singleLine: true),
        ),
      );
    }

    if (children.isEmpty) {
      children.add(
        pw.Text(
          'Add details',
          style: const pw.TextStyle(
            fontSize: 7.8,
            color: _muted,
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _profileBullet(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 10,
          height: 10,
          child: pw.CustomPaint(
            size: const PdfPoint(10, 10),
            painter: (canvas, size) {
              canvas
                ..setStrokeColor(_accent)
                ..setLineWidth(1.3)
                // PDF canvas coordinates are vertically inverted relative to
                // Flutter screen painting, so the check path must be flipped
                // to keep the tick leaning in the correct direction.
                ..moveTo(1.4, 4.8)
                ..lineTo(3.7, 2.6)
                ..lineTo(8.2, 8.2)
                ..strokePath();
            },
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: _bodyText(
            line,
            fontSize: 8.1,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _yearPill(String range, {required bool dark}) {
    final parts = range.split('-');
    final start = parts.isNotEmpty ? parts.first : range;
    final end = parts.length > 1 ? parts.sublist(1).join('-') : '';

    return pw.Container(
      width: 56,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: pw.BoxDecoration(
        color: dark ? _headerFill : _cream,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            _sanitizePdfText(start),
            style: pw.TextStyle(
              fontSize: 7.8,
              color: dark ? PdfColors.white : _ink,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Container(
            width: 26,
            height: 0.8,
            color: dark ? _cream : _accent,
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
          ),
          pw.Text(
            _sanitizePdfText(end),
            style: pw.TextStyle(
              fontSize: 7.6,
              color: dark ? PdfColors.white : _ink,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _goldBarBullet(String line, {bool singleLine = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 8,
          height: 1.2,
          margin: const pw.EdgeInsets.only(top: 5),
          color: _accent,
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: _bodyText(
            line,
            fontSize: 7.9,
            color: _muted,
            align: singleLine ? pw.TextAlign.left : pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _bodyText(
    String value, {
    double fontSize = 8,
    PdfColor color = _ink,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Text(
      _sanitizePdfText(value),
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        lineSpacing: 1.18,
      ),
      textAlign: align,
    );
  }
}
