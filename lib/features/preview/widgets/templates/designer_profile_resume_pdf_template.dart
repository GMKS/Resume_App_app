part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class DesignerProfileResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(DesignerProfileTemplateSupport.pageHex);
  static const PdfColor _sheet =
      PdfColor.fromInt(DesignerProfileTemplateSupport.sheetHex);
  static const PdfColor _sidebarTop =
      PdfColor.fromInt(DesignerProfileTemplateSupport.sidebarTopHex);
  static const PdfColor _sidebarBottom =
      PdfColor.fromInt(DesignerProfileTemplateSupport.sidebarBottomHex);
  static const PdfColor _heading =
      PdfColor.fromInt(DesignerProfileTemplateSupport.headingHex);
  static const PdfColor _ink =
      PdfColor.fromInt(DesignerProfileTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(DesignerProfileTemplateSupport.mutedHex);
  static const PdfColor _divider =
      PdfColor.fromInt(DesignerProfileTemplateSupport.dividerHex);
  static const PdfColor _sidebarText =
      PdfColor.fromInt(DesignerProfileTemplateSupport.sidebarTextHex);
  static const PdfColor _profileTint =
      PdfColor.fromInt(DesignerProfileTemplateSupport.profileTintHex);

  static const double _sidebarWidth = 152;
  static const double _sheetInset = 10;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'references',
    'projects',
    'certifications',
    'languages',
  ];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final normalizedResume = resume.templateId == 'designer_profile'
        ? resume.copyWith(
            customSections: ensureProfessionalRoleSections(resume),
          )
        : resume;
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      normalizedResume,
      defaultOrder: _defaultOrder,
      allowedKeys: _defaultOrder,
    );

    final name = DesignerProfileTemplateSupport.displayName(normalizedResume);
    final title = DesignerProfileTemplateSupport.displayTitle(normalizedResume);
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final contactItems = DesignerProfileTemplateSupport.contactItems(
      normalizedResume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final educationEntries = DesignerProfileTemplateSupport.educationEntries(
      normalizedResume.education,
      maxItems: 2,
      yearOnly: true,
    );
    final skillNames = DesignerProfileTemplateSupport.skillNames(
      normalizedResume.skills,
      customSections: normalizedResume.customSections,
      maxItems: 8,
    );
    final summaryLines = DesignerProfileTemplateSupport.summaryLines(
      normalizedResume.objective,
    );
    final experienceEntries = DesignerProfileTemplateSupport.experienceEntries(
      normalizedResume.experience,
      maxDetailLines: 12,
      yearOnly: false,
    );
    final referenceEntries = DesignerProfileTemplateSupport.referenceEntries(
      normalizedResume.references,
      maxItems: 4,
    );
    final projectEntries = DesignerProfileTemplateSupport.projectEntries(
      normalizedResume.projects,
      customSections: normalizedResume.customSections,
      maxDetailLines: 8,
      compactLinks: true,
    );
    final certificationEntries =
        DesignerProfileTemplateSupport.certificationEntries(
      normalizedResume.certifications,
      customSections: normalizedResume.customSections,
      compactLinks: true,
    );
    final languageLines = DesignerProfileTemplateSupport.languageLines(
      normalizedResume.languages,
    );
    final photoBytes =
        (normalizedResume.personalInfo.profileImage?.isNotEmpty ?? false)
            ? base64Decode(normalizedResume.personalInfo.profileImage!)
            : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryLines.map(_aboutStarBullet),
        pw.SizedBox(height: 10),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 11),
            child: _experienceBlock(entry),
          ),
        ),
      ];
    }

    if (referenceEntries.isNotEmpty) {
      sections['references'] = [
        _sectionHeader('REFERENCES'),
        pw.Wrap(
          spacing: 12,
          runSpacing: 8,
          children: referenceEntries
              .map(
                (entry) => pw.SizedBox(
                  width: 168,
                  child: _referenceBlock(entry),
                ),
              )
              .toList(growable: false),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _projectBlock(entry),
          ),
        ),
      ];
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...certificationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _certificationBlock(entry),
          ),
        ),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...languageLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 8.7,
                color: _muted,
              ),
            ),
          ),
        ),
      ];
    }

    _addUserCustomSections(
      resume: normalizedResume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase()),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(_sidebarWidth + 26, 24, 24, 24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context,
              photoBytes,
              initials.isEmpty ? 'DP' : initials,
              educationEntries,
              skillNames,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(name, title, contactItems),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    Uint8List? photoBytes,
    String initials,
    List<DesignerProfileEducationEntry> educationEntries,
    List<String> skillNames,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _sheetInset,
          right: _sheetInset,
          top: _sheetInset,
          bottom: _sheetInset,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: _sheet,
              border: pw.Border.all(color: _divider, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
          ),
        ),
        pw.Positioned(
          left: _sheetInset,
          top: _sheetInset,
          bottom: _sheetInset,
          child: pw.SizedBox(
            width: _sidebarWidth,
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                  colors: [_sidebarTop, _sidebarBottom],
                ),
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  bottomLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(14),
                  bottomRight: pw.Radius.circular(14),
                ),
              ),
              padding: const pw.EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: context.pageNumber == 1
                  ? _buildSidebar(
                      photoBytes, initials, educationEntries, skillNames)
                  : pw.SizedBox(),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSidebar(
    Uint8List? photoBytes,
    String initials,
    List<DesignerProfileEducationEntry> educationEntries,
    List<String> skillNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Container(
            width: 84,
            height: 84,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: photoBytes == null ? _profileTint : null,
              border: pw.Border.all(
                color: const PdfColor(1, 1, 1, 0.76),
                width: 2,
              ),
              image: photoBytes != null
                  ? pw.DecorationImage(
                      image: pw.MemoryImage(photoBytes),
                      fit: pw.BoxFit.cover,
                    )
                  : null,
            ),
            child: photoBytes == null
                ? pw.Center(
                    child: pw.Text(
                      initials,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _heading,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        pw.SizedBox(height: 20),
        if (educationEntries.isNotEmpty) ...[
          _sidebarSectionHeader('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 9),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degree),
                    style: pw.TextStyle(
                      fontSize: 8.8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 7.8,
                      color: _sidebarText,
                      lineSpacing: 1.2,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.dateRange),
                    style: const pw.TextStyle(
                      fontSize: 7.7,
                      color: _sidebarText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (skillNames.isNotEmpty) ...[
          _sidebarSectionHeader('SKILLS'),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(top: 4, right: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor(1, 1, 1, 0.82),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(skill),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: _sidebarText,
                        lineSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildHeader(
    String name,
    String title,
    List<DesignerProfileContactItem> contactItems,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(name).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _heading,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (title.trim().isNotEmpty)
                      pw.Text(
                        _sanitizePdfText(title),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: _muted,
                          lineSpacing: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              if (contactItems.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                pw.SizedBox(
                  width: 176,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: contactItems
                        .map(
                          (item) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Text(
                              _sanitizePdfText(item.label),
                              style: const pw.TextStyle(
                                fontSize: 8.4,
                                color: _muted,
                                lineSpacing: 1.15,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
          pw.Container(
            height: 1,
            color: _divider,
            margin: const pw.EdgeInsets.only(top: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 9.6,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.0,
            ),
          ),
          pw.Container(
            height: 1,
            color: const PdfColor(1, 1, 1, 0.3),
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _heading,
              letterSpacing: 1.0,
            ),
          ),
          pw.Container(
            height: 1,
            color: _divider,
            margin: const pw.EdgeInsets.only(top: 4),
          ),
        ],
      ),
    );
  }

  pw.Widget _aboutStarBullet(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.2),
            child: _aboutStarMarker(),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(value),
              style: const pw.TextStyle(
                fontSize: 9.1,
                color: _muted,
                lineSpacing: 1.38,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _aboutStarMarker() {
    return pw.SizedBox(
      width: 8.4,
      height: 8.4,
      child: pw.CustomPaint(
        size: const PdfPoint(8.4, 8.4),
        painter: (canvas, size) {
          canvas.setFillColor(_sidebarTop);
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

  pw.Widget _experienceBlock(DesignerProfileExperienceEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                style: const pw.TextStyle(
                  fontSize: 8.2,
                  color: _muted,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
          if (entry.companyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.companyLine),
                style: pw.TextStyle(
                  fontSize: 8.8,
                  color: _heading,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map(_detailBullet),
        ],
      ),
    );
  }

  pw.Widget _referenceBlock(DesignerProfileReferenceEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.name),
          style: pw.TextStyle(
            fontSize: 9.4,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        if (entry.roleLine.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.roleLine),
              style: const pw.TextStyle(
                fontSize: 8.2,
                color: _muted,
                lineSpacing: 1.15,
              ),
            ),
          ),
        if (entry.contactLine.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(entry.contactLine),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _heading,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _projectBlock(DesignerProfileProjectEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.6,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (entry.technologyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.technologyLine),
                style: pw.TextStyle(
                  fontSize: 8.3,
                  color: _heading,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map(_detailBullet),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(link),
                style: const pw.TextStyle(
                  fontSize: 8.1,
                  color: _heading,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(DesignerProfileCertificationEntry entry) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 9.2,
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
                  fontSize: 8.1,
                  color: _muted,
                  lineSpacing: 1.15,
                ),
              ),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(link),
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _heading,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _detailBullet(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            decoration: const pw.BoxDecoration(
              color: _sidebarTop,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(value),
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: _muted,
                lineSpacing: 1.3,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
