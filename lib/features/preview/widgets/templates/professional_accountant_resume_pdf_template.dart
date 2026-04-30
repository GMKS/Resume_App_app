part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class ProfessionalAccountantResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg = PdfColors.white;
  static const PdfColor _ink = PdfColor.fromInt(0xFF26282D);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);

  static const double _pageHorizontal = 34;
  static const double _pageTop = 34;
  static const double _pageBottom = 34;
  static const double _mainColumnWidth = 352;
  static const double _sidebarWidth = 150;
  static const double _columnGap = 18;
  static const double _firstPageGuideTop = 96;
  static const double _headerContactWidth = 190;

  static const _mainSectionOrder = <String>['projects', 'experience'];

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final mainOrder = await _loadPdfSectionOrderForKeys(
      resume,
      defaultOrder: _mainSectionOrder,
      allowedKeys: _mainSectionOrder,
    );

    final mainSections = <String, List<pw.Widget>>{};
    if (resume.projects.isNotEmpty) {
      mainSections['projects'] = [
        _mainSectionHeader('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _projectBlock(project, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }
    if (resume.experience.isNotEmpty) {
      mainSections['experience'] = [
        _mainSectionHeader('EXPERIENCE', accentColor),
        ...resume.experience.map(
          (experience) => _experienceBlock(experience, accentColor),
        ),
      ];
    }

    _addUserCustomSections(
      resume: resume,
      sections: mainSections,
      accentColor: accentColor,
      bottomSpacing: 10,
      headerBuilder: (title) =>
          _mainSectionHeader(title.toUpperCase(), accentColor),
    );

    final hasSummary = resume.objective?.trim().isNotEmpty ?? false;
    final hasSidebar = resume.skills.isNotEmpty ||
        resume.education.isNotEmpty ||
        resume.certifications.isNotEmpty ||
        resume.languages.isNotEmpty;

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
            child: _buildBackground(
              context,
              resume,
              accentColor,
              hasSidebar: hasSidebar,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 16),
          if (hasSummary) ...[
            _mainConstrained(_buildSummarySection(resume, accentColor)),
            if (mainSections.isNotEmpty) pw.SizedBox(height: 14),
          ],
          ..._applyPdfSectionOrder(mainOrder, mainSections)
              .map(_mainConstrained),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground(
    pw.Context context,
    ResumeModel resume,
    PdfColor accentColor, {
    required bool hasSidebar,
  }) {
    final guideColor = _blendPdfWithWhite(accentColor, 0.76);
    final top = context.pageNumber == 1 ? _firstPageGuideTop : _pageTop;

    return pw.Stack(
      children: [
        pw.Container(color: _pageBg),
        pw.Positioned(
          left: _pageHorizontal + _mainColumnWidth + (_columnGap / 2),
          top: top,
          bottom: _pageBottom,
          child: pw.SizedBox(
            width: 1.15,
            child: pw.Container(color: guideColor),
          ),
        ),
        if (context.pageNumber == 1 && hasSidebar)
          pw.Positioned(
            left: _pageHorizontal + _mainColumnWidth + _columnGap,
            top: top,
            child: pw.SizedBox(
              width: _sidebarWidth,
              child: _buildSidebar(resume, accentColor),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final name = resume.personalInfo.fullName.trim().isEmpty
        ? 'John Smith'
        : _sanitizePdfText(resume.personalInfo.fullName.trim());
    final title = _sanitizePdfText(resume.personalInfo.jobTitle).trim();
    final contactItems = _contactItems(resume);

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
              24,
              _pageHorizontal,
              22,
            ),
            color: accentColor,
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
                          fontSize: 23,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      if (title.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          title,
                          style: const pw.TextStyle(
                            fontSize: 10.1,
                            color: PdfColor(1, 1, 1, 0.74),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.SizedBox(
                  width: _headerContactWidth,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: contactItems
                        .map(
                          (item) => _headerContactItem(item, accentColor),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerContactItem(
    _ProfessionalAccountantPdfContactItem item,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              item.label,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(
                fontSize: 8.1,
                color: PdfColor(1, 1, 1, 0.74),
              ),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.SizedBox(
            width: 11,
            height: 11,
            child: pw.CustomPaint(
              size: const PdfPoint(11, 11),
              painter: (canvas, size) {
                final cx = size.x / 2;
                final cy = size.y / 2;
                canvas.setFillColor(_blendPdfWithWhite(accentColor, 0.56));
                canvas.drawEllipse(cx, cy, cx, cy);
                canvas.fillPath();
                _drawPdfIcon(
                    canvas, item.iconType, cx, cy, cx * 0.52, PdfColors.white);
              },
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(ResumeModel resume, PdfColor accentColor) {
    final summaryLines = _splitSegments(resume.objective ?? '');
    if (summaryLines.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _mainSectionHeader('PROFESSIONAL SUMMARY', accentColor),
        ...summaryLines.map(
          (line) => _summaryBullet(line, accentColor),
        ),
      ],
    );
  }

  pw.Widget _buildSidebar(ResumeModel resume, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (resume.skills.isNotEmpty) ...[
          _sidebarSectionHeader('SKILLS', accentColor),
          ...resume.skills
              .map((skill) => _sidebarBullet(skill.name, accentColor)),
          pw.SizedBox(height: 9),
        ],
        if (resume.education.isNotEmpty) ...[
          _sidebarSectionHeader('EDUCATION', accentColor),
          ...resume.education.map(_sidebarEducationBlock),
          pw.SizedBox(height: 9),
        ],
        if (resume.certifications.isNotEmpty) ...[
          _sidebarSectionHeader('CERTIFICATIONS', accentColor),
          ...resume.certifications.map(_sidebarCertificationBlock),
          pw.SizedBox(height: 9),
        ],
        if (resume.languages.isNotEmpty) ...[
          _sidebarSectionHeader('LANGUAGES', accentColor),
          ...resume.languages.map(_sidebarLanguageBlock),
        ],
      ],
    );
  }

  pw.Widget _mainConstrained(pw.Widget child) {
    return pw.SizedBox(width: _mainColumnWidth, child: child);
  }

  pw.Widget _mainSectionHeader(String title, PdfColor accentColor) {
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
              letterSpacing: 0.7,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 1.0,
            color: _blendPdfWithWhite(accentColor, 0.74),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarSectionHeader(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 0.9,
            color: _blendPdfWithWhite(accentColor, 0.74),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryBullet(String line, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: _pageBg,
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: accentColor, width: 0.8),
              ),
            ),
          ),
          pw.SizedBox(width: 6),
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
    final location = (experience.location ?? '').trim();
    if (location.isNotEmpty) {
      metaParts.add(_sanitizePdfText(location));
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
                    fontSize: 10.6,
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
                style: const pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
            ],
          ),
          if (metaParts.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                metaParts.join('  |  '),
                style: const pw.TextStyle(fontSize: 8.9, color: _muted),
              ),
            ),
          if (details.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: details
                    .map(
                      (detail) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Container(
                                width: 4,
                                height: 4,
                                decoration: pw.BoxDecoration(
                                  color: accentColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child:
                                  _bodyText(detail, fontSize: 8.9, color: _ink),
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

  pw.Widget _projectBlock(Project project, PdfColor accentColor) {
    final content =
        ProfessionalAccountantTemplateSupport.projectContent(project);
    final summaryLines = content.details;
    final links = content.links;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(
              project.title.trim().isEmpty ? 'Project' : project.title.trim(),
            ),
            style: pw.TextStyle(
              fontSize: 10.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (summaryLines.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: summaryLines
                    .map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: _bodyText(line, fontSize: 8.8, color: _muted),
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
                style: const pw.TextStyle(fontSize: 8.4, color: _muted),
              ),
            ),
          if (links.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: links
                    .map(
                      (link) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          link,
                          style: pw.TextStyle(
                            fontSize: 8.4,
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

  pw.Widget _sidebarBullet(String label, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(
                color: accentColor,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(label),
              style: const pw.TextStyle(fontSize: 8.5, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarEducationBlock(Education education) {
    final degree = [education.degree.trim(), education.fieldOfStudy.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(degree.isEmpty ? 'Education' : degree),
            style: pw.TextStyle(
              fontSize: 8.7,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (education.institution.trim().isNotEmpty)
            pw.Text(
              _sanitizePdfText(education.institution.trim()),
              style: const pw.TextStyle(fontSize: 8.2, color: _muted),
            ),
          pw.Text(
            education.isCurrentlyStudying
                ? _present()
                : DateFormat('yyyy')
                    .format(education.endDate ?? education.startDate),
            style: const pw.TextStyle(fontSize: 8.0, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarCertificationBlock(Certification certification) {
    final issuer = certification.issuer.trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(certification.name.trim()),
            style: pw.TextStyle(
              fontSize: 8.6,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (issuer.isNotEmpty)
            pw.Text(
              _sanitizePdfText(issuer),
              style: const pw.TextStyle(fontSize: 8.1, color: _muted),
            ),
        ],
      ),
    );
  }

  pw.Widget _sidebarLanguageBlock(Language language) {
    final proficiency = language.proficiency.trim();
    final label = proficiency.isEmpty
        ? language.name.trim()
        : '${language.name.trim()} | $proficiency';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        _sanitizePdfText(label),
        style: const pw.TextStyle(fontSize: 8.2, color: _muted),
      ),
    );
  }

  pw.Widget _bodyText(
    String text, {
    double fontSize = 9.0,
    PdfColor color = _muted,
  }) {
    return pw.Text(
      _sanitizePdfText(text),
      textAlign: pw.TextAlign.justify,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        lineSpacing: 1.3,
      ),
    );
  }

  List<_ProfessionalAccountantPdfContactItem> _contactItems(
      ResumeModel resume) {
    return ProfessionalAccountantTemplateSupport.contactItems(
      resume.personalInfo,
    )
        .map(
          (item) => _ProfessionalAccountantPdfContactItem(
            iconType: _contactIconType(item.kind),
            label: _sanitizePdfText(item.label),
          ),
        )
        .toList(growable: false);
  }

  List<String> _splitSegments(String text) {
    final normalized = _sanitizePdfText(text).trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final lines = normalized
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(
          (line) =>
              line.replaceFirst(RegExp(r'^[-*•▪■□✪✦★☆➣◦○]+\s*'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return lines;
  }

  String _dateRange(DateTime startDate, DateTime? endDate, bool isCurrent) {
    final start = DateFormat('MMM yyyy').format(startDate);
    final end =
        isCurrent ? _present() : DateFormat('MMM yyyy').format(endDate!);
    return '$start - $end';
  }

  String _contactIconType(ProfessionalAccountantContactKind kind) {
    switch (kind) {
      case ProfessionalAccountantContactKind.email:
        return 'email';
      case ProfessionalAccountantContactKind.phone:
        return 'phone';
      case ProfessionalAccountantContactKind.location:
        return 'location';
      case ProfessionalAccountantContactKind.linkedin:
        return 'linkedin';
      case ProfessionalAccountantContactKind.github:
      case ProfessionalAccountantContactKind.website:
        return 'website';
    }
  }
}

class _ProfessionalAccountantPdfContactItem {
  const _ProfessionalAccountantPdfContactItem({
    required this.iconType,
    required this.label,
  });

  final String iconType;
  final String label;
}
