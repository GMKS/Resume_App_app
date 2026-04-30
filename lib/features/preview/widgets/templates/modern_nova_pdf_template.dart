part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ModernNovaPdfTemplate extends PdfTemplate {
  static const PdfColor _ink = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final headerEnd = _blendWithWhite(accentColor, 0.18);
    final sections = <String, List<pw.Widget>>{};

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _buildSectionTitle('PROFESSIONAL SUMMARY', accentColor),
        ..._buildBulletLines(
          _splitPdfLines(resume.objective),
          accentColor,
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildSectionTitle('WORK EXPERIENCE', accentColor),
        ...resume.experience.map(
            (experience) => _buildExperienceEntry(experience, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildSectionTitle('EDUCATION', accentColor),
        ...resume.education
            .map((education) => _buildEducationEntry(education, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildSectionTitle('SKILLS', accentColor),
        pw.Wrap(
          spacing: 7,
          runSpacing: 7,
          children: resume.skills
              .map((skill) => _buildSkillChip(skill.name, accentColor))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildSectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildProjectEntry(project, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildSectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
          (certification) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _formatCertification(certification),
              style: const pw.TextStyle(
                fontSize: 9.3,
                color: _muted,
                lineSpacing: 1.35,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildSectionTitle('LANGUAGES', accentColor),
        pw.Wrap(
          spacing: 14,
          runSpacing: 5,
          children: resume.languages
              .map(
                (language) => pw.Text(
                  _formatLanguage(language),
                  style: const pw.TextStyle(fontSize: 9.3, color: _muted),
                ),
              )
              .toList(growable: false),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 10,
      headerBuilder: (title) =>
          _buildSectionTitle(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
        ),
        build: (context) => [
          _buildHeader(resume, accentColor, headerEnd),
          pw.SizedBox(height: 22),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  PdfColor _blendWithWhite(PdfColor color, double amount) {
    final t = amount.clamp(0.0, 1.0);
    return PdfColor(
      color.red + (1 - color.red) * t,
      color.green + (1 - color.green) * t,
      color.blue + (1 - color.blue) * t,
      color.alpha,
    );
  }

  pw.Widget _buildHeader(
    ResumeModel resume,
    PdfColor accentColor,
    PdfColor headerEnd,
  ) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim())
        : 'Your Name';
    final title = resume.personalInfo.jobTitle?.trim() ?? '';
    final contactItems = _buildContactItems(resume);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [accentColor, headerEnd]),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(18)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (title.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      _sanitizePdfText(title),
                      style: const pw.TextStyle(
                        fontSize: 13,
                        color: PdfColor(1, 1, 1, 0.92),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (contactItems.isNotEmpty) ...[
            pw.SizedBox(width: 18),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: contactItems
                  .map((item) => _buildContactPill(item, accentColor))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  List<_ModernNovaPdfContactItem> _buildContactItems(ResumeModel resume) {
    final items = <_ModernNovaPdfContactItem>[];

    void add(String icon, String? value) {
      final trimmed = _sanitizePdfText(value).trim();
      if (trimmed.isNotEmpty) {
        items.add(_ModernNovaPdfContactItem(icon: icon, value: trimmed));
      }
    }

    add('email', resume.personalInfo.email);
    add('phone', resume.personalInfo.phone);
    add('location', resume.personalInfo.address);
    add('linkedin', resume.personalInfo.linkedIn);
    add('website', resume.personalInfo.github);
    add('website', resume.personalInfo.website);

    return items;
  }

  pw.Widget _buildContactPill(
    _ModernNovaPdfContactItem item,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: 208,
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 16,
            height: 16,
            child: pw.CustomPaint(
              size: const PdfPoint(16, 16),
              painter: (canvas, size) {
                final radius = size.x / 2;
                canvas.setFillColor(accentColor);
                canvas.drawEllipse(radius, radius, radius, radius);
                canvas.fillPath();
                _drawPdfIcon(
                  canvas,
                  item.icon,
                  radius,
                  radius,
                  radius * 0.56,
                  PdfColors.white,
                );
              },
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              item.value,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 8.4,
                color: accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, PdfColor accentColor) {
    final underlineWidth = (title.length * 5.6).clamp(58.0, 170.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 13,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: underlineWidth,
            height: 2.2,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildBulletLines(
    List<String> lines,
    PdfColor accentColor, {
    double fontSize = 9.6,
    PdfColor textColor = _muted,
  }) {
    final cleanedLines = lines
        .map((line) => _sanitizePdfText(line).trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return cleanedLines.map((line) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 5,
              height: 5,
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              decoration: pw.BoxDecoration(
                color: accentColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                line,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  pw.Widget _buildExperienceEntry(Experience experience, PdfColor accentColor) {
    final dateRange = _formatExperienceDateRange(experience);
    final companyLine = [
      if (experience.company.trim().isNotEmpty)
        _sanitizePdfText(experience.company.trim()),
      if ((experience.location?.trim().isNotEmpty ?? false))
        _sanitizePdfText(experience.location!.trim()),
    ].join(' - ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(experience.position),
                      style: pw.TextStyle(
                        fontSize: 12.4,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (companyLine.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(
                          companyLine,
                          style:
                              pw.TextStyle(fontSize: 9.4, color: accentColor),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.SizedBox(
                width: 112,
                child: pw.Text(
                  dateRange,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 9.2, color: _muted),
                ),
              ),
            ],
          ),
          ..._buildBulletLines(
            _collectExperienceLines(experience),
            accentColor,
            fontSize: 9.1,
          ),
        ],
      ),
    );
  }

  String _formatExperienceDateRange(Experience experience) {
    final startLabel = DateFormat('MMM yyyy').format(experience.startDate);
    if (experience.isCurrentlyWorking) {
      return '$startLabel - ${_present()}';
    }

    final endDate = experience.endDate;
    if (endDate == null) {
      return startLabel;
    }

    return '$startLabel - ${DateFormat('MMM yyyy').format(endDate)}';
  }

  pw.Widget _buildEducationEntry(Education education, PdfColor accentColor) {
    final degree = _sanitizePdfText(
      '${education.degree} ${education.fieldOfStudy}'.trim(),
    );
    final institutionLine = [
      if (education.institution.trim().isNotEmpty)
        _sanitizePdfText(education.institution.trim()),
      if ((education.location?.trim().isNotEmpty ?? false))
        _sanitizePdfText(education.location!.trim()),
    ].join(' - ');
    final dateRange =
        '${education.startDate.year} - ${education.isCurrentlyStudying ? _present() : (education.endDate?.year.toString() ?? _present())}';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  degree.isNotEmpty ? degree : 'Education',
                  style: pw.TextStyle(
                    fontSize: 11.4,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (institutionLine.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      institutionLine,
                      style: pw.TextStyle(fontSize: 9.2, color: accentColor),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.SizedBox(
            width: 84,
            child: pw.Text(
              dateRange,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9.1, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillChip(String skill, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _blendWithWhite(accentColor, 0.88),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
            color: _blendWithWhite(accentColor, 0.64), width: 0.6),
      ),
      child: pw.Text(
        _sanitizePdfText(skill),
        style: pw.TextStyle(
          fontSize: 8.8,
          color: accentColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildProjectEntry(Project project, PdfColor accentColor) {
    final descriptionLines = _splitPdfLines(
      project.description.trim().isNotEmpty
          ? project.description
          : project.technologies.join(', '),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 11.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (descriptionLines.isNotEmpty)
            ..._buildBulletLines(
              descriptionLines,
              accentColor,
              fontSize: 9.1,
            ),
          if (project.url?.trim().isNotEmpty ?? false)
            pw.Text(
              _sanitizePdfText(project.url!.trim()),
              style: pw.TextStyle(
                fontSize: 8.8,
                color: accentColor,
                decoration: pw.TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }

  String _formatCertification(Certification certification) {
    final issuer = _sanitizePdfText(certification.issuer).trim();
    final name = _sanitizePdfText(certification.name).trim();
    if (issuer.isEmpty) {
      return name;
    }
    return '$name - $issuer';
  }

  String _formatLanguage(Language language) {
    final name = _sanitizePdfText(language.name).trim();
    final proficiency = _sanitizePdfText(language.proficiency).trim();
    if (proficiency.isEmpty) {
      return name;
    }
    return '$name ($proficiency)';
  }
}

class _ModernNovaPdfContactItem {
  const _ModernNovaPdfContactItem({required this.icon, required this.value});

  final String icon;
  final String value;
}
