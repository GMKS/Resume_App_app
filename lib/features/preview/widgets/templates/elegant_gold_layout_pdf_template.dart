part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ElegantGoldLayoutTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(ElegantGoldTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(ElegantGoldTemplateSupport.paperHex);
  static const PdfColor _card =
      PdfColor.fromInt(ElegantGoldTemplateSupport.cardHex);
  static const PdfColor _headerStart =
      PdfColor.fromInt(ElegantGoldTemplateSupport.headerStartHex);
  static const PdfColor _headerEnd =
      PdfColor.fromInt(ElegantGoldTemplateSupport.headerEndHex);
  static const PdfColor _headerText =
      PdfColor.fromInt(ElegantGoldTemplateSupport.headerTextHex);
  static const PdfColor _accent =
      PdfColor.fromInt(ElegantGoldTemplateSupport.accentHex);
  static const PdfColor _border =
      PdfColor.fromInt(ElegantGoldTemplateSupport.borderHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ElegantGoldTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ElegantGoldTemplateSupport.mutedHex);

  static const double _pageMargin = 18;
  static const double _leftColumnWidth = 152;
  static const double _columnGap = 12;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    final normalizedResume =
        ElegantGoldTemplateSupport.normalizedResume(resume) ?? resume;
    final name = ElegantGoldTemplateSupport.displayName(normalizedResume);
    final title = ElegantGoldTemplateSupport.displayTitle(normalizedResume);
    final contactItems = ElegantGoldTemplateSupport.contactItems(
      normalizedResume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ElegantGoldTemplateSupport.summaryLines(
      normalizedResume.objective,
      maxItems: null,
    );
    final educationEntries = ElegantGoldTemplateSupport.educationEntries(
      normalizedResume.education,
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = ElegantGoldTemplateSupport.skillNames(
      normalizedResume.skills,
      maxItems: 8,
    );
    final languageLines = ElegantGoldTemplateSupport.languageLines(
      normalizedResume.languages,
      maxItems: null,
    );
    final experienceEntries = ElegantGoldTemplateSupport.experienceEntries(
      normalizedResume.experience,
      maxItems: null,
      maxDetailLines: 3,
      yearOnly: false,
    );
    final projectEntries = ElegantGoldTemplateSupport.projectEntries(
      normalizedResume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        ElegantGoldTemplateSupport.certificationEntries(
      normalizedResume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final customSections = ElegantGoldTemplateSupport.customSectionEntries(
      normalizedResume.customSections,
      maxItems: null,
      maxItemsPerSection: null,
    );
    final references = ElegantGoldTemplateSupport.referenceEntries(
      normalizedResume.references,
      maxItems: 2,
    );
    final photoBytes = _decodeProfilePhoto(normalizedResume);
    final initials = _resumeInitials(normalizedResume, 'HR');

    final pinnedExperiences = experienceEntries.take(2).toList(growable: false);
    final overflowExperiences = experienceEntries
        .skip(pinnedExperiences.length)
        .toList(growable: false);
    const leftInset = _leftColumnWidth + _columnGap;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_pageMargin),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _page),
          ),
        ),
        build: (context) {
          final introLeftColumnChildren = <pw.Widget>[
            if (educationEntries.isNotEmpty)
              _sidebarCard(
                'EDUCATION',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: educationEntries
                      .map(
                        (entry) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                _sanitizePdfText(entry.institution),
                                style: pw.TextStyle(
                                  fontSize: 7.6,
                                  color: _ink,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1),
                                child: _bodyText(
                                  entry.degreeLine,
                                  fontSize: 7,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1),
                                child: _bodyText(
                                  entry.dateRange,
                                  fontSize: 6.8,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            if (skillNames.isNotEmpty) ...[
              if (educationEntries.isNotEmpty) pw.SizedBox(height: 8),
              _sidebarCard(
                'SKILLS',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: skillNames
                      .map(
                        (skill) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: _bodyText(
                            '- ${_sanitizePdfText(skill)}',
                            fontSize: 7.2,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
            if (languageLines.isNotEmpty) ...[
              if (educationEntries.isNotEmpty || skillNames.isNotEmpty)
                pw.SizedBox(height: 8),
              _sidebarCard(
                'LANGUAGES',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: languageLines
                      .map(
                        (line) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: _bodyText(line, fontSize: 7),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ];

          final introRightColumnChildren = <pw.Widget>[
            if (pinnedExperiences.isNotEmpty)
              _mainCard(
                'EXPERIENCE',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: _experienceBlock(pinnedExperiences.first),
                    ),
                  ],
                ),
              ),
            if (pinnedExperiences.length > 1) ...[
              if (pinnedExperiences.isNotEmpty) pw.SizedBox(height: 8),
              _mainCard(
                null,
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: pinnedExperiences
                      .skip(1)
                      .map(
                        (entry) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: _experienceBlock(entry),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ];

          final widgets = <pw.Widget>[
            _heroIntroSection(
              name: name,
              title: title,
              photoBytes: photoBytes,
              initials: initials,
              contactItems: contactItems,
              summaryLines: summaryLines,
              leftColumnChildren: introLeftColumnChildren,
              rightColumnChildren: introRightColumnChildren,
            ),
          ];

          if (overflowExperiences.isNotEmpty) {
            widgets.addAll([
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: leftInset),
                child: _mainCard(
                  'ADDITIONAL EXPERIENCE',
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: overflowExperiences
                        .map(
                          (entry) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: _experienceBlock(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ]);
          }

          if (projectEntries.isNotEmpty) {
            widgets.addAll([
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: leftInset),
                child: _mainCard(
                  'PROJECTS',
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: projectEntries
                        .map(
                          (entry) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: _projectBlock(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ]);
          }

          if (certificationEntries.isNotEmpty) {
            widgets.addAll([
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: leftInset),
                child: _mainCard(
                  'CERTIFICATIONS',
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: certificationEntries
                        .map(
                          (entry) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: _certificationBlock(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ]);
          }

          if (customSections.isNotEmpty) {
            widgets.addAll(
              customSections.expand((section) {
                return [
                  pw.SizedBox(height: 10),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: leftInset),
                    child: _mainCard(
                      section.title.toUpperCase(),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: section.itemLines
                            .map(
                              (line) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: _bodyText(
                                  line,
                                  fontSize: 7.4,
                                  align: pw.TextAlign.justify,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ];
              }),
            );
          }

          if (references.isNotEmpty) {
            widgets.addAll([
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: leftInset),
                child: _mainCard(
                  'REFERENCES',
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: references.map((entry) {
                      final index = references.indexOf(entry);
                      return pw.Expanded(
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(
                            right: index == 0 ? 6 : 0,
                            left: index == 0 ? 0 : 6,
                          ),
                          child: pw.Column(
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
                              if (entry.metaLine.isNotEmpty)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 2),
                                  child:
                                      _bodyText(entry.metaLine, fontSize: 7.1),
                                ),
                              if (entry.contactLine.isNotEmpty)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 2),
                                  child: _bodyText(entry.contactLine,
                                      fontSize: 7.1),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
            ]);
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  pw.Widget _heroIntroSection({
    required String name,
    required String title,
    required Uint8List? photoBytes,
    required String initials,
    required List<ElegantGoldContactItem> contactItems,
    required List<String> summaryLines,
    required List<pw.Widget> leftColumnChildren,
    required List<pw.Widget> rightColumnChildren,
  }) {
    const double introHeaderHeight = 118;
    const double introCardsTop = 90;

    final displaySummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'Results-driven professional with expertise in delivering high-quality business systems with modern, user-focused workflows.',
          ];
    final contactCard = _sidebarCard(
      'CONTACT',
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: contactItems
            .map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _bodyText(
                  item.label,
                  fontSize: item.kind == ElegantGoldContactKind.address
                      ? 7
                      : 7.2,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
    final aboutCard = _mainCard(
      'ABOUT ME',
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: _buildArrowPointerBullets(
          displaySummaryLines.join('\n'),
          _accent,
          fontSize: 7.6,
          lineSpacing: 1.28,
          bottomPadding: 3,
          textColor: _muted,
          textAlign: pw.TextAlign.justify,
        ),
      ),
    );
    final introLeftChildren = <pw.Widget>[contactCard];
    if (leftColumnChildren.isNotEmpty) {
      introLeftChildren.add(pw.SizedBox(height: 8));
      introLeftChildren.addAll(leftColumnChildren);
    }
    final introRightChildren = <pw.Widget>[aboutCard];
    if (rightColumnChildren.isNotEmpty) {
      introRightChildren.add(pw.SizedBox(height: 8));
      introRightChildren.addAll(rightColumnChildren);
    }

    return pw.Container(
      width: double.infinity,
      child: pw.Stack(
        children: [
          pw.Container(
            width: double.infinity,
            height: introHeaderHeight,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [_headerStart, _headerEnd],
              ),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(18),
                topRight: pw.Radius.circular(18),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(name).toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 23,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            _sanitizePdfText(title),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: _headerText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _photoTemplateAvatar(
                  photoBytes: photoBytes,
                  initials: initials,
                  size: 72,
                  borderColor: PdfColors.white,
                  fillColor: PdfColors.white,
                  textColor: _accent,
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: introCardsTop),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: _leftColumnWidth,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: introLeftChildren,
                  ),
                ),
                pw.SizedBox(width: _columnGap),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: introRightChildren,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _header(
    String name,
    String title,
    Uint8List? photoBytes,
    String initials,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_headerStart, _headerEnd],
        ),
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(18),
          topRight: pw.Radius.circular(18),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(name).toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 23,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      _sanitizePdfText(title),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _headerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _photoTemplateAvatar(
            photoBytes: photoBytes,
            initials: initials,
            size: 72,
            borderColor: PdfColors.white,
            fillColor: PdfColors.white,
            textColor: _accent,
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarCard(String title, pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(9, 9, 9, 8),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: _headerEnd,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(18)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7.4,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  pw.Widget _mainCard(String? title, pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            top: 2,
            right: 0,
            bottom: 2,
            child: pw.Container(
              width: 2.2,
              decoration: const pw.BoxDecoration(
                color: _accent,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 7),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if ((title ?? '').isNotEmpty) ...[
                  pw.Text(
                    title!,
                    style: pw.TextStyle(
                      fontSize: 8.8,
                      color: _headerEnd,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    height: 0.8,
                    color: _border,
                    margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
                  ),
                ],
                pw.Container(
                  width: double.infinity,
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(ElegantGoldExperienceEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 8.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _bodyText(entry.metaLine, fontSize: 7.2),
          ),
          ...entry.detailLines.take(2).map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: _bodyText(
                    '- ${_sanitizePdfText(line)}',
                    fontSize: 7.1,
                    align: pw.TextAlign.justify,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(ElegantGoldProjectEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 8.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _bodyText(
                line,
                fontSize: 7.2,
                align: pw.TextAlign.justify,
              ),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _bodyText(link, fontSize: 7.1, color: _headerEnd),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(ElegantGoldCertificationEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 8.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _bodyText(line, fontSize: 7.1),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _bodyText(link, fontSize: 7.1, color: _headerEnd),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyText(
    String text, {
    double fontSize = 7.2,
    PdfColor color = _muted,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Text(
      _sanitizePdfText(text),
      textAlign: align,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        lineSpacing: 1.24,
      ),
    );
  }
}
