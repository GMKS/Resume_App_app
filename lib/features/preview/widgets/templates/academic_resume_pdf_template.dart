part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class AcademicResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFFAF8F5);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2D2D2D);
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _light = PdfColor.fromInt(0xFF8A8A8A);

  static const _defaultOrder = <String>[
    'summary',
    'education',
    'skills',
    'experience',
    'projects',
    'certifications',
    'languages',
  ];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: _defaultOrder,
      allowedKeys: _defaultOrder,
    );
    final softRule = _blendPdfWithWhite(accentColor, 0.65);
    final sections = <String, List<pw.Widget>>{};

    final objectiveLines = _objectiveLines(resume.objective);
    if (objectiveLines.isNotEmpty) {
      sections['summary'] = [
        _buildSectionHeader('OBJECTIVE', accentColor, softRule),
        ..._buildObjectivePoints(objectiveLines, accentColor),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildSectionHeader('EDUCATION', accentColor, softRule),
        ...resume.education.map(
          (education) => _buildEducationItem(education, accentColor),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildSectionHeader('SKILLS', accentColor, softRule),
        _buildSkillChips(resume.skills, accentColor),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildSectionHeader('EXPERIENCE', accentColor, softRule),
        ...resume.experience.map(
          (experience) => _buildExperienceItem(experience, accentColor),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildSectionHeader('PROJECTS', accentColor, softRule),
        ...resume.projects.map(
          (project) => _buildProjectItem(project, accentColor),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildSectionHeader('CERTIFICATIONS', accentColor, softRule),
        ...resume.certifications.map(
          (certification) => _buildCertificationItem(certification),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildSectionHeader('LANGUAGES', accentColor, softRule),
        ...resume.languages.map(_buildLanguageItem),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) =>
          _buildSectionHeader(title.toUpperCase(), accentColor, softRule),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(44, 34, 34, 32),
          buildBackground: (context) => _buildBackground(accentColor),
        ),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 16),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(PdfColor accentColor) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Container(color: _pageBg),
          ),
          pw.Positioned(
            left: 8,
            top: 14,
            bottom: 14,
            child: pw.Container(width: 5, color: accentColor),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isEmpty
        ? 'JOHN SMITH'
        : _sanitizePdfText(resume.personalInfo.fullName.trim().toUpperCase());
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final contactLines = _contactLines(resume);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 23,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 1.0,
          ),
        ),
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Container(height: 1.0, width: double.infinity, color: _ink),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 0.45,
          width: double.infinity,
          color: const PdfColor.fromInt(0xFFCCCCCC),
        ),
        if (contactLines.isNotEmpty) ...[
          pw.SizedBox(height: 7),
          ...contactLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1.5),
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSectionHeader(
    String title,
    PdfColor accentColor,
    PdfColor ruleColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 7, height: 7, color: accentColor),
              pw.SizedBox(width: 7),
              pw.Text(
                _h(title),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 0.7,
            color: ruleColor,
          ),
          pw.SizedBox(height: 3),
        ],
      ),
    );
  }

  List<pw.Widget> _buildObjectivePoints(
    List<String> lines,
    PdfColor accentColor,
  ) {
    return lines
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.6),
                  child: _buildSparkleBullet(accentColor),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _fullWidthText(
                    line,
                    style: const pw.TextStyle(
                      fontSize: 10,
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

  pw.Widget _buildSparkleBullet(PdfColor accentColor) {
    return pw.SizedBox(
      width: 10,
      height: 10,
      child: pw.CustomPaint(
        size: const PdfPoint(10, 10),
        painter: (canvas, size) {
          final centerX = size.x / 2;
          final centerY = size.y / 2;
          canvas
            ..setStrokeColor(accentColor)
            ..setLineWidth(0.9)
            ..moveTo(centerX, size.y * 0.1)
            ..lineTo(centerX, size.y * 0.9)
            ..moveTo(size.x * 0.1, centerY)
            ..lineTo(size.x * 0.9, centerY)
            ..moveTo(size.x * 0.24, size.y * 0.24)
            ..lineTo(size.x * 0.76, size.y * 0.76)
            ..moveTo(size.x * 0.76, size.y * 0.24)
            ..lineTo(size.x * 0.24, size.y * 0.76)
            ..strokePath();
        },
      ),
    );
  }

  pw.Widget _buildEducationItem(Education education, PdfColor accentColor) {
    final degree = _sanitizePdfText(
      '${education.degree} ${education.fieldOfStudy}'.trim(),
    ).trim();
    final institution = _sanitizePdfText(education.institution).trim();
    final location = _sanitizePdfText(education.location).trim();
    final endYear = education.isCurrentlyStudying
        ? _present()
        : (education.endDate?.year.toString() ??
            education.startDate.year.toString());
    final institutionLine = [
      if (institution.isNotEmpty) institution,
      if (location.isNotEmpty) location,
      if (endYear.isNotEmpty) endYear,
    ].join('  ·  ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _fullWidthText(
            degree.isNotEmpty ? degree : 'Education',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (institutionLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: _fullWidthText(
                institutionLine,
                style: const pw.TextStyle(fontSize: 9.6, color: _muted),
              ),
            ),
          if ((education.grade ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: _fullWidthText(
                'Grade: ${_sanitizePdfText(education.grade!)}',
                style: const pw.TextStyle(fontSize: 9.0, color: _muted),
              ),
            ),
          if ((education.description ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                _sanitizePdfText(education.description!),
                style: const pw.TextStyle(
                  fontSize: 9.0,
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

  pw.Widget _buildSkillChips(List<Skill> skills, PdfColor accentColor) {
    final labels = skills
        .map((skill) => _sanitizePdfText(skill.name).trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14),
      child: pw.Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels.map((label) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: accentColor, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _ink),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  pw.Widget _buildExperienceItem(Experience experience, PdfColor accentColor) {
    final company = _sanitizePdfText(experience.company).trim();
    final location = _sanitizePdfText(experience.location).trim();
    final companyLine = [
      if (company.isNotEmpty) company,
      if (location.isNotEmpty) location,
    ].join('  ·  ');
    final dateLabel = _dateRange(
      experience.startDate,
      experience.endDate,
      experience.isCurrentlyWorking,
    );
    final detailLines = _collectExperienceLines(experience)
        .map((line) => _sanitizePdfText(line).trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _fullWidthText(
            _sanitizePdfText(experience.position),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 1.5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _fullWidthText(
                  companyLine,
                  style: pw.TextStyle(
                    fontSize: 9.6,
                    color: accentColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                dateLabel,
                style: const pw.TextStyle(fontSize: 8.8, color: _light),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
          if (detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 2.5),
            ...detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: _fullWidthText(
                  line,
                  style: const pw.TextStyle(
                    fontSize: 9.2,
                    color: _muted,
                    lineSpacing: 1.4,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildProjectItem(Project project, PdfColor accentColor) {
    final title = _sanitizePdfText(project.title).trim();
    final description = _sanitizePdfText(project.description).trim();
    final url = _sanitizePdfText(project.url).trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _fullWidthText(
            title.isNotEmpty ? title : 'Project',
            style: pw.TextStyle(
              fontSize: 10.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: _fullWidthText(
                description,
                style: const pw.TextStyle(
                  fontSize: 9.0,
                  color: _muted,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          if (url.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: _fullWidthText(
                url,
                style: pw.TextStyle(fontSize: 8.6, color: accentColor),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationItem(Certification certification) {
    final issuer = _sanitizePdfText(certification.issuer).trim();
    final label = issuer.isNotEmpty
        ? '${_sanitizePdfText(certification.name)} - $issuer'
        : _sanitizePdfText(certification.name);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 3),
      child: _fullWidthText(
        label,
        style: const pw.TextStyle(fontSize: 9.2, color: _muted),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  pw.Widget _buildLanguageItem(Language language) {
    final name = _sanitizePdfText(language.name).trim();
    final proficiency = _sanitizePdfText(language.proficiency).trim();
    final label = proficiency.isNotEmpty ? '$name $proficiency' : name;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 2),
      child: _fullWidthText(
        label,
        style: const pw.TextStyle(fontSize: 9.2, color: _muted),
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
      child: pw.Text(text, style: style, textAlign: textAlign),
    );
  }

  List<String> _objectiveLines(String? text) {
    return _splitPdfLines(text);
  }

  List<String> _contactLines(ResumeModel resume) {
    final primary = <String>[];
    final secondary = <String>[];

    void addPrimary(String? value) {
      final sanitized = _sanitizePdfText(value).trim();
      if (sanitized.isNotEmpty) {
        primary.add(sanitized);
      }
    }

    void addSecondary(String? value, {bool compact = false}) {
      var sanitized = _sanitizePdfText(value).trim();
      if (compact) {
        sanitized = _compactLink(sanitized);
      }
      if (sanitized.isNotEmpty) {
        secondary.add(sanitized);
      }
    }

    addPrimary(resume.personalInfo.email);
    addPrimary(resume.personalInfo.phone);
    addSecondary(resume.personalInfo.address);
    addSecondary(resume.personalInfo.linkedIn, compact: true);
    addSecondary(resume.personalInfo.github, compact: true);
    addSecondary(resume.personalInfo.website, compact: true);

    return [
      if (primary.isNotEmpty) primary.join('  |  '),
      if (secondary.isNotEmpty) secondary.join('  |  '),
    ];
  }

  String _compactLink(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return '';
    }
    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  String _dateRange(DateTime startDate, DateTime? endDate, bool isCurrent) {
    final start = DateFormat('yyyy').format(startDate);
    final end = isCurrent
        ? _present()
        : DateFormat('yyyy').format(endDate ?? startDate);
    return '$start - $end';
  }
}
