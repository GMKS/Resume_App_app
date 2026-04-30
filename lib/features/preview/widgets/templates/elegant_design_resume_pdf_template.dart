part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ElegantDesignResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(ElegantDesignTemplateSupport.pageHex);
  static const PdfColor _sheet =
      PdfColor.fromInt(ElegantDesignTemplateSupport.sheetHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(ElegantDesignTemplateSupport.sidebarHex);
  static const PdfColor _line =
      PdfColor.fromInt(ElegantDesignTemplateSupport.lineHex);
  static const PdfColor _heading =
      PdfColor.fromInt(ElegantDesignTemplateSupport.headingHex);
  static const PdfColor _accent =
      PdfColor.fromInt(ElegantDesignTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ElegantDesignTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ElegantDesignTemplateSupport.mutedHex);
  static const PdfColor _sidebarText =
      PdfColor.fromInt(ElegantDesignTemplateSupport.sidebarTextHex);
  static const PdfColor _avatarFill =
      PdfColor.fromInt(ElegantDesignTemplateSupport.avatarFillHex);

  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 142;
  static const double _contentGap = 20;
  static const double _avatarSize = 68;
  static const int _maxSidebarEducationItems = 2;
  static const int _maxSidebarSkillItems = 8;

  static const List<String> _defaultOrder = <String>[
    'summary',
    'experience',
    'projects',
    'education',
    'skills',
    'references',
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

    final name = ElegantDesignTemplateSupport.displayName(resume);
    final title =
        ElegantDesignTemplateSupport.displayTitle(resume).toUpperCase();
    final address = ElegantDesignTemplateSupport.address(resume.personalInfo);
    final contactItems = ElegantDesignTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final educationEntries = ElegantDesignTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final skillNames = ElegantDesignTemplateSupport.skillNames(resume.skills);
    final summaryLines = ElegantDesignTemplateSupport.summaryLines(
      resume.objective,
    );
    final experienceEntries = ElegantDesignTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 12,
      yearOnly: false,
    );
    final projectEntries = ElegantDesignTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 8,
      compactLinks: true,
    );
    final certificationEntries =
        ElegantDesignTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = ElegantDesignTemplateSupport.languageLines(
      resume.languages,
    );
    final referenceEntries = ElegantDesignTemplateSupport.referenceEntries(
      resume.references,
      maxItems: 4,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    final sidebarEducationEntries = educationEntries
        .take(_maxSidebarEducationItems)
        .toList(growable: false);
    final overflowEducationEntries = educationEntries
        .skip(sidebarEducationEntries.length)
        .toList(growable: false);
    final sidebarSkillNames =
        skillNames.take(_maxSidebarSkillItems).toList(growable: false);
    final overflowSkillNames =
        skillNames.skip(sidebarSkillNames.length).toList(growable: false);
    final sidebarCertificationEntries =
        certificationEntries.toList(growable: false);
    final sidebarLanguageLines = languageLines.toList(growable: false);
    final summaryWidgets = <pw.Widget>[
      for (final entry in summaryLines.asMap().entries)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _numberedSummaryLine(entry.key, entry.value),
        ),
    ];

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryWidgets,
        pw.SizedBox(height: 8),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: _experienceBlock(entry),
          ),
        ),
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

    if (overflowEducationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...overflowEducationEntries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _educationBlock(entry),
          ),
        ),
      ];
    }

    if (overflowSkillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        ...overflowSkillNames.map(
          (skill) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: _bodyText(skill),
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
                  width: 170,
                  child: _referenceBlock(entry),
                ),
              )
              .toList(growable: false),
        ),
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
            _pageMargin + _sidebarWidth + _contentGap,
            _pageTop,
            _pageMargin,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context.pageNumber,
              photoBytes,
              initials.isEmpty ? 'ED' : initials,
              contactItems,
              sidebarEducationEntries,
              sidebarSkillNames,
              sidebarCertificationEntries,
              sidebarLanguageLines,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _header(name, title, address),
                  pw.SizedBox(height: 10),
                ],
              )
            : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    int pageNumber,
    Uint8List? photoBytes,
    String initials,
    List<ElegantDesignContactItem> contactItems,
    List<ElegantDesignEducationEntry> educationEntries,
    List<String> skillNames,
    List<ElegantDesignCertificationEntry> certificationEntries,
    List<String> languageLines,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: _page),
        pw.Positioned(
          left: _pageMargin - 4,
          right: _pageMargin - 4,
          top: _pageTop - 4,
          bottom: _pageBottom - 4,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              color: _sheet,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin - 4,
          top: _pageTop - 4,
          bottom: _pageBottom - 4,
          child: pw.Container(
            width: _sidebarWidth,
            color: _sidebar,
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + ((_sidebarWidth - _avatarSize) / 2) - 4,
            top: _pageTop + 8,
            child: _avatar(photoBytes, initials),
          ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + 88,
            child: pw.SizedBox(
              width: _sidebarWidth - 20,
              child: _sidebarContent(
                contactItems,
                educationEntries,
                skillNames,
                certificationEntries,
                languageLines,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _avatar(Uint8List? photoBytes, String initials) {
    return pw.Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: photoBytes == null ? _avatarFill : null,
        border: pw.Border.all(color: _accent, width: 1.2),
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
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
            )
          : null,
    );
  }

  pw.Widget _sidebarContent(
    List<ElegantDesignContactItem> contactItems,
    List<ElegantDesignEducationEntry> educationEntries,
    List<String> skillNames,
    List<ElegantDesignCertificationEntry> certificationEntries,
    List<String> languageLines,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sidebarHeader('CONTACT'),
        ...contactItems.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(item.label),
              style: const pw.TextStyle(
                fontSize: 7.8,
                color: _sidebarText,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (educationEntries.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degreeLine),
                    style: pw.TextStyle(
                      fontSize: 8.2,
                      fontWeight: pw.FontWeight.bold,
                      color: _sidebarText,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: _sidebarText,
                      lineSpacing: 1.15,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.dateRange),
                    style: const pw.TextStyle(
                      fontSize: 7.4,
                      color: _sidebarText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('SKILLS'),
          ...skillNames.map(_sidebarBulletRow),
        ],
        if (certificationEntries.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('CERTIFICATIONS'),
          ...certificationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.name),
                    style: pw.TextStyle(
                      fontSize: 7.8,
                      fontWeight: pw.FontWeight.bold,
                      color: _sidebarText,
                    ),
                  ),
                  ...entry.detailLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 7.2,
                          color: _sidebarText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (languageLines.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('LANGUAGES'),
          ...languageLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 7.6,
                  color: _sidebarText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8.6,
          color: _heading,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _sidebarBulletRow(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3,
            height: 3,
            margin: const pw.EdgeInsets.only(top: 4, right: 5),
            decoration: const pw.BoxDecoration(
              color: _accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: _sidebarText,
                lineSpacing: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _header(String name, String title, String address) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(name),
            style: pw.TextStyle(
              fontSize: 27,
              color: _heading,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          if (title.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(title),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (address.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(address),
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  color: _muted,
                ),
              ),
            ),
          pw.Container(
            height: 1,
            color: _line,
            margin: const pw.EdgeInsets.only(top: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10,
              color: _heading,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(height: 1, color: _line),
          ),
        ],
      ),
    );
  }

  pw.Widget _numberedSummaryLine(int index, String line) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 14,
            child: pw.Text(
              '${index + 1}.',
              style: pw.TextStyle(
                fontSize: 8.7,
                color: _accent,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: _bodyText(line),
          ),
        ],
      ),
    );
  }

  pw.Widget _mainFrame(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(right: 2),
      child: child,
    );
  }

  pw.Widget _bodyText(
    String value, {
    double size = 8.5,
    PdfColor color = _muted,
    pw.FontWeight? weight,
  }) {
    return pw.Text(
      _sanitizePdfText(value),
      textAlign: pw.TextAlign.justify,
      style: pw.TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        lineSpacing: 1.22,
      ),
    );
  }

  pw.Widget _detailBullet(String line) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4.3, right: 6),
            decoration: const pw.BoxDecoration(
              color: _accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: _bodyText(line, size: 8.3),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(ElegantDesignExperienceEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 9.6,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                style: const pw.TextStyle(
                  fontSize: 7.9,
                  color: _accent,
                ),
              ),
            ],
          ),
          if (entry.companyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
              child: pw.Text(
                _sanitizePdfText(entry.companyLine),
                style: pw.TextStyle(
                  fontSize: 8.4,
                  color: _heading,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _detailBullet(line),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(ElegantDesignProjectEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (entry.technologyLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
              child: pw.Text(
                _sanitizePdfText(entry.technologyLine),
                style: const pw.TextStyle(
                  fontSize: 7.8,
                  color: _accent,
                ),
              ),
            ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: _bodyText(line),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(ElegantDesignEducationEntry entry) {
    return _mainFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.degreeLine),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(entry.institutionLine),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            _sanitizePdfText(entry.dateRange),
            style: const pw.TextStyle(
              fontSize: 7.8,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(ElegantDesignCertificationEntry entry) {
    return _mainFrame(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 8.9,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: _bodyText(line, size: 7.9),
            ),
          ),
          ...entry.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 7.9,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _referenceBlock(ElegantDesignReferenceEntry entry) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(ElegantDesignTemplateSupport.sheetHex),
        border: pw.Border.all(color: _line, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.name),
            style: pw.TextStyle(
              fontSize: 8.4,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (entry.roleLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.roleLine),
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: _muted,
                ),
              ),
            ),
          if (entry.contactLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.contactLine),
                style: const pw.TextStyle(
                  fontSize: 7.4,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
