part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class DeveloperResumePdfTemplate extends PdfTemplate {
  static const PdfColor _hero = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _panel = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF64748B);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);

    final sections = <String, List<pw.Widget>>{};
    if (resume.objective?.trim().isNotEmpty ?? false) {
      sections['summary'] = [
        _buildSectionTitle('SUMMARY', accentColor),
        _buildSummaryPanel(resume.objective!, accentColor),
        pw.SizedBox(height: 16),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildSectionTitle('EXPERIENCE', accentColor),
        ...resume.experience
            .map((experience) => _buildExperienceCard(experience, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildSectionTitle('EDUCATION', accentColor),
        ...resume.education
            .map((education) => _buildEducationCard(education, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildSectionTitle('TECH STACK', accentColor),
        _buildSkillChips(resume, accentColor),
        pw.SizedBox(height: 16),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildSectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildProjectCard(project, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildSectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications.map((certification) =>
            _buildCertificationLine(certification, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildSectionTitle('LANGUAGES', accentColor),
        pw.Text(
          resume.languages
              .map(
                (language) =>
                    '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})',
              )
              .join('   |   '),
          style: const pw.TextStyle(fontSize: 9.2, color: _ink),
        ),
        pw.SizedBox(height: 12),
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
          margin: pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
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

  List<String> _contactLines(ResumeModel resume) {
    final lines = <String>[];

    void add(String? value, {bool compact = false}) {
      final raw = value?.trim() ?? '';
      if (raw.isEmpty) {
        return;
      }

      final normalized = compact ? _compactUrl(raw) : _sanitizePdfText(raw);
      if (normalized.trim().isNotEmpty) {
        lines.add(normalized.trim());
      }
    }

    add(resume.personalInfo.email);
    add(resume.personalInfo.phone);
    add(resume.personalInfo.address);
    add(resume.personalInfo.linkedIn, compact: true);
    add(resume.personalInfo.github, compact: true);
    add(resume.personalInfo.website, compact: true);
    return lines;
  }

  String _compactUrl(String value) {
    var result = _sanitizePdfText(value).trim();
    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isEmpty
        ? 'YOUR NAME'
        : _sanitizePdfText(resume.personalInfo.fullName.trim());
    final title = resume.personalInfo.jobTitle?.trim() ?? '';
    final contacts = _contactLines(resume);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const pw.BoxDecoration(
        color: _hero,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 25,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if (title.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '< ${_sanitizePdfText(title).toUpperCase()} />',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          if (contacts.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            ...contacts.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 1.5),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(
                    fontSize: 8.2,
                    color: PdfColor(1, 1, 1, 0.78),
                    lineSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: _hero,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              '[ ${_h(title)} ]',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(left: 8),
              height: 10,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: pw.Container(
                      height: 1.2,
                      color: _scalePdfColor(accentColor, 1.0, 0.45),
                    ),
                  ),
                  pw.Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: pw.Container(width: 2.6, color: accentColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _summarySegments(String text) {
    final normalized = _sanitizePdfText(text).trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final explicit = normalized
        .split(RegExp(r'\n+|[•▪]+'))
        .map((line) => line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (explicit.length > 1) {
      return explicit;
    }

    return _splitPdfLines(normalized);
  }

  pw.Widget _buildSummaryPanel(String text, PdfColor accentColor) {
    final segments = _summarySegments(text);
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.Container(
              width: 3,
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(10),
                  bottomLeft: pw.Radius.circular(10),
                ),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: segments
                  .map(
                    (segment) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '> ',
                            style: pw.TextStyle(
                              fontSize: 9.2,
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              segment,
                              style: const pw.TextStyle(
                                fontSize: 9.2,
                                color: _ink,
                                lineSpacing: 1.45,
                              ),
                              textAlign: pw.TextAlign.justify,
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

  pw.Widget _buildSkillChips(ResumeModel resume, PdfColor accentColor) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resume.skills
          .map(
            (skill) => pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const pw.BoxDecoration(
                color: _hero,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                _sanitizePdfText(skill.name),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  pw.Widget _buildExperienceCard(Experience experience, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
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
                        fontSize: 11.4,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Text(
                      _sanitizePdfText(
                        '${experience.company}${experience.location != null && experience.location!.isNotEmpty ? '  |  ${experience.location}' : ''}',
                      ),
                      style: pw.TextStyle(fontSize: 9, color: accentColor),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: const pw.BoxDecoration(
                  color: _hero,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(experience.endDate!)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_collectExperienceLines(experience).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ..._buildExperienceLineWidgets(
              experience,
              accentColor,
              fontSize: 8.8,
              leftPadding: 2,
              textColor: _muted,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildProjectCard(Project project, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10.6,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (project.technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
              child: pw.Text(
                project.technologies.map(_sanitizePdfText).join(' | '),
                style: pw.TextStyle(fontSize: 8.3, color: accentColor),
              ),
            ),
          if (project.description.isNotEmpty)
            pw.Text(
              _sanitizePdfText(project.description),
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _ink,
                lineSpacing: 1.45,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          if (project.url?.trim().isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                _sanitizePdfText(project.url!.trim()),
                style: pw.TextStyle(
                  fontSize: 8.2,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildEducationCard(Education education, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(
                    education.degree.isEmpty
                        ? education.fieldOfStudy
                        : education.degree,
                  ),
                  style: pw.TextStyle(
                    fontSize: 10.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(education.institution),
                  style: pw.TextStyle(fontSize: 8.8, color: accentColor),
                ),
                if (education.location?.isNotEmpty ?? false)
                  pw.Text(
                    _sanitizePdfText(education.location!),
                    style: const pw.TextStyle(fontSize: 8.2, color: _muted),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '${DateFormat('yyyy').format(education.startDate)} - ${education.isCurrentlyStudying ? _present() : DateFormat('yyyy').format(education.endDate!)}',
              style: const pw.TextStyle(fontSize: 8.2, color: _muted),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationLine(
    Certification certification,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 7,
            height: 7,
            margin: const pw.EdgeInsets.only(top: 3, right: 6),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '${_sanitizePdfText(certification.name)}${certification.issuer.isNotEmpty ? ' | ${_sanitizePdfText(certification.issuer)}' : ''}',
              style: const pw.TextStyle(fontSize: 8.8, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}
