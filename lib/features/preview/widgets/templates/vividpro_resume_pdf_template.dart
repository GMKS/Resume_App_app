part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class VividProResumePdfTemplate extends PdfTemplate {
  static const PdfColor _text = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _softBlue = PdfColor.fromInt(0xFFE6F4FF);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final chipColors = <PdfColor>[
      const PdfColor.fromInt(0xFF7C3AED),
      const PdfColor.fromInt(0xFFEC4899),
      const PdfColor.fromInt(0xFFF59E0B),
      const PdfColor.fromInt(0xFF10B981),
    ];
    final customSections = orderedUserCustomSections(resume)
        .where((section) => section.items.isNotEmpty)
        .toList(growable: false);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Container(
            width: double.infinity,
            color: accentColor,
            padding: const pw.EdgeInsets.fromLTRB(34, 24, 34, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resume.personalInfo.fullName.trim().isEmpty
                      ? 'YOUR NAME'
                      : _sanitizePdfText(resume.personalInfo.fullName),
                  style: pw.TextStyle(
                    fontSize: 21,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(resume.personalInfo.jobTitle!),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
                if (resume.personalInfo.email.isNotEmpty ||
                    resume.personalInfo.phone.isNotEmpty ||
                    resume.personalInfo.address.isNotEmpty ||
                    (resume.personalInfo.linkedIn?.isNotEmpty ?? false) ||
                    (resume.personalInfo.github?.isNotEmpty ?? false) ||
                    (resume.personalInfo.website?.isNotEmpty ?? false)) ...[
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (resume.personalInfo.email.isNotEmpty)
                        _coolBlueContact(resume.personalInfo.email),
                      if (resume.personalInfo.phone.isNotEmpty)
                        _coolBlueContact(resume.personalInfo.phone),
                      if (resume.personalInfo.address.isNotEmpty)
                        _coolBlueContact(resume.personalInfo.address),
                      if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                        _coolBlueContact(resume.personalInfo.linkedIn!),
                      if (resume.personalInfo.github?.isNotEmpty ?? false)
                        _coolBlueContact(resume.personalInfo.github!),
                      if (resume.personalInfo.website?.isNotEmpty ?? false)
                        _coolBlueContact(resume.personalInfo.website!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(34, 24, 34, 34),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (resume.objective?.isNotEmpty ?? false) ...[
                  _coolBlueSection('PROFESSIONAL SUMMARY', accentColor),
                  ..._buildSparkSummaryBullets(
                    resume.objective!,
                    accentColor,
                    fontSize: 8.8,
                    lineSpacing: 1.3,
                    bottomPadding: 4,
                    textColor: _muted,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (resume.experience.isNotEmpty) ...[
                  _coolBlueSection('EXPERIENCE', accentColor),
                  ...resume.experience.map((exp) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _sanitizePdfText(exp.position),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _text,
                              ),
                            ),
                            pw.Text(
                              _sanitizePdfText(exp.company),
                              style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: _muted,
                              ),
                            ),
                            if (exp.description.isNotEmpty)
                              pw.Text(
                                _sanitizePdfText(exp.description),
                                style: const pw.TextStyle(
                                  fontSize: 8.7,
                                  color: _text,
                                  lineSpacing: 1.3,
                                ),
                                textAlign: pw.TextAlign.justify,
                              ),
                            if (exp.achievements.isNotEmpty) ...[
                              pw.SizedBox(height: 3),
                              ...exp.achievements.take(2).map(
                                    (item) => pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 4,
                                          height: 4,
                                          margin: const pw.EdgeInsets.only(
                                            top: 4,
                                            right: 6,
                                          ),
                                          decoration: pw.BoxDecoration(
                                            color: accentColor,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            _sanitizePdfText(item),
                                            style: const pw.TextStyle(
                                              fontSize: 8.5,
                                              color: _muted,
                                              lineSpacing: 1.25,
                                            ),
                                            textAlign: pw.TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      )),
                ],
                if (resume.education.isNotEmpty) ...[
                  _coolBlueSection('EDUCATION', accentColor),
                  ...resume.education.map((edu) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _sanitizePdfText(edu.degree),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _text,
                              ),
                            ),
                            pw.Text(
                              _sanitizePdfText(edu.institution),
                              style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: _muted,
                              ),
                            ),
                            pw.Text(
                              DateFormat('yyyy')
                                  .format(edu.endDate ?? edu.startDate),
                              style: const pw.TextStyle(
                                fontSize: 8.2,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      )),
                  pw.SizedBox(height: 10),
                ],
                if (resume.skills.isNotEmpty) ...[
                  _coolBlueSection('SKILLS', accentColor),
                  pw.Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: resume.skills.take(8).toList().asMap().entries.map(
                      (entry) {
                        final chipColor =
                            chipColors[entry.key % chipColors.length];
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _softBlue,
                            border: pw.Border.all(
                              color: chipColor,
                              width: 0.9,
                            ),
                          ),
                          child: pw.Text(
                            _sanitizePdfText(entry.value.name),
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _text,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ).toList(growable: false),
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (resume.languages.isNotEmpty) ...[
                  _coolBlueSection('LANGUAGES', accentColor),
                  ...resume.languages.map((lang) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Text(
                          '${_sanitizePdfText(lang.name)}${lang.proficiency.isNotEmpty ? ' | ${_sanitizePdfText(lang.proficiency)}' : ''}',
                          style: const pw.TextStyle(
                            fontSize: 8.6,
                            color: _muted,
                          ),
                        ),
                      )),
                  pw.SizedBox(height: 10),
                ],
                if (resume.projects.isNotEmpty) ...[
                  _coolBlueSection('PROJECTS', accentColor),
                  ...resume.projects.map((proj) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _sanitizePdfText(proj.title),
                              style: pw.TextStyle(
                                fontSize: 9.6,
                                fontWeight: pw.FontWeight.bold,
                                color: _text,
                              ),
                            ),
                            if (proj.description.isNotEmpty)
                              pw.Text(
                                _sanitizePdfText(proj.description),
                                style: const pw.TextStyle(
                                  fontSize: 8.5,
                                  color: _muted,
                                  lineSpacing: 1.25,
                                ),
                                textAlign: pw.TextAlign.justify,
                              ),
                            if (proj.url?.isNotEmpty ?? false)
                              pw.Text(
                                _sanitizePdfText(proj.url!),
                                style: pw.TextStyle(
                                  fontSize: 8.3,
                                  color: accentColor,
                                  decoration: pw.TextDecoration.underline,
                                ),
                              ),
                          ],
                        ),
                      )),
                  pw.SizedBox(height: 10),
                ],
                if (resume.certifications.isNotEmpty) ...[
                  _coolBlueSection('CERTIFICATIONS', accentColor),
                  ...resume.certifications.map((cert) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _sanitizePdfText(cert.name),
                              style: pw.TextStyle(
                                fontSize: 9.2,
                                fontWeight: pw.FontWeight.bold,
                                color: _text,
                              ),
                            ),
                            if (cert.issuer.isNotEmpty)
                              pw.Text(
                                _sanitizePdfText(cert.issuer),
                                style: const pw.TextStyle(
                                  fontSize: 8.5,
                                  color: _muted,
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
                        _coolBlueSection(title.toUpperCase(), accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _coolBlueSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(height: 1, color: accentColor),
            pw.SizedBox(height: 6),
          ],
        ),
      );

  pw.Widget _coolBlueContact(String value) => pw.Text(
        _sanitizePdfText(value),
        style: const pw.TextStyle(
          fontSize: 8.2,
          color: PdfColors.white,
        ),
      );
}