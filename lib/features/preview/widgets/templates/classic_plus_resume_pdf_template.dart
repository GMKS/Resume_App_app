part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ClassicPlusResumePdfTemplate extends PdfTemplate {
  static const PdfColor _nearBlack = PdfColor(0.153, 0.153, 0.153); // #272727
  static const PdfColor _midGray = PdfColor(0.5, 0.5, 0.5);
  static const PdfColor _lightGray = PdfColor(0.85, 0.85, 0.85);
  static const double _contactColumnWidth = 154;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        // Header
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Left: Name and Title
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resume.personalInfo.fullName.isEmpty
                        ? 'YOUR NAME'
                        : resume.personalInfo.fullName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: _nearBlack,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      resume.personalInfo.jobTitle!,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: _midGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 18),
            // Right: fixed-width contact column so the block stays anchored.
            pw.Container(
              width: _contactColumnWidth,
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: _buildHeaderContacts(resume),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),
        // Thick full-width line below header
        pw.Container(
          width: double.infinity,
          height: 3,
          color: accentColor,
        ),
        pw.SizedBox(height: 20),

        // Summary
        if (resume.objective?.trim().isNotEmpty ?? false) ...[
          _buildSectionHeader('PROFESSIONAL SUMMARY', accentColor),
          ..._buildSparkleBullets(
            _splitSummarySegments(resume.objective!),
            _nearBlack,
          ),
          pw.SizedBox(height: 18),
        ],

        // Experience
        if (resume.experience.isNotEmpty) ...[
          _buildSectionHeader('WORK EXPERIENCE', accentColor),
          ...resume.experience
              .map((exp) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(exp.position),
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _nearBlack,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _experienceMeta(exp),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: _midGray,
                          ),
                        ),
                        if (exp.description.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              _sanitizePdfText(exp.description),
                              style: const pw.TextStyle(
                                fontSize: 9.5,
                                color: _nearBlack,
                                lineSpacing: 1.4,
                              ),
                              textAlign: pw.TextAlign.justify,
                            ),
                          ),
                        if (exp.achievements.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          ..._buildDashes(exp.achievements, _nearBlack),
                        ],
                      ],
                    ),
                  ))
              ,
        ],

        // Education
        if (resume.education.isNotEmpty) ...[
          _buildSectionHeader('EDUCATION', accentColor),
          ...resume.education
              .map((edu) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _nearBlack,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${_sanitizePdfText(edu.institution)} \u2022 ${DateFormat('yyyy').format(edu.endDate ?? edu.startDate)}',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: _midGray,
                          ),
                        ),
                      ],
                    ),
                  ))
              ,
        ],

        // Skills (Pill layout)
        if (resume.skills.isNotEmpty) ...[
          _buildSectionHeader('SKILLS', accentColor),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resume.skills
                .map((skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4.5),
                      decoration: pw.BoxDecoration(
                        color: PdfColor(
                          accentColor.red * 0.08 + 0.92,
                          accentColor.green * 0.08 + 0.92,
                          accentColor.blue * 0.08 + 0.92,
                        ),
                        border: pw.Border.all(
                          color: PdfColor(
                            accentColor.red * 0.28 + 0.62,
                            accentColor.green * 0.28 + 0.62,
                            accentColor.blue * 0.28 + 0.62,
                          ),
                          width: 0.6,
                        ),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Text(
                        _sanitizePdfText(skill.name),
                        style: pw.TextStyle(
                          fontSize: 9.8,
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          pw.SizedBox(height: 18),
        ],

        // Projects
        if (resume.projects.isNotEmpty) ...[
          _buildSectionHeader('PROJECTS', accentColor),
          ...resume.projects
              .map((proj) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(proj.title),
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _nearBlack,
                          ),
                        ),
                        if (proj.url != null && proj.url!.trim().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _sanitizePdfText(proj.url!),
                                style: const pw.TextStyle(
                                  fontSize: 8.9,
                                  color: _midGray,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                        if (proj.technologies.isNotEmpty)
                          pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(top: 2, bottom: 2),
                            child: pw.Text(
                              _sanitizePdfText(proj.technologies.join(', ')),
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: accentColor,
                              ),
                            ),
                          ),
                        if (proj.description.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          ..._buildDashes(
                            _splitSummarySegments(proj.description),
                            _nearBlack,
                          ),
                        ],
                      ],
                    ),
                  ))
              ,
        ],

        // Certifications
        if (resume.certifications.isNotEmpty) ...[
          _buildSectionHeader('CERTIFICATIONS', accentColor),
          ...resume.certifications
              .map((cert) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      cert.issuer.isNotEmpty
                          ? '${_sanitizePdfText(cert.name)} \u2022 ${_sanitizePdfText(cert.issuer)}'
                          : _sanitizePdfText(cert.name),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _nearBlack,
                      ),
                    ),
                  ))
              ,
          pw.SizedBox(height: 12),
        ],

        // Languages
        if (resume.languages.isNotEmpty) ...[
          _buildSectionHeader('LANGUAGES', accentColor),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: resume.languages
                .map((lang) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        lang.proficiency.isNotEmpty
                            ? '${_sanitizePdfText(lang.name)} - ${_sanitizePdfText(lang.proficiency)}'
                            : _sanitizePdfText(lang.name),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _nearBlack,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
        ...orderedUserCustomSections(resume)
            .where((section) => section.items.isNotEmpty)
            .expand(
              (section) => _buildGenericUserCustomSectionWidgets(
                section,
                accentColor: accentColor,
                bottomSpacing: 10,
                headerBuilder: (title) =>
                    _buildSectionHeader(title.toUpperCase(), accentColor),
              ),
            ),
      ],
    ));

    return pdf;
  }

  List<pw.Widget> _buildHeaderContacts(ResumeModel resume) {
    final List<String> lines = [];
    if (resume.personalInfo.email.isNotEmpty) {
      lines.add(resume.personalInfo.email);
    }
    if (resume.personalInfo.phone.isNotEmpty) {
      lines.add(resume.personalInfo.phone);
    }
    if (resume.personalInfo.address.isNotEmpty) {
      lines.add(resume.personalInfo.address);
    }
    if (resume.personalInfo.linkedIn?.isNotEmpty ?? false) {
      lines.add(resume.personalInfo.linkedIn!);
    }
    if (resume.personalInfo.github?.isNotEmpty ?? false) {
      lines.add(resume.personalInfo.github!);
    }
    if (resume.personalInfo.website?.isNotEmpty ?? false) {
      lines.add(resume.personalInfo.website!);
    }

    return lines
        .map((text) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                _sanitizePdfText(text),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: _midGray,
                  lineSpacing: 1.15,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ))
        .toList();
  }

  List<String> _splitSummarySegments(String text) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final segments = lines.isNotEmpty
        ? lines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    return segments
        .map((line) => line.replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _experienceMeta(Experience exp) {
    final company = _sanitizePdfText(exp.company);
    final location = _sanitizePdfText(exp.location ?? '');
    final dateRange =
        '${DateFormat('yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('yyyy').format(exp.endDate!)}';

    if (location.isEmpty) {
      return '$company \u2022 $dateRange';
    }

    return '$company \u2022 $location \u2022 $dateRange';
  }

  pw.Widget _buildSectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 24,
            height: 4,
            color: accentColor,
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Container(
              height: 1,
              color: _lightGray,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildSparkleBullets(List<String> items, PdfColor color) {
    return items
        .map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 3.5, right: 8, left: 2),
                    child: pw.SizedBox(
                      width: 6,
                      height: 6,
                      child: pw.CustomPaint(
                        size: const PdfPoint(6, 6),
                        painter: (canvas, size) {
                          final double w = size.x;
                          final double h = size.y;
                          final double w2 = w / 2;
                          final double h2 = h / 2;
                          canvas.moveTo(w2, 0);
                          canvas.curveTo(w2, h * 0.35, w * 0.65, h2, w, h2);
                          canvas.curveTo(w * 0.65, h2, w2, h * 0.65, w2, h);
                          canvas.curveTo(w2, h * 0.65, w * 0.35, h2, 0, h2);
                          canvas.curveTo(w * 0.35, h2, w2, h * 0.35, w2, 0);
                          canvas.setFillColor(color);
                          canvas.fillPath();
                        },
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(item),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        lineSpacing: 1.4,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  List<pw.Widget> _buildDashes(List<String> items, PdfColor color) {
    return items
        .map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 6),
                    child: pw.Text('- ',
                        style: pw.TextStyle(color: color, fontSize: 9.5)),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(item),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        lineSpacing: 1.4,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
