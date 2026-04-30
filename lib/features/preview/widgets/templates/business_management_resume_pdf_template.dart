part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class BusinessManagementResumePdfTemplate extends PdfTemplate {
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
    final sectionOrder = await _loadPdfSectionOrder(normalizedResume);
    final sections = <String, List<pw.Widget>>{};

    if (normalizedResume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _buildExecutiveSection('OBJECTIVE', accentColor),
        ..._buildExecutiveSummaryBullets(
          normalizedResume.objective!,
          accentColor,
        ),
        pw.SizedBox(height: 16),
      ];
    }
    if (normalizedResume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildExecutiveSection('PROFESSIONAL EXPERIENCE', accentColor),
        ...normalizedResume.experience
            .map((exp) => _buildExecutiveExperience(exp, accentColor)),
      ];
    }
    if (normalizedResume.education.isNotEmpty) {
      sections['education'] = [
        _buildExecutiveSection('EDUCATION', accentColor),
        ...normalizedResume.education
            .map((edu) => _buildExecutiveEducation(edu, accentColor)),
      ];
    }
    if (normalizedResume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildExecutiveSection('SKILLS', accentColor),
        _fullWidthText(
          normalizedResume.skills
              .map((skill) => _sanitizePdfText(skill.name))
              .join('  /  '),
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 14),
      ];
    }
    if (normalizedResume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildExecutiveSection('PROJECTS', accentColor),
        ...normalizedResume.projects
            .map((project) => _buildExecutiveProject(project, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }
    if (normalizedResume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildExecutiveSection('CERTIFICATIONS', accentColor),
        ...normalizedResume.certifications.map(
          (cert) => _buildExecutiveCertification(cert, accentColor),
        ),
        pw.SizedBox(height: 12),
      ];
    }
    if (normalizedResume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildExecutiveSection('LANGUAGES', accentColor),
        _fullWidthText(
          normalizedResume.languages
              .map(
                (lang) =>
                    '${_sanitizePdfText(lang.name)} (${_sanitizePdfText(lang.proficiency)})',
              )
              .join('   '),
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 12),
      ];
    }

    for (final section in orderedUserCustomSections(normalizedResume)) {
      if (section.items.isEmpty) {
        continue;
      }
      sections[section.id] = [
        _buildExecutiveSection(section.title.toUpperCase(), accentColor),
        ...section.items.map(
          (item) {
            final displayItem = buildUserCustomSectionDisplayItem(item);
            final metaParts = <String>[
              if (displayItem.subtitle.isNotEmpty)
                _sanitizePdfText(displayItem.subtitle),
              if (displayItem.date != null)
                DateFormat('MMM yyyy').format(displayItem.date!),
            ];

            if (!displayItem.hasContent) {
              return pw.SizedBox.shrink();
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 12,
                    child: pw.CustomPaint(
                      size: const PdfPoint(12, 12),
                      painter: (canvas, size) {
                        canvas.setFillColor(accentColor);
                        canvas.drawEllipse(6, 6, 2.5, 2.5);
                        canvas.fillPath();
                      },
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (displayItem.heading.isNotEmpty)
                          _fullWidthText(
                            _sanitizePdfText(displayItem.heading),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              lineSpacing: 1.6,
                            ),
                            textAlign: pw.TextAlign.justify,
                          ),
                        if (metaParts.isNotEmpty)
                          _fullWidthText(
                            metaParts.join('  |  '),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                            textAlign: pw.TextAlign.justify,
                          ),
                        ...displayItem.detailLines.map(
                          (line) => pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: _fullWidthText(
                              _sanitizePdfText(line),
                              style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: PdfColors.grey700,
                                lineSpacing: 1.4,
                              ),
                              textAlign: pw.TextAlign.justify,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        pw.SizedBox(height: 12),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 40),
        build: (context) => [
          _buildExecutiveHeader(normalizedResume, accentColor),
          pw.SizedBox(height: 18),
          pw.Container(
            height: 1,
            width: double.infinity,
            color: PdfColors.grey800,
          ),
          pw.SizedBox(height: 20),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildExecutiveHeader(ResumeModel resume, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF2ECE5),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  resume.personalInfo.fullName.isEmpty
                      ? 'YOUR NAME'
                      : _sanitizePdfText(resume.personalInfo.fullName),
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 118,
                  child: pw.Align(
                    alignment: pw.Alignment.topRight,
                    child: pw.Text(
                      _sanitizePdfText(resume.personalInfo.jobTitle!),
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        color: PdfColors.grey700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (resume.personalInfo.email.isNotEmpty)
                _buildExecutiveHeaderItem(
                  'email',
                  resume.personalInfo.email,
                  accentColor,
                ),
              if (resume.personalInfo.phone.isNotEmpty)
                _buildExecutiveHeaderItem(
                  'phone',
                  resume.personalInfo.phone,
                  accentColor,
                ),
              if (resume.personalInfo.address.isNotEmpty)
                _buildExecutiveHeaderItem(
                  'location',
                  resume.personalInfo.address,
                  accentColor,
                ),
              if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                _buildExecutiveHeaderItem(
                  'linkedin',
                  resume.personalInfo.linkedIn!,
                  accentColor,
                ),
              if (resume.personalInfo.website?.isNotEmpty ?? false)
                _buildExecutiveHeaderItem(
                  'website',
                  resume.personalInfo.website!,
                  accentColor,
                ),
              if (resume.personalInfo.github?.isNotEmpty ?? false)
                _buildExecutiveHeaderItem(
                  'website',
                  resume.personalInfo.github!,
                  accentColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveHeaderItem(
    String icon,
    String value,
    PdfColor accentColor,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          margin: const pw.EdgeInsets.only(right: 4),
          child: pw.CustomPaint(
            size: const PdfPoint(12, 12),
            painter: (canvas, size) {
              final cx = size.x / 2;
              final cy = size.y / 2;
              canvas.setFillColor(accentColor);
              canvas.drawEllipse(cx, cy, cx, cy);
              canvas.fillPath();
              _drawPdfIcon(canvas, icon, cx, cy, cx * 0.5, PdfColors.white);
            },
          ),
        ),
        pw.Text(
          _sanitizePdfText(value),
          style: const pw.TextStyle(fontSize: 8.1, color: PdfColors.grey800),
        ),
      ],
    );
  }

  pw.Widget _buildExecutiveSection(String title, PdfColor accentColor) {
    return _buildRightBarSectionHeader(
      title,
      textColor: PdfColors.grey900,
      dividerColor: PdfColors.grey400,
      barColor: accentColor,
      fontSize: 12,
      letterSpacing: 0.9,
      marginBottom: 12,
      titleBottomSpacing: 4,
      barHeight: 12,
    );
  }

  List<pw.Widget> _buildExecutiveSummaryBullets(
    String text,
    PdfColor accentColor,
  ) {
    final segments = _splitPdfLines(text);
    if (segments.isEmpty) {
      return const [];
    }

    return segments.map((line) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 12,
              child: pw.CustomPaint(
                size: const PdfPoint(12, 12),
                painter: (canvas, size) {
                  canvas.setFillColor(accentColor);
                  canvas.drawEllipse(6, 6, 2.5, 2.5);
                  canvas.fillPath();
                },
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.6),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  pw.Widget _buildExecutiveExperience(Experience exp, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
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
                  _sanitizePdfText(exp.position),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 98,
                child: pw.Text(
                  _dateRange(
                    exp.startDate,
                    exp.endDate,
                    exp.isCurrentlyWorking,
                    'MMM yyyy',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          _fullWidthText(
            _sanitizePdfText(
              '${exp.company}${exp.location != null && exp.location!.isNotEmpty ? ' - ${exp.location}' : ''}',
            ),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
            textAlign: pw.TextAlign.justify,
          ),
          if (_collectExperienceLines(exp).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._buildExperienceLineWidgets(
              exp,
              accentColor,
              fontSize: 9,
              leftPadding: 16,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveEducation(Education edu, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(edu.degree),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                DateFormat('yyyy').format(edu.endDate ?? edu.startDate),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          _fullWidthText(
            _sanitizePdfText(
              '${edu.institution}${edu.location != null && edu.location!.isNotEmpty ? ' - ${edu.location}' : ''}',
            ),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
            textAlign: pw.TextAlign.justify,
          ),
          if (edu.grade != null && edu.grade!.isNotEmpty)
            _fullWidthText(
              'Grade: ${_sanitizePdfText(edu.grade!)}',
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveProject(Project project, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (project.description.isNotEmpty)
            _fullWidthText(
              _sanitizePdfText(project.description),
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.45),
              textAlign: pw.TextAlign.justify,
            ),
          if (project.technologies.isNotEmpty)
            _fullWidthText(
              'Stack: ${project.technologies.map(_sanitizePdfText).join(', ')}',
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.grey800,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          if (project.url?.isNotEmpty ?? false)
            _fullWidthText(
              _sanitizePdfText(project.url!),
              style: pw.TextStyle(fontSize: 8.5, color: accentColor),
              textAlign: pw.TextAlign.justify,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveCertification(
    Certification cert,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _fullWidthText(
              _sanitizePdfText(cert.name),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.justify,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _sanitizePdfText(cert.issuer),
                style: pw.TextStyle(fontSize: 8.8, color: accentColor),
              ),
              if ((cert.credentialId ?? '').isNotEmpty)
                pw.Text(
                  _sanitizePdfText(cert.credentialId!),
                  style: const pw.TextStyle(
                    fontSize: 8.1,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _fullWidthText(
    String text, {
    required pw.TextStyle style,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  String _dateRange(
    DateTime startDate,
    DateTime? endDate,
    bool isCurrent,
    String pattern,
  ) {
    final start = DateFormat(pattern).format(startDate);
    final end = isCurrent
        ? _present()
        : DateFormat(pattern).format(endDate ?? startDate);
    return '$start - $end';
  }
}
