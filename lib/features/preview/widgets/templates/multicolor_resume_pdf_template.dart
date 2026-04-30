part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class MulticolorResumePdfTemplate extends PdfTemplate {
  static const PdfColor _violet = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor _pink = PdfColor.fromInt(0xFFEC4899);
  static const PdfColor _amber = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor _emerald = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF1a1a1a);
  static const PdfColor _grayText = PdfColor.fromInt(0xFF666666);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final customSections = orderedUserCustomSections(resume)
      .where((section) => section.items.isNotEmpty)
      .toList(growable: false);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 42),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (resume.personalInfo.fullName.isEmpty
                              ? 'YOUR NAME'
                              : resume.personalInfo.fullName)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkText,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        resume.personalInfo.jobTitle!.toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _violet,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (resume.personalInfo.email.isNotEmpty)
                    _contactLine(resume.personalInfo.email),
                  if (resume.personalInfo.phone.isNotEmpty)
                    _contactLine(resume.personalInfo.phone),
                  if (resume.personalInfo.address.isNotEmpty)
                    _contactLine(resume.personalInfo.address),
                  if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.linkedIn!),
                  if (resume.personalInfo.github?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.github!),
                  if (resume.personalInfo.website?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.website!),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Container(height: 2, color: accentColor)),
              pw.Expanded(child: pw.Container(height: 2, color: _pink)),
              pw.Expanded(child: pw.Container(height: 2, color: _amber)),
              pw.Expanded(child: pw.Container(height: 2, color: _emerald)),
            ],
          ),
          pw.SizedBox(height: 16),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _sectionHeader('PROFILE', accentColor),
            pw.SizedBox(height: 6),
            ..._multicolorProfileBullets(resume.objective!, accentColor),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _sectionHeader('EXPERIENCE', _pink),
            pw.SizedBox(height: 6),
            ...resume.experience.map((exp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              (exp.location != null && exp.location!.isNotEmpty)
                                  ? '${exp.company.toUpperCase()} - ${exp.location!.toUpperCase()}'
                                  : exp.company.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${DateFormat('MMMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMMM yyyy').format(exp.endDate!)}',
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: _grayText,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        exp.position,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: _grayText,
                        ),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        ..._buildSummaryBullets(
                          exp.description,
                          _pink,
                          textAlign: pw.TextAlign.justify,
                        ),
                      ],
                    ],
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.education.isNotEmpty) ...[
            _sectionHeader('EDUCATION', _amber),
            pw.SizedBox(height: 6),
            ...resume.education.map((edu) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        edu.institution.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      pw.Text(
                        edu.fieldOfStudy.isNotEmpty
                            ? '${edu.degree} of ${edu.fieldOfStudy}'
                            : edu.degree,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: _grayText,
                        ),
                      ),
                      pw.Text(
                        DateFormat('yyyy').format(edu.endDate ?? edu.startDate),
                        style: const pw.TextStyle(
                          fontSize: 8.6,
                          color: _grayText,
                        ),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.skills.isNotEmpty) ...[
            _sectionHeader('SKILLS', _emerald),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resume.skills.take(12).toList().asMap().entries.map((entry) {
                final colors = [_violet, _pink, _amber, _emerald];
                final color = colors[entry.key % colors.length];
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: color.shade(0.12),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    entry.value.name,
                    style: pw.TextStyle(fontSize: 8.5, color: color),
                  ),
                );
              }).toList(growable: false),
            ),
            pw.SizedBox(height: 12),
          ],
          if (resume.projects.isNotEmpty) ...[
            _sectionHeader('PROJECTS', _violet),
            pw.SizedBox(height: 6),
            ...resume.projects.map((proj) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizePdfText(proj.title),
                        style: pw.TextStyle(
                          fontSize: 9.8,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      if (proj.description.isNotEmpty)
                        pw.Text(
                          _sanitizePdfText(proj.description),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            lineSpacing: 1.45,
                            color: _grayText,
                          ),
                          textAlign: pw.TextAlign.justify,
                        ),
                      if (proj.url?.isNotEmpty ?? false)
                        pw.Text(
                          _sanitizePdfText(proj.url!),
                          style: const pw.TextStyle(
                            fontSize: 8.8,
                            color: _violet,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES', _pink),
            pw.SizedBox(height: 6),
            ...resume.languages.map((lang) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${_sanitizePdfText(lang.name)}${lang.proficiency.isNotEmpty ? ' | ${_sanitizePdfText(lang.proficiency)}' : ''}',
                    style: const pw.TextStyle(fontSize: 9.2, color: _grayText),
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS', _amber),
            pw.SizedBox(height: 6),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _multicolorArrowMarker(_amber),
                      pw.SizedBox(width: 2),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: _sanitizePdfText(cert.name),
                                style: pw.TextStyle(
                                  fontSize: 9.2,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _darkText,
                                ),
                              ),
                              if (cert.issuer.isNotEmpty)
                                pw.TextSpan(
                                  text: ' - ${_sanitizePdfText(cert.issuer)}',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: _grayText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          ...customSections.expand(
            (section) => _buildGenericUserCustomSectionWidgets(
              section,
              accentColor: accentColor,
              bottomSpacing: 10,
              headerBuilder: (title) =>
                  _sectionHeader(title.toUpperCase(), accentColor),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  List<pw.Widget> _multicolorProfileBullets(
    String text,
    PdfColor bulletColor,
  ) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final segments = lines.isNotEmpty
        ? lines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);

    return segments
        .map((line) => line.replaceFirst(RegExp(r'^[-*•➤]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _multicolorArrowMarker(bulletColor),
                pw.SizedBox(width: 2),
                pw.Expanded(
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      lineSpacing: 1.8,
                      color: _grayText,
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

  pw.Widget _multicolorArrowMarker(PdfColor color) => pw.SizedBox(
        width: 14,
        height: 12,
        child: pw.CustomPaint(
          size: const PdfPoint(14, 12),
          painter: (canvas, size) {
            canvas.setFillColor(color);
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

  pw.Widget _contactLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 9, color: _grayText),
        ),
      );

  pw.Widget _sectionHeader(String title, PdfColor color) =>
      _buildRightBarSectionHeader(
        title,
        textColor: color,
        dividerColor: PdfColor(color.red, color.green, color.blue, 0.18),
        fontSize: 11,
        letterSpacing: 1.0,
        marginBottom: 10,
        titleBottomSpacing: 4,
        barHeight: 10,
      );
}