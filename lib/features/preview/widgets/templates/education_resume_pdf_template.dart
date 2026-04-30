part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class EducationResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFFAF6F0);
  static const PdfColor _navy = PdfColor.fromInt(0xFF333C4D);
  static const PdfColor _cream = PdfColor.fromInt(0xFFD4B896);
  static const PdfColor _ink = PdfColor.fromInt(0xFF3A3A3A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF7B7B84);
  static const double _pageHorizontal = 42;
  static const double _pageTop = 30;
  static const double _pageBottom = 30;
  static const double _contactColumnWidth = 184;
  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final sections = <String, List<pw.Widget>>{};

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionHeader('EDUCATION'),
        ...resume.education.map((education) => _educationBlock(education)),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionHeader('EXPERIENCE'),
        ...resume.experience.map((experience) => _experienceBlock(experience)),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _sectionHeader('OBJECTIVE'),
        ..._objectiveBullets(resume.objective!),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionHeader('SKILLS'),
        pw.Wrap(
          spacing: 8,
          runSpacing: 7,
          children: resume.skills
              .map((skill) => _skillChip(skill.name))
              .toList(growable: false),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionHeader('PROJECTS'),
        ...resume.projects.map((project) => _projectBlock(project)),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionHeader('CERTIFICATIONS'),
        ...resume.certifications
            .map((certification) => _certificationBlock(certification)),
        pw.SizedBox(height: 8),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionHeader('LANGUAGES'),
        ...resume.languages.map((language) => _languageBlock(language)),
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
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.fromLTRB(
        -_pageHorizontal,
        -_pageTop,
        -_pageHorizontal,
        22,
      ),
      padding: const pw.EdgeInsets.fromLTRB(
          _pageHorizontal, 26, _pageHorizontal, 24),
      color: _navy,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resume.personalInfo.fullName.trim().isEmpty
                      ? 'John Smith'
                      : _sanitizePdfText(resume.personalInfo.fullName.trim()),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (resume.personalInfo.jobTitle?.trim().isNotEmpty ?? false)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      _sanitizePdfText(resume.personalInfo.jobTitle!.trim()),
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: _cream,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            width: _contactColumnWidth,
            alignment: pw.Alignment.topRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: _headerLines(resume)
                  .asMap()
                  .entries
                  .map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        entry.value,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 8.4,
                          color: _headerLineColor(entry.key),
                          lineSpacing: 1.15,
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

  List<String> _headerLines(ResumeModel resume) {
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

    return lines.isNotEmpty
        ? lines
        : const [
            'john.smith@email.com  |  (555) 123-4567',
            'linkedin.com/in/johnsmith  |  github.com/johnsmith',
          ];
  }

  PdfColor _headerLineColor(int index) {
    if (index == 0) {
      return const PdfColor(1, 1, 1, 0.84);
    }

    return PdfColor(
      (_cream.red * 0.82) + 0.18,
      (_cream.green * 0.82) + 0.18,
      (_cream.blue * 0.82) + 0.18,
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 1.2,
            color: _ruleColor(),
          ),
        ],
      ),
    );
  }

  pw.Widget _educationBlock(Education education) {
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final subtitleParts = <String>[];
    if (education.institution.trim().isNotEmpty) {
      subtitleParts.add(_sanitizePdfText(education.institution.trim()));
    }
    final year = education.isCurrentlyStudying
        ? _present()
        : (education.endDate?.year.toString() ??
            education.startDate.year.toString());

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
                  _sanitizePdfText(degree.isEmpty ? 'Education' : degree),
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: 46,
                child: pw.Text(
                  year,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          if (subtitleParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                subtitleParts.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 9.4,
                  color: _muted,
                ),
              ),
            ),
          if (education.grade?.trim().isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(education.grade!.trim()),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(Experience experience) {
    final metaParts = <String>[];
    if (experience.company.trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(experience.company.trim()));
    }
    if ((experience.location ?? '').trim().isNotEmpty) {
      metaParts.add(_sanitizePdfText(experience.location!.trim()));
    }

    final details = <pw.Widget>[];
    if (experience.description.trim().isNotEmpty) {
      details.add(_bodyParagraph(experience.description.trim()));
    }
    for (final achievement in experience.achievements) {
      if (achievement.trim().isEmpty) continue;
      details.add(_dashLine(achievement.trim()));
    }

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
                  _sanitizePdfText(
                    experience.position.trim().isEmpty
                        ? 'Role'
                        : experience.position.trim(),
                  ),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 70,
                child: pw.Text(
                  _dateRange(experience.startDate, experience.endDate,
                      experience.isCurrentlyWorking),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _muted,
                  ),
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
                  fontSize: 9.4,
                  color: _muted,
                ),
              ),
            ),
          if (details.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: details,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _projectBlock(Project project) {
    final summaryLines = _projectSummaryLines(project);
    final projectLinks = _projectLinks(project);
    final details = <pw.Widget>[];

    if (summaryLines.isNotEmpty) {
      details.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: summaryLines
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: _bodyParagraph(line),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    }

    if (projectLinks.isNotEmpty) {
      details.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: projectLinks
                .map(
                  (link) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      link,
                      style: const pw.TextStyle(
                        fontSize: 8.8,
                        color: _navy,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
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
          ...details,
        ],
      ),
    );
  }

  pw.Widget _certificationBlock(Certification certification) {
    final text = certification.issuer.trim().isNotEmpty
        ? '${_sanitizePdfText(certification.name.trim())}  |  ${_sanitizePdfText(certification.issuer.trim())}'
        : _sanitizePdfText(certification.name.trim());

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9.4,
          color: _muted,
        ),
      ),
    );
  }

  pw.Widget _languageBlock(Language language) {
    final label = language.proficiency.trim().isNotEmpty
        ? '${_sanitizePdfText(language.name.trim())} ${_sanitizePdfText(language.proficiency.trim())}'
        : _sanitizePdfText(language.name.trim());

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        label,
        style: const pw.TextStyle(
          fontSize: 9.4,
          color: _muted,
        ),
      ),
    );
  }

  pw.Widget _skillChip(String name) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _softAccent(0.16),
        border: pw.Border.all(color: _softAccent(0.34), width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Text(
        _sanitizePdfText(name.trim()),
        style: pw.TextStyle(
          fontSize: 8.8,
          color: _navy,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  List<pw.Widget> _objectiveBullets(String text) {
    final segments = _splitSegments(text);
    if (segments.isEmpty) {
      return const [];
    }

    return segments
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 14,
                  height: 12,
                  child: pw.CustomPaint(
                    size: const PdfPoint(14, 12),
                    painter: (canvas, size) {
                      canvas.setFillColor(_cream);
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
                    _sanitizePdfText(line),
                    style: const pw.TextStyle(
                      fontSize: 9.2,
                      color: _ink,
                      lineSpacing: 1.35,
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

  pw.Widget _bodyParagraph(String text) {
    return pw.Text(
      _sanitizePdfText(text),
      style: const pw.TextStyle(
        fontSize: 9.2,
        color: _ink,
        lineSpacing: 1.35,
      ),
      textAlign: pw.TextAlign.justify,
    );
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
          (line) => line.replaceFirst(
            RegExp(r'^[-•*▪■□✪✦★☆➣◦○]+\s*'),
            '',
          ),
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

    final trimmed = line.trim();
    return trimmed == matches.first.trim();
  }

  pw.Widget _dashLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '- ',
            style: const pw.TextStyle(
              fontSize: 9.2,
              color: _muted,
            ),
          ),
          pw.Expanded(child: _bodyParagraph(text)),
        ],
      ),
    );
  }

  String _compactLink(String value) {
    var compact = value.trim();
    compact = compact.replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    compact = compact.replaceFirst(
      RegExp(r'^www\.+', caseSensitive: false),
      '',
    );
    compact = compact.replaceFirst(RegExp(r'^[./\s]+'), '');
    return _sanitizePdfText(compact.replaceAll(RegExp(r'/$'), ''));
  }

  String _dateRange(DateTime start, DateTime? end, bool isCurrent) {
    final endLabel = isCurrent ? _present() : DateFormat('yyyy').format(end!);
    return '${DateFormat('yyyy').format(start)} - $endLabel';
  }

  PdfColor _ruleColor() {
    return PdfColor(
      _cream.red * 0.34 + 0.66,
      _cream.green * 0.34 + 0.66,
      _cream.blue * 0.34 + 0.66,
    );
  }

  PdfColor _softAccent(double weight) {
    return PdfColor(
      _cream.red * weight + (1 - weight),
      _cream.green * weight + (1 - weight),
      _cream.blue * weight + (1 - weight),
    );
  }
}
