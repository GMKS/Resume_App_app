part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

/// Professional template – isolated codebase.
class ProfessionalResumePdfTemplate extends PdfTemplate {
  static const PdfColor _paper = PdfColor.fromInt(0xFFF7F8FC);
  static const PdfColor _card = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _rail = PdfColor.fromInt(0xFFD7DFEA);
  static const PdfColor _ink = PdfColor.fromInt(0xFF243041);
  static const PdfColor _muted = PdfColor.fromInt(0xFF667085);
  static const PdfColor _line = PdfColor.fromInt(0xFFD9E2EC);

  static const double _outerPad = 18;
  static const double _barWidth = 9;
  static const double _barGap = 4;
  static const double _barRadius = 6.0;
  static const double _cardRadius = 12.0;
  static const double _bodyRightInset = 4.0;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final edgeAccent = _blendPdfWithWhite(accentColor, 0.24);

    final displayName =
        _sanitizePdfText(ProfessionalTemplateSupport.displayName(resume))
            .toUpperCase();
    final displayTitle = _sanitizePdfText(
      ProfessionalTemplateSupport.displayTitle(resume),
    );
    final contactItems = ProfessionalTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ProfessionalTemplateSupport.summaryLines(
      resume.objective,
    );
    final experienceEntries = ProfessionalTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: null,
      yearOnly: true,
    );
    final skillNames = ProfessionalTemplateSupport.skillNames(resume.skills);
    final educationEntries = ProfessionalTemplateSupport.educationEntries(
      resume.education,
      yearOnly: true,
    );
    final projectEntries = ProfessionalTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: null,
      compactLinks: true,
    );
    final certificationEntries =
        ProfessionalTemplateSupport.certificationEntries(
      resume.certifications,
      compactLinks: true,
    );
    final languageLines = ProfessionalTemplateSupport.languageLines(
      resume.languages,
    );
    final languageSectionFreeSpace = 52.0 + (languageLines.length * 12.0);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 32, 20, 28),
          buildBackground: (context) => _buildBackground(),
        ),
        build: (context) => [
          _buildHeader(
            displayName,
            displayTitle,
            contactItems,
            accentColor,
            edgeAccent,
          ),
          if (summaryLines.isNotEmpty) ...[
            _sectionHeader('PROFILE SNAPSHOT', accentColor),
            _summaryCard(summaryLines, accentColor),
            pw.SizedBox(height: 14),
          ],
          if (experienceEntries.isNotEmpty) ...[
            _sectionHeader('CAREER EXPERIENCE', accentColor),
            ...experienceEntries
                .map((entry) => _experienceCard(entry, accentColor, edgeAccent)),
            pw.SizedBox(height: 4),
          ],
          if (skillNames.isNotEmpty) ...[
            _sectionHeader('CORE SKILLS', accentColor),
            _skillsCard(skillNames),
            pw.SizedBox(height: 14),
          ],
          if (educationEntries.isNotEmpty) ...[
            _sectionHeader('EDUCATION', accentColor),
            ...educationEntries
                .map((education) => _educationCard(education)),
            pw.SizedBox(height: 4),
          ],
          if (projectEntries.isNotEmpty) ...[
            _sectionHeader('PROJECTS', accentColor),
            ...projectEntries
                .map((project) => _projectCard(project, accentColor)),
            pw.SizedBox(height: 4),
          ],
          if (certificationEntries.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS', accentColor),
            _stackedListCard(
              certificationEntries
                  .map((entry) => _certificationEntry(entry, accentColor))
                  .toList(growable: false),
            ),
            pw.SizedBox(height: 4),
          ],
          if (languageLines.isNotEmpty) ...[
            pw.NewPage(freeSpace: languageSectionFreeSpace),
            _sectionHeader('LANGUAGES', accentColor),
            _stackedTextCard(languageLines),
            pw.SizedBox(height: 4),
          ],
          ...orderedUserCustomSections(resume)
              .where((section) => section.items.isNotEmpty)
              .expand(
                (section) => _buildGenericUserCustomSectionWidgets(
                  section,
                  accentColor: accentColor,
                  bottomSpacing: 6,
                  headerBuilder: (title) =>
                      _sectionHeader(title.toUpperCase(), accentColor),
                ),
              ),
          if (resume.references.isNotEmpty) ...[
            _sectionHeader('REFERENCES', accentColor),
            ...resume.references.map((ref) => _referenceCard(ref, accentColor)),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildBackground() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Container(
            width: double.infinity,
            height: double.infinity,
            color: _paper,
          ),
          pw.Positioned(
            left: _outerPad,
            top: _outerPad,
            bottom: _outerPad,
            child: pw.Container(
              width: _barWidth,
              decoration: pw.BoxDecoration(
                color: _rail,
                borderRadius: pw.BorderRadius.circular(_barRadius),
              ),
            ),
          ),
          pw.Positioned(
            left: _outerPad + _barWidth + _barGap,
            right: _outerPad,
            top: _outerPad,
            bottom: _outerPad,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(_cardRadius),
                border: pw.Border.all(color: _line, width: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(
    String name,
    String title,
    List<ProfessionalContactItem> contactItems,
    PdfColor accentColor,
    PdfColor edgeAccent,
  ) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 16, right: _bodyRightInset),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(_cardRadius),
        border: pw.Border.all(color: edgeAccent, width: 0.9),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.SizedBox(
              width: 12,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(_cardRadius),
                    bottomLeft: pw.Radius.circular(_cardRadius),
                  ),
                ),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name.trim().isEmpty ? 'YOUR NAME' : name,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                    letterSpacing: 0.8,
                  ),
                ),
                if (title.trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 10.2,
                        color: _muted,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (contactItems.isNotEmpty) ...[
                  pw.SizedBox(height: 11),
                  pw.Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: contactItems
                        .map((item) => _contactCapsule(item.label))
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _contactCapsule(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(4.6),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(fontSize: 8.0, color: _muted),
      ),
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8, right: _bodyRightInset),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _ink,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              _h(title),
              style: pw.TextStyle(
                fontSize: 8.4,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              height: 1,
              color: _line,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 24,
            height: 4,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _cardShell(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10, right: _bodyRightInset),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: child,
    );
  }

  pw.Widget _bulletLine(
    String line,
    PdfColor accentColor, {
    double fontSize = 8.8,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 5,
            height: 5,
            margin: const pw.EdgeInsets.only(top: 4, right: 7),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(1),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: pw.TextStyle(
                fontSize: fontSize,
                color: _ink,
                lineSpacing: 1.42,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryCard(List<String> summaryLines, PdfColor accentColor) {
    return _cardShell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: summaryLines
            .map((line) => _bulletLine(line, accentColor, fontSize: 9.0))
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _experienceCard(
    ProfessionalExperienceEntry entry,
    PdfColor accentColor,
    PdfColor edgeAccent,
  ) {
    return _cardShell(
      pw.Column(
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
                      _sanitizePdfText(entry.title),
                      style: pw.TextStyle(
                        fontSize: 11.0,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _sanitizePdfText(entry.companyLine),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: _muted,
                      ),
                    ),
                    if (entry.locationLine.trim().isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _sanitizePdfText(entry.locationLine),
                          style: const pw.TextStyle(
                            fontSize: 7.9,
                            color: _muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: _card,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: edgeAccent, width: 0.8),
                ),
                child: pw.Text(
                  _sanitizePdfText(entry.dateRange),
                  style: pw.TextStyle(
                    fontSize: 7.8,
                    color: _muted,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 7),
            ...entry.detailLines
                .map((line) => _bulletLine(line, accentColor))
                ,
          ],
        ],
      ),
    );
  }

  pw.Widget _skillsCard(List<String> skills) {
    return _cardShell(
      pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills
            .map(
              (skill) => pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _card,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _line, width: 0.8),
                ),
                child: pw.Text(
                  _sanitizePdfText(skill),
                  style: const pw.TextStyle(fontSize: 8.3, color: _muted),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _educationCard(ProfessionalEducationEntry education) {
    return _cardShell(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(education.degreeLine),
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    _sanitizePdfText(education.institutionLine),
                    style: const pw.TextStyle(
                      fontSize: 8.4,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            _sanitizePdfText(education.dateRange),
            style: const pw.TextStyle(fontSize: 8.0, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _projectCard(
    ProfessionalProjectEntry project,
    PdfColor accentColor,
  ) {
    return _cardShell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10.0,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          ...project.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.6,
                  color: _muted,
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          ...project.links.map(
            (link) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                _sanitizePdfText(link),
                style: pw.TextStyle(
                  fontSize: 8.0,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _certificationEntry(
    ProfessionalCertificationEntry entry,
    PdfColor accentColor,
  ) {
    final secondary = entry.detailLines.isNotEmpty
        ? ' - ${entry.detailLines.first}'
        : '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText('${entry.name}$secondary'),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _muted,
          ),
        ),
        ...entry.links.map(
          (link) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(link),
              style: pw.TextStyle(
                fontSize: 7.8,
                color: accentColor,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _referenceCard(Reference reference, PdfColor accentColor) {
    return _cardShell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(reference.name),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              _sanitizePdfText(
                '${reference.position} | ${reference.company}',
              ),
              style: const pw.TextStyle(
                fontSize: 8.6,
                color: _muted,
              ),
            ),
          ),
          if (reference.email.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(reference.email),
                style: const pw.TextStyle(fontSize: 8.0, color: _muted),
              ),
            ),
          if (reference.phone.isNotEmpty)
            pw.Text(
              _sanitizePdfText(reference.phone),
              style: const pw.TextStyle(fontSize: 8.0, color: _muted),
            ),
        ],
      ),
    );
  }

  pw.Widget _stackedListCard(List<pw.Widget> items) {
    return _cardShell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .asMap()
            .entries
            .map(
              (entry) => pw.Padding(
                padding: pw.EdgeInsets.only(
                  bottom: entry.key == items.length - 1 ? 0 : 8,
                ),
                child: entry.value,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _stackedTextCard(List<String> items) {
    return _cardShell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .asMap()
            .entries
            .map(
              (entry) => pw.Padding(
                padding: pw.EdgeInsets.only(
                  bottom: entry.key == items.length - 1 ? 0 : 6,
                ),
                child: pw.Text(
                  _sanitizePdfText(entry.value),
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: _muted,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
