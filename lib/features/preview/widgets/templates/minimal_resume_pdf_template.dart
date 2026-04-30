part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class MinimalResumePdfTemplate extends MinimalTemplate {
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFF6F2E8);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2E3137);
  static const PdfColor _muted = PdfColor.fromInt(0xFF656B74);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(26, 24, 26, 26),
            decoration: const pw.BoxDecoration(color: _pageBg),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 154,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.personalInfo.phone.isNotEmpty)
                            _buildContactIconRow(
                              'phone',
                              resume.personalInfo.phone,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                          if (resume.personalInfo.email.isNotEmpty)
                            _buildContactIconRow(
                              'email',
                              resume.personalInfo.email,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                          if (resume.personalInfo.address.isNotEmpty)
                            _buildContactIconRow(
                              'location',
                              resume.personalInfo.address,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.website ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'website',
                              resume.personalInfo.website!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'linkedin',
                              resume.personalInfo.linkedIn!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.github ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'website',
                              resume.personalInfo.github!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: const PdfColor.fromInt(0xFF656B74),
                              textSize: 7.3,
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            _sanitizePdfText(
                              resume.personalInfo.fullName.isEmpty
                                  ? 'Your Name'
                                  : resume.personalInfo.fullName,
                            ).toUpperCase(),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 24,
                              color: const PdfColor.fromInt(0xFF243B53),
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(
                                  fontSize: 10.8,
                                  color: PdfColor.fromInt(0xFF656B74),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  height: 1,
                  width: double.infinity,
                  color: accentColor,
                ),
                if ((resume.objective ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  _buildMinimalSectionHeader(
                    'PROFESSIONAL SUMMARY',
                    accentColor,
                  ),
                  ..._buildMinimalSummaryBullets(
                    resume.objective!,
                    accentColor,
                  ),
                  pw.SizedBox(height: 18),
                ],
                if (resume.experience.isNotEmpty) ...[
                  _buildMinimalSectionHeader('EXPERIENCE', accentColor),
                  ...resume.experience.map(
                    (experience) =>
                        _buildAlignedMinimalExperience(experience, accentColor),
                  ),
                ],
                if (resume.education.isNotEmpty) ...[
                  _buildMinimalSectionHeader('EDUCATION', accentColor),
                  ...resume.education.map(
                    (education) =>
                        _buildMinimalEducation(education, accentColor),
                  ),
                ],
                if (resume.skills.isNotEmpty) ...[
                  _buildMinimalSectionHeader('SKILLS', accentColor),
                  pw.Text(
                    resume.skills
                        .map((skill) => _sanitizePdfText(skill.name))
                        .join(' / '),
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColor.fromInt(0xFF2E3137),
                      lineSpacing: 1.45,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                ],
                if (resume.projects.isNotEmpty) ...[
                  _buildMinimalSectionHeader('PROJECTS', accentColor),
                  ...resume.projects.map(
                    (project) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(project.title),
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: const PdfColor.fromInt(0xFF2E3137),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (project.description.isNotEmpty)
                            pw.Text(
                              _sanitizePdfText(project.description),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromInt(0xFF656B74),
                                lineSpacing: 1.35,
                              ),
                              textAlign: pw.TextAlign.justify,
                            ),
                          if ((project.url?.trim().isNotEmpty ?? false) &&
                              !_sanitizePdfText(project.description)
                                  .contains(_sanitizePdfText(project.url!)))
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                _sanitizePdfText(project.url!),
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  color: accentColor,
                                  decoration: pw.TextDecoration.underline,
                                ),
                              ),
                            ),
                          if (project.technologies.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                project.technologies
                                    .map(_sanitizePdfText)
                                    .join(', '),
                                style: const pw.TextStyle(
                                  fontSize: 8.5,
                                  color: PdfColor.fromInt(0xFF2E3137),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (resume.certifications.isNotEmpty) ...[
                  _buildMinimalSectionHeader('CERTIFICATIONS', accentColor),
                  ...resume.certifications.map(
                    (certification) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(
                        '${_sanitizePdfText(certification.name)}${certification.issuer.isNotEmpty ? ' - ${_sanitizePdfText(certification.issuer)}' : ''}',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColor.fromInt(0xFF2E3137),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
                if (resume.languages.isNotEmpty) ...[
                  _buildMinimalSectionHeader('LANGUAGES', accentColor),
                  pw.Text(
                    resume.languages
                        .map(
                          (language) =>
                              '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})',
                        )
                        .join(', '),
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColor.fromInt(0xFF656B74),
                      lineSpacing: 1.35,
                    ),
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
                            _buildMinimalSectionHeader(
                          title.toUpperCase(),
                          accentColor,
                        ),
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

  List<String> _collectMinimalSummarySegments(String text) {
    final normalized = _sanitizePdfText(text).trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final explicitSegments = normalized
        .split(RegExp(r'\n+|[•▪]+'))
        .map((line) => line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (explicitSegments.length > 1) {
      return explicitSegments;
    }

    return [normalized.replaceAll(RegExp(r'\s+'), ' ')];
  }

  List<pw.Widget> _buildMinimalSummaryBullets(
    String text,
    PdfColor accentColor,
  ) {
    final segments = _collectMinimalSummarySegments(text);
    if (segments.isEmpty) {
      return const [];
    }

    return segments
        .map(
          (segment) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3.2),
                  child: pw.Container(
                    width: 7,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: _muted, width: 0.55),
                    ),
                    child: pw.Center(
                      child: pw.Container(
                        width: 2.1,
                        height: 2.1,
                        decoration: const pw.BoxDecoration(
                          color: _muted,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    segment,
                    style: const pw.TextStyle(
                      fontSize: 9.3,
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

  pw.Widget _buildAlignedMinimalExperience(
    Experience experience,
    PdfColor accentColor,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${_sanitizePdfText(experience.position)} - ${_sanitizePdfText(experience.company)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(experience.endDate!)}',
                  style: const pw.TextStyle(fontSize: 8.6, color: _muted),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if ((experience.location ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(experience.location!),
                style: pw.TextStyle(fontSize: 8.5, color: accentColor),
              ),
            ),
          if (_collectExperienceLines(experience).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._buildExperienceLineWidgets(
              experience,
              accentColor,
              leftPadding: 4,
              fontSize: 8.8,
              textColor: _muted,
            ),
          ],
        ],
      ),
    );
  }
}
