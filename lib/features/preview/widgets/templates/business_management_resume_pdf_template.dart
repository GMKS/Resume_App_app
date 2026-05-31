part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class BusinessManagementResumePdfTemplate extends PdfTemplate {
  static const PdfColor _executiveAccent = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _darkBase = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFFCFCFD);
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _divider = PdfColor.fromInt(0xFFD7DEE8);
  static const PdfColor _headerTitle = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _panelBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _railBg = PdfColor.fromInt(0xFFF5F1EA);

  static const double _pageMargin = 22;
  static const double _pageTop = 22;
  static const double _pageBottom = 24;
  static const _mainSectionOrder = <String>['experience', 'projects'];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();

    final pdf = _buildDocument();
    final normalizedResume = resume.templateId == 'executive'
        ? resume.copyWith(
            customSections: ensureProfessionalRoleSections(resume),
          )
        : resume;
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      normalizedResume,
      defaultOrder: _mainSectionOrder,
      allowedKeys: _mainSectionOrder,
    );

    final resolvedAccent = _executiveAccent;
    final headerBg = _blend(resolvedAccent, _darkBase, 0.78);
    final accentWash = _blend(resolvedAccent, PdfColors.white, 0.82);
    final strongAccent = _blend(resolvedAccent, _darkBase, 0.22);

    final summaryLines = _summaryLines(normalizedResume);
    final executiveHighlights = _executiveHighlights(normalizedResume);
    final experiences = _experienceEntries(normalizedResume);
    final projects = _projectEntries(normalizedResume);
    final skills = _skillNames(normalizedResume);
    final educationEntries = _educationEntries(normalizedResume);
    final certifications = _certificationLines(normalizedResume);
    final languages = _languageLines(normalizedResume);
    final focusItems = skills.take(4).toList(growable: false);
    final featuredExperiences = experiences.take(1).toList(growable: false);
    final remainingExperiences =
        experiences.skip(featuredExperiences.length).toList(growable: false);
    final remainingProjects = projects;
    final railSkills = skills.take(5).toList(growable: false);
    final remainingSkills =
        skills.skip(railSkills.length).toList(growable: false);
    final primaryEducation =
        educationEntries.isNotEmpty ? educationEntries.first : null;
    final remainingEducation = educationEntries
        .skip(primaryEducation == null ? 0 : 1)
        .toList(growable: false);
    final railCertifications = certifications.take(2).toList(growable: false);
    final remainingCertifications =
        certifications.skip(railCertifications.length).toList(growable: false);
    final railLanguages = languages.take(2).toList(growable: false);
    final remainingLanguages =
        languages.skip(railLanguages.length).toList(growable: false);

    final customSections = <pw.Widget>[];
    for (final section in orderedUserCustomSections(normalizedResume)) {
      final widgets = _customSectionWidgets(
        section,
        accentColor: resolvedAccent,
        strongAccent: strongAccent,
      );
      if (widgets.isNotEmpty) {
        customSections.addAll(widgets);
      }
    }

    final executivePageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(
        _pageMargin,
        _pageTop,
        _pageMargin,
        _pageBottom,
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: _background(),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: executivePageTheme,
        build: (context) => _buildExecutiveFirstPage(
          normalizedResume,
          sectionOrder: sectionOrder,
          accentColor: resolvedAccent,
          headerBg: headerBg,
          accentWash: accentWash,
          strongAccent: strongAccent,
          summaryLines: summaryLines,
          focusItems: focusItems,
          executiveHighlights: executiveHighlights,
          featuredExperiences: featuredExperiences,
          railSkills: railSkills,
          primaryEducation: primaryEducation,
          railCertifications: railCertifications,
          railLanguages: railLanguages,
        ),
      ),
    );

    final continuationWidgets = _buildContinuationWidgets(
      normalizedResume,
      sectionOrder: sectionOrder,
      accentColor: resolvedAccent,
      headerBg: headerBg,
      accentWash: accentWash,
      strongAccent: strongAccent,
      remainingExperiences: remainingExperiences,
      remainingProjects: remainingProjects,
      remainingSkills: remainingSkills,
      remainingEducation: remainingEducation,
      remainingCertifications: remainingCertifications,
      remainingLanguages: remainingLanguages,
      customSections: customSections,
    );

    if (continuationWidgets.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: executivePageTheme,
          build: (context) => continuationWidgets,
        ),
      );
    }

    return pdf;
  }

  pw.Widget _background() {
    return pw.Container(color: PdfColors.white);
  }

  pw.Widget _heroShell({
    required PdfColor headerBg,
    required pw.Widget child,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: pw.BoxDecoration(
        color: headerBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
      ),
      child: child,
    );
  }

  pw.Widget _heroHeader(
    ResumeModel resume, {
    required PdfColor headerBg,
    required PdfColor accentWash,
    required PdfColor strongAccent,
    required List<String> summaryLines,
    required List<String> focusItems,
  }) {
    final name = _displayName(resume);
    final title = _displayTitle(resume);
    final contactItems = _contactItems(resume);
    return _heroShell(
      headerBg: headerBg,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if (title.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              maxLines: 2,
              style: pw.TextStyle(
                fontSize: 11.2,
                fontWeight: pw.FontWeight.bold,
                color: _headerTitle,
              ),
            ),
          ],
          if (contactItems.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildHeaderContactGrid(
              contactItems,
              accentWash: accentWash,
            ),
          ],
          if (summaryLines.isNotEmpty || focusItems.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _heroSummaryPanel(
              summaryLines: summaryLines.take(3).toList(growable: false),
              focusItems: focusItems,
              panelBg: _blend(headerBg, PdfColors.white, 0.08),
              panelBorder: _blend(headerBg, PdfColors.white, 0.14),
              accentWash: accentWash,
              strongAccent: strongAccent,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveFirstPage(
    ResumeModel resume, {
    required List<String> sectionOrder,
    required PdfColor accentColor,
    required PdfColor headerBg,
    required PdfColor accentWash,
    required PdfColor strongAccent,
    required List<String> summaryLines,
    required List<String> focusItems,
    required List<String> executiveHighlights,
    required List<_BusinessManagementPdfExperienceEntry> featuredExperiences,
    required List<String> railSkills,
    required _BusinessManagementPdfEducationEntry? primaryEducation,
    required List<String> railCertifications,
    required List<String> railLanguages,
  }) {
    final firstPageMainSections = <String, List<pw.Widget>>{};

    if (featuredExperiences.isNotEmpty) {
      firstPageMainSections['experience'] = [
        _sectionHeader(
          'Executive Experience',
          eyebrow: 'CAREER TRACK',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...featuredExperiences.map(
          (entry) => _experienceBlock(
            entry,
            strongAccent: strongAccent,
          ),
        ),
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: 248,
          child: _heroHeader(
            resume,
            headerBg: headerBg,
            accentWash: accentWash,
            strongAccent: strongAccent,
            summaryLines: summaryLines,
            focusItems: focusItems,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.SizedBox(
          height: 500,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 340,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (executiveHighlights.isNotEmpty) ...[
                        _sectionHeader(
                          'Key Executive Wins',
                          eyebrow: 'BOARD BRIEF',
                          accentColor: accentColor,
                          strongAccent: strongAccent,
                        ),
                        ...executiveHighlights.asMap().entries.map(
                              (entry) => _executiveHighlightTile(
                                entry.key,
                                entry.value,
                                accentColor: accentColor,
                                strongAccent: strongAccent,
                              ),
                            ),
                      ],
                      ..._applyPdfSectionOrder(
                          sectionOrder, firstPageMainSections),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(
                width: 190,
                child: _rightRail(
                  accentColor: accentColor,
                  accentWash: accentWash,
                  strongAccent: strongAccent,
                  railSkills: railSkills,
                  primaryEducation: primaryEducation,
                  railCertifications: railCertifications,
                  railLanguages: railLanguages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildContinuationWidgets(
    ResumeModel resume, {
    required List<String> sectionOrder,
    required PdfColor accentColor,
    required PdfColor headerBg,
    required PdfColor accentWash,
    required PdfColor strongAccent,
    required List<_BusinessManagementPdfExperienceEntry> remainingExperiences,
    required List<_BusinessManagementPdfProjectEntry> remainingProjects,
    required List<String> remainingSkills,
    required List<_BusinessManagementPdfEducationEntry> remainingEducation,
    required List<String> remainingCertifications,
    required List<String> remainingLanguages,
    required List<pw.Widget> customSections,
  }) {
    final continuationSections = <String, List<pw.Widget>>{};

    if (remainingExperiences.isNotEmpty) {
      continuationSections['experience'] = [
        _sectionHeader(
          'Executive Experience',
          eyebrow: 'CAREER TRACK',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...remainingExperiences.map(
          (entry) => _experienceBlock(
            entry,
            strongAccent: strongAccent,
          ),
        ),
      ];
    }

    if (remainingProjects.isNotEmpty) {
      continuationSections['projects'] = [
        _sectionHeader(
          'Selected Initiatives',
          eyebrow: 'STRATEGIC DELIVERY',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...remainingProjects.map(_projectBlock),
      ];
    }

    final widgets = <pw.Widget>[
      pw.Text(
        '${_displayName(resume)}  |  Executive Resume',
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: strongAccent,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 0.9, color: _divider),
      pw.SizedBox(height: 12),
      ..._applyPdfSectionOrder(sectionOrder, continuationSections),
      if (remainingSkills.isNotEmpty) ...[
        _sectionHeader(
          'Strategic Competencies',
          eyebrow: 'CORE STRENGTHS',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: remainingSkills
              .map((skill) => _skillChip(skill, accentColor, width: 168))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 8),
      ],
      if (remainingEducation.isNotEmpty) ...[
        _sectionHeader(
          'Education',
          eyebrow: 'ACADEMIC BACKGROUND',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...remainingEducation.map(
          (entry) => _plainEducationBlock(
            entry,
            strongAccent: strongAccent,
          ),
        ),
      ],
      if (remainingCertifications.isNotEmpty) ...[
        _sectionHeader(
          'Certifications',
          eyebrow: 'CREDENTIALS',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...remainingCertifications.map(_plainBulletBlock),
      ],
      if (remainingLanguages.isNotEmpty) ...[
        _sectionHeader(
          'Languages',
          eyebrow: 'COMMUNICATION',
          accentColor: accentColor,
          strongAccent: strongAccent,
        ),
        ...remainingLanguages.map(_plainBulletBlock),
      ],
      ...customSections,
    ];

    return widgets;
  }

  pw.Widget _buildHeaderContactGrid(
    List<_BusinessManagementPdfContactItem> contactItems, {
    required PdfColor accentWash,
  }) {
    final rows = _chunk(contactItems, 2);

    return pw.Column(
      children: rows
          .asMap()
          .entries
          .map(
            (entry) => pw.Padding(
              padding: pw.EdgeInsets.only(top: entry.key == 0 ? 0 : 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < entry.value.length; index++) ...[
                    pw.SizedBox(
                      width: 240,
                      child: _contactCard(
                        entry.value[index],
                        accentWash: accentWash,
                      ),
                    ),
                    if (index != entry.value.length - 1) pw.SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  pw.Widget _rightRail({
    required PdfColor accentColor,
    required PdfColor accentWash,
    required PdfColor strongAccent,
    required List<String> railSkills,
    required _BusinessManagementPdfEducationEntry? primaryEducation,
    required List<String> railCertifications,
    required List<String> railLanguages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: pw.BoxDecoration(
        color: _railBg,
        border: pw.Border.all(color: accentWash, width: 0.85),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (railSkills.isNotEmpty) ...[
            _railSectionTitle('STRATEGIC COMPETENCIES', strongAccent),
            ...railSkills.map(
              (skill) => _skillChip(skill, accentColor, width: 160),
            ),
          ],
          if (primaryEducation != null) ...[
            pw.SizedBox(height: 6),
            _railSectionTitle('EDUCATION', strongAccent),
            pw.Text(
              primaryEducation.degree,
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              primaryEducation.institution,
              style: const pw.TextStyle(
                fontSize: 7.9,
                color: _muted,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              primaryEducation.dateRange,
              style: pw.TextStyle(
                fontSize: 7.6,
                fontWeight: pw.FontWeight.bold,
                color: strongAccent,
              ),
            ),
          ],
          if (railCertifications.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _railSectionTitle('CERTIFICATIONS', strongAccent),
            ...railCertifications.map(
              (certification) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  certification,
                  style: const pw.TextStyle(
                    fontSize: 7.8,
                    color: _muted,
                    lineSpacing: 1.3,
                  ),
                ),
              ),
            ),
          ],
          if (railLanguages.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _railSectionTitle('LANGUAGES', strongAccent),
            ...railLanguages.map(
              (language) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  language,
                  style: const pw.TextStyle(
                    fontSize: 7.8,
                    color: _muted,
                    lineSpacing: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _summaryParagraph(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(
          fontSize: 9,
          color: _muted,
          lineSpacing: 1.45,
        ),
      ),
    );
  }

  pw.Widget _plainSectionHeader(
    String title, {
    String? eyebrow,
    required PdfColor strongAccent,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if ((eyebrow ?? '').isNotEmpty) ...[
            pw.Text(
              eyebrow!,
              style: pw.TextStyle(
                fontSize: 6.9,
                fontWeight: pw.FontWeight.bold,
                color: strongAccent,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 3),
          ],
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 12.5,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(height: 0.8, color: _divider),
        ],
      ),
    );
  }

  pw.Widget _plainBulletBlock(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        '- ${_sanitizePdfText(line)}',
        style: const pw.TextStyle(
          fontSize: 8.8,
          color: _muted,
          lineSpacing: 1.4,
        ),
      ),
    );
  }

  pw.Widget _plainEducationBlock(
    _BusinessManagementPdfEducationEntry entry, {
    required PdfColor strongAccent,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            entry.degree,
            style: const pw.TextStyle(fontSize: 9.6, color: _ink),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            entry.institution,
            style: const pw.TextStyle(fontSize: 8.4, color: _muted),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            entry.dateRange,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: strongAccent,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _contactCard(
    _BusinessManagementPdfContactItem item, {
    required PdfColor accentWash,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: pw.BoxDecoration(
        color: _blend(_darkBase, PdfColors.white, 0.15),
        border: pw.Border.all(
          color: _blend(_darkBase, PdfColors.white, 0.2),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _contactCaption(item.kind),
            style: pw.TextStyle(
              fontSize: 6.9,
              fontWeight: pw.FontWeight.bold,
              color: accentWash,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _sanitizePdfText(item.label),
            style: const pw.TextStyle(
              fontSize: 8.4,
              color: PdfColors.white,
              lineSpacing: 1.3,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  pw.Widget _heroSummaryPanel({
    required List<String> summaryLines,
    required List<String> focusItems,
    required PdfColor panelBg,
    required PdfColor panelBorder,
    required PdfColor accentWash,
    required PdfColor strongAccent,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: pw.BoxDecoration(
        color: panelBg,
        border: pw.Border.all(color: panelBorder, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (summaryLines.isNotEmpty)
            pw.SizedBox(
              width: 270,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Leadership Profile',
                    style: pw.TextStyle(
                      fontSize: 7.1,
                      fontWeight: pw.FontWeight.bold,
                      color: accentWash,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...summaryLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 9.2,
                          color: PdfColors.white,
                          lineSpacing: 1.45,
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (summaryLines.isNotEmpty && focusItems.isNotEmpty)
            pw.SizedBox(width: 10),
          if (focusItems.isNotEmpty)
            pw.SizedBox(
              width: 165,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Leadership Focus',
                    style: pw.TextStyle(
                      fontSize: 7.1,
                      fontWeight: pw.FontWeight.bold,
                      color: accentWash,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...focusItems.map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                        ),
                        child: pw.Text(
                          _sanitizePdfText(item),
                          style: pw.TextStyle(
                            fontSize: 7.8,
                            fontWeight: pw.FontWeight.bold,
                            color: strongAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(
    String title, {
    String? eyebrow,
    required PdfColor accentColor,
    required PdfColor strongAccent,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if ((eyebrow ?? '').isNotEmpty) ...[
            pw.Text(
              eyebrow!,
              style: pw.TextStyle(
                fontSize: 6.8,
                fontWeight: pw.FontWeight.bold,
                color: strongAccent,
                letterSpacing: 0.85,
              ),
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 18,
                height: 3,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.Container(height: 0.9, color: _divider),
        ],
      ),
    );
  }

  pw.Widget _executiveHighlightTile(
    int index,
    String text, {
    required PdfColor accentColor,
    required PdfColor strongAccent,
  }) {
    final label = index < 9 ? '0${index + 1}' : '${index + 1}';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: pw.BoxDecoration(
        color: _panelBg,
        border: pw.Border.all(color: _divider, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22,
            height: 22,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _blend(accentColor, PdfColors.white, 0.82),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7.8,
                fontWeight: pw.FontWeight.bold,
                color: strongAccent,
                letterSpacing: 0.6,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 275,
            child: pw.Text(
              _sanitizePdfText(text),
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _ink,
                lineSpacing: 1.45,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(
    _BusinessManagementPdfExperienceEntry entry, {
    required PdfColor strongAccent,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 92,
            padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: pw.BoxDecoration(
              color: _panelBg,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TENURE',
                  style: pw.TextStyle(
                    fontSize: 6.4,
                    fontWeight: pw.FontWeight.bold,
                    color: strongAccent,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  entry.dateRange,
                  style: const pw.TextStyle(
                    fontSize: 8.1,
                    color: _ink,
                    lineSpacing: 1.25,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  entry.title,
                  style: const pw.TextStyle(
                    fontSize: 10.8,
                    color: _ink,
                  ),
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  entry.companyLine,
                  style: pw.TextStyle(
                    fontSize: 8.8,
                    fontWeight: pw.FontWeight.bold,
                    color: strongAccent,
                  ),
                  maxLines: 2,
                ),
                if (entry.highlights.isNotEmpty) ...[
                  pw.SizedBox(height: 7),
                  _bulletLines(
                    entry.highlights,
                    fontSize: 8.7,
                    textColor: _muted,
                    markerColor: strongAccent,
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Container(height: 0.8, color: _divider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(_BusinessManagementPdfProjectEntry entry) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: const pw.BoxDecoration(
        color: _panelBg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            entry.title,
            style: const pw.TextStyle(
              fontSize: 10.5,
              color: _ink,
            ),
            maxLines: 2,
          ),
          if (entry.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              entry.description,
              style: const pw.TextStyle(
                fontSize: 8.7,
                color: _muted,
                lineSpacing: 1.45,
              ),
              maxLines: 3,
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _railSectionTitle(String title, PdfColor strongAccent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 6.9,
          fontWeight: pw.FontWeight.bold,
          color: strongAccent,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  pw.Widget _skillChip(
    String label,
    PdfColor accentColor, {
    required double width,
  }) {
    return pw.Container(
      width: width,
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(
          color: _blend(accentColor, PdfColors.white, 0.82),
          width: 0.8,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 5,
            height: 5,
            decoration: pw.BoxDecoration(
              color: accentColor,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.SizedBox(
            width: width - 23,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 8,
                color: _ink,
                lineSpacing: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _customSectionWidgets(
    CustomSection section, {
    required PdfColor accentColor,
    required PdfColor strongAccent,
  }) {
    final title = displayUserCustomSectionTitle(section);
    final items = section.items
        .map(
          (item) => _customSectionItem(
            item,
            accentColor: accentColor,
            strongAccent: strongAccent,
          ),
        )
        .whereType<pw.Widget>()
        .toList(growable: false);

    if (items.isEmpty) {
      return const [];
    }

    return [
      _plainSectionHeader(
        title,
        strongAccent: strongAccent,
      ),
      ...items,
    ];
  }

  pw.Widget? _customSectionItem(
    CustomSectionItem item, {
    required PdfColor accentColor,
    required PdfColor strongAccent,
  }) {
    final displayItem = buildUserCustomSectionDisplayItem(item);
    final metaParts = <String>[
      if (displayItem.subtitle.isNotEmpty)
        _sanitizePdfText(displayItem.subtitle),
      if (displayItem.date != null)
        DateFormat('MMM yyyy').format(displayItem.date!),
    ];

    if (!displayItem.hasContent) {
      return null;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (displayItem.heading.isNotEmpty)
            pw.Text(
              _sanitizePdfText(displayItem.heading),
              style: const pw.TextStyle(
                fontSize: 9.6,
                color: _ink,
              ),
            ),
          if (metaParts.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              metaParts.join('  |  '),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _muted,
              ),
            ),
          ],
          if (displayItem.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _bulletLines(
              displayItem.detailLines,
              fontSize: 8.6,
              textColor: _muted,
              markerColor: strongAccent,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _bulletLines(
    List<String> lines, {
    required double fontSize,
    required PdfColor textColor,
    required PdfColor markerColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '- ${_sanitizePdfText(line)}',
                style: pw.TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  lineSpacing: 1.4,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _displayName(ResumeModel resume) {
    final value = _truncatePdfText(
      _sanitizePdfText(resume.personalInfo.fullName).trim(),
      maxChars: 52,
    );
    return value.isNotEmpty ? value : 'YOUR NAME';
  }

  String _displayTitle(ResumeModel resume) {
    return _truncatePdfText(
      _sanitizePdfText(resume.personalInfo.jobTitle).trim(),
      maxChars: 84,
    );
  }

  List<_BusinessManagementPdfContactItem> _contactItems(ResumeModel resume) {
    final items = <_BusinessManagementPdfContactItem>[];

    void add(String kind, String? value) {
      final trimmed = _truncatePdfText(
        _sanitizePdfText(value ?? '').trim(),
        maxChars: 84,
      );
      if (trimmed.isEmpty || items.any((item) => item.label == trimmed)) {
        return;
      }
      items.add(_BusinessManagementPdfContactItem(kind: kind, label: trimmed));
    }

    add('email', resume.personalInfo.email);
    add('phone', resume.personalInfo.phone);
    add('location', resume.personalInfo.address);
    add('linkedin', resume.personalInfo.linkedIn);
    add('github', resume.personalInfo.github);
    add('website', resume.personalInfo.website);

    return items.take(6).toList(growable: false);
  }

  String _contactCaption(String kind) {
    switch (kind) {
      case 'email':
        return 'EMAIL';
      case 'phone':
        return 'PHONE';
      case 'location':
        return 'LOCATION';
      case 'linkedin':
        return 'PROFILE';
      case 'github':
        return 'GITHUB';
      case 'website':
        return 'WEB';
      default:
        return 'DETAIL';
    }
  }

  List<String> _summaryLines(ResumeModel resume) {
    return _splitPdfLines(resume.objective ?? '')
        .map(
          (line) => _truncatePdfText(
            _sanitizePdfText(line).trim(),
            maxChars: 180,
          ),
        )
        .where((line) => line.isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  List<String> _skillNames(ResumeModel resume) {
    return resume.skills
        .map(
          (skill) => _truncatePdfText(
            _sanitizePdfText(skill.name).trim(),
            maxChars: 32,
          ),
        )
        .where((skill) => skill.isNotEmpty)
        .take(8)
        .toList(growable: false);
  }

  List<String> _executiveHighlights(ResumeModel resume) {
    final values = <String>[];

    void add(String value) {
      final trimmed = _sanitizePdfText(value).trim();
      if (trimmed.isNotEmpty && !values.contains(trimmed)) {
        values.add(trimmed);
      }
    }

    for (final entry in _experienceEntries(resume)) {
      for (final line in entry.highlights) {
        add(line);
        if (values.length == 3) {
          return values;
        }
      }
    }

    for (final line in _summaryLines(resume)) {
      add(line);
      if (values.length == 3) {
        break;
      }
    }

    return values;
  }

  List<_BusinessManagementPdfExperienceEntry> _experienceEntries(
    ResumeModel resume,
  ) {
    return resume.experience.map((experience) {
      final location = _sanitizePdfText(experience.location ?? '').trim();
      final company = _sanitizePdfText(experience.company).trim();
      final title = _sanitizePdfText(experience.position).trim();
      final companyLine = [
        if (company.isNotEmpty) company,
        if (location.isNotEmpty) location,
      ].join(' - ');
      final end = experience.isCurrentlyWorking
          ? _present()
          : _pdfDate(experience.endDate ?? experience.startDate);
      final highlights = <String>[];

      for (final achievement in experience.achievements) {
        final trimmed = _sanitizePdfText(achievement).trim();
        if (trimmed.isNotEmpty && !highlights.contains(trimmed)) {
          highlights.add(trimmed);
        }
      }

      for (final line in _splitPdfLines(experience.description)) {
        final trimmed = _sanitizePdfText(line).trim();
        if (trimmed.isNotEmpty && !highlights.contains(trimmed)) {
          highlights.add(trimmed);
        }
      }

      return _BusinessManagementPdfExperienceEntry(
        title: title.isNotEmpty ? title : 'Role',
        companyLine: companyLine.isNotEmpty ? companyLine : 'Company',
        dateRange: '${_pdfDate(experience.startDate)} - $end',
        highlights: highlights.take(2).toList(growable: false),
      );
    }).toList(growable: false);
  }

  List<_BusinessManagementPdfEducationEntry> _educationEntries(
    ResumeModel resume,
  ) {
    return resume.education.take(2).map((education) {
      final degree = [
        _sanitizePdfText(education.degree).trim(),
        _sanitizePdfText(education.fieldOfStudy).trim(),
      ].where((part) => part.isNotEmpty).join(' ');
      final institution = _sanitizePdfText(education.institution).trim();
      final end = education.isCurrentlyStudying
          ? _present()
          : (education.endDate?.year.toString() ??
              education.startDate.year.toString());

      return _BusinessManagementPdfEducationEntry(
        degree: degree.isNotEmpty ? degree : 'Education',
        institution: institution.isNotEmpty ? institution : 'Institution',
        dateRange: '${education.startDate.year} - $end',
      );
    }).toList(growable: false);
  }

  List<_BusinessManagementPdfProjectEntry> _projectEntries(ResumeModel resume) {
    return resume.projects.map((project) {
      final title = _sanitizePdfText(project.title).trim();
      final description = project.description.trim().isNotEmpty
          ? _sanitizePdfText(project.description).trim()
          : project.technologies
              .map((item) => _sanitizePdfText(item).trim())
              .where((item) => item.isNotEmpty)
              .join(', ');

      return _BusinessManagementPdfProjectEntry(
        title: title.isNotEmpty ? title : 'Project',
        description: description,
      );
    }).toList(growable: false);
  }

  List<String> _certificationLines(ResumeModel resume) {
    return resume.certifications
        .map((certification) {
          final name = _sanitizePdfText(certification.name).trim();
          final issuer = _sanitizePdfText(certification.issuer).trim();
          if (name.isEmpty) {
            return '';
          }
          return issuer.isNotEmpty ? '$name - $issuer' : name;
        })
        .where((line) => line.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  List<String> _languageLines(ResumeModel resume) {
    return resume.languages
        .map((language) {
          final name = _sanitizePdfText(language.name).trim();
          final proficiency = _sanitizePdfText(language.proficiency).trim();
          if (name.isEmpty) {
            return '';
          }
          return proficiency.isNotEmpty ? '$name - $proficiency' : name;
        })
        .where((line) => line.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  List<List<T>> _chunk<T>(List<T> values, int size) {
    final chunks = <List<T>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = index + size < values.length ? index + size : values.length;
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }

  PdfColor _blend(PdfColor a, PdfColor b, double t) {
    final factor = t.clamp(0, 1).toDouble();

    double mix(double start, double end) => start + ((end - start) * factor);

    return PdfColor(
      mix(a.red, b.red),
      mix(a.green, b.green),
      mix(a.blue, b.blue),
    );
  }

  String _truncatePdfText(String text, {required int maxChars}) {
    if (text.length <= maxChars) {
      return text;
    }

    return '${text.substring(0, maxChars).trim()}...';
  }
}

class _BusinessManagementPdfContactItem {
  const _BusinessManagementPdfContactItem({
    required this.kind,
    required this.label,
  });

  final String kind;
  final String label;
}

class _BusinessManagementPdfExperienceEntry {
  const _BusinessManagementPdfExperienceEntry({
    required this.title,
    required this.companyLine,
    required this.dateRange,
    required this.highlights,
  });

  final String title;
  final String companyLine;
  final String dateRange;
  final List<String> highlights;
}

class _BusinessManagementPdfEducationEntry {
  const _BusinessManagementPdfEducationEntry({
    required this.degree,
    required this.institution,
    required this.dateRange,
  });

  final String degree;
  final String institution;
  final String dateRange;
}

class _BusinessManagementPdfProjectEntry {
  const _BusinessManagementPdfProjectEntry({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
