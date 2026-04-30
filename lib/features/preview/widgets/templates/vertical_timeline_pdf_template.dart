part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

// ════════════════════════════════════════════════════════════════════════════
// Vertical Timeline Template
// White background layout: name + title top-left, photo card top-right,
// then bullet-dot / timeline sections for experience and education with
// a contact footer bar — faithful to the Connor Hamilton Canva reference.
// ════════════════════════════════════════════════════════════════════════════
class VerticalTimelineTemplate extends PdfTemplate {
  static const _bodyText = PdfColor.fromInt(0xFF1A2535);
  static const _mutedText = PdfColor.fromInt(0xFF6B7280);
  static const double _photoSize = 80;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final displayName = VerticalTimelineTemplateSupport.displayName(resume);
    final displayTitle = VerticalTimelineTemplateSupport.displayTitle(resume);
    final summaryLines = VerticalTimelineTemplateSupport.summaryLines(
      resume.objective,
    );
    final educationEntries = VerticalTimelineTemplateSupport.educationEntries(
      resume.education,
    );
    final experienceEntries = VerticalTimelineTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 6,
    );
    final projectEntries = VerticalTimelineTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 6,
      compactLinks: true,
    );
    final skillNames = VerticalTimelineTemplateSupport.skillNames(resume.skills);
    final certificationLines = VerticalTimelineTemplateSupport.certificationLines(
      resume.certifications,
    );
    final languageLines = VerticalTimelineTemplateSupport.languageLines(
      resume.languages,
    );
    final contactItems = VerticalTimelineTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
    );

    // Decode profile photo if provided
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    final initials = _initials(displayName);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(44, 36, 44, 36),
      build: (ctx) => [
        // ── Name / photo header row ──────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: name + title
            pw.Expanded(
                child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(displayName),
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: _bodyText),
                ),
                if (displayTitle.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(displayTitle),
                    style: pw.TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ],
            )),
            pw.SizedBox(width: 20),
            pw.SizedBox(
              width: _photoSize,
              height: _photoSize,
              child: pw.Container(
                width: _photoSize,
                height: _photoSize,
                decoration: pw.BoxDecoration(
                  color: photoBytes != null
                      ? null
                      : PdfColor(accentColor.red, accentColor.green,
                          accentColor.blue, 0.15),
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
                            color: accentColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        pw.Container(
          height: 2,
          color: accentColor,
          margin: const pw.EdgeInsets.only(top: 8, bottom: 14),
        ),

        // ── ABOUT ────────────────────────────────────────────────────────
        if (summaryLines.isNotEmpty) ...[
          _vtSection('About', accentColor),
          ..._buildSummaryBullets(
                  summaryLines.join('\n'),
                  accentColor,
                  textAlign: pw.TextAlign.justify)
              .map((w) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2), child: w)),
          pw.SizedBox(height: 10),
        ],

        // ── EDUCATION ────────────────────────────────────────────────────
        if (educationEntries.isNotEmpty) ...[
          _vtSection('Education', accentColor),
          ...educationEntries.map((edu) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _vtDot(accentColor),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                        pw.Text(_sanitizePdfText(edu.degree),
                              style: pw.TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _bodyText)),
                        pw.Text(_sanitizePdfText(edu.institutionLine),
                              style: pw.TextStyle(
                                  fontSize: 9.5,
                                  color: accentColor,
                                  fontWeight: pw.FontWeight.bold)),
                        pw.Text(_sanitizePdfText(edu.dateRange),
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _mutedText)),
                        ])),
                  ]),
            );
          }),
          pw.SizedBox(height: 6),
        ],

        // ── EXPERIENCE ───────────────────────────────────────────────────
        if (experienceEntries.isNotEmpty) ...[
          _vtSection('Experience', accentColor),
          ...experienceEntries.map((exp) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Timeline: dot + connector line
                    pw.Column(children: [
                      pw.Container(
                          width: 11,
                          height: 11,
                          decoration: pw.BoxDecoration(
                              color: accentColor, shape: pw.BoxShape.circle)),
                      pw.Container(
                          width: 1.5,
                          height: _timelineConnectorHeight(exp.detailLines.length),
                          color: PdfColor(accentColor.red, accentColor.green,
                              accentColor.blue, 0.28)),
                    ]),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                          pw.Text(_sanitizePdfText(exp.title),
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _bodyText)),
                          pw.Text(
                            '${_sanitizePdfText(exp.metaLine)}  |  ${_sanitizePdfText(exp.dateRange)}',
                            style: pw.TextStyle(
                                fontSize: 9.5,
                                color: accentColor,
                                fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          if (exp.detailLines.isNotEmpty)
                            ..._buildSummaryBullets(
                                exp.detailLines.join('\n'),
                                accentColor,
                                textAlign: pw.TextAlign.justify),
                        ])),
                  ]),
            );
          }),
        ],

        // ── PROJECTS ─────────────────────────────────────────────────────
        if (projectEntries.isNotEmpty) ...[
          _vtSection('Projects', accentColor),
          ...projectEntries.map((project) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(children: [
                        pw.Container(
                            width: 11,
                            height: 11,
                            decoration: pw.BoxDecoration(
                                color: accentColor, shape: pw.BoxShape.circle)),
                        pw.Container(
                            width: 1.5,
                          height: _projectConnectorHeight(project),
                            color: PdfColor(accentColor.red, accentColor.green,
                                accentColor.blue, 0.28)),
                      ]),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                            pw.Text(_sanitizePdfText(project.title),
                                style: pw.TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _bodyText)),
                            if (project.technologiesLine.isNotEmpty)
                              pw.Text(
                                _sanitizePdfText(project.technologiesLine),
                                style: pw.TextStyle(
                                    fontSize: 8.8,
                                    color: accentColor,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            if (project.detailLines.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              ..._buildSummaryBullets(
                                  project.detailLines.join('\n'),
                                  accentColor,
                                  textAlign: pw.TextAlign.justify),
                            ],
                            if (project.links.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              ...project.links.map(
                                (link) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 2),
                                  child: pw.Text(
                                    _sanitizePdfText(link),
                                    style: pw.TextStyle(
                                      fontSize: 8.6,
                                      color: accentColor,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ])),
                    ]),
              )),
        ],

        // ── SKILLS ───────────────────────────────────────────────────────
        if (skillNames.isNotEmpty) ...[
          _vtSection('Skills', accentColor),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Wrap(
              spacing: 8,
              runSpacing: 5,
              children: skillNames.map((skill) {
                return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                  pw.Container(
                      width: 5,
                      height: 5,
                      margin: const pw.EdgeInsets.only(right: 5),
                      decoration: pw.BoxDecoration(
                          color: accentColor, shape: pw.BoxShape.circle)),
                      pw.Text(_sanitizePdfText(skill),
                      style:
                          const pw.TextStyle(fontSize: 9.5, color: _bodyText)),
                  pw.SizedBox(width: 16),
                ]);
              }).toList(),
            ),
          ),
        ],

        // ── CERTIFICATIONS ───────────────────────────────────────────────
        if (certificationLines.isNotEmpty) ...[
          _vtSection('Certifications', accentColor),
          ...certificationLines.map((line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _vtDot(accentColor),
                      pw.Expanded(
                          child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 9.6,
                          color: _bodyText,
                        ),
                      )),
                    ]),
              )),
        ],

        // ── LANGUAGES ────────────────────────────────────────────────────
        if (languageLines.isNotEmpty) ...[
          _vtSection('Languages', accentColor),
          pw.Wrap(
            spacing: 20,
            runSpacing: 4,
            children: languageLines
                .map(
                    (line) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                          pw.Container(
                              width: 5,
                              height: 5,
                              margin: const pw.EdgeInsets.only(right: 5),
                              decoration: pw.BoxDecoration(
                                  color: accentColor,
                                  shape: pw.BoxShape.circle)),
                          pw.Text(
                            _sanitizePdfText(line),
                            style: const pw.TextStyle(
                              fontSize: 9.4,
                              color: _bodyText,
                            ),
                          ),
                        ]))
                .toList(),
          ),
          pw.SizedBox(height: 12),
        ],

        ...orderedUserCustomSections(resume)
            .where((section) => section.items.isNotEmpty)
            .expand(
              (section) => _buildGenericUserCustomSectionWidgets(
                section,
                accentColor: accentColor,
                bottomSpacing: 10,
                headerBuilder: (title) =>
                    _vtSection(title.toUpperCase(), accentColor),
              ),
            ),

        if (contactItems.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _buildFooter(contactItems, accentColor),
        ],
      ],
    ));
    return doc;
  }

  String _initials(String name) {
    final parts = name
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'YN';
    }
    return parts.map((part) => part[0]).join().toUpperCase();
  }

  double _timelineConnectorHeight(int detailCount) {
    if (detailCount <= 0) {
      return 24;
    }
    return 20 + (detailCount * 16);
  }

  double _projectConnectorHeight(VerticalTimelineProjectEntry entry) {
    final contentLines = entry.detailLines.length + entry.links.length;
    if (contentLines <= 0) {
      return 20;
    }
    return 16 + (contentLines * 12);
  }

  pw.Widget _buildFooter(
    List<VerticalTimelineContactItem> contactItems,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: pw.Wrap(
        alignment: pw.WrapAlignment.center,
        spacing: 12,
        runSpacing: 5,
        children: contactItems
            .map(
              (item) => pw.Text(
                _sanitizePdfText(item.label),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.white,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _vtSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_h(title.toUpperCase()),
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _bodyText,
                      letterSpacing: 0.8)),
              pw.Container(
                  height: 2,
                  color: accentColor,
                  margin: const pw.EdgeInsets.only(top: 4, bottom: 2)),
            ]),
      );

  pw.Widget _vtDot(PdfColor color) => pw.Container(
        width: 9,
        height: 9,
        margin: const pw.EdgeInsets.only(top: 1.5, right: 10),
        decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      );
}
