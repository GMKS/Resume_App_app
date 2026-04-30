part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class CreativeResumePdfTemplate extends PdfTemplate {
  static const PdfColor _ink = PdfColor.fromInt(0xFF2D3142);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFFFF8F1);
  static const PdfColor _softCard = PdfColor.fromInt(0xFFFFFBF5);
  static const PdfColor _headerMuted = PdfColor(1, 1, 1, 0.76);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);

    final sections = <String, List<pw.Widget>>{};
    if (resume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _sectionTitle('PROFILE', accentColor),
        ..._buildProfileBullets(resume.objective!, accentColor),
        pw.SizedBox(height: 12),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionTitle('EXPERIENCE', accentColor),
        ...resume.experience.map((exp) => _experienceCard(exp, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionTitle('EDUCATION', accentColor),
        ...resume.education.map((edu) => _educationBlock(edu, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionTitle('SKILLS', accentColor),
        pw.Wrap(
          spacing: 8,
          runSpacing: 6,
          children: resume.skills
              .map((skill) => _skillChip(skill.name, accentColor))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _projectBlock(project, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications
            .map((cert) => _certificationBlock(cert, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionTitle('LANGUAGES', accentColor),
        ...resume.languages.map(_languageLine),
        pw.SizedBox(height: 8),
      ];
    }
    for (final section in orderedUserCustomSections(resume)
      .where((value) => value.items.isNotEmpty)) {
      sections[section.id] = [
        _sectionTitle(section.title.toUpperCase(), accentColor,
            translate: false),
        ...section.items.map((item) => _customSectionItem(item, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: _pageBg,
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(14)),
                    border: pw.Border.all(
                      color: _scalePdfColor(accentColor, 1.0, 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        header: (context) =>
            context.pageNumber == 1 ? pw.SizedBox() : pw.SizedBox(height: 16),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 16),
          ..._applyPdfSectionOrder(sectionOrder, sections).map(
            (widget) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 18),
              child: widget,
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final contactLines = <String>[
      if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
      if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
      if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
        resume.personalInfo.linkedIn!,
      if ((resume.personalInfo.github ?? '').isNotEmpty)
        resume.personalInfo.github!,
      if ((resume.personalInfo.website ?? '').isNotEmpty)
        resume.personalInfo.website!,
      if (resume.personalInfo.address.isNotEmpty) resume.personalInfo.address,
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(14),
          topRight: pw.Radius.circular(14),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(
              resume.personalInfo.fullName.isEmpty
                  ? 'Your Name'
                  : resume.personalInfo.fullName,
            ),
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(resume.personalInfo.jobTitle!),
                style: pw.TextStyle(
                  fontSize: 13,
                  color: _scalePdfColor(accentColor, 1.0, 0.95),
                ),
              ),
            ),
          if (contactLines.isNotEmpty) ...[
            pw.SizedBox(height: 7),
            ...contactLines.map(_buildHeaderContactLine),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildHeaderContactLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          _sanitizePdfText(text),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _headerMuted,
            lineSpacing: 1.2,
          ),
        ),
      );

  pw.Widget _sectionTitle(
    String title,
    PdfColor accentColor, {
    bool translate = true,
  }) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        ),
        child: pw.Text(
          translate ? _h(title) : _sanitizePdfText(title),
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
      );

  List<pw.Widget> _buildProfileBullets(String text, PdfColor accentColor) {
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

    return segments.map((line) {
      final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 14,
              height: 12,
              child: pw.CustomPaint(
                size: const PdfPoint(14, 12),
                painter: (canvas, size) {
                  canvas.setFillColor(accentColor);
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
            ),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Text(
                cleanLine,
                style: const pw.TextStyle(
                  fontSize: 9.1,
                  color: _ink,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  pw.Widget _experienceCard(Experience exp, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _softCard,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _scalePdfColor(accentColor, 1.0, 0.18)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizePdfText(exp.position),
                        style: pw.TextStyle(
                          fontSize: 10.8,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _sanitizePdfText(exp.company),
                          style:
                              pw.TextStyle(fontSize: 9.2, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 120,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _monthRange(
                          exp.startDate,
                          exp.endDate,
                          exp.isCurrentlyWorking,
                        ),
                        style: const pw.TextStyle(fontSize: 8.8, color: _muted),
                        textAlign: pw.TextAlign.right,
                      ),
                      if ((exp.location ?? '').isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            _sanitizePdfText(exp.location!),
                            style: const pw.TextStyle(
                                fontSize: 8.6, color: _muted),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_collectExperienceLines(exp).isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ..._collectExperienceLines(exp)
                  .map((line) => _experienceLine(line, accentColor)),
            ],
          ],
        ),
      );

  pw.Widget _experienceLine(String line, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '• ',
              style: pw.TextStyle(fontSize: 8.8, color: accentColor),
            ),
            pw.Expanded(
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );

  pw.Widget _educationBlock(Education edu, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(
                      edu.degree.isEmpty ? edu.fieldOfStudy : edu.degree,
                    ),
                    style: pw.TextStyle(
                      fontSize: 10.2,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      _sanitizePdfText(
                        [
                          edu.institution,
                          if ((edu.location ?? '').isNotEmpty) edu.location!,
                        ].where((value) => value.trim().isNotEmpty).join(' • '),
                      ),
                      style: const pw.TextStyle(fontSize: 8.9, color: _muted),
                    ),
                  ),
                  if ((edu.grade ?? '').isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        'Grade: ${_sanitizePdfText(edu.grade!)}',
                        style: const pw.TextStyle(fontSize: 8.4, color: _ink),
                      ),
                    ),
                  if ((edu.description ?? '').isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        _sanitizePdfText(edu.description!),
                        style: const pw.TextStyle(
                          fontSize: 8.4,
                          color: _muted,
                          lineSpacing: 1.4,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 72,
              child: pw.Text(
                _yearRange(edu.startDate, edu.endDate, edu.isCurrentlyStudying),
                style: const pw.TextStyle(fontSize: 8.6, color: _muted),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );

  pw.Widget _skillChip(String label, PdfColor accentColor) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: _scalePdfColor(accentColor, 0.9, 1.0)),
        ),
        child: pw.Text(
          _sanitizePdfText(label),
          style: pw.TextStyle(
            fontSize: 8.4,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  pw.Widget _projectBlock(Project project, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _sanitizePdfText(project.title),
              style: pw.TextStyle(
                fontSize: 10.4,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            if (project.description.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  _sanitizePdfText(project.description),
                  style: const pw.TextStyle(
                    fontSize: 8.9,
                    color: _muted,
                    lineSpacing: 1.4,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            if (project.technologies.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  project.technologies.map(_sanitizePdfText).join(' • '),
                  style: pw.TextStyle(fontSize: 8.2, color: accentColor),
                ),
              ),
            if ((project.url ?? '').trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  _sanitizePdfText(project.url!),
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    color: accentColor,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      );

  pw.Widget _certificationBlock(Certification cert, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _sanitizePdfText(cert.name),
              style: pw.TextStyle(
                fontSize: 9,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (_certificationMeta(cert).isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _certificationMeta(cert),
                  style: const pw.TextStyle(fontSize: 8.4, color: _muted),
                ),
              ),
            if ((cert.credentialId ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  '${_h('Credential ID')}: ${_sanitizePdfText(cert.credentialId!)}',
                  style: pw.TextStyle(fontSize: 8.2, color: accentColor),
                ),
              ),
            if ((cert.credentialUrl ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _sanitizePdfText(cert.credentialUrl!),
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    color: accentColor,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      );

  pw.Widget _languageLine(Language language) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})',
          style: const pw.TextStyle(fontSize: 8.8, color: _muted),
        ),
      );

  pw.Widget _customSectionItem(CustomSectionItem item, PdfColor accentColor) {
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
                fontSize: 9.4,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: pw.TextStyle(fontSize: 8.6, color: accentColor),
              ),
            ),
          ...displayItem.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  color: _muted,
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

  String _monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText = isCurrent || end == null
        ? _present()
        : DateFormat('MMM yyyy').format(end);
    return '${DateFormat('MMM yyyy').format(start)} - $endText';
  }

  String _yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText =
        isCurrent || end == null ? _present() : DateFormat('yyyy').format(end);
    return '${DateFormat('yyyy').format(start)} - $endText';
  }

  String _certificationMeta(Certification cert) {
    final parts = <String>[];
    if (cert.issuer.isNotEmpty) {
      parts.add(_sanitizePdfText(cert.issuer));
    }
    if (cert.issueDate != null) {
      parts.add('${_h('Issued')} ${_pdfDate(cert.issueDate!)}');
    }
    if (cert.expiryDate != null) {
      parts.add('${_h('Expires')} ${_pdfDate(cert.expiryDate!)}');
    }
    return parts.join(' • ');
  }
}
