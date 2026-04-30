part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ClassicTempResumePdfTemplate extends PdfTemplate {
  static const PdfColor _accent =
      PdfColor.fromInt(ClassicTempTemplateSupport.accentHex);
  static const PdfColor _ink =
      PdfColor.fromInt(ClassicTempTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(ClassicTempTemplateSupport.mutedHex);
  static const PdfColor _subtle =
      PdfColor.fromInt(ClassicTempTemplateSupport.subtleHex);
  static const PdfColor _pageBg =
      PdfColor.fromInt(ClassicTempTemplateSupport.pageHex);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final sections = <String, List<pw.Widget>>{};

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _sectionHeader('PROFILE'),
        ..._summaryBulletLines(
          ClassicTempTemplateSupport.summaryLines(resume.objective),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...ClassicTempTemplateSupport.experienceEntries(
          resume.experience,
          maxDetailLines: 3,
        ).map(_experienceBlock),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...ClassicTempTemplateSupport.educationEntries(
          resume.education,
          maxDetailLines: 2,
        ).map(_educationBlock),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        _bodyParagraph(
          ClassicTempTemplateSupport.skillNames(resume.skills).join('  |  '),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...ClassicTempTemplateSupport.projectEntries(
          resume.projects,
          maxDetailLines: 3,
        ).map(_projectBlock),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...ClassicTempTemplateSupport.certificationEntries(
                resume.certifications)
            .map(_certificationBlock),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...ClassicTempTemplateSupport.languageLines(resume.languages)
            .map(_languageLine),
        pw.SizedBox(height: 10),
      ];
    }

    for (final section in orderedUserCustomSections(resume)
        .where((item) => item.items.isNotEmpty)) {
      sections[section.id] = [
        _sectionHeader(section.title.toUpperCase(), translate: false),
        ...section.items.map(_customSectionItem),
        pw.SizedBox(height: 10),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 30),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildHeader(resume),
          pw.SizedBox(height: 14),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim())
        : 'YOUR NAME';
    final title = resume.personalInfo.jobTitle?.trim() ?? '';
    final contactLines = ClassicTempTemplateSupport.contactLines(
      resume.personalInfo,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          name.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 25,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 1.8,
          ),
        ),
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            _sanitizePdfText(title),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 11,
              color: _subtle,
            ),
          ),
        ],
        if (contactLines.isNotEmpty) ...[
          pw.SizedBox(height: 9),
          ...contactLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _subtle,
                ),
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Container(height: 1.2, color: _accent),
      ],
    );
  }

  pw.Widget _sectionHeader(String title, {bool translate = true}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            translate ? _h(title) : _sanitizePdfText(title),
            style: pw.TextStyle(
              fontSize: 11.3,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
              letterSpacing: 0.7,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              height: 1,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _summaryBulletLines(List<String> lines) {
    return lines
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _summaryArrowMarker(),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    _sanitizePdfText(line),
                    style: const pw.TextStyle(
                      fontSize: 9.2,
                      color: _muted,
                      lineSpacing: 1.45,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(growable: false);
  }

  pw.Widget _summaryArrowMarker() {
    return pw.SizedBox(
      width: 14,
      height: 12,
      child: pw.CustomPaint(
        size: const PdfPoint(14, 12),
        painter: (canvas, size) {
          canvas.setFillColor(_accent);
          canvas.moveTo(size.x - 1, size.y / 2);
          canvas.lineTo(6.5, 1);
          canvas.lineTo(6.5, 4.3);
          canvas.lineTo(1, 4.3);
          canvas.lineTo(1, size.y - 4.3);
          canvas.lineTo(6.5, size.y - 4.3);
          canvas.lineTo(6.5, size.y - 1);
          canvas.closePath();
          canvas.fillPath();
        },
      ),
    );
  }

  pw.Widget _bodyParagraph(String text) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(
          fontSize: 9.2,
          color: _muted,
          lineSpacing: 1.45,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  pw.Widget _detailBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: const pw.BoxDecoration(
                color: _accent,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(text),
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _muted,
                lineSpacing: 1.4,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(ClassicTempExperienceEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.title),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: 92,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _subtle,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _sanitizePdfText(entry.companyLine),
            style: const pw.TextStyle(
              fontSize: 9.2,
              color: _subtle,
            ),
          ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...entry.detailLines.map(_detailBullet),
          ],
        ],
      ),
    );
  }

  pw.Widget _educationBlock(ClassicTempEducationEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.degree),
                  style: pw.TextStyle(
                    fontSize: 10.6,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: 92,
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _subtle,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _sanitizePdfText(entry.institutionLine),
            style: const pw.TextStyle(
              fontSize: 9.2,
              color: _subtle,
            ),
          ),
          if (entry.supportingLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...entry.supportingLines.map(_detailBullet),
          ],
        ],
      ),
    );
  }

  pw.Widget _projectBlock(ClassicTempProjectEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (entry.links.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.links.join(' | ')),
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  color: _accent,
                ),
              ),
            ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...entry.detailLines.map(_detailBullet),
          ],
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(ClassicTempCertificationEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (entry.supportingLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...entry.supportingLines
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: _bodyParagraph(line),
                  ),
                )
                ,
          ],
        ],
      ),
    );
  }

  pw.Widget _languageLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(
          fontSize: 9,
          color: _muted,
        ),
      ),
    );
  }

  pw.Widget _customSectionItem(CustomSectionItem item) {
    final displayItem = buildUserCustomSectionDisplayItem(item);
    final metaParts = <String>[
      if (displayItem.subtitle.isNotEmpty) _sanitizePdfText(displayItem.subtitle),
      if (displayItem.date != null)
        DateFormat('MMM yyyy').format(displayItem.date!),
    ];

    if (!displayItem.hasContent) {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (displayItem.heading.isNotEmpty)
            pw.Text(
              _sanitizePdfText(displayItem.heading),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _accent,
                ),
              ),
            ),
          ...displayItem.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _bodyParagraph(line.trim()),
            ),
          ),
        ],
      ),
    );
  }
}
