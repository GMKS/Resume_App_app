part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class SlateArcResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(SlateArcTemplateSupport.pageHex);
  static const PdfColor _header =
      PdfColor.fromInt(SlateArcTemplateSupport.headerHex);
  static const PdfColor _headerInk =
      PdfColor.fromInt(SlateArcTemplateSupport.headerInkHex);
  static const PdfColor _sectionInk =
      PdfColor.fromInt(SlateArcTemplateSupport.sectionInkHex);
  static const PdfColor _bodyMuted =
      PdfColor.fromInt(SlateArcTemplateSupport.bodyMutedHex);
  static const PdfColor _divider =
      PdfColor.fromInt(SlateArcTemplateSupport.dividerHex);
  static const PdfColor _photoBg =
      PdfColor.fromInt(SlateArcTemplateSupport.photoBgHex);

  static const double _pageMargin = 24;
  static const double _pageTop = 24;
  static const double _pageBottom = 24;
  static const double _headerHeight = 76;
  static const double _sidebarWidth = 124;
  static const double _contentGap = 18;
  static const double _dividerXOffset = 8;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'certifications',
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

    final name = SlateArcTemplateSupport.displayName(resume);
    final title = SlateArcTemplateSupport.displayTitle(resume);
    final contactItems = SlateArcTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final languageLines = SlateArcTemplateSupport.languageLines(
      resume.languages,
      maxItems: 4,
    );
    final educationEntries = SlateArcTemplateSupport.educationEntries(
      resume.education,
      maxItems: 2,
    );
    final skillNames = SlateArcTemplateSupport.skillNames(
      resume.skills,
      maxItems: 6,
    );
    final summaryLines = SlateArcTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final experienceEntries = SlateArcTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: null,
    );
    final projectEntries = SlateArcTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries = SlateArcTemplateSupport.certificationEntries(
      resume.certifications,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final leadExperience = experienceEntries.take(2).toList(growable: false);
    final overflowExperience =
        experienceEntries.skip(leadExperience.length).toList(growable: false);
    final keepProjectsOnLead = projectEntries.length <= 2;
    final keepCertificationsOnLead =
        keepProjectsOnLead && certificationEntries.length <= 2;
    final leadProjects =
        keepProjectsOnLead ? projectEntries : <SlateArcProjectEntry>[];
    final overflowProjects =
        keepProjectsOnLead ? <SlateArcProjectEntry>[] : projectEntries;
    final leadCertifications = keepCertificationsOnLead
        ? certificationEntries
        : <SlateArcCertificationEntry>[];
    final overflowCertifications = keepCertificationsOnLead
        ? <SlateArcCertificationEntry>[]
        : certificationEntries;

    final leadSections = <String, List<pw.Widget>>{};
    if (summaryLines.isNotEmpty) {
      leadSections['summary'] = [
        _sectionHeader('PROFILE'),
        ...summaryLines.map(_summaryLine),
        pw.SizedBox(height: 10),
      ];
    }
    if (leadExperience.isNotEmpty) {
      leadSections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...leadExperience.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry, accentColor),
          ),
        ),
      ];
    }
    if (leadProjects.isNotEmpty) {
      leadSections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...leadProjects.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 7),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }
    if (leadCertifications.isNotEmpty) {
      leadSections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...leadCertifications.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _certificationLine(entry),
          ),
        ),
      ];
    }

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin + _sidebarWidth + _contentGap,
            _pageTop + _headerHeight + 12,
            _pageMargin,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              accentColor,
              name,
              title,
              photoBytes,
              contactItems,
              languageLines,
              educationEntries,
              skillNames,
              includeContent: true,
            ),
          ),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: _applyPdfSectionOrder(sectionOrder, leadSections),
        ),
      ),
    );

    final overflowSections = <String, List<pw.Widget>>{};
    if (overflowExperience.isNotEmpty) {
      overflowSections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...overflowExperience.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry, accentColor),
          ),
        ),
      ];
    }
    if (overflowProjects.isNotEmpty) {
      overflowSections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...overflowProjects.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 7),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }
    if (overflowCertifications.isNotEmpty) {
      overflowSections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...overflowCertifications.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _certificationLine(entry),
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: overflowSections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase()),
    );

    if (overflowSections.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(
              _pageMargin + _sidebarWidth + _contentGap,
              _pageTop + _headerHeight + 12,
              _pageMargin,
              _pageBottom,
            ),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: _buildBackground(
                accentColor,
                name,
                title,
                photoBytes,
                contactItems,
                languageLines,
                educationEntries,
                skillNames,
                includeContent: false,
              ),
            ),
          ),
          build: (context) =>
              _applyPdfSectionOrder(sectionOrder, overflowSections),
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildBackground(
    PdfColor accentColor,
    String name,
    String title,
    Uint8List? photoBytes,
    List<SlateArcContactItem> contactItems,
    List<String> languageLines,
    List<SlateArcEducationEntry> educationEntries,
    List<String> skillNames, {
    required bool includeContent,
  }) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin,
          right: _pageMargin,
          top: _pageTop,
          child: pw.Container(
            height: _headerHeight,
            decoration: const pw.BoxDecoration(
              color: _header,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(24),
              ),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin,
          top: _pageTop + _headerHeight + 10,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: _sidebarWidth,
            child: includeContent
                ? _buildSidebar(
                    accentColor,
                    contactItems,
                    languageLines,
                    educationEntries,
                    skillNames,
                  )
                : pw.SizedBox(),
          ),
        ),
        pw.Positioned(
          left: _pageMargin + _sidebarWidth + _dividerXOffset,
          top: _pageTop + _headerHeight + 10,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1,
            child: pw.Container(color: _divider),
          ),
        ),
        if (includeContent) ...[
          pw.Positioned(
            left: _pageMargin + 16,
            right: _pageMargin + 84,
            top: _pageTop + 16,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(name).toUpperCase(),
                  maxLines: 1,
                  style: pw.TextStyle(
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                    color: _headerInk,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    _sanitizePdfText(title),
                    maxLines: 1,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _bodyMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Positioned(
            right: _pageMargin + 14,
            top: _pageTop + 10,
            child: pw.SizedBox(
              width: 58,
              height: 58,
              child: pw.Container(
                decoration: photoBytes == null
                    ? pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _photoBg,
                        border: pw.Border.all(
                          color: PdfColors.white,
                          width: 3,
                        ),
                      )
                    : pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(
                          color: PdfColors.white,
                          width: 3,
                        ),
                        image: pw.DecorationImage(
                          image: pw.MemoryImage(photoBytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                child: photoBytes == null
                    ? pw.Center(
                        child: pw.Text(
                          _initials(name),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSidebar(
    PdfColor accentColor,
    List<SlateArcContactItem> contactItems,
    List<String> languageLines,
    List<SlateArcEducationEntry> educationEntries,
    List<String> skillNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contactItems.isNotEmpty) ...[
          _sidebarSectionHeader('CONTACT', accentColor),
          ...contactItems.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(item.label),
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _bodyMuted,
                  lineSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
        if (languageLines.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _sidebarSectionHeader('LANGUAGES', accentColor),
          ...languageLines.map(
            (line) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor(
                  accentColor.red,
                  accentColor.green,
                  accentColor.blue,
                  0.10,
                ),
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(6),
                ),
                border: pw.Border.all(
                  color: PdfColor(
                    accentColor.red,
                    accentColor.green,
                    accentColor.blue,
                    0.22,
                  ),
                  width: 0.8,
                ),
              ),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 7.7,
                  color: _sectionInk,
                ),
              ),
            ),
          ),
        ],
        if (educationEntries.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _sidebarSectionHeader('EDUCATION', accentColor),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degree),
                    style: pw.TextStyle(
                      fontSize: 8.2,
                      fontWeight: pw.FontWeight.bold,
                      color: _sectionInk,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      _sanitizePdfText(
                        '${entry.institutionLine} - ${entry.dateLabel}',
                      ),
                      style: const pw.TextStyle(
                        fontSize: 7.7,
                        color: _bodyMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _sidebarSectionHeader('SKILLS', accentColor),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '- ${_sanitizePdfText(skill)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _bodyMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarSectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _sectionInk,
        ),
      ),
    );
  }

  pw.Widget _bodyText(String value) {
    return pw.Text(
      _sanitizePdfText(value),
      textAlign: pw.TextAlign.justify,
      style: const pw.TextStyle(
        fontSize: 8.5,
        color: _bodyMuted,
        lineSpacing: 1.35,
      ),
    );
  }

  pw.Widget _summaryLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.2),
            child: _summaryStarMarker(),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(child: _bodyText(value)),
        ],
      ),
    );
  }

  pw.Widget _summaryStarMarker() {
    return pw.SizedBox(
      width: 8.4,
      height: 8.4,
      child: pw.CustomPaint(
        size: const PdfPoint(8.4, 8.4),
        painter: (canvas, size) {
          canvas.setFillColor(_sectionInk);
          canvas.moveTo(size.x * 0.5, 0.45);
          canvas.lineTo(size.x * 0.62, size.y * 0.33);
          canvas.lineTo(size.x - 0.35, size.y * 0.36);
          canvas.lineTo(size.x * 0.69, size.y * 0.58);
          canvas.lineTo(size.x * 0.81, size.y - 0.35);
          canvas.lineTo(size.x * 0.5, size.y * 0.72);
          canvas.lineTo(size.x * 0.19, size.y - 0.35);
          canvas.lineTo(size.x * 0.31, size.y * 0.58);
          canvas.lineTo(0.35, size.y * 0.36);
          canvas.lineTo(size.x * 0.38, size.y * 0.33);
          canvas.closePath();
          canvas.fillPath();
        },
      ),
    );
  }

  pw.Widget _experienceBlock(
    SlateArcExperienceEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 9.8,
            fontWeight: pw.FontWeight.bold,
            color: _sectionInk,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1.5, bottom: 1.5),
          child: pw.Text(
            _sanitizePdfText('${entry.metaLine}  •  ${entry.dateRange}'),
            style: pw.TextStyle(
              fontSize: 8.2,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: _bodyText(line),
          ),
        ),
      ],
    );
  }

  pw.Widget _projectBlock(SlateArcProjectEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.title),
          style: pw.TextStyle(
            fontSize: 8.9,
            fontWeight: pw.FontWeight.bold,
            color: _sectionInk,
          ),
        ),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.5),
            child: _bodyText(line),
          ),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.2),
            child: pw.Text(
              _sanitizePdfText(link),
              style: const pw.TextStyle(
                fontSize: 8.1,
                color: PdfColor.fromInt(SlateArcTemplateSupport.sectionInkHex),
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _certificationLine(SlateArcCertificationEntry entry) {
    final line = entry.metaLine.isNotEmpty
        ? '${entry.name} - ${entry.metaLine}'
        : entry.name;
    return pw.Text(
      _sanitizePdfText(line),
      style: const pw.TextStyle(
        fontSize: 8.2,
        color: _bodyMuted,
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'JS';
    }

    return parts.map((part) => part.substring(0, 1)).join().toUpperCase();
  }
}
