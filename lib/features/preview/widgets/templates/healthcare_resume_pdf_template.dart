part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class HealthcareResumePdfTemplate extends PdfTemplate {
  static const PdfColor _page =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.pageHex);
  static const PdfColor _paper =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.paperHex);
  static const PdfColor _sidebar =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.sidebarHex);
  static const PdfColor _heading =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.headingHex);
  static const PdfColor _accent =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.mutedHex);
  static const PdfColor _sidebarText =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.sidebarTextHex);
  static const PdfColor _line =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.lineHex);
  static const PdfColor _avatarFill =
      PdfColor.fromInt(HealthcareResumeTemplateSupport.avatarFillHex);

  static const double _pageMargin = 24;
  static const double _pageTop = 24;
  static const double _pageBottom = 24;
  static const double _sidebarWidth = 150;
  static const double _contentGap = 20;
  static const double _headerSpacer = 86;
  static const double _avatarSize = 70;
  static const int _maxSidebarSkillItems = 10;
  static const int _maxSidebarCertificationItems = 6;
  static const int _maxSidebarLanguageItems = 4;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    final normalizedResume =
        HealthcareResumeTemplateSupport.normalizeResume(resume) ?? resume;
    final name = HealthcareResumeTemplateSupport.displayName(normalizedResume);
    final title = HealthcareResumeTemplateSupport.displayTitle(normalizedResume)
        .toUpperCase();
    final address =
        HealthcareResumeTemplateSupport.address(normalizedResume.personalInfo);
    final contactItems = HealthcareResumeTemplateSupport.contactItems(
      normalizedResume.personalInfo,
      compactLinks: true,
      includeAddress: false,
    );
    final summaryLines = HealthcareResumeTemplateSupport.summaryLines(
      normalizedResume.objective,
      maxItems: null,
    );
    final skillNames = HealthcareResumeTemplateSupport.skillNames(
      normalizedResume.skills,
      customSections: normalizedResume.customSections,
      maxItems: null,
    );
    final certificationEntries =
        HealthcareResumeTemplateSupport.certificationEntries(
      normalizedResume.certifications,
      customSections: normalizedResume.customSections,
      maxItems: null,
      compactLinks: true,
    );
    final languageLines = HealthcareResumeTemplateSupport.languageLines(
      normalizedResume.languages,
      maxItems: null,
    );
    final projectEntries = HealthcareResumeTemplateSupport.projectEntries(
      normalizedResume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    final experienceEntries = HealthcareResumeTemplateSupport.experienceEntries(
      normalizedResume.experience,
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );
    final educationEntries = HealthcareResumeTemplateSupport.educationEntries(
      normalizedResume.education,
      maxItems: null,
      yearOnly: true,
    );
    final allBodyCustomSections =
        HealthcareResumeTemplateSupport.bodyCustomSections(
      normalizedResume.customSections,
      maxSections: null,
      maxItemsPerSection: null,
    );
    final sidebarCustomSections = normalizedResume.customSections
      .where(HealthcareResumeTemplateSupport.isSidebarCustomSection)
      .where(
        (section) =>
          HealthcareResumeTemplateSupport.customSectionLines(section)
            .isNotEmpty,
      )
      .toList(growable: false);
    final sidebarCustomSectionIds = sidebarCustomSections
      .map((section) => section.id)
      .toSet();
    final bodyCustomSections = allBodyCustomSections
      .where((section) => !sidebarCustomSectionIds.contains(section.id))
      .toList(growable: false);
    final references = normalizedResume.references;
    final photoBytes =
        (normalizedResume.personalInfo.profileImage?.isNotEmpty ?? false)
            ? base64Decode(normalizedResume.personalInfo.profileImage!)
            : null;

    final sidebarSkillNames =
        skillNames.take(_maxSidebarSkillItems).toList(growable: false);
    final overflowSkillNames =
        skillNames.skip(sidebarSkillNames.length).toList(growable: false);
    final sidebarCertificationEntries = certificationEntries
        .take(_maxSidebarCertificationItems)
        .toList(growable: false);
    final overflowCertificationEntries = certificationEntries
        .skip(sidebarCertificationEntries.length)
        .toList(growable: false);

    final sections = <String, List<pw.Widget>>{};
    final orderedKeys = <String>['summary', 'experience', 'education', 'projects'];

    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('ABOUT ME'),
        ...summaryLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: _chevronLine(line),
          ),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (experienceEntries.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...experienceEntries.expand(_experienceWidgets),
      ];
    }

    if (educationEntries.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...educationEntries.expand(_educationWidgets),
      ];
    }

    if (projectEntries.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...projectEntries.expand(_projectWidgets),
      ];
    }

    if (languageLines.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...languageLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
            ),
          ),
        ),
      ];
      orderedKeys.add('languages');
    }

    if (overflowSkillNames.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        ...overflowSkillNames.map(
          (skill) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              _sanitizePdfText(skill),
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
            ),
          ),
        ),
      ];
      orderedKeys.add('skills');
    }

    if (overflowCertificationEntries.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...overflowCertificationEntries.expand(_certificationWidgets),
      ];
      orderedKeys.add('certifications');
    }

    for (final section in bodyCustomSections) {
      sections[section.id] = [
        _sectionHeader(section.title.toUpperCase()),
        ...section.lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: _detailBulletLine(line),
          ),
        ),
        pw.SizedBox(height: 6),
      ];
      orderedKeys.add(section.id);
    }

    if (references.isNotEmpty) {
      sections['references'] = [
        _sectionHeader('REFERENCES'),
        ...references.take(3).expand(_referenceWidgets),
      ];
      orderedKeys.add('references');
    }

    final sectionOrder = await _loadPdfSectionOrderForKeys(
      normalizedResume,
      defaultOrder: orderedKeys,
      allowedKeys: orderedKeys,
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
              name: name,
              title: title,
              address: address,
              contactItems: contactItems,
              sidebarSkillNames: sidebarSkillNames,
              sidebarCertificationEntries: sidebarCertificationEntries,
              sidebarLanguageLines: const <String>[],
              sidebarCustomSections: sidebarCustomSections,
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox(height: _headerSpacer)
            : pw.SizedBox.shrink(),
        build: (context) => _applyPdfSectionOrder(sectionOrder, sections),
      ),
    );

    return pdf;
  }

  pw.Widget _background({
    required int pageNumber,
    required Uint8List? photoBytes,
    required String name,
    required String title,
    required String address,
    required List<HealthcareResumeContactItem> contactItems,
    required List<String> sidebarSkillNames,
    required List<HealthcareResumeCertificationEntry>
        sidebarCertificationEntries,
    required List<String> sidebarLanguageLines,
    required List<CustomSection> sidebarCustomSections,
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
              color: _paper,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
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
        pw.Positioned(
          left: _pageMargin + _sidebarWidth + (_contentGap / 2),
          top: _pageTop,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1,
            child: pw.Container(color: _line),
          ),
        ),
        if (pageNumber == 1) ...[
          pw.Positioned(
            left: _pageMargin + ((_sidebarWidth - _avatarSize) / 2),
            top: _pageTop + 10,
            child: _avatar(photoBytes),
          ),
          pw.Positioned(
            left: _pageMargin + 10,
            top: _pageTop + 90,
            child: pw.SizedBox(
              width: _sidebarWidth - 20,
              child: _sidebarContent(
                contactItems,
                sidebarSkillNames,
                sidebarCertificationEntries,
                sidebarLanguageLines,
                sidebarCustomSections,
              ),
            ),
          ),
          pw.Positioned(
            left: _pageMargin + _sidebarWidth + _contentGap,
            right: _pageMargin,
            top: _pageTop + 8,
            child: _header(name, title, address),
          ),
        ],
      ],
    );
  }

  pw.Widget _avatar(Uint8List? photoBytes) {
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
              child: pw.SizedBox(
                width: 24,
                height: 24,
                child: pw.CustomPaint(
                  size: const PdfPoint(24, 24),
                  painter: (canvas, size) {
                    canvas.setFillColor(_accent);
                    canvas.drawEllipse(size.x / 2, 6, 4, 4);
                    canvas.fillPath();
                    canvas.drawEllipse(size.x / 2, 17, 8, 5);
                    canvas.fillPath();
                  },
                ),
              ),
            )
          : null,
    );
  }

  pw.Widget _sidebarContent(
    List<HealthcareResumeContactItem> contactItems,
    List<String> skillNames,
    List<HealthcareResumeCertificationEntry> certifications,
    List<String> languageLines,
    List<CustomSection> sidebarCustomSections,
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
                fontSize: 7.7,
                color: _sidebarText,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (skillNames.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('SKILLS'),
          ...skillNames.map(_sidebarBulletRow),
        ],
        if (certifications.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          _sidebarHeader('CERTIFICATIONS'),
          ...certifications.expand(_sidebarCertificationWidgets),
        ],
        if (sidebarCustomSections.isNotEmpty) ...[
          ...sidebarCustomSections.expand((section) {
            final lines = HealthcareResumeTemplateSupport.customSectionLines(
              section,
              maxItems: 3,
            );
            if (lines.isEmpty) {
              return const <pw.Widget>[];
            }
            return [
              pw.SizedBox(height: 9),
              _sidebarHeader(section.title.toUpperCase()),
              ...lines.map(_sidebarBulletRow),
            ];
          }),
        ],
      ],
    );
  }

  pw.Widget _sidebarHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8.8,
                color: _heading,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.9,
              ),
            ),
          ),
          pw.Container(width: 1.2, height: 8, color: _accent),
        ],
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
            margin: const pw.EdgeInsets.only(top: 4.2, right: 5),
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(name),
          style: pw.TextStyle(
            fontSize: 24,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          _sanitizePdfText(title),
          style: pw.TextStyle(
            fontSize: 10,
            color: _accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (address.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(address),
              style: const pw.TextStyle(
                fontSize: 8.2,
                color: _muted,
              ),
            ),
          ),
        pw.Container(
          height: 1,
          color: _line,
          margin: const pw.EdgeInsets.only(top: 8),
        ),
      ],
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
              letterSpacing: 0.9,
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

  pw.Widget _chevronLine(String line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, right: 6),
          child: pw.SizedBox(
            width: 7,
            height: 8,
            child: pw.CustomPaint(
              size: const PdfPoint(7, 8),
              painter: (canvas, size) {
                canvas.setStrokeColor(_accent);
                canvas.setLineWidth(1.2);
                canvas.moveTo(1, 1);
                canvas.lineTo(size.x - 1, size.y / 2);
                canvas.lineTo(1, size.y - 1);
                canvas.strokePath();
              },
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(line),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
              lineSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _detailBulletLine(String line) {
    return pw.Row(
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
            _sanitizePdfText(line),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 8.3,
              color: _muted,
              lineSpacing: 1.24,
            ),
          ),
        ),
      ],
    );
  }

  Iterable<pw.Widget> _projectWidgets(
    HealthcareResumeProjectEntry entry,
  ) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.title),
      style: pw.TextStyle(
        fontSize: 9.0,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    if (entry.technologyLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
        child: pw.Text(
          _sanitizePdfText(entry.technologyLine),
          style: const pw.TextStyle(fontSize: 7.8, color: _accent),
        ),
      );
    }
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: _detailBulletLine(line),
      );
    }
    for (final link in entry.links) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          _sanitizePdfText(link),
          style: pw.TextStyle(
            fontSize: 8.0,
            color: _accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _experienceWidgets(
    HealthcareResumeExperienceEntry entry,
  ) sync* {
    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      ],
    );
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
      child: pw.Text(
        _sanitizePdfText(entry.companyLine),
        style: pw.TextStyle(
          fontSize: 8.3,
          color: _accent,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: _detailBulletLine(line),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _educationWidgets(
    HealthcareResumeEducationEntry entry,
  ) sync* {
    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitizePdfText(entry.degreeLine),
                style: pw.TextStyle(
                  fontSize: 9.0,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _sanitizePdfText(entry.institutionLine),
                style: const pw.TextStyle(fontSize: 8.1, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          _sanitizePdfText(entry.dateRange),
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      ],
    );
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _certificationWidgets(
    HealthcareResumeCertificationEntry entry,
  ) sync* {
    yield pw.Text(
      _sanitizePdfText(entry.name),
      style: pw.TextStyle(
        fontSize: 8.9,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(line),
          style: const pw.TextStyle(
            fontSize: 7.8,
            color: _muted,
            lineSpacing: 1.2,
          ),
        ),
      );
    }
    for (final link in entry.links) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(link),
          style: pw.TextStyle(
            fontSize: 7.8,
            color: _accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }

  Iterable<pw.Widget> _sidebarCertificationWidgets(
    HealthcareResumeCertificationEntry entry,
  ) sync* {
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        _sanitizePdfText(entry.name),
        style: pw.TextStyle(
          fontSize: 7.5,
          color: _sidebarText,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    for (final line in entry.detailLines) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          _sanitizePdfText(line),
          style: const pw.TextStyle(fontSize: 7.2, color: _sidebarText),
        ),
      );
    }
  }

  Iterable<pw.Widget> _referenceWidgets(Reference reference) sync* {
    final roleLine = [
      reference.position.trim(),
      reference.company.trim(),
    ].where((part) => part.isNotEmpty).join('  |  ');
    final contactLine = [
      reference.email.trim(),
      reference.phone.trim(),
    ].where((part) => part.isNotEmpty).join('  |  ');

    yield pw.Text(
      _sanitizePdfText(reference.name),
      style: pw.TextStyle(
        fontSize: 8.9,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    if (roleLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(roleLine),
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      );
    }
    if (contactLine.isNotEmpty) {
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text(
          _sanitizePdfText(contactLine),
          style: const pw.TextStyle(fontSize: 7.6, color: _muted),
        ),
      );
    }
    yield pw.SizedBox(height: 6);
  }
}
