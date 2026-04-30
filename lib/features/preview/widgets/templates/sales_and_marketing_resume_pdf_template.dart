part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class SalesAndMarketingResumePdfTemplate extends PdfTemplate {
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFF2ECE5);
  static const PdfColor _divider = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _headerTitle = PdfColor.fromInt(0xFF4B5563);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final sections = <String, List<pw.Widget>>{};

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _buildSalesSection('OBJECTIVE', accentColor),
        ..._buildSalesBulletLines(
          _splitPdfLines(resume.objective),
          accentColor,
          fontSize: 9.8,
        ),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildSalesSection('PROFESSIONAL EXPERIENCE', accentColor),
        ...resume.experience.map(
            (experience) => _buildSalesExperience(experience, accentColor)),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildSalesSection('EDUCATION', accentColor),
        ...resume.education.map((education) => _buildSalesEducation(education)),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildSalesSection('SKILLS', accentColor),
        _buildSalesSkillsWrap(resume.skills, accentColor),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildSalesSection('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildSalesProject(project, accentColor)),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildSalesSection('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
          (certification) => _buildSalesCertification(certification),
        ),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildSalesSection('LANGUAGES', accentColor),
        ...resume.languages
            .map((language) => _buildSalesLanguageLine(language)),
        pw.SizedBox(height: 4),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) =>
          _buildSalesSection(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 40),
        build: (context) => [
          _buildSalesHeader(resume, accentColor),
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Container(
              height: 1,
              width: double.infinity,
              color: _divider,
            ),
          ),
          pw.SizedBox(height: 14),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildSalesHeader(ResumeModel resume, PdfColor accentColor) {
    final contactRows = _buildSalesContactRows(resume);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const pw.BoxDecoration(
        color: _headerBg,
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
                    color: _ink,
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
                        color: _headerTitle,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (contactRows.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildSalesHeaderContactGrid(contactRows, accentColor),
          ],
        ],
      ),
    );
  }

  List<List<_SalesPdfContactItem>> _buildSalesContactRows(ResumeModel resume) {
    final info = resume.personalInfo;
    final items = <_SalesPdfContactItem>[];

    void add(String icon, String? value) {
      final sanitized = _sanitizePdfText(value).trim();
      if (sanitized.isNotEmpty) {
        items.add(_SalesPdfContactItem(icon: icon, label: sanitized));
      }
    }

    add('email', info.email);
    add('phone', info.phone);
    add('location', info.address);
    add('linkedin', info.linkedIn);
    add('github', info.github);
    add('website', info.website);

    if (items.isEmpty) {
      return const [];
    }

    final rows = <List<_SalesPdfContactItem>>[];
    for (var index = 0; index < items.length; index += 3) {
      final end = index + 3 < items.length ? index + 3 : items.length;
      rows.add(items.sublist(index, end));
    }
    return rows;
  }

  pw.Widget _buildSalesHeaderContactGrid(
    List<List<_SalesPdfContactItem>> rows,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          if (rowIndex > 0) pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var columnIndex = 0; columnIndex < 3; columnIndex++) ...[
                pw.Expanded(
                  child: columnIndex < rows[rowIndex].length
                      ? _buildSalesHeaderItem(
                          rows[rowIndex][columnIndex],
                          accentColor,
                        )
                      : pw.SizedBox(),
                ),
                if (columnIndex != 2) pw.SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSalesHeaderItem(
    _SalesPdfContactItem item,
    PdfColor accentColor,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 13,
          height: 13,
          margin: const pw.EdgeInsets.only(top: 0.3),
          child: pw.CustomPaint(
            size: const PdfPoint(13, 13),
            painter: (canvas, size) {
              final centerX = size.x / 2;
              final centerY = size.y / 2;
              final radius = (size.x / 2) - 0.8;

              canvas.setFillColor(PdfColors.white);
              canvas.drawEllipse(centerX, centerY, radius, radius);
              canvas.fillPath();

              canvas.setStrokeColor(accentColor);
              canvas.setLineWidth(0.8);
              canvas.drawEllipse(centerX, centerY, radius, radius);
              canvas.strokePath();

              _drawSalesHeaderIcon(
                canvas,
                item.icon,
                centerX,
                centerY,
                radius * 0.62,
                accentColor,
              );
            },
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            item.label,
            style: const pw.TextStyle(
              fontSize: 8.1,
              color: _muted,
              lineSpacing: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  void _drawSalesHeaderIcon(
    PdfGraphics canvas,
    String iconType,
    double cx,
    double cy,
    double r,
    PdfColor color,
  ) {
    if (iconType == 'github') {
      canvas.setStrokeColor(color);
      canvas.setLineWidth(r * 0.22);
      canvas.moveTo(cx - r * 0.72, cy);
      canvas.lineTo(cx - r * 0.28, cy + r * 0.54);
      canvas.moveTo(cx - r * 0.72, cy);
      canvas.lineTo(cx - r * 0.28, cy - r * 0.54);
      canvas.moveTo(cx + r * 0.72, cy);
      canvas.lineTo(cx + r * 0.28, cy + r * 0.54);
      canvas.moveTo(cx + r * 0.72, cy);
      canvas.lineTo(cx + r * 0.28, cy - r * 0.54);
      canvas.moveTo(cx - r * 0.08, cy - r * 0.78);
      canvas.lineTo(cx + r * 0.08, cy + r * 0.78);
      canvas.strokePath();
      return;
    }

    _drawPdfIcon(canvas, iconType, cx, cy, r, color);
  }

  pw.Widget _buildSalesSection(String title, PdfColor accentColor) {
    return _buildRightBarSectionHeader(
      title,
      textColor: _ink,
      dividerColor: _divider,
      barColor: accentColor,
      fontSize: 11.6,
      letterSpacing: 0.9,
      marginBottom: 12,
      titleBottomSpacing: 4,
      barHeight: 11,
    );
  }

  List<pw.Widget> _buildSalesBulletLines(
    List<String> lines,
    PdfColor accentColor, {
    double fontSize = 9.2,
    PdfColor textColor = _muted,
    double bottomPadding = 5,
  }) {
    if (lines.isEmpty) {
      return const [];
    }

    return lines
        .map(
          (line) => pw.Padding(
            padding: pw.EdgeInsets.only(bottom: bottomPadding),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 11,
                  child: pw.CustomPaint(
                    size: const PdfPoint(11, 11),
                    painter: (canvas, size) {
                      canvas.setFillColor(accentColor);
                      canvas.drawEllipse(5.5, 5.5, 2.0, 2.0);
                      canvas.fillPath();
                    },
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    line,
                    style: pw.TextStyle(
                      fontSize: fontSize,
                      color: textColor,
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

  pw.Widget _buildSalesExperience(Experience experience, PdfColor accentColor) {
    final company = _sanitizePdfText(experience.company).trim();
    final location = _sanitizePdfText(experience.location).trim();
    final companyLine = [
      if (company.isNotEmpty) company,
      if (location.isNotEmpty) location,
    ].join(' - ');
    final details = _collectExperienceLines(experience);

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(experience.position).trim().isEmpty
                      ? 'Role Title'
                      : _sanitizePdfText(experience.position),
                  style: pw.TextStyle(
                    fontSize: 10.8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 106,
                child: pw.Text(
                  _dateRange(
                    experience.startDate,
                    experience.endDate,
                    experience.isCurrentlyWorking,
                  ),
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: _muted,
                    lineSpacing: 1.2,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if (companyLine.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _fullWidthText(
              companyLine,
              style: const pw.TextStyle(fontSize: 9.2, color: _muted),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._buildSalesBulletLines(
              details,
              accentColor,
              fontSize: 9,
              textColor: _muted,
              bottomPadding: 4,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSalesEducation(Education education) {
    final degree = [
      _sanitizePdfText(education.degree).trim(),
      _sanitizePdfText(education.fieldOfStudy).trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    final institution = [
      _sanitizePdfText(education.institution).trim(),
      _sanitizePdfText(education.location).trim(),
    ].where((value) => value.isNotEmpty).join(' - ');

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  degree.isEmpty ? 'Education' : degree,
                  style: pw.TextStyle(
                    fontSize: 10.6,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 82,
                child: pw.Text(
                  _educationDateRange(education),
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: _muted,
                    lineSpacing: 1.2,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if (institution.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _fullWidthText(
              institution,
              style: const pw.TextStyle(fontSize: 9.2, color: _muted),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          if (education.grade != null && education.grade!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: _fullWidthText(
                'Grade: ${_sanitizePdfText(education.grade!)}',
                style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                textAlign: pw.TextAlign.justify,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSalesProject(Project project, PdfColor accentColor) {
    final title = _sanitizePdfText(project.title).trim();
    final description = _sanitizePdfText(project.description).trim();
    final technologies = project.technologies
        .map((item) => _sanitizePdfText(item).trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    final url = _sanitizePdfText(project.url).trim();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.isEmpty ? 'Project' : title,
            style: pw.TextStyle(
              fontSize: 9.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            _fullWidthText(
              description,
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _muted,
                lineSpacing: 1.45,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          if (technologies.isNotEmpty) ...[
            pw.SizedBox(height: 1.3),
            _fullWidthText(
              'Technologies: $technologies',
              style: const pw.TextStyle(fontSize: 8.3, color: _muted),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          if (url.isNotEmpty && !description.contains(url)) ...[
            pw.SizedBox(height: 1.3),
            _fullWidthText(
              url,
              style: pw.TextStyle(fontSize: 8.3, color: accentColor),
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSalesCertification(Certification certification) {
    final name = _sanitizePdfText(certification.name).trim();
    final details = [
      _sanitizePdfText(certification.issuer).trim(),
      _sanitizePdfText(certification.credentialId).trim(),
    ].where((value) => value.isNotEmpty).join('  |  ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _fullWidthText(
            name.isEmpty ? 'Certification' : name,
            style: pw.TextStyle(
              fontSize: 9.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
            textAlign: pw.TextAlign.justify,
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 1.3),
            _fullWidthText(
              details,
              style: const pw.TextStyle(fontSize: 8.4, color: _muted),
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSalesSkillsWrap(List<Skill> skills, PdfColor accentColor) {
    final names = skills
        .map((skill) => _sanitizePdfText(skill.name).trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names
          .map((name) => _buildSalesSkillChip(name, accentColor))
          .toList(growable: false),
    );
  }

  pw.Widget _buildSalesSkillChip(String label, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accentColor, 0.11),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _scalePdfColor(accentColor, 1.0, 0.22)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: accentColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildSalesLanguageLine(Language language) {
    final name = _sanitizePdfText(language.name).trim();
    final proficiency = _sanitizePdfText(language.proficiency).trim();
    final value = [
      if (name.isNotEmpty) name,
      if (proficiency.isNotEmpty) proficiency,
    ].join(' - ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: _fullWidthText(
        value,
        style: const pw.TextStyle(fontSize: 8.8, color: _muted),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  String _educationDateRange(Education education) {
    final start = DateFormat('yyyy').format(education.startDate);
    final end = education.isCurrentlyStudying
        ? _present()
        : DateFormat('yyyy').format(education.endDate ?? education.startDate);
    return '$start - $end';
  }

  pw.Widget _fullWidthText(
    String text, {
    required pw.TextStyle style,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(text, style: style, textAlign: textAlign),
    );
  }

  String _dateRange(DateTime startDate, DateTime? endDate, bool isCurrent) {
    final start = DateFormat('MMM yyyy').format(startDate);
    final end = isCurrent
        ? _present()
        : DateFormat('MMM yyyy').format(endDate ?? startDate);
    return '$start - $end';
  }
}

class _SalesPdfContactItem {
  const _SalesPdfContactItem({required this.icon, required this.label});

  final String icon;
  final String label;
}
