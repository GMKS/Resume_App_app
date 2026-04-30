part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class AtsOptimizedCleanResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(AtsOptimizedCleanTemplateSupport.pageHex);
  static const PdfColor _ink =
      PdfColor.fromInt(AtsOptimizedCleanTemplateSupport.inkHex);
  static const PdfColor _body =
      PdfColor.fromInt(AtsOptimizedCleanTemplateSupport.bodyHex);
  static const PdfColor _muted =
      PdfColor.fromInt(AtsOptimizedCleanTemplateSupport.mutedHex);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    final contactItems = AtsOptimizedCleanTemplateSupport.contactItems(
      resume.personalInfo,
    );
    final summaryLines = AtsOptimizedCleanTemplateSupport.summaryLines(
      resume.objective,
    );
    final resolvedSummaryLines = summaryLines.isNotEmpty
        ? summaryLines
        : const [
            'A motivated professional with specialist expertise in engineering and project delivery.',
          ];
    final skillNames = AtsOptimizedCleanTemplateSupport.skillNames(
      resume.skills,
      maxItems: 10,
    );
    final experiences = AtsOptimizedCleanTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 6,
      yearOnly: true,
    );
    final educations = AtsOptimizedCleanTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final projects = AtsOptimizedCleanTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 4,
      compactLinks: true,
    );
    final certifications = AtsOptimizedCleanTemplateSupport.certificationLines(
      resume.certifications,
    );
    final languages = AtsOptimizedCleanTemplateSupport.languageLines(
      resume.languages,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildHeader(resume, contactItems, accentColor),
          pw.SizedBox(height: 12),
          _buildAboutAndSkills(
            resolvedSummaryLines,
            skillNames,
            certifications,
            accentColor,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 0.8,
            color: _blendPdfWithWhite(accentColor, 0.28),
          ),
          pw.SizedBox(height: 10),
          if (experiences.isNotEmpty) ...[
            _sectionHeader('EXPERIENCE', accentColor),
            ...experiences.map(
              (entry) => _experienceBlock(entry),
            ),
          ],
          if (educations.isNotEmpty) ...[
            _sectionHeader('EDUCATION', accentColor),
            ...educations.map(
              (entry) => _educationBlock(entry),
            ),
          ],
          if (projects.isNotEmpty) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.NewPage(
                  freeSpace: 80 + (projects.length * 22),
                ),
                _sectionHeader('PROJECTS', accentColor),
                ...projects.map(
                  (entry) => _projectBlock(entry, accentColor),
                ),
              ],
            ),
          ],
          if (languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES', accentColor),
            ...languages.map(_simpleLine),
          ],
          ...orderedUserCustomSections(resume).expand(
            (section) => _buildGenericUserCustomSectionWidgets(
              section,
              accentColor: accentColor,
              bottomSpacing: 8,
              headerBuilder: (title) =>
                  _sectionHeader(title.toUpperCase(), accentColor),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(
    ResumeModel resume,
    List<AtsOptimizedCleanContactItem> contactItems,
    PdfColor accentColor,
  ) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim()).toUpperCase()
        : 'YOUR NAME';
    final title = (resume.personalInfo.jobTitle ?? '').trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.jobTitle!.trim())
        : 'MBA, Software Engineering';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (title.isNotEmpty)
                    pw.Text(
                      title,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _muted,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 18),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: contactItems
                    .map(
                      (item) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          _sanitizePdfText(item.label),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(
                            fontSize: 8.8,
                            color: _body,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(width: double.infinity, height: 1.8, color: accentColor),
      ],
    );
  }

  pw.Widget _buildAboutAndSkills(
    List<String> summaryLines,
    List<String> skillNames,
    List<String> certifications,
    PdfColor accentColor,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionHeader('ABOUT ME', accentColor),
              ...summaryLines.map(_summaryLine),
            ],
          ),
        ),
        if (skillNames.isNotEmpty || certifications.isNotEmpty) ...[
          pw.SizedBox(width: 14),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (skillNames.isNotEmpty) ...[
                  pw.Text(
                    'Core Skills',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: skillNames
                        .map(
                          (skill) => pw.Text(
                            _sanitizePdfText(skill),
                            style: const pw.TextStyle(
                              fontSize: 8.8,
                              color: _body,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (certifications.isNotEmpty) ...[
                  pw.SizedBox(height: skillNames.isNotEmpty ? 8 : 6),
                  pw.Text(
                    'Certifications',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  ...certifications.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 8.4,
                          color: _body,
                          lineSpacing: 1.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        _h(title),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  pw.Widget _summaryLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 6),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: const pw.BoxDecoration(
                color: _ink,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _body,
                lineSpacing: 1.45,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(AtsOptimizedCleanExperienceEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
              pw.SizedBox(width: 10),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _muted,
                ),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.companyLine),
            style: const pw.TextStyle(
              fontSize: 9,
              color: _body,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _body,
                  lineSpacing: 1.4,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(AtsOptimizedCleanEducationEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.degree),
                  style: pw.TextStyle(
                    fontSize: 9.5,
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
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: const pw.TextStyle(
              fontSize: 8.8,
              color: _body,
            ),
          ),
          ...entry.supportingLines.map(
            (line) => pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 8.2,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(
    AtsOptimizedCleanProjectEntry entry,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.5,
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
                  fontSize: 8.8,
                  color: _body,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.url),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _simpleLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(
          fontSize: 8.8,
          color: _body,
          lineSpacing: 1.35,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
}
