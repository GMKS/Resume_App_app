part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class PinkRoseModernPdfTemplate extends PdfTemplate {
  static const PdfColor _rose = PdfColor.fromInt(0xFFD87093);
  static const PdfColor _roseDeep = PdfColor.fromInt(0xFF8B4962);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFCF8FA);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2E2430);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6F6570);
  static const PdfColor _rule = PdfColor.fromInt(0xFFE8D6DE);

  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'skills',
    'languages',
    'education',
    'projects',
    'certifications',
  ];

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

    final sections = <String, List<pw.Widget>>{};
    if ((resume.objective ?? '').trim().isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('PROFILE'),
        ..._buildProfileSummaryBullets(resume.objective!),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...resume.experience
            .map((experience) => _buildExperienceBlock(experience)),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        _fullWidthText(
          resume.skills
              .map((skill) => _sanitizePdfText(skill.name))
              .where((skill) => skill.isNotEmpty)
              .join(' - '),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _muted,
            lineSpacing: 1.35,
          ),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        _fullWidthText(
          resume.languages
              .map(
                (language) => language.proficiency.trim().isNotEmpty
                    ? '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})'
                    : _sanitizePdfText(language.name),
              )
              .where((language) => language.isNotEmpty)
              .join(' - '),
          style: const pw.TextStyle(
            fontSize: 8.7,
            color: _muted,
            lineSpacing: 1.35,
          ),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...resume.education.map(_buildEducationBlock),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...resume.projects.map(_buildProjectBlock),
        pw.SizedBox(height: 4),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...resume.certifications.map(_buildCertificationBlock),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase()),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _paper),
          ),
        ),
        build: (context) => [
          _buildHeader(resume),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: _rule),
          pw.SizedBox(height: 16),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume) {
    final contacts = _resumeContactValues(
      resume,
      includeAddress: true,
      includeLinkedIn: true,
      includeGithub: true,
      includeWebsite: true,
    ).map(_compactContactValue).where((value) => value.isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 2, width: 70, color: _rose),
        pw.SizedBox(height: 10),
        pw.Text(
          (resume.personalInfo.fullName.isEmpty
                  ? 'YOUR NAME'
                  : _sanitizePdfText(resume.personalInfo.fullName))
              .toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 1.25,
          ),
        ),
        if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            _sanitizePdfText(resume.personalInfo.jobTitle!),
            style: pw.TextStyle(
              fontSize: 11,
              color: _roseDeep,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        if (contacts.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 3,
            children: contacts.map(_contactLine).toList(growable: false),
          ),
        ],
      ],
    );
  }

  String _compactContactValue(String value) {
    var result = _sanitizePdfText(value).trim();
    if (result.isEmpty) {
      return '';
    }

    if (result.contains('@') || result.startsWith('+')) {
      return result;
    }

    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  pw.Widget _contactLine(String text) => pw.Text(
        text,
      style: const pw.TextStyle(fontSize: 8.2, color: _muted),
      );

  pw.Widget _sectionHeader(String title) => _buildRightBarSectionHeader(
        title,
        textColor: _roseDeep,
        dividerColor: _rose,
        fontSize: 10.2,
        letterSpacing: 1.15,
        marginBottom: 6,
        titleBottomSpacing: 3,
        lineThickness: 1,
        barHeight: 6,
      );

  List<pw.Widget> _buildProfileSummaryBullets(String text) {
    final segments = _splitPdfLines(text);
    if (segments.isEmpty) {
      return const [];
    }

    return segments
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Container(
              width: double.infinity,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 14,
                    height: 12,
                    child: pw.CustomPaint(
                      size: const PdfPoint(14, 12),
                      painter: (canvas, size) {
                        canvas.setFillColor(_rose);
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
                    child: _fullWidthText(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 9.4,
                        lineSpacing: 1.55,
                        color: _muted,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  pw.Widget _buildExperienceBlock(Experience experience) {
    final detailLines = _descriptionFirstExperienceLines(experience);
    final companyLine = [
      _sanitizePdfText(experience.company).trim(),
      _sanitizePdfText(experience.location).trim(),
    ].where((value) => value.isNotEmpty).join(' | ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 11),
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
                        fontSize: 10.2,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    if (companyLine.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        companyLine,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: _roseDeep,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: 92,
                child: pw.Text(
                  '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(experience.endDate!)}',
                  style: const pw.TextStyle(fontSize: 8.4, color: _muted),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if (detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            ...detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: _fullWidthText(
                  line,
                  style: const pw.TextStyle(
                    fontSize: 8.7,
                    lineSpacing: 1.4,
                    color: _muted,
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

  pw.Widget _buildEducationBlock(Education education) {
    final title = '${education.degree} ${education.fieldOfStudy}'.trim();
    final dateRange =
        '${DateFormat('yyyy').format(education.startDate)} - ${education.isCurrentlyStudying ? _present() : DateFormat('yyyy').format(education.endDate ?? education.startDate)}';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(title.isNotEmpty ? title : education.institution),
            style: pw.TextStyle(
              fontSize: 9.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _sanitizePdfText(education.institution),
            style: pw.TextStyle(
              fontSize: 8.8,
              color: _roseDeep,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '$dateRange${education.location?.trim().isNotEmpty ?? false ? ' | ${_sanitizePdfText(education.location)}' : ''}',
            style: const pw.TextStyle(fontSize: 8.4, color: _muted),
          ),
          if (education.grade?.isNotEmpty ?? false)
            pw.Text(
              'Grade: ${_sanitizePdfText(education.grade!)}',
              style: const pw.TextStyle(fontSize: 8.3, color: _muted),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectBlock(Project project) {
    final description = _sanitizePdfText(project.description).trim();
    final url = _sanitizePdfText(project.url).trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 9.6,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (project.technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'Stack: ${project.technologies.map(_sanitizePdfText).join(', ')}',
                style: const pw.TextStyle(fontSize: 8.3, color: _roseDeep),
              ),
            ),
          if (description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _fullWidthText(
                description,
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  lineSpacing: 1.35,
                  color: _muted,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          if (url.isNotEmpty && !description.contains(url))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                url,
                style: const pw.TextStyle(
                  fontSize: 8.2,
                  color: _roseDeep,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationBlock(Certification certification) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(certification.name),
            style: pw.TextStyle(
              fontSize: 9.3,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (certification.issuer.isNotEmpty)
            pw.Text(
              _sanitizePdfText(certification.issuer),
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          if (certification.credentialId?.isNotEmpty ?? false)
            pw.Text(
              '${_h('Credential ID')}: ${_sanitizePdfText(certification.credentialId!)}',
              style: const pw.TextStyle(fontSize: 8.2, color: _roseDeep),
            ),
        ],
      ),
    );
  }
}