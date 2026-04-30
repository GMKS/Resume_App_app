part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ModernEdgeResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(ModernEdgeTemplateSupport.pageHex);
  static const PdfColor _sheet =
      PdfColor.fromInt(ModernEdgeTemplateSupport.sheetHex);
  static const PdfColor _sidebarTop =
      PdfColor.fromInt(ModernEdgeTemplateSupport.sidebarTopHex);
  static const PdfColor _sidebarBottom =
      PdfColor.fromInt(ModernEdgeTemplateSupport.sidebarBottomHex);
  static const PdfColor _accent =
      PdfColor.fromInt(ModernEdgeTemplateSupport.accentHex);
  static const PdfColor _accentDark =
      PdfColor.fromInt(ModernEdgeTemplateSupport.accentDarkHex);
  static const PdfColor _accentSoft =
      PdfColor.fromInt(ModernEdgeTemplateSupport.accentSoftHex);
  static const PdfColor _line =
      PdfColor.fromInt(ModernEdgeTemplateSupport.lineHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ModernEdgeTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ModernEdgeTemplateSupport.mutedHex);
  static const PdfColor _sidebarInk =
      PdfColor.fromInt(ModernEdgeTemplateSupport.sidebarInkHex);
  static const PdfColor _sidebarMuted =
      PdfColor.fromInt(ModernEdgeTemplateSupport.sidebarMutedHex);

  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 22;
  static const double _sidebarWidth = 154;
  static const double _contentGap = 18;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
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

    final name = ModernEdgeTemplateSupport.displayName(resume);
    final title = ModernEdgeTemplateSupport.displayTitle(resume);
    final sidebarContacts = ModernEdgeTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ModernEdgeTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    final experienceEntries = ModernEdgeTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );
    final projectEntries = ModernEdgeTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final skillNames = ModernEdgeTemplateSupport.skillNames(resume.skills);
    final educationEntries = ModernEdgeTemplateSupport.educationEntries(
      resume.education,
      maxItems: null,
      yearOnly: true,
    );
    final certificationEntries = ModernEdgeTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = ModernEdgeTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    final sections = <String, List<pw.Widget>>{};

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: _bulletLine(line),
          ),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = _experienceSectionWidgets(experienceEntries);
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = _projectSectionWidgets(projectEntries);
    }

    if (certificationEntries.isNotEmpty) {
      sections['certifications'] =
          _certificationSectionWidgets(certificationEntries);
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: languageLines.map(_languageChip).toList(growable: false),
        ),
      ];
    }

    for (final section in orderedUserCustomSections(resume).where(
      (section) => section.items.isNotEmpty,
    )) {
      sections[section.id] = _userCustomSectionWidgets(section);
    }

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
              sidebarContacts: sidebarContacts,
              skillNames: skillNames,
              educationEntries: educationEntries,
              name: name,
            ),
          ),
        ),
        build: (context) => [
          _header(name, title),
          pw.SizedBox(height: 10),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _background({
    required int pageNumber,
    required Uint8List? photoBytes,
    required List<ModernEdgeContactItem> sidebarContacts,
    required List<String> skillNames,
    required List<ModernEdgeEducationEntry> educationEntries,
    required String name,
  }) {
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
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
          ),
        ),
        pw.Positioned(
          left: _pageMargin - 4,
          top: _pageTop - 4,
          bottom: _pageBottom - 4,
          child: pw.Container(
            width: _sidebarWidth,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
                colors: [_sidebarTop, _sidebarBottom],
              ),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                bottomLeft: pw.Radius.circular(10),
              ),
            ),
            padding: const pw.EdgeInsets.fromLTRB(14, 18, 14, 18),
            child: pageNumber == 1
                ? _sidebar(
                    photoBytes: photoBytes,
                    sidebarContacts: sidebarContacts,
                    skillNames: skillNames,
                    educationEntries: educationEntries,
                    name: name,
                  )
                : pw.SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  pw.Widget _sidebar({
    required Uint8List? photoBytes,
    required List<ModernEdgeContactItem> sidebarContacts,
    required List<String> skillNames,
    required List<ModernEdgeEducationEntry> educationEntries,
    required String name,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Container(
            width: 78,
            height: 78,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: photoBytes == null ? PdfColors.white : null,
              border: pw.Border.all(color: PdfColors.white, width: 2),
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
                      _initials(name),
                      style: pw.TextStyle(
                        fontSize: 20,
                        color: _accent,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        pw.SizedBox(height: 16),
        _sidebarSection('CONTACT'),
        ...sidebarContacts.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _sanitizePdfText(item.label),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _sidebarMuted,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sidebarSection('SKILLS'),
          pw.Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skillNames.map(_skillChip).toList(growable: false),
          ),
        ],
        if (educationEntries.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sidebarSection('EDUCATION'),
          ...educationEntries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(entry.degreeLine),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: _sidebarInk,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 7.8,
                      color: _sidebarMuted,
                      lineSpacing: 1.15,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(entry.dateRange),
                    style: const pw.TextStyle(
                      fontSize: 7.6,
                      color: _sidebarMuted,
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

  pw.Widget _header(
    String name,
    String title,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(name),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        if (title.trim().isNotEmpty)
          pw.Text(
            _sanitizePdfText(title),
            style: pw.TextStyle(
              fontSize: 11,
              color: _accentDark,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
      ],
    );
  }

  pw.Widget _sidebarSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9.2,
              color: _sidebarInk,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.Container(
            height: 1,
            color: const PdfColor(1, 1, 1, 0.35),
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10.4,
              color: _accent,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.02,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(height: 1, color: _line),
          ),
        ],
      ),
    );
  }

  pw.Widget _skillChip(String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(
          color: const PdfColor(1, 1, 1, 0.6),
          width: 0.5,
        ),
      ),
      child: pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(
          fontSize: 7.8,
          color: _accentDark,
        ),
      ),
    );
  }

  pw.Widget _languageChip(String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: _accentSoft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(fontSize: 8, color: _accentDark),
      ),
    );
  }

  pw.Widget _bulletLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Container(
            width: 4,
            height: 4,
            decoration: const pw.BoxDecoration(
              color: _accentDark,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
              lineSpacing: 1.28,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _experienceSectionWidgets(
    List<ModernEdgeExperienceEntry> entries,
  ) {
    final widgets = <pw.Widget>[];
    for (var index = 0; index < entries.length; index++) {
      widgets.addAll(
        _experienceEntryWidgets(
          entries[index],
          includeSectionHeader: index == 0,
        ),
      );
    }
    return widgets;
  }

  List<pw.Widget> _experienceEntryWidgets(
    ModernEdgeExperienceEntry entry, {
    required bool includeSectionHeader,
  }) {
    final widgets = <pw.Widget>[];
    widgets.add(
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (includeSectionHeader) _sectionHeader('EXPERIENCE'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    _sanitizePdfText(entry.title),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(fontSize: 7.8, color: _muted),
                ),
              ],
            ),
            pw.Text(
              _sanitizePdfText(entry.companyLine),
              style: pw.TextStyle(
                fontSize: 8.5,
                color: _accentDark,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 3),
          ],
        ),
      ),
    );
    widgets.addAll(
      entry.detailLines.map(
        (line) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: _bulletLine(line),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));
    return widgets;
  }

  List<pw.Widget> _projectSectionWidgets(List<ModernEdgeProjectEntry> entries) {
    final widgets = <pw.Widget>[];
    for (var index = 0; index < entries.length; index++) {
      widgets.addAll(
        _projectEntryWidgets(
          entries[index],
          includeSectionHeader: index == 0,
        ),
      );
    }
    return widgets;
  }

  List<pw.Widget> _projectEntryWidgets(
    ModernEdgeProjectEntry entry, {
    required bool includeSectionHeader,
  }) {
    final widgets = <pw.Widget>[];
    widgets.add(
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (includeSectionHeader) _sectionHeader('PROJECTS'),
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
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _sanitizePdfText(entry.technologyLine),
                  style: const pw.TextStyle(fontSize: 8, color: _accentDark),
                ),
              ),
            if (entry.detailLines.isNotEmpty || entry.links.isNotEmpty)
              pw.SizedBox(height: 3),
          ],
        ),
      ),
    );
    widgets.addAll(
      entry.detailLines.map(
        (line) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: _bulletLine(line),
        ),
      ),
    );
    widgets.addAll(
      entry.links.map(
        (link) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
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
    );
    widgets.add(pw.SizedBox(height: 8));
    return widgets;
  }

  List<pw.Widget> _certificationSectionWidgets(
    List<ModernEdgeCertificationEntry> entries,
  ) {
    final widgets = <pw.Widget>[];
    for (var index = 0; index < entries.length; index++) {
      widgets.addAll(
        _certificationEntryWidgets(
          entries[index],
          includeSectionHeader: index == 0,
        ),
      );
    }
    return widgets;
  }

  List<pw.Widget> _certificationEntryWidgets(
    ModernEdgeCertificationEntry entry, {
    required bool includeSectionHeader,
  }) {
    final widgets = <pw.Widget>[];
    widgets.add(
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (includeSectionHeader) _sectionHeader('CERTIFICATIONS'),
            pw.Text(
              _sanitizePdfText(entry.name),
              style: pw.TextStyle(
                fontSize: 8.8,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (entry.metaLine.isNotEmpty)
              pw.Text(
                _sanitizePdfText(entry.metaLine),
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _muted,
                  lineSpacing: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
    widgets.addAll(
      entry.links.map(
        (link) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(
            _sanitizePdfText(link),
            style: pw.TextStyle(
              fontSize: 7.8,
              color: _accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    return widgets;
  }

  List<pw.Widget> _userCustomSectionWidgets(CustomSection section) {
    final normalizedTitle = normalizeUserCustomSectionTitle(section.title);
    final title = normalizedTitle.isEmpty ? 'CUSTOM SECTION' : normalizedTitle;
    final widgets = <pw.Widget>[];

    for (var index = 0; index < section.items.length; index++) {
      final displayItem = buildUserCustomSectionDisplayItem(section.items[index]);
      if (!displayItem.hasContent) {
        continue;
      }

      final metaParts = <String>[
        if (displayItem.subtitle.isNotEmpty)
          _sanitizePdfText(displayItem.subtitle),
        if (displayItem.date != null)
          DateFormat('MMM yyyy').format(displayItem.date!),
      ];

      widgets.add(
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (index == 0) _sectionHeader(title.toUpperCase()),
              if (displayItem.heading.isNotEmpty)
                pw.Text(
                  _sanitizePdfText(displayItem.heading),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              if (metaParts.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
                  child: pw.Text(
                    metaParts.join('  |  '),
                    style: const pw.TextStyle(
                      fontSize: 8.2,
                      color: _muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      widgets.addAll(
        displayItem.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4.5,
                  height: 4.5,
                  margin: const pw.EdgeInsets.only(top: 3.2, right: 6),
                  decoration: const pw.BoxDecoration(
                    color: _accent,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    _sanitizePdfText(line),
                    style: const pw.TextStyle(
                      fontSize: 8.9,
                      color: PdfColor.fromInt(0xFF374151),
                      lineSpacing: 1.28,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));
    }

    if (widgets.isEmpty) {
      return [
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionHeader(title.toUpperCase()),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  _sanitizePdfText('No content added yet.'),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
        ),
      ];
    }

    return widgets;
  }

  pw.Widget _experienceBlock(ModernEdgeExperienceEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(entry.title),
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              _sanitizePdfText(entry.dateRange),
              style: const pw.TextStyle(fontSize: 7.8, color: _muted),
            ),
          ],
        ),
        pw.Text(
          _sanitizePdfText(entry.companyLine),
          style: pw.TextStyle(
            fontSize: 8.5,
            color: _accentDark,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: _bulletLine(line),
          ),
        ),
      ],
    );
  }

  pw.Widget _projectBlock(ModernEdgeProjectEntry entry) {
    return pw.Column(
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
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(entry.technologyLine),
              style: const pw.TextStyle(fontSize: 8, color: _accentDark),
            ),
          ),
        if (entry.detailLines.isNotEmpty) pw.SizedBox(height: 3),
        ...entry.detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: _bulletLine(line),
          ),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
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
    );
  }

  pw.Widget _certificationBlock(ModernEdgeCertificationEntry entry) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(entry.name),
          style: pw.TextStyle(
            fontSize: 8.8,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (entry.metaLine.isNotEmpty)
          pw.Text(
            _sanitizePdfText(entry.metaLine),
            style: const pw.TextStyle(
              fontSize: 8,
              color: _muted,
              lineSpacing: 1.2,
            ),
          ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(link),
              style: pw.TextStyle(
                fontSize: 7.8,
                color: _accent,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .toList(growable: false);
    return parts.isEmpty ? 'ME' : parts.join();
  }
}
