part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ForestEdgeResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(ForestEdgeTemplateSupport.pageBgHex);
  static const PdfColor _paper =
      PdfColor.fromInt(ForestEdgeTemplateSupport.paperHex);
  static const PdfColor _card =
      PdfColor.fromInt(ForestEdgeTemplateSupport.cardHex);
  static const PdfColor _headerTint =
      PdfColor.fromInt(ForestEdgeTemplateSupport.headerTintHex);
  static const PdfColor _headerAccent =
      PdfColor.fromInt(ForestEdgeTemplateSupport.headerAccentHex);
  static const PdfColor _line =
      PdfColor.fromInt(ForestEdgeTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ForestEdgeTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ForestEdgeTemplateSupport.mutedHex);
  static const PdfColor _soft =
      PdfColor.fromInt(ForestEdgeTemplateSupport.softHex);

  static const double _shellMargin = 18;
  static const double _contentInsetX = 16;
  static const double _contentInsetTop = 14;
  static const double _contentInsetBottom = 16;
  static const double _contactCardWidth = 176;

  static const List<String> _defaultOrder = <String>[
    'summary',
    'education',
    'experience',
    'projects',
    'certifications',
    'skills',
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

    final name = ForestEdgeTemplateSupport.displayName(resume);
    final title = ForestEdgeTemplateSupport.displayTitle(resume);
    final contactItems = ForestEdgeTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ForestEdgeTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final educationEntries = ForestEdgeTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final experienceEntries = ForestEdgeTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: true,
    );
    final skillNames = ForestEdgeTemplateSupport.skillNames(
      resume.skills,
      maxItems: null,
    );
    final languageLines = ForestEdgeTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final projectEntries = ForestEdgeTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries = ForestEdgeTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionCard(
          title: 'ABOUT ME',
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: summaryLines
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _chevronBulletLine(line),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = _groupedSectionCards(
        'EDUCATION',
        educationEntries
            .map(
              (entry) => _educationBlock(entry),
            )
            .toList(growable: false),
      );
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _groupedSectionCards(
        'WORK EXPERIENCE',
        experienceEntries
            .map(
              (entry) => _experienceBlock(entry),
            )
            .toList(growable: false),
      );
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = _groupedSectionCards(
        'PROJECTS',
        projectEntries
            .map(
              (entry) => _projectBlock(entry),
            )
            .toList(growable: false),
      );
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = _groupedSectionCards(
        'CERTIFICATIONS',
        certificationEntries
            .map(
              (entry) => _certificationBlock(entry),
            )
            .toList(growable: false),
      );
    }

    if (skillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionCard(
          title: 'SKILLS',
          child: pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skillNames
                .map(
                  (skill) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: _headerTint,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Text(
                      _sanitizePdfText(skill),
                      style: const pw.TextStyle(
                        fontSize: 6.9,
                        color: _muted,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionCard(
          title: 'LANGUAGES',
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: languageLines
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _bodyText(
                      line,
                      fontSize: 6.9,
                      color: _muted,
                      align: pw.TextAlign.justify,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ];
    }

    for (final section in orderedUserCustomSections(resume)) {
      if (section.items.isEmpty) {
        sections[section.id] = [
          _sectionCard(
            title: normalizeUserCustomSectionTitle(section.title).isEmpty
                ? 'CUSTOM SECTION'
                : normalizeUserCustomSectionTitle(section.title).toUpperCase(),
            child: pw.Text(
              'No content added yet.',
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ),
          pw.SizedBox(height: 10),
        ];
        continue;
      }

      sections[section.id] = _groupedSectionCards(
        normalizeUserCustomSectionTitle(section.title).isEmpty
            ? 'CUSTOM SECTION'
            : normalizeUserCustomSectionTitle(section.title).toUpperCase(),
        section.items
            .map(_userCustomSectionBlock)
            .whereType<pw.Widget>()
            .toList(growable: false),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _shellMargin + _contentInsetX,
            _shellMargin + _contentInsetTop,
            _shellMargin + _contentInsetX,
            _shellMargin + _contentInsetBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _backgroundShell(),
          ),
        ),
        build: (context) => [
          _headerRow(name, title, contactItems),
          pw.SizedBox(height: 10),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _backgroundShell() {
    return pw.Stack(
      children: [
        pw.Container(color: _pageBg),
        pw.Positioned(
          left: _shellMargin,
          top: _shellMargin,
          right: _shellMargin,
          bottom: _shellMargin,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              color: _paper,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _headerRow(
    String name,
    String title,
    List<ForestEdgeContactItem> contactItems,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _headerPanel(name, title)),
        pw.SizedBox(width: 10),
        pw.SizedBox(
          width: _contactCardWidth,
          child: _contactCard(contactItems),
        ),
      ],
    );
  }

  pw.Widget _headerPanel(String fullName, String title) {
    return pw.Stack(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(16, 18, 20, 14),
          decoration: const pw.BoxDecoration(
            color: _paper,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(12),
              topRight: pw.Radius.circular(26),
              bottomLeft: pw.Radius.circular(12),
              bottomRight: pw.Radius.circular(12),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitizePdfText(fullName).toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  _sanitizePdfText(title).toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: _soft,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              pw.Container(
                width: 120,
                height: 1,
                color: _headerAccent,
                margin: const pw.EdgeInsets.only(top: 8),
              ),
            ],
          ),
        ),
        pw.Positioned(
          top: -2,
          right: -8,
          child: pw.Container(
            width: 86,
            height: 54,
            decoration: const pw.BoxDecoration(
              color: _headerTint,
              borderRadius: pw.BorderRadius.only(
                topRight: pw.Radius.circular(18),
                bottomLeft: pw.Radius.circular(42),
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _contactCard(List<ForestEdgeContactItem> contactItems) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: contactItems.isEmpty
            ? [
                pw.Text(
                  'Add contact details',
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ]
            : contactItems
                .map(
                  (item) => _buildContactIconRow(
                    _contactIconName(item.kind),
                    _sanitizePdfText(item.label),
                    _headerAccent,
                    iconFg: PdfColors.white,
                    textColor: _muted,
                    textSize: 7.0,
                  ),
                )
                .toList(growable: false),
      ),
    );
  }

  String _contactIconName(ForestEdgeContactKind kind) {
    switch (kind) {
      case ForestEdgeContactKind.phone:
        return 'phone';
      case ForestEdgeContactKind.address:
        return 'location';
      case ForestEdgeContactKind.email:
        return 'email';
      case ForestEdgeContactKind.linkedin:
        return 'linkedin';
      case ForestEdgeContactKind.github:
        return 'website';
      case ForestEdgeContactKind.website:
        return 'website';
    }
  }

  pw.Widget _sectionCard({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Stack(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(14, 24, 14, 12),
          decoration: pw.BoxDecoration(
            color: _card,
            border: pw.Border.all(color: _line, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: child,
        ),
        pw.Positioned(
          left: 12,
          top: 7,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _headerAccent, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Text(
              _h(title),
              style: pw.TextStyle(
                fontSize: 7.4,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _contentCard(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: child,
    );
  }

  List<pw.Widget> _groupedSectionCards(
    String title,
    List<pw.Widget> items, {
    double sectionBottomSpacing = 10,
  }) {
    if (items.isEmpty) {
      return const <pw.Widget>[];
    }

    return <pw.Widget>[
      pw.Inseparable(
        child: _sectionCard(
          title: title,
          child: items.first,
        ),
      ),
      ...items.skip(1).map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Inseparable(
                child: _contentCard(item),
              ),
            ),
          ),
      if (sectionBottomSpacing > 0) pw.SizedBox(height: sectionBottomSpacing),
    ];
  }

  pw.Widget _chevronBulletLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, right: 5),
          child: pw.CustomPaint(
            size: const PdfPoint(8, 8),
            painter: (canvas, size) {
              canvas.setStrokeColor(_ink);
              canvas.setLineWidth(0.9);
              canvas.moveTo(1.0, 1.2);
              canvas.lineTo(4.2, 4.0);
              canvas.lineTo(1.0, 6.8);
              canvas.strokePath();
            },
          ),
        ),
        pw.Expanded(
          child: _bodyText(
            line,
            fontSize: 7.1,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _educationBlock(ForestEdgeEducationEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(entry.institution),
                style: pw.TextStyle(
                  fontSize: 8.2,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              _sanitizePdfText(entry.dateRange),
              style: const pw.TextStyle(
                fontSize: 7,
                color: _soft,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        _bodyText(
          entry.degreeLine,
          fontSize: 7.3,
          color: _ink,
        ),
      ],
    );
  }

  pw.Widget _experienceBlock(ForestEdgeExperienceEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(entry.company),
                style: pw.TextStyle(
                  fontSize: 8.2,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              _sanitizePdfText(entry.dateRange),
              style: pw.TextStyle(
                fontSize: 7,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _bodyText(
            entry.title,
            fontSize: 7.2,
            color: _muted,
          ),
        ),
        if (entry.location.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.location),
              style: const pw.TextStyle(
                fontSize: 6.9,
                color: _soft,
              ),
            ),
          ),
        if (entry.detailLines.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _dotBulletLine(line),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _projectBlock(ForestEdgeProjectEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 7.8,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (entry.detailLines.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.detailLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: _bodyText(
                        line,
                        fontSize: 6.9,
                        color: _muted,
                        align: pw.TextAlign.justify,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(link),
              style: pw.TextStyle(
                fontSize: 6.9,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _certificationBlock(ForestEdgeCertificationEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.name),
          style: pw.TextStyle(
            fontSize: 7.8,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _bodyText(
              line,
              fontSize: 6.9,
              color: _muted,
              align: pw.TextAlign.justify,
            ),
          ),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(link),
              style: pw.TextStyle(
                fontSize: 6.8,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget? _userCustomSectionBlock(CustomSectionItem item) {
    final displayItem = buildUserCustomSectionDisplayItem(item);
    final metaParts = <String>[];
    if (displayItem.subtitle.isNotEmpty) {
      metaParts.add(_sanitizePdfText(displayItem.subtitle));
    }
    if (displayItem.date != null) {
      metaParts.add(DateFormat('MMM yyyy').format(displayItem.date!));
    }

    if (!displayItem.hasContent) {
      return null;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (displayItem.heading.isNotEmpty)
          pw.Text(
            _sanitizePdfText(displayItem.heading),
            style: pw.TextStyle(
              fontSize: 7.8,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        if (metaParts.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              metaParts.join('  |  '),
              style: const pw.TextStyle(
                fontSize: 6.9,
                color: _soft,
              ),
            ),
          ),
        if (displayItem.detailLines.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...displayItem.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _dotBulletLine(line),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _dotBulletLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Container(
            width: 3.5,
            height: 3.5,
            decoration: const pw.BoxDecoration(
              color: _soft,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: _bodyText(
            line,
            fontSize: 6.9,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _bodyText(
    String value, {
    double fontSize = 7,
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
