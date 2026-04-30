part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class BalancedTwoColumnLayoutTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.paperHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.sidebarHex);
  static const PdfColor _line =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.lineHex);
  static const PdfColor _gold =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.goldHex);
  static const PdfColor _goldDark =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.goldDarkHex);
  static const PdfColor _ink =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.mutedHex);
  static const PdfColor _avatarFill =
      PdfColor.fromInt(BalancedTwoColumnTemplateSupport.avatarFillHex);

  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 176;
  static const double _contentGap = 18;
  static const double _headerHeight = 80;
  static const double _avatarSize = 62;
  static const int _maxSidebarSummaryItems = 5;
  static const int _maxSidebarExperienceItems = 2;

  static const List<String> _defaultOrder = <String>[
    'summary',
    'skills',
    'education',
    'projects',
    'experience',
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

    final name = BalancedTwoColumnTemplateSupport.displayName(resume);
    final title = BalancedTwoColumnTemplateSupport.displayTitle(resume);
    final contactItems = BalancedTwoColumnTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = BalancedTwoColumnTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final skillNames = BalancedTwoColumnTemplateSupport.skillNames(
      resume.skills,
      maxItems: null,
    );
    final educationEntries = BalancedTwoColumnTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final experienceEntries =
        BalancedTwoColumnTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: 4,
      yearOnly: false,
    );
    final projectEntries = BalancedTwoColumnTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: 3,
      compactLinks: true,
    );
    final certificationEntries =
        BalancedTwoColumnTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = BalancedTwoColumnTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'BT');

    final sidebarSummaryLines =
        summaryLines.take(_maxSidebarSummaryItems).toList(growable: false);
    final overflowSummaryLines =
        summaryLines.skip(sidebarSummaryLines.length).toList(growable: false);

    final sidebarExperienceEntries = BalancedTwoColumnTemplateSupport
        .experienceEntries(
      resume.experience,
      maxItems: _maxSidebarExperienceItems,
      maxDetailLines: 0,
      yearOnly: false,
    )
        .toList(growable: false);
    final sidebarCertificationEntries = certificationEntries.toList(growable: false);
    final sidebarLanguageLines = languageLines.toList(growable: false);

    final sections = <String, List<pw.Widget>>{};

    if (overflowSummaryLines.isNotEmpty) {
      sections['summary'] = _groupedSectionWidgets(
        'PROFILE SUMMARY',
        [
          _contentCard(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: overflowSummaryLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: _markerLine(line),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      );
    }

    if (skillNames.isNotEmpty) {
      sections['skills'] = _groupedSectionWidgets(
        'SKILLS',
        [
          _contentCard(
            child: pw.Wrap(
              spacing: 5,
              runSpacing: 5,
              children: skillNames.map(_skillChip).toList(growable: false),
            ),
          ),
        ],
      );
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = _groupedSectionWidgets(
        'EDUCATION',
        educationEntries
            .map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _contentCard(child: _educationBlock(entry)),
              ),
            )
            .toList(growable: false),
        bottomSpacing: 4,
      );
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = _groupedSectionWidgets(
        'PROJECTS',
        projectEntries
            .map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _contentCard(child: _projectBlock(entry)),
              ),
            )
            .toList(growable: false),
        bottomSpacing: 4,
      );
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _groupedSectionWidgets(
        'EXPERIENCE DETAILS',
        experienceEntries
            .map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _contentCard(child: _experienceBlock(entry)),
              ),
            )
            .toList(growable: false),
        bottomSpacing: 4,
      );
    }

    // All certifications and languages are shown together in the sidebar
    // so they are not split between sidebar and body content.

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
              initials: initials,
              name: name,
              title: title,
              summaryLines: sidebarSummaryLines,
              sidebarExperienceEntries: sidebarExperienceEntries,
              sidebarCertificationEntries: sidebarCertificationEntries,
              sidebarLanguageLines: sidebarLanguageLines,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox(height: _headerHeight + 10)
            : pw.SizedBox.shrink(),
        build: (context) {
          final widgets = <pw.Widget>[];

          if (contactItems.isNotEmpty) {
            widgets.addAll([
              _sectionHeader('CONTACT'),
              _contentCard(child: _contactBlock(contactItems)),
              pw.SizedBox(height: 10),
            ]);
          }

          widgets.addAll(_applyPdfSectionOrder(sectionOrder, sections));
          return widgets;
        },
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
    required List<String> summaryLines,
    required List<BalancedTwoColumnExperienceEntry> sidebarExperienceEntries,
    required List<BalancedTwoColumnCertificationEntry>
        sidebarCertificationEntries,
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
        pw.Positioned(
          left: _pageMargin - 2,
          top: _pageTop - 2,
          bottom: _pageBottom - 2,
          child: pw.Container(
            width: _sidebarWidth,
            color: _sidebar,
          ),
        ),
        pw.Positioned(
          left: _pageMargin + _sidebarWidth + (_contentGap / 2),
          top: _pageTop - 2,
          bottom: _pageBottom - 2,
          child: pw.Container(
            width: 1,
            color: _line,
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + _sidebarWidth + _contentGap,
            right: _pageMargin + _avatarSize + 18,
            top: _pageTop + 4,
            child: _headerBlock(name, title),
          ),
          pw.Positioned(
            right: _pageMargin + 2,
            top: _pageTop + 4,
            child: _photoTemplateAvatar(
              photoBytes: photoBytes,
              initials: initials,
              size: _avatarSize,
              borderColor: _gold,
              fillColor: _avatarFill,
              textColor: _gold,
            ),
          ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + 10,
            child: pw.SizedBox(
              width: _sidebarWidth - 20,
              child: _sidebarContent(
                summaryLines,
                sidebarExperienceEntries,
                sidebarCertificationEntries,
                sidebarLanguageLines,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _headerBlock(String name, String title) {
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
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              _sanitizePdfText(title),
              style: const pw.TextStyle(
                fontSize: 10,
                color: _gold,
              ),
            ),
          ),
        pw.Container(
          height: 1,
          color: _line,
          margin: const pw.EdgeInsets.only(top: 10),
        ),
      ],
    );
  }

  pw.Widget _sidebarContent(
    List<String> summaryLines,
    List<BalancedTwoColumnExperienceEntry> experienceEntries,
    List<BalancedTwoColumnCertificationEntry> certificationEntries,
    List<String> languageLines,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (summaryLines.isNotEmpty) ...[
          _sectionHeader('PROFILE', compact: true),
          ...summaryLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _markerLine(line),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        if (experienceEntries.isNotEmpty) ...[
          _sectionHeader('EXPERIENCE SUMMARY', compact: true),
          ...experienceEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: _sidebarExperienceBlock(entry),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        if (certificationEntries.isNotEmpty) ...[
          _sectionHeader('CERTIFICATIONS', compact: true),
          _contentCard(
            padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 7),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: certificationEntries
                  .map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: _certificationBlock(entry, compact: true),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        if (languageLines.isNotEmpty) ...[
          _sectionHeader('LANGUAGES', compact: true),
          _contentCard(
            padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 7),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(languageLines.join('  |  ')),
                  style: const pw.TextStyle(
                    fontSize: 7.6,
                    color: PdfColors.black,
                    lineSpacing: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sectionHeader(String title, {bool compact = false}) {
    return _photoTemplateSectionTitle(
      title,
      _goldDark,
      dividerColor: _line,
      fontSize: compact ? 9 : 10,
    );
  }

  pw.BoxDecoration _contentCardDecoration() {
    return pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _line, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );
  }

  pw.Widget _contentCard({
    required pw.Widget child,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(10),
  }) {
    return pw.Container(
      width: double.infinity,
      padding: padding,
      decoration: _contentCardDecoration(),
      child: child,
    );
  }

  List<pw.Widget> _groupedSectionWidgets(
    String title,
    List<pw.Widget> items, {
    double bottomSpacing = 10,
  }) {
    if (items.isEmpty) {
      return const <pw.Widget>[];
    }

    return <pw.Widget>[
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionHeader(title),
            items.first,
          ],
        ),
      ),
      ...items.skip(1).map((item) => pw.Inseparable(child: item)),
      if (bottomSpacing > 0) pw.SizedBox(height: bottomSpacing),
    ];
  }

  pw.Widget _bodyText(
    String text, {
    double fontSize = 8,
    PdfColor color = _muted,
    pw.TextAlign align = pw.TextAlign.left,
    int? maxLines,
  }) {
    return pw.Text(
      _sanitizePdfText(text),
      maxLines: maxLines,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        lineSpacing: 1.25,
      ),
    );
  }

  pw.Widget _markerLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 2.4,
          height: 9,
          margin: const pw.EdgeInsets.only(right: 5, top: 1),
          decoration: const pw.BoxDecoration(
            color: _gold,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.5)),
          ),
        ),
        pw.Expanded(
          child: _bodyText(
            line,
            fontSize: 7.8,
            color: _muted,
            align: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _sidebarExperienceBlock(BalancedTwoColumnExperienceEntry entry) {
    final metaLine = entry.metaLine.isNotEmpty
        ? '${entry.metaLine}  |  ${entry.dateRange}'
        : entry.dateRange;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 8.4,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _bodyText(
            metaLine,
            fontSize: 7.2,
            color: _gold,
            maxLines: 2,
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
                      child: _markerLine(line),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _contactBlock(List<BalancedTwoColumnContactItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _bodyText(item.label),
            ),
          )
          .toList(growable: false),
    );
  }

  pw.Widget _skillChip(String skill) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: _sidebar,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        _sanitizePdfText(skill),
        style: const pw.TextStyle(
          fontSize: 7.4,
          color: _goldDark,
        ),
      ),
    );
  }

  pw.Widget _educationBlock(BalancedTwoColumnEducationEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.degreeLine),
          style: pw.TextStyle(
            fontSize: 8.6,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _bodyText(
            entry.institutionLine,
            fontSize: 7.8,
            color: _muted,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _bodyText(
            entry.dateRange,
            fontSize: 7.4,
            color: _gold,
          ),
        ),
      ],
    );
  }

  pw.Widget _experienceBlock(BalancedTwoColumnExperienceEntry entry) {
    final metaLine = entry.metaLine.isNotEmpty
        ? '${entry.metaLine}  |  ${entry.dateRange}'
        : entry.dateRange;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 8.8,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _bodyText(
            metaLine,
            fontSize: 7.6,
            color: _gold,
          ),
        ),
        if (entry.detailLines.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.detailLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: _markerLine(line),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _projectBlock(BalancedTwoColumnProjectEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 8.8,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (entry.detailLines.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.detailLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: _bodyText(
                        line,
                        align: pw.TextAlign.justify,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (entry.links.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.links
                  .map(
                    (link) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: _bodyText(
                        link,
                        fontSize: 7.6,
                        color: _goldDark,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }

  pw.Widget _certificationBlock(
    BalancedTwoColumnCertificationEntry entry, {
    bool compact = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.name),
          style: pw.TextStyle(
            fontSize: compact ? 7.8 : 8.4,
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
                        fontSize: compact ? 7.1 : 7.6,
                        color: _muted,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (entry.links.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: entry.links
                  .map(
                    (link) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: _bodyText(
                        link,
                        fontSize: compact ? 7.0 : 7.4,
                        color: _goldDark,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}
