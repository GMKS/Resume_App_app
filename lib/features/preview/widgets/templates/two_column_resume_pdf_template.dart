part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class TwoColumnResumePdfTemplate extends TwoColumnTemplate {
  static const double _pageMargin = 24;
  static const double _sidebarWidth = 150;
  static const double _sidebarGap = 12;
  static const double _firstPageSidebarTop = 98;
  static const double _continuationSidebarTop = 24;

  static const PdfColor _navyDark = PdfColor.fromInt(0xFF1E2D3D);
  static const PdfColor _pageTint = PdfColor.fromInt(0xFFF3F2F8);
  static const PdfColor _sidebarTint = PdfColor.fromInt(0xFFE7E5F2);
  static const PdfColor _bodyText = PdfColor.fromInt(0xFF374151);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF6B7280);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);
    final mainSectionOrder = sectionOrder
        .where(
          (sectionId) => const [
            'summary',
            'experience',
            'education',
            'projects',
          ].contains(sectionId),
        )
        .toList(growable: false);

    final objectiveLines = _splitTwoColumnSummaryLines(resume.objective ?? '');
    final sidebarSkills = resume.skills.take(6).toList(growable: false);
    final sidebarLanguages = resume.languages.take(4).toList(growable: false);
    final sidebarCertifications =
        resume.certifications.take(3).toList(growable: false);

    final sections = <String, List<pw.Widget>>{};
    if (objectiveLines.isNotEmpty) {
      sections['summary'] = [
        _buildMainSectionTitle('OBJECTIVE', accentColor),
        ...objectiveLines.map(
          (line) => _buildTwoColumnSummaryBulletRow(line, accentColor),
        ),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildMainSectionTitle('EXPERIENCE', accentColor),
        ...resume.experience
            .map((experience) => _buildExperienceCard(experience, accentColor)),
        pw.SizedBox(height: 2),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildMainSectionTitle('EDUCATION', accentColor),
        ...resume.education
            .map((education) => _buildEducationCard(education, accentColor)),
        pw.SizedBox(height: 2),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildMainSectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildProjectCard(project, accentColor)),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: sections,
      accentColor: accentColor,
      bottomSpacing: 8,
      headerBuilder: (title) =>
          _buildMainSectionTitle(title.toUpperCase(), accentColor),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _pageMargin,
            _pageMargin,
            _pageMargin,
            _pageMargin,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: _buildBackground(
              context,
              resume,
              accentColor,
              skills: sidebarSkills,
              languages: sidebarLanguages,
              certifications: sidebarCertifications,
            ),
          ),
        ),
        build: (context) => [
          _buildHeaderBar(resume, accentColor),
          pw.SizedBox(height: 12),
          ..._applyPdfSectionOrder(mainSectionOrder, sections).map(
            (widget) => pw.Padding(
              padding:
                  const pw.EdgeInsets.only(left: _sidebarWidth + _sidebarGap),
              child: widget,
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    ResumeModel resume,
    PdfColor accentColor, {
    required List<Skill> skills,
    required List<Language> languages,
    required List<Certification> certifications,
  }) {
    final sidebarTop = context.pageNumber == 1
        ? _firstPageSidebarTop
        : _continuationSidebarTop;

    return pw.Stack(
      children: [
        pw.Container(color: _pageTint),
        pw.Positioned(
          left: _pageMargin,
          top: sidebarTop,
          bottom: _pageMargin,
          child: pw.SizedBox(
            width: _sidebarWidth,
            child: _buildSidebarPane(
              resume,
              accentColor,
              skills: skills,
              languages: languages,
              certifications: certifications,
              includeContent: context.pageNumber == 1,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSidebarPane(
    ResumeModel resume,
    PdfColor accentColor, {
    required List<Skill> skills,
    required List<Language> languages,
    required List<Certification> certifications,
    required bool includeContent,
  }) {
    final contacts = _resumeContactValues(
      resume,
      includeAddress: true,
      includeLinkedIn: true,
      includeGithub: true,
      includeWebsite: true,
    ).map(_compactSidebarValue).toList(growable: false);

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: const pw.BoxDecoration(
        color: _sidebarTint,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: includeContent
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (skills.isNotEmpty) ...[
                  _buildSidebarHeading('SKILLS', accentColor),
                  ...skills.map((skill) => _buildSidebarBullet(skill.name)),
                  pw.SizedBox(height: 8),
                ],
                if (contacts.isNotEmpty) ...[
                  _buildSidebarHeading('CONTACT', accentColor),
                  ...contacts.map(_buildSidebarText),
                  pw.SizedBox(height: 8),
                ],
                if (languages.isNotEmpty) ...[
                  _buildSidebarHeading('LANGUAGES', accentColor),
                  ...languages.map(
                    (language) => _buildSidebarText(
                      '${language.name}${language.proficiency.isNotEmpty ? ' (${language.proficiency})' : ''}',
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
                if (certifications.isNotEmpty) ...[
                  _buildSidebarHeading('CERTIFICATIONS', accentColor),
                  ...certifications.map(
                    (certification) => _buildSidebarText(
                      certification.issuer.isNotEmpty
                          ? '${certification.name} - ${certification.issuer}'
                          : certification.name,
                    ),
                  ),
                ],
              ],
            )
          : pw.SizedBox.expand(),
    );
  }

  String _compactSidebarValue(String value) {
    var result = _sanitizePdfText(value).trim();
    if (result.isEmpty) {
      return '';
    }

    result = result.replaceFirst(RegExp(r'^https?://'), '');
    result = result.replaceFirst(RegExp(r'^www\.'), '');
    result = result.replaceFirst(RegExp(r'/$'), '');
    return result;
  }

  pw.Widget _buildExperienceCard(Experience experience, PdfColor accentColor) {
    final details = _descriptionFirstExperienceLines(experience);
    final location = (experience.location ?? '').trim();
    final companyLine = location.isNotEmpty
        ? '${experience.company}  |  $location'
        : experience.company;

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(experience.position),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _navyDark,
            ),
          ),
          if (companyLine.trim().isNotEmpty)
            pw.Text(
              _sanitizePdfText(companyLine),
              style: pw.TextStyle(fontSize: 7.2, color: accentColor),
            ),
          pw.Text(
            '${DateFormat('MMM yyyy').format(experience.startDate)} - ${experience.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(experience.endDate!)}',
            style: const pw.TextStyle(fontSize: 6.6, color: _mutedText),
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...details.map(
              (line) => _buildTwoColumnSummaryBulletRow(line, accentColor),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducationCard(Education education, PdfColor accentColor) {
    final title = '${education.degree} ${education.fieldOfStudy}'.trim();
    final end = education.isCurrentlyStudying
        ? _present()
        : DateFormat('yyyy').format(education.endDate ?? education.startDate);
    final location = (education.location ?? '').trim();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(title.isNotEmpty ? title : education.institution),
            style: pw.TextStyle(
              fontSize: 8.4,
              fontWeight: pw.FontWeight.bold,
              color: _navyDark,
            ),
          ),
          pw.Text(
            _sanitizePdfText(education.institution),
            style: pw.TextStyle(fontSize: 7.2, color: accentColor),
          ),
          pw.Text(
            '${DateFormat('yyyy').format(education.startDate)} - $end${location.isNotEmpty ? '  |  ${_sanitizePdfText(location)}' : ''}',
            style: const pw.TextStyle(fontSize: 6.8, color: _mutedText),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectCard(Project project, PdfColor accentColor) {
    final sanitizedDescription = _sanitizePdfText(project.description);
    final sanitizedUrl = _sanitizePdfText(project.url).trim();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 8.4,
              fontWeight: pw.FontWeight.bold,
              color: _navyDark,
            ),
          ),
          if (project.technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                project.technologies.map(_sanitizePdfText).join(' | '),
                style: pw.TextStyle(fontSize: 7.2, color: accentColor),
              ),
            ),
          if (sanitizedDescription.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                sanitizedDescription,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: _bodyText,
                  lineSpacing: 1.25,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          if (sanitizedUrl.isNotEmpty &&
              !sanitizedDescription.contains(sanitizedUrl))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                sanitizedUrl,
                style: pw.TextStyle(
                  fontSize: 6.9,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
