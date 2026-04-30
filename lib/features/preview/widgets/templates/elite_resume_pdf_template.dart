part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class EliteResumePdfTemplate extends PdfTemplate {
  static const PdfColor _headerBg = PdfColor.fromInt(0xFF35354A);
  static const PdfColor _pageBg = PdfColors.white;
  static const PdfColor _ink = PdfColor.fromInt(0xFF2D3142);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6F7380);
  static const double _pageHorizontal = 40;
  static const double _pageTop = 34;
  static const double _pageBottom = 34;
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

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _sectionHeader('SUMMARY', accentColor),
        ..._summaryWidgets(resume.objective!),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE', accentColor),
        ...resume.experience
            .map((experience) => _experienceBlock(experience, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION', accentColor),
        ...resume.education.map(_educationBlock),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS', accentColor),
        pw.Wrap(
          spacing: 7,
          runSpacing: 7,
          children: resume.skills
              .map((skill) => _skillChip(skill.name, accentColor))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _projectBlock(project, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS', accentColor),
        ...resume.certifications.map(
            (certification) => _certificationBlock(certification, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES', accentColor),
        ...resume.languages.map(_languageBlock),
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
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 18),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isEmpty
        ? 'JOHN SMITH'
        : _sanitizePdfText(resume.personalInfo.fullName.trim().toUpperCase());
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final contactLines = _contactLines(resume);

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.fromLTRB(
              -_pageHorizontal,
              -_pageTop,
              -_pageHorizontal,
              0,
            ),
            padding: const pw.EdgeInsets.fromLTRB(
              _pageHorizontal,
              26,
              _pageHorizontal,
              22,
            ),
            color: _headerBg,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    style: const pw.TextStyle(
                      fontSize: 10.2,
                      color: PdfColor(1, 1, 1, 0.74),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
                if (contactLines.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  ...contactLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        line,
                        style: const pw.TextStyle(
                          fontSize: 8.7,
                          color: PdfColor(1, 1, 1, 0.7),
                          lineSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.fromLTRB(
              -_pageHorizontal,
              0,
              -_pageHorizontal,
              0,
            ),
            height: 2.2,
            color: PdfColor(
              accentColor.red,
              accentColor.green,
              accentColor.blue,
              0.84,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 11.2,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 1.1,
            color: _blendPdfWithWhite(accentColor, 0.72),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _summaryWidgets(String text) {
    final lines = _splitSegments(text);
    if (lines.isEmpty) {
      return const [];
    }

    return lines
        .asMap()
        .entries
        .map((entry) => _summaryBullet(entry.key + 1, entry.value))
        .toList(growable: false);
  }

  pw.Widget _summaryBullet(int index, String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 13,
            child: pw.Text(
              '$index.',
              style: pw.TextStyle(
                fontSize: 9.3,
                fontWeight: pw.FontWeight.bold,
                color: _headerBg,
              ),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(child: _bodyText(line)),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(Experience experience, PdfColor accentColor) {
    final metaParts = <String>[];
    if (experience.company.trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(experience.company.trim()));
    }
    if ((experience.location ?? '').trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(experience.location!.trim()));
    }
    final details = _descriptionFirstExperienceLines(experience);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(
                    experience.position.trim().isEmpty
                        ? 'Role'
                        : experience.position.trim(),
                  ),
                  style: pw.TextStyle(
                    fontSize: 11.2,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                _dateRange(
                  experience.startDate,
                  experience.endDate,
                  experience.isCurrentlyWorking,
                ),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                ),
              ),
            ],
          ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 9.3,
                  color: _muted,
                ),
              ),
            ),
          if (details.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: details
                    .map(
                      (detail) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '- ',
                              style: pw.TextStyle(
                                fontSize: 9.1,
                                color: accentColor,
                              ),
                            ),
                            pw.Expanded(
                              child: _bodyText(
                                detail,
                                fontSize: 9.1,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(Education education) {
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final metaParts = <String>[];
    if (education.institution.trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(education.institution.trim()));
    }
    if ((education.location ?? '').trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(education.location!.trim()));
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(degree.isEmpty ? 'Education' : degree),
                  style: pw.TextStyle(
                    fontSize: 10.8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                education.isCurrentlyStudying
                    ? _present()
                    : DateFormat('yyyy')
                        .format(education.endDate ?? education.startDate),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                ),
              ),
            ],
          ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 9.2,
                  color: _muted,
                ),
              ),
            ),
          if ((education.grade ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(education.grade!.trim()),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: _muted,
                ),
              ),
            ),
          if ((education.description ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _bodyText(education.description!, fontSize: 9.0),
            ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(Project project, PdfColor accentColor) {
    final summaryLines = _projectSummaryLines(project);
    final links = _projectLinks(project);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(
              project.title.trim().isEmpty ? 'Project' : project.title.trim(),
            ),
            style: pw.TextStyle(
              fontSize: 10.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (summaryLines.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: summaryLines
                    .map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: _bodyText(line, fontSize: 9.0),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          if (project.technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'Stack: ${_sanitizePdfText(project.technologies.join(', '))}',
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                ),
              ),
            ),
          if (links.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: links
                    .map(
                      (link) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          link,
                          style: pw.TextStyle(
                            fontSize: 8.7,
                            color: accentColor,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
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
    final meta = <String>[];
    if (certification.issuer.trim().isNotEmpty) {
      meta.add(_sanitizePdfText(certification.issuer.trim()));
    }
    if (certification.issueDate != null) {
      meta.add(DateFormat('yyyy').format(certification.issueDate!));
    }
    if ((certification.credentialId ?? '').trim().isNotEmpty) {
      meta.add(_sanitizePdfText(certification.credentialId!.trim()));
    }

    final link = _compactLink(certification.credentialUrl ?? '');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(certification.name.trim()),
            style: pw.TextStyle(
              fontSize: 9.8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (meta.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                meta.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                ),
              ),
            ),
          if (link.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                link,
                style: pw.TextStyle(
                  fontSize: 8.6,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _languageBlock(Language language) {
    final label = language.proficiency.trim().isNotEmpty
        ? '${_sanitizePdfText(language.name.trim())} (${_sanitizePdfText(language.proficiency.trim())})'
        : _sanitizePdfText(language.name.trim());

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        label,
        style: const pw.TextStyle(
          fontSize: 9.1,
          color: _muted,
        ),
      ),
    );
  }

  pw.Widget _skillChip(String name, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _softAccent(accentColor, 0.08),
        border:
            pw.Border.all(color: _softAccent(accentColor, 0.24), width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Text(
        _sanitizePdfText(name.trim()),
        style: pw.TextStyle(
          fontSize: 8.7,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _bodyText(
    String text, {
    double fontSize = 9.2,
    PdfColor color = _muted,
  }) {
    return pw.Text(
      _sanitizePdfText(text),
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        lineSpacing: 1.35,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }

  List<String> _contactLines(ResumeModel resume) {
    final info = resume.personalInfo;
    final lines = <String>[];
    final primary = <String>[];

    if (info.email.trim().isNotEmpty) {
      primary.add(_sanitizePdfText(info.email.trim()));
    }
    if (info.phone.trim().isNotEmpty) {
      primary.add(_sanitizePdfText(info.phone.trim()));
    }
    if (primary.isNotEmpty) {
      lines.add(primary.join('  |  '));
    }

    if (info.address.trim().isNotEmpty) {
      lines.add(_sanitizePdfText(info.address.trim()));
    }

    final links = <String>[];
    if (info.linkedIn?.trim().isNotEmpty ?? false) {
      links.add(_compactLink(info.linkedIn!));
    }
    if (info.github?.trim().isNotEmpty ?? false) {
      links.add(_compactLink(info.github!));
    }
    if (info.website?.trim().isNotEmpty ?? false) {
      links.add(_compactLink(info.website!));
    }
    if (links.isNotEmpty) {
      lines.add(links.join('  |  '));
    }

    return lines;
  }

  List<String> _splitSegments(String text) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final segments = lines.isNotEmpty
        ? lines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    return segments
        .map(
          (line) => line.replaceFirst(RegExp(r'^[-•*▪■□✪✦★☆➣◦○]+\s*'), ''),
        )
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _projectSummaryLines(Project project) {
    if (project.description.trim().isNotEmpty) {
      return _splitSegments(project.description).where((line) {
        final matches = _extractLinks(line);
        return matches.isEmpty || !_isStandaloneLink(line, matches);
      }).toList(growable: false);
    }

    final fallback = project.technologies
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    if (fallback.isEmpty) {
      return const [];
    }

    return [fallback];
  }

  List<String> _projectLinks(Project project) {
    final links = <String>[];
    final seen = <String>{};

    void collectFrom(String source) {
      for (final link in _extractLinks(source)) {
        final compact = _compactLink(link);
        final key = compact.toLowerCase();
        if (compact.isEmpty || !seen.add(key)) {
          continue;
        }
        links.add(compact);
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
    final endLabel =
        isCurrent ? _present() : DateFormat('MMM yyyy').format(end!);
    return '${DateFormat('MMM yyyy').format(start)} - $endLabel';
  }

  PdfColor _softAccent(PdfColor accentColor, double weight) {
    return PdfColor(
      accentColor.red * weight + (1 - weight),
      accentColor.green * weight + (1 - weight),
      accentColor.blue * weight + (1 - weight),
    );
  }
}
