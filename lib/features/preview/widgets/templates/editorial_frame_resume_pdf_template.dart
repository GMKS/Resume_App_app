part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class EditorialFrameResumePdfTemplate extends PdfTemplate {
  static const PdfColor _paper =
      PdfColor.fromInt(EditorialFrameTemplateSupport.paperHex);
  static const PdfColor _accent =
      PdfColor.fromInt(EditorialFrameTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(EditorialFrameTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(EditorialFrameTemplateSupport.mutedHex);
  static const PdfColor _line =
      PdfColor.fromInt(EditorialFrameTemplateSupport.lineHex);
  static const PdfColor _photoTint =
      PdfColor.fromInt(EditorialFrameTemplateSupport.photoTintHex);

  static const double _pageMargin = 30;
  static const double _pageTop = 30;
  static const double _pageBottom = 30;
  static const double _sidebarWidth = 86;
  static const double _sidebarGap = 22;
  static const double _photoWidth = 82;
  static const double _photoHeight = 104;
  static const int _maxSidebarSkillItems = 6;
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

    final name = EditorialFrameTemplateSupport.displayName(resume);
    final title = EditorialFrameTemplateSupport.displayTitle(resume);
    final address = EditorialFrameTemplateSupport.displayAddress(resume);
    final contactItems = EditorialFrameTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
    );
    final skillNames = EditorialFrameTemplateSupport.skillNames(resume.skills);
    final sidebarSkillNames =
        skillNames.take(_maxSidebarSkillItems).toList(growable: false);
    final overflowSkillNames =
        skillNames.skip(sidebarSkillNames.length).toList(growable: false);
    final summaryLines =
        EditorialFrameTemplateSupport.summaryLines(resume.objective);
    final experienceEntries = EditorialFrameTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: null,
    );
    final educationEntries = EditorialFrameTemplateSupport.educationEntries(
      resume.education,
    );
    final projectEntries = EditorialFrameTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        EditorialFrameTemplateSupport.certificationEntries(
      resume.certifications,
    );
    final languageLines =
        EditorialFrameTemplateSupport.languageLines(resume.languages);
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('PERSONAL PROFILE'),
        ...summaryLines.map(_bulletLine),
        pw.SizedBox(height: 10),
      ];
    }
    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('WORK EXPERIENCE'),
        ...experienceEntries.expand((entry) => _experienceWidgets(entry)),
      ];
    }
    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...educationEntries.expand((entry) => _educationWidgets(entry)),
      ];
    }
    if (overflowSkillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('EXPERTISE'),
        ...overflowSkillNames.expand((skill) => _skillWidgets(skill)),
      ];
    }
    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.expand((entry) => _projectWidgets(entry)),
      ];
    }
    if (certificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...certificationEntries.expand((entry) => _certificationWidgets(entry)),
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
              style: const pw.TextStyle(fontSize: 8.2, color: _muted),
            ),
          ),
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
            _pageMargin + _sidebarWidth + _sidebarGap,
            _pageTop,
            _pageMargin,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context,
              name,
              title,
              address,
              photoBytes,
              contactItems,
              sidebarSkillNames,
            ),
          ),
        ),
        header: (context) =>
            context.pageNumber == 1 ? _headerSpacer() : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    String name,
    String title,
    String address,
    Uint8List? photoBytes,
    List<EditorialFrameContactItem> contactItems,
    List<String> skillNames,
  ) {
    return pw.Stack(
      children: [
        pw.Container(color: _paper),
        pw.Positioned(
          left: _pageMargin + _sidebarWidth,
          top: _pageTop,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1,
            child: pw.Container(color: _line),
          ),
        ),
        if (context.pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin,
            top: _pageTop,
            child: _photoFrame(photoBytes),
          ),
          pw.Positioned(
            left: _pageMargin,
            top: _pageTop + _photoHeight + 18,
            child: pw.SizedBox(
              width: _sidebarWidth - 10,
              child: _sidebarContent(contactItems, skillNames),
            ),
          ),
          pw.Positioned(
            left: _pageMargin + _sidebarWidth + _sidebarGap,
            right: _pageMargin,
            top: _pageTop,
            child: _headerBlock(name, title, address),
          ),
        ],
      ],
    );
  }

  pw.Widget _photoFrame(Uint8List? photoBytes) {
    return pw.Container(
      width: _photoWidth,
      height: _photoHeight,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 1),
      ),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: photoBytes == null ? _photoTint : null,
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
                  'PHOTO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  pw.Widget _sidebarContent(
    List<EditorialFrameContactItem> contactItems,
    List<String> skillNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sidebarSectionHeader('CONTACT'),
        ...contactItems.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(item.label),
              style: const pw.TextStyle(
                fontSize: 8.0,
                color: _muted,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _sidebarSectionHeader('EXPERTISE'),
          ...skillNames.map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                _sanitizePdfText(skill),
                style: const pw.TextStyle(fontSize: 8.0, color: _muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sidebarSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.4,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  pw.Widget _headerBlock(String name, String title, String address) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(name).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
            letterSpacing: 1.2,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(title),
              style: const pw.TextStyle(fontSize: 12, color: _muted),
            ),
          ),
        if (address.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              _sanitizePdfText(address),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
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

  pw.Widget _headerSpacer() {
    return pw.SizedBox(height: _photoHeight + 24);
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  pw.Widget _bulletLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4.2, right: 6),
            decoration: const pw.BoxDecoration(
              color: _accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(value),
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(
                fontSize: 8.7,
                color: _muted,
                lineSpacing: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Iterable<pw.Widget> _experienceWidgets(
      EditorialFrameExperienceEntry entry) sync* {
    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          textAlign: pw.TextAlign.right,
          style: const pw.TextStyle(fontSize: 8.1, color: _muted),
        ),
      ],
    );
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1.5, bottom: 2),
      child: pw.Text(
        _sanitizePdfText(entry.companyLine),
        style: pw.TextStyle(
          fontSize: 8.8,
          color: _accent,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    for (final line in entry.detailLines) {
      yield _bulletLine(line);
    }
    yield pw.SizedBox(height: 8);
  }

  Iterable<pw.Widget> _educationWidgets(
      EditorialFrameEducationEntry entry) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.degree),
      style: pw.TextStyle(
        fontSize: 8.8,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1, bottom: 6),
      child: pw.Text(
        _sanitizePdfText('${entry.institutionLine}  •  ${entry.dateLabel}'),
        style: const pw.TextStyle(fontSize: 8.1, color: _muted),
      ),
    );
  }

  Iterable<pw.Widget> _skillWidgets(String skill) sync* {
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(skill),
        style: const pw.TextStyle(fontSize: 8.2, color: _muted),
      ),
    );
  }

  Iterable<pw.Widget> _projectWidgets(EditorialFrameProjectEntry entry) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.title),
      style: pw.TextStyle(
        fontSize: 9.0,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
    for (final line in entry.detailLines) {
      yield _bulletLine(line);
    }
    for (final link in entry.links) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(
          _sanitizePdfText(link),
          style: const pw.TextStyle(
            fontSize: 8.0,
            color: _accent,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _certificationWidgets(
      EditorialFrameCertificationEntry entry) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.name),
      style: pw.TextStyle(
        fontSize: 8.3,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
    if (entry.metaLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1, bottom: 4),
        child: pw.Text(
          _sanitizePdfText(entry.metaLine),
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      );
    } else {
      yield pw.SizedBox(height: 4);
    }
  }
}
