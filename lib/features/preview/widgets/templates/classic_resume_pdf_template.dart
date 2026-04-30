part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ClassicResumePdfTemplate extends PdfTemplate {
  static const PdfColor _warmHeader = PdfColor.fromInt(0xFFF2ECE5);
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _divider = PdfColor.fromInt(0xFFD1D5DB);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final sections = <String, List<pw.Widget>>{};

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _buildSectionTitle('OBJECTIVE', accentColor),
        ..._buildBulletLines(
          _splitPdfLines(resume.objective),
          accentColor,
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildSectionTitle('PROFESSIONAL EXPERIENCE', accentColor),
        ...resume.experience.map(
            (experience) => _buildExperienceEntry(experience, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildSectionTitle('EDUCATION', accentColor),
        ...resume.education
            .map((education) => _buildEducationEntry(education, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildSectionTitle('SKILLS', accentColor),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
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
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildSectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
          (certification) =>
              _buildCertificationEntry(certification, accentColor),
        ),
        pw.SizedBox(height: 10),
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
                  style: const pw.TextStyle(fontSize: 9.1, color: _muted),
                ),
              )
              .toList(growable: false),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    for (final section in orderedUserCustomSections(resume)
      .where((value) => value.items.isNotEmpty)) {
      sections[section.id] = [
        _buildSectionTitle(section.title.toUpperCase(), accentColor,
            translate: false),
        ...section.items.map(
          (item) => _buildCustomSectionItem(item, accentColor),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(42, 40, 42, 36),
        ),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 16),
          pw.Container(height: 0.9, color: _divider),
          pw.SizedBox(height: 16),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim())
        : 'YOUR NAME';
    final title = resume.personalInfo.jobTitle?.trim() ?? '';
    final contactItems = _buildContactItems(resume);

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const pw.BoxDecoration(
        color: _warmHeader,
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
                  name,
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              if (title.isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    _sanitizePdfText(title),
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: _muted,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
          if (contactItems.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 14,
              runSpacing: 4,
              children: contactItems
                  .map((item) => _buildHeaderItem(item, accentColor))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  List<_ClassicResumePdfContactItem> _buildContactItems(ResumeModel resume) {
    final items = <_ClassicResumePdfContactItem>[];

    void add(String icon, String? value) {
      final trimmed = _sanitizePdfText(value).trim();
      if (trimmed.isNotEmpty) {
        items.add(_ClassicResumePdfContactItem(icon: icon, value: trimmed));
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

  pw.Widget _buildHeaderItem(
    _ClassicResumePdfContactItem item,
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
              final radius = size.x / 2;
              canvas.setFillColor(accentColor);
              canvas.drawEllipse(radius, radius, radius, radius);
              canvas.fillPath();
              _drawPdfIcon(
                canvas,
                item.icon,
                radius,
                radius,
                radius * 0.5,
                PdfColors.white,
              );
            },
          ),
        ),
        pw.Text(
          item.value,
          style: const pw.TextStyle(fontSize: 8.1, color: _muted),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(
    String title,
    PdfColor accentColor, {
    bool translate = true,
  }) {
    return _buildRightBarSectionHeader(
      translate ? title : _sanitizePdfText(title),
      textColor: _ink,
      dividerColor: _divider,
      barColor: accentColor,
      fontSize: 12,
      letterSpacing: 0.9,
      marginBottom: 12,
      titleBottomSpacing: 4,
      barHeight: 12,
    );
  }

  List<pw.Widget> _buildBulletLines(
    List<String> lines,
    PdfColor accentColor, {
    double fontSize = 9.3,
    PdfColor textColor = _muted,
  }) {
    final cleaned = lines
        .map((line) => _sanitizePdfText(line).trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return cleaned.map((line) {
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
    final companyLine = [
      if (experience.company.trim().isNotEmpty)
        _sanitizePdfText(experience.company.trim()),
      if ((experience.location?.trim().isNotEmpty ?? false))
        _sanitizePdfText(experience.location!.trim()),
    ].join(' - ');
    final dateRange =
        '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(experience.endDate!)}';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
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
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    if (companyLine.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          companyLine,
                          style:
                              const pw.TextStyle(fontSize: 9.5, color: _muted),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 110,
                child: pw.Text(
                  dateRange,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if (_collectExperienceLines(experience).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ..._buildBulletLines(
              _collectExperienceLines(experience),
              accentColor,
              fontSize: 9.0,
            ),
          ],
        ],
      ),
    );
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
                      degree.isNotEmpty ? degree : 'Education',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    if (institutionLine.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          institutionLine,
                          style:
                              const pw.TextStyle(fontSize: 9.4, color: _muted),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 86,
                child: pw.Text(
                  _yearRange(
                    education.startDate,
                    education.endDate,
                    education.isCurrentlyStudying,
                  ),
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if ((education.grade ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                'Grade: ${_sanitizePdfText(education.grade!)}',
                style: const pw.TextStyle(fontSize: 8.8, color: _muted),
              ),
            ),
          if ((education.description ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(education.description!),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillChip(String label, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _blendWithWhite(accentColor, 0.9),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
          color: _blendWithWhite(accentColor, 0.72),
          width: 0.7,
        ),
      ),
      child: pw.Text(
        _sanitizePdfText(label),
        style: pw.TextStyle(
          fontSize: 8.8,
          color: accentColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildProjectEntry(Project project, PdfColor accentColor) {
    final detailLines = _splitPdfLines(
      project.description.trim().isNotEmpty
          ? project.description
          : project.technologies.join(', '),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (detailLines.isNotEmpty)
            ..._buildBulletLines(
              detailLines,
              accentColor,
              fontSize: 8.9,
            ),
          if ((project.url ?? '').trim().isNotEmpty)
            pw.Text(
              _sanitizePdfText(project.url!.trim()),
              style: pw.TextStyle(
                fontSize: 8.6,
                color: accentColor,
                decoration: pw.TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationEntry(
    Certification certification,
    PdfColor accentColor,
  ) {
    final meta = _certificationMeta(certification);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(certification.name),
            style: pw.TextStyle(
              fontSize: 10,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (meta.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                meta,
                style: const pw.TextStyle(fontSize: 8.8, color: _muted),
              ),
            ),
          if ((certification.credentialUrl ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(certification.credentialUrl!.trim()),
                style: pw.TextStyle(
                  fontSize: 8.3,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomSectionItem(
    CustomSectionItem item,
    PdfColor accentColor,
  ) {
    final displayItem = buildUserCustomSectionDisplayItem(item);
    final metaParts = <String>[];
    if (displayItem.subtitle.isNotEmpty) {
      metaParts.add(_sanitizePdfText(displayItem.subtitle));
    }
    if (displayItem.date != null) {
      metaParts.add(DateFormat('MMM yyyy').format(displayItem.date!));
    }

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
                fontSize: 9.6,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: pw.TextStyle(fontSize: 8.8, color: accentColor),
              ),
            ),
          ...displayItem.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.7,
                  color: _muted,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText = isCurrent || end == null ? _present() : end.year.toString();
    return '${start.year} - $endText';
  }

  String _certificationMeta(Certification certification) {
    final parts = <String>[];
    if (certification.issuer.trim().isNotEmpty) {
      parts.add(_sanitizePdfText(certification.issuer.trim()));
    }
    if ((certification.credentialId ?? '').trim().isNotEmpty) {
      parts.add(
          '${_h('Credential ID')}: ${_sanitizePdfText(certification.credentialId!.trim())}');
    }
    return parts.join(' • ');
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

class _ClassicResumePdfContactItem {
  const _ClassicResumePdfContactItem({required this.icon, required this.value});

  final String icon;
  final String value;
}
