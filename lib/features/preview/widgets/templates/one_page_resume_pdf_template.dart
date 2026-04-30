part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class OnePageResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _ink = PdfColor.fromInt(0xFF253243);
  static const PdfColor _muted = PdfColor.fromInt(0xFF667085);
  static const PdfColor _chipText = PdfColor.fromInt(0xFF2D3748);
  static const double _pageHorizontal = 34;
  static const double _pageTop = 28;
  static const double _pageBottom = 30;
  static const double _rightMetaWidth = 140;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
    'languages',
  ];
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );
  static final RegExp _leadingBulletPattern = RegExp(
    r'^[-•*▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );
  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );

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

    final summaryLines = _summaryLines(resume.objective);
    if (summaryLines.isNotEmpty) {
      sections['summary'] = [
        _sectionHeader('OBJECTIVE', accentColor),
        ...summaryLines.map(
          (line) => _objectiveBulletLine(line, accentColor),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE', accentColor),
        ...resume.experience.map(
          (experience) => _experienceBlock(experience, accentColor),
        ),
        pw.SizedBox(height: 2),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION', accentColor),
        ...resume.education.map(
          (education) => _educationBlock(education, accentColor),
        ),
        pw.SizedBox(height: 2),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS', accentColor),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: resume.skills
              .map((skill) => _skillChip(skill.name, accentColor))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS', accentColor),
        ...resume.projects.map(
          (project) => _projectBlock(project, accentColor),
        ),
        pw.SizedBox(height: 2),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
          (certification) => _certificationBlock(certification, accentColor),
        ),
        pw.SizedBox(height: 2),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES', accentColor),
        pw.Wrap(
          spacing: 18,
          runSpacing: 4,
          children: resume.languages
              .map((language) => _languageLabel(language))
              .toList(growable: false),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) => _sectionHeader(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageHorizontal,
            _pageTop,
            _pageHorizontal,
            _pageBottom,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildTopStrip(resume, accentColor),
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 14),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildTopStrip(ResumeModel resume, PdfColor accentColor) {
    final items = _topStripItems(resume);

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.fromLTRB(
        -_pageHorizontal,
        -_pageTop,
        -_pageHorizontal,
        14,
      ),
      padding: const pw.EdgeInsets.fromLTRB(
        _pageHorizontal,
        8,
        _pageHorizontal,
        8,
      ),
      color: accentColor,
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 3,
        alignment: pw.WrapAlignment.spaceBetween,
        children: items
            .map(
              (item) => pw.Text(
                item,
                style: const pw.TextStyle(
                  fontSize: 8.3,
                  color: PdfColors.white,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim())
        : 'John Smith';
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final address = _sanitizePdfText(resume.personalInfo.address).trim();

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (title.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(width: 14),
                pw.Container(
                  width: _rightMetaWidth,
                  alignment: pw.Alignment.topRight,
                  child: pw.Text(
                    address,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 8.8,
                      color: _muted,
                      lineSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(width: double.infinity, height: 2, color: accentColor),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 1.2,
            color: _blendPdfWithWhite(accentColor, 0.32),
          ),
        ],
      ),
    );
  }

  pw.Widget _objectiveBulletLine(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _objectiveArrowMarker(accentColor),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.6,
                color: _ink,
                lineSpacing: 1.35,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _objectiveArrowMarker(PdfColor accentColor) {
    return pw.SizedBox(
      width: 11,
      height: 12,
      child: pw.CustomPaint(
        size: const PdfPoint(11, 12),
        painter: (canvas, size) {
          canvas.setFillColor(accentColor);
          canvas.moveTo(10, size.y / 2);
          canvas.lineTo(5.2, 1);
          canvas.lineTo(5.2, 4.2);
          canvas.lineTo(1, 4.2);
          canvas.lineTo(1, size.y - 4.2);
          canvas.lineTo(5.2, size.y - 4.2);
          canvas.lineTo(5.2, size.y - 1);
          canvas.closePath();
          canvas.fillPath();
        },
      ),
    );
  }

  pw.Widget _experienceBlock(Experience experience, PdfColor accentColor) {
    final meta = [
      _sanitizePdfText(experience.company).trim(),
      _sanitizePdfText(experience.location).trim(),
    ].where((part) => part.isNotEmpty).join('  |  ');
    final detailLines = _collectExperienceLines(experience);

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _fullWidthText(
                  _sanitizePdfText(
                    experience.position.trim().isNotEmpty
                        ? experience.position.trim()
                        : 'Role',
                  ),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _rightMetaWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  _dateRange(
                    experience.startDate,
                    experience.endDate,
                    experience.isCurrentlyWorking,
                  ),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.7,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                meta,
                style: pw.TextStyle(
                  fontSize: 9.2,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ...detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _fullWidthText(
                line,
                style: const pw.TextStyle(
                  fontSize: 9.1,
                  color: _ink,
                  lineSpacing: 1.32,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(Education education, PdfColor accentColor) {
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final institution = _sanitizePdfText(education.institution).trim();
    final grade = _sanitizePdfText(education.grade).trim();
    final year = education.isCurrentlyStudying
        ? _present()
        : (education.endDate?.year.toString() ??
            education.startDate.year.toString());

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _fullWidthText(
                  _sanitizePdfText(degree.isNotEmpty ? degree : 'Education'),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _rightMetaWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  year,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.7,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          if (institution.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                institution,
                style: pw.TextStyle(
                  fontSize: 9.2,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (grade.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                grade,
                style: const pw.TextStyle(fontSize: 8.9, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(Project project, PdfColor accentColor) {
    final detailLines = _projectSummaryLines(project);
    final links = _projectLinks(project);

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _fullWidthText(
            _sanitizePdfText(
              project.title.trim().isNotEmpty
                  ? project.title.trim()
                  : 'Project',
            ),
            style: pw.TextStyle(
              fontSize: 10.6,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _fullWidthText(
                line,
                style: const pw.TextStyle(
                  fontSize: 9.0,
                  color: _ink,
                  lineSpacing: 1.32,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          ...links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _fullWidthText(
                link,
                style: pw.TextStyle(fontSize: 8.7, color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(
    Certification certification,
    PdfColor accentColor,
  ) {
    final name = _sanitizePdfText(certification.name).trim();
    final issuer = _sanitizePdfText(certification.issuer).trim();
    final credentialId = _sanitizePdfText(certification.credentialId).trim();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _fullWidthText(
              name.isNotEmpty ? name : 'Certification',
              style: pw.TextStyle(
                fontSize: 9.8,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: _rightMetaWidth,
            alignment: pw.Alignment.topRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (issuer.isNotEmpty)
                  pw.Text(
                    issuer,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 8.6, color: accentColor),
                  ),
                if (credentialId.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      credentialId,
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8.0, color: _muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _languageLabel(Language language) {
    final label = language.proficiency.trim().isNotEmpty
        ? '${_sanitizePdfText(language.name).trim()} ${_sanitizePdfText(language.proficiency).trim()}'
            .trim()
        : _sanitizePdfText(language.name).trim();

    return pw.Text(
      label,
      style: const pw.TextStyle(
        fontSize: 9.1,
        color: _ink,
      ),
    );
  }

  pw.Widget _skillChip(String name, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accentColor, 0.12),
        border: pw.Border.all(
          color: _blendPdfWithWhite(accentColor, 0.26),
          width: 0.6,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        _sanitizePdfText(name).trim(),
        style: pw.TextStyle(
          fontSize: 8.8,
          color: _chipText,
          fontWeight: pw.FontWeight.bold,
        ),
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

  List<String> _topStripItems(ResumeModel resume) {
    final items = <String>[];

    void addValue(String value, {bool compact = false}) {
      final normalized =
          compact ? _compactLink(value) : _sanitizePdfText(value).trim();
      if (normalized.isNotEmpty && !items.contains(normalized)) {
        items.add(normalized);
      }
    }

    addValue(resume.personalInfo.email);
    addValue(resume.personalInfo.phone);
    addValue(resume.personalInfo.linkedIn ?? '', compact: true);
    addValue(resume.personalInfo.github ?? '', compact: true);
    addValue(resume.personalInfo.website ?? '', compact: true);

    return items.isNotEmpty
        ? items
        : const [
            'john@email.com',
            '(555) 123-4567',
            'linkedin.com/in/js',
            'github.com/jsmith',
            'johnsmith.dev',
          ];
  }

  List<String> _summaryLines(String? text) {
    final normalized = _sanitizePdfText(text).trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final lineSegments = normalized
        .split(RegExp(r'\n+'))
        .expand(_splitSummarySegments)
        .toList(growable: false);
    if (lineSegments.length > 1) {
      return lineSegments;
    }

    return normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .expand(_splitSummarySegments)
        .toList(growable: false);
  }

  Iterable<String> _splitSummarySegments(String value) sync* {
    final trimmed = _sanitizePdfText(value).trim();
    if (trimmed.isEmpty) {
      return;
    }

    for (final segment in trimmed.split(_inlineBulletSeparatorPattern)) {
      final cleaned = _cleanSummaryBullet(segment);
      if (cleaned.isNotEmpty) {
        yield cleaned;
      }
    }
  }

  String _cleanSummaryBullet(String value) {
    return _sanitizePdfText(value).trim().replaceFirst(_leadingBulletPattern, '');
  }

  List<String> _projectSummaryLines(Project project) {
    if (project.description.trim().isNotEmpty) {
      return _splitPdfLines(project.description).where((line) {
        final links = _extractLinks(line);
        return links.isEmpty || !_isStandaloneLink(line, links);
      }).toList(growable: false);
    }

    final fallback = project.technologies
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    return fallback.isNotEmpty ? [fallback] : const [];
  }

  List<String> _projectLinks(Project project) {
    final links = <String>[];
    final seen = <String>{};

    void collectFrom(String source) {
      for (final link in _extractLinks(source)) {
        final normalized = _compactLink(link);
        final key = normalized.toLowerCase();
        if (normalized.isEmpty || !seen.add(key)) {
          continue;
        }
        links.add(normalized);
      }
    }

    collectFrom(project.url ?? '');
    collectFrom(project.description);
    return links;
  }

  List<String> _extractLinks(String text) {
    return _linkPattern
        .allMatches(text)
        .map((match) => match.group(0) ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  bool _isStandaloneLink(String line, List<String> matches) {
    if (matches.length != 1) {
      return false;
    }

    return line.trim() == matches.first.trim();
  }

  String _compactLink(String value) {
    var compact = value.trim();
    if (compact.isEmpty) {
      return '';
    }

    compact = compact.replaceFirst(RegExp(r'^https?://'), '');
    compact = compact.replaceFirst(RegExp(r'^www\.'), '');
    return _sanitizePdfText(compact.replaceAll(RegExp(r'/$'), ''));
  }

  String _dateRange(DateTime start, DateTime? end, bool isCurrent) {
    final endLabel = isCurrent ? _present() : DateFormat('yyyy').format(end!);
    return '${DateFormat('yyyy').format(start)} - $endLabel';
  }
}
