part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class EmeraldExecutiveResumePdfTemplate extends PdfTemplate {
  static const PdfColor _ink = PdfColor.fromInt(0xFF18261E);
  static const PdfColor _muted = PdfColor.fromInt(0xFF63746C);
  static const PdfColor _rule = PdfColor.fromInt(0xFFD8E0DB);
  static const double _pageHorizontal = 34;
  static const double _pageTop = 30;
  static const double _pageBottom = 32;
  static const double _dateLaneWidth = 108;
  static const _defaultOrder = <String>[
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
    'languages',
  ];
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
        _sectionHeader('SUMMARY', accentColor),
        ...summaryLines.map((line) => _summaryBullet(line, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('PROFESSIONAL EXPERIENCE', accentColor),
        ...resume.experience.map(
          (experience) => _experienceBlock(experience, accentColor),
        ),
        pw.SizedBox(height: 4),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION', accentColor),
        ...resume.education.map(
          (education) => _educationBlock(education, accentColor),
        ),
        pw.SizedBox(height: 4),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS', accentColor),
        pw.Text(
          resume.skills
              .map((skill) => _sanitizePdfText(skill.name).trim())
              .where((skill) => skill.isNotEmpty)
              .join('  •  '),
          style: const pw.TextStyle(
            fontSize: 9.1,
            color: _ink,
            lineSpacing: 1.35,
          ),
          textAlign: pw.TextAlign.justify,
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
        pw.SizedBox(height: 4),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
          (certification) => _certificationBlock(certification, accentColor),
        ),
        pw.SizedBox(height: 4),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES', accentColor),
        ...resume.languages.map(
          (language) => _languageLine(language, accentColor),
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
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 10),
          pw.Container(width: double.infinity, height: 6, color: accentColor),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isNotEmpty
        ? _sanitizePdfText(resume.personalInfo.fullName.trim()).toUpperCase()
        : 'GMK SEENAI';
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final photoBytes = _profileImageBytes(resume.personalInfo.profileImage);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 72,
          height: 72,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: accentColor, width: 2.2),
            color: _blendPdfWithWhite(accentColor, 0.9),
          ),
          child: pw.ClipOval(
            child: photoBytes != null
                ? pw.Image(
                    pw.MemoryImage(photoBytes),
                    width: 72,
                    height: 72,
                    fit: pw.BoxFit.cover,
                  )
                : pw.Center(
                    child: pw.Text(
                      _initials(name),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 23,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1,
                ),
              ),
              if (title.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _muted,
                    lineSpacing: 1.1,
                  ),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Container(width: double.infinity, height: 0.9, color: _rule),
              pw.SizedBox(height: 6),
              ..._contactRows(_contactItems(resume), accentColor),
            ],
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _contactRows(
    List<_EmeraldExecutivePdfContactItem> items,
    PdfColor accentColor,
  ) {
    final rows = <pw.Widget>[];
    for (var index = 0; index < items.length; index += 2) {
      final pair = items.skip(index).take(2).toList(growable: false);
      rows.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: index + 2 < items.length ? 3 : 0),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _contactItem(pair.first, accentColor)),
              if (pair.length == 2) ...[
                pw.SizedBox(width: 12),
                pw.Expanded(child: _contactItem(pair.last, accentColor)),
              ],
            ],
          ),
        ),
      );
    }
    return rows;
  }

  pw.Widget _contactItem(
    _EmeraldExecutivePdfContactItem item,
    PdfColor accentColor,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          margin: const pw.EdgeInsets.only(top: 1, right: 4),
          child: pw.CustomPaint(
            size: const PdfPoint(10, 10),
            painter: (canvas, size) {
              final cx = size.x / 2;
              final cy = size.y / 2;
              canvas.setFillColor(accentColor);
              canvas.drawEllipse(cx, cy, cx, cy);
              canvas.fillPath();
              _drawPdfIcon(
                  canvas, item.icon, cx, cy, cx * 0.5, PdfColors.white);
            },
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            item.text,
            style: const pw.TextStyle(
              fontSize: 8.1,
              color: _ink,
              lineSpacing: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return _buildRightBarSectionHeader(
      title,
      textColor: accentColor,
      dividerColor: _blendPdfWithWhite(accentColor, 0.34),
      barColor: accentColor,
      fontSize: 10.8,
      letterSpacing: 0.55,
      marginBottom: 8,
      titleBottomSpacing: 2,
      lineThickness: 1.2,
      barHeight: 10,
    );
  }

  pw.Widget _summaryBullet(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              line,
              style: const pw.TextStyle(
                fontSize: 9,
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

  pw.Widget _experienceBlock(Experience experience, PdfColor accentColor) {
    final detailLines = _collectExperienceLines(experience);
    final metaLine = [
      _sanitizePdfText(experience.company).trim(),
      _sanitizePdfText(experience.location).trim(),
    ].where((part) => part.isNotEmpty).join('  •  ');

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(
                    experience.position.trim().isNotEmpty
                        ? experience.position.trim()
                        : 'Role',
                  ),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _dateLaneWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  _dateRange(
                    experience.startDate,
                    experience.endDate,
                    ongoing: experience.isCurrentlyWorking,
                  ),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 7.6,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          if (metaLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
              child: pw.Text(
                metaLine,
                style: const pw.TextStyle(
                  fontSize: 8.2,
                  color: _ink,
                ),
              ),
            ),
          ...detailLines.take(4).map(
                (detail) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.5),
                  child: pw.Text(
                    _sanitizePdfText(detail),
                    style: const pw.TextStyle(
                      fontSize: 8.4,
                      color: _muted,
                      lineSpacing: 1.3,
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
    final degreeLine = [
      _sanitizePdfText(education.degree).trim(),
      _sanitizePdfText(education.fieldOfStudy).trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final supportingLines = [
      if ((education.grade ?? '').trim().isNotEmpty)
        'Grade: ${_sanitizePdfText(education.grade).trim()}',
      if ((education.description ?? '').trim().isNotEmpty)
        _sanitizePdfText(education.description).trim(),
    ];

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(
                    education.institution.trim().isNotEmpty
                        ? education.institution.trim()
                        : 'Institution',
                  ),
                  style: pw.TextStyle(
                    fontSize: 9.7,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: _dateLaneWidth,
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  _dateRange(
                    education.startDate,
                    education.endDate,
                    ongoing: education.isCurrentlyStudying,
                    monthYear: false,
                  ),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 7.6,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          if (degreeLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: pw.Text(
                degreeLine,
                style: const pw.TextStyle(
                  fontSize: 8.4,
                  color: _ink,
                ),
              ),
            ),
          ...supportingLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _muted,
                  lineSpacing: 1.3,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(Project project, PdfColor accentColor) {
    final detailLines = _projectDetailLines(project);
    final projectDates = _projectDateRange(project);
    final url = _sanitizePdfText(project.url).trim();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(
                    project.title.trim().isNotEmpty
                        ? project.title.trim()
                        : 'Project',
                  ),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              if (projectDates.isNotEmpty) ...[
                pw.SizedBox(width: 12),
                pw.Container(
                  width: _dateLaneWidth,
                  alignment: pw.Alignment.topRight,
                  child: pw.Text(
                    projectDates,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 7.6,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          ...detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 8.4,
                  color: _muted,
                  lineSpacing: 1.3,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (url.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                url,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: accentColor,
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
    final issueDate = certification.issueDate != null
        ? _pdfDate(certification.issueDate!)
        : '';
    final metaLines = <String>[];
    if (certification.issuer.trim().isNotEmpty) {
      metaLines.add(_sanitizePdfText(certification.issuer).trim());
    }
    if ((certification.credentialId ?? '').trim().isNotEmpty) {
      metaLines.add(
        '${_h('Credential ID')}: ${_sanitizePdfText(certification.credentialId).trim()}',
      );
    }
    if ((certification.credentialUrl ?? '').trim().isNotEmpty) {
      metaLines.add(_sanitizePdfText(certification.credentialUrl).trim());
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(
                    certification.name.trim().isNotEmpty
                        ? certification.name.trim()
                        : 'Certification',
                  ),
                  style: pw.TextStyle(
                    fontSize: 9.2,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              if (issueDate.isNotEmpty) ...[
                pw.SizedBox(width: 12),
                pw.Container(
                  width: _dateLaneWidth,
                  alignment: pw.Alignment.topRight,
                  child: pw.Text(
                    issueDate,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 7.6,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          ...metaLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _muted,
                  lineSpacing: 1.25,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _languageLine(Language language, PdfColor accentColor) {
    final label = [
      _sanitizePdfText(language.name).trim(),
      _sanitizePdfText(language.proficiency).trim(),
    ].where((part) => part.isNotEmpty).join(' - ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 8.6,
                color: _ink,
                lineSpacing: 1.3,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _profileImageBytes(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value.split(',').last);
    } catch (_) {
      return null;
    }
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'GS';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  List<_EmeraldExecutivePdfContactItem> _contactItems(ResumeModel resume) {
    final items = <_EmeraldExecutivePdfContactItem>[];

    void addItem(String icon, String value, {bool compact = false}) {
      final text =
          compact ? _compactUrl(value) : _sanitizePdfText(value).trim();
      if (text.isEmpty || items.any((item) => item.text == text)) {
        return;
      }
      items.add(_EmeraldExecutivePdfContactItem(icon: icon, text: text));
    }

    addItem('phone', resume.personalInfo.phone);
    addItem('email', resume.personalInfo.email);
    addItem('location', resume.personalInfo.address);
    addItem('linkedin', resume.personalInfo.linkedIn ?? '', compact: true);
    addItem('website', resume.personalInfo.website ?? '', compact: true);
    addItem('website', resume.personalInfo.github ?? '', compact: true);

    return items;
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

  List<String> _projectDetailLines(Project project) {
    final descriptionLines = _sanitizePdfText(project.description)
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanListMarker)
        .where((line) => line.isNotEmpty)
        .where((line) => line != _sanitizePdfText(project.url).trim())
        .toList(growable: false);
    if (descriptionLines.isNotEmpty) {
      return descriptionLines.take(3).toList(growable: false);
    }

    return project.technologies
        .map((item) => _sanitizePdfText(item).trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  String _projectDateRange(Project project) {
    if (project.startDate == null && project.endDate == null) {
      return '';
    }

    final format = DateFormat('MMM yyyy');
    final startLabel =
        project.startDate != null ? format.format(project.startDate!) : '';
    final endLabel =
        project.endDate != null ? format.format(project.endDate!) : '';
    if (startLabel.isEmpty) {
      return endLabel;
    }
    if (endLabel.isEmpty) {
      return startLabel;
    }
    return '$startLabel - $endLabel';
  }

  String _dateRange(
    DateTime start,
    DateTime? end, {
    required bool ongoing,
    bool monthYear = true,
  }) {
    final format = DateFormat(monthYear ? 'MMM yyyy' : 'yyyy');
    final startLabel = format.format(start);
    final endLabel =
        ongoing ? _present() : (end != null ? format.format(end) : startLabel);
    return '$startLabel - $endLabel';
  }

  String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingBulletPattern, '');
  }

  Iterable<String> _splitSummarySegments(String value) sync* {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    for (final segment in trimmed.split(_inlineBulletSeparatorPattern)) {
      final cleaned = _cleanListMarker(segment);
      if (cleaned.isNotEmpty) {
        yield cleaned;
      }
    }
  }

  String _compactUrl(String value) {
    var compact = _sanitizePdfText(value).trim();
    if (compact.isEmpty) {
      return '';
    }

    compact =
        compact.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    compact = compact.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    return compact.replaceAll(RegExp(r'/$'), '');
  }
}

class _EmeraldExecutivePdfContactItem {
  const _EmeraldExecutivePdfContactItem({
    required this.icon,
    required this.text,
  });

  final String icon;
  final String text;
}
