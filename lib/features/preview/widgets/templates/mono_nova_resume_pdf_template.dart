part of 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

class MonoNovaResumePdfTemplate extends PdfTemplate {
  static const PdfColor _pageBg =
      PdfColor.fromInt(MonoNovaTemplateSupport.pageHex);
  static const PdfColor _text =
      PdfColor.fromInt(MonoNovaTemplateSupport.inkHex);
  static const PdfColor _muted =
      PdfColor.fromInt(MonoNovaTemplateSupport.mutedHex);
  static const PdfColor _rule =
      PdfColor.fromInt(MonoNovaTemplateSupport.ruleHex);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    final name = MonoNovaTemplateSupport.displayName(resume);
    final title = MonoNovaTemplateSupport.displayTitle(resume);
    final contacts = MonoNovaTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
    );
    final summaryLines = MonoNovaTemplateSupport.summaryLines(resume.objective);
    final experiences = MonoNovaTemplateSupport.experienceEntries(
      resume.experience,
      maxDetailLines: 6,
    );
    final educations =
        MonoNovaTemplateSupport.educationEntries(resume.education);
    final skills = MonoNovaTemplateSupport.skillNames(resume.skills);
    final projects = MonoNovaTemplateSupport.projectEntries(
      resume.projects,
      maxDetailLines: 3,
      compactLinks: true,
    );
    final certifications = MonoNovaTemplateSupport.certificationLines(
      resume.certifications,
    );
    final languages = MonoNovaTemplateSupport.languageLines(resume.languages);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _pageBg),
          ),
        ),
        build: (context) => [
          _buildHeader(name, title, contacts),
          pw.SizedBox(height: 10),
          pw.Container(height: 1.2, color: _rule),
          pw.SizedBox(height: 12),
          if (summaryLines.isNotEmpty) ...[
            _sectionHeader('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 4),
            ...summaryLines.map(_summaryLine),
            pw.SizedBox(height: 10),
          ],
          if (experiences.isNotEmpty) ...[
            _sectionHeader('EXPERIENCE'),
            pw.SizedBox(height: 4),
            ...experiences.map(_experienceBlock),
            pw.SizedBox(height: 4),
          ],
          if (educations.isNotEmpty || skills.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (educations.isNotEmpty)
                  pw.Expanded(child: _educationSection(educations)),
                if (educations.isNotEmpty && skills.isNotEmpty)
                  pw.SizedBox(width: 16),
                if (skills.isNotEmpty)
                  pw.Expanded(child: _skillsSection(skills)),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
          if (projects.isNotEmpty) ...[
            _sectionHeader('PROJECTS'),
            pw.SizedBox(height: 4),
            ...projects.map(_projectBlock),
            pw.SizedBox(height: 6),
          ],
          if (certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS'),
            pw.SizedBox(height: 4),
            ...certifications.map(_simpleLine),
            pw.SizedBox(height: 6),
          ],
          if (languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES'),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 16,
              runSpacing: 4,
              children: languages
                  .map(
                    (line) => pw.Text(
                      _sanitizePdfText(line),
                      style: const pw.TextStyle(fontSize: 8.8, color: _muted),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          ...orderedUserCustomSections(resume)
              .where((section) => section.items.isNotEmpty)
              .expand(_customSectionWidgets),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(
    String name,
    String title,
    List<MonoNovaContactItem> contacts,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitizePdfText(name),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _text,
                ),
              ),
              if (title.trim().isNotEmpty)
                pw.Text(
                  _sanitizePdfText(title),
                  style: const pw.TextStyle(fontSize: 13, color: _muted),
                ),
            ],
          ),
        ),
        if (contacts.isNotEmpty) ...[
          pw.SizedBox(width: 14),
          pw.SizedBox(
            width: 170,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: contacts
                  .map(
                    (item) => pw.Text(
                      _sanitizePdfText(item.label),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: item.kind.index >=
                                MonoNovaContactKind.linkedin.index
                            ? 8.1
                            : 8.6,
                        color: _muted,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _h(title),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _text,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: _rule),
      ],
    );
  }

  pw.Widget _summaryLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
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
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(line),
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _muted,
                lineSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _experienceBlock(MonoNovaExperienceEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(entry.metaLine),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: _muted,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                _sanitizePdfText(entry.dateRange),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                ),
              ),
            ],
          ),
          if (entry.detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            ...entry.detailLines.map(_summaryLine),
          ],
        ],
      ),
    );
  }

  pw.Widget _educationSection(List<MonoNovaEducationEntry> entries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('EDUCATION'),
        pw.SizedBox(height: 4),
        ...entries.map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(entry.degree),
                  style: pw.TextStyle(
                    fontSize: 9.6,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
                pw.Text(
                  '${_sanitizePdfText(entry.institutionLine)}  •  ${_sanitizePdfText(entry.dateLabel)}',
                  style: const pw.TextStyle(fontSize: 8.8, color: _muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _skillsSection(List<String> skills) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('SKILLS'),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitizePdfText(skills.join(', ')),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _muted,
            lineSpacing: 1.4,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  List<pw.Widget> _customSectionWidgets(CustomSection section) {
    final title = displayUserCustomSectionTitle(
      section,
      fallback: 'SECTION',
    );
    final widgets = <pw.Widget>[
      _sectionHeader(title.toUpperCase()),
      pw.SizedBox(height: 4),
    ];

    for (final item in section.items) {
      final displayItem = buildUserCustomSectionDisplayItem(item);
      if (!displayItem.hasContent) {
        continue;
      }

      final metaParts = <String>[
        if (displayItem.subtitle.isNotEmpty)
          _sanitizePdfText(displayItem.subtitle),
        if (displayItem.date != null)
          DateFormat('MMM yyyy').format(displayItem.date!),
      ];

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (displayItem.heading.isNotEmpty)
                pw.Text(
                  _sanitizePdfText(displayItem.heading),
                  style: pw.TextStyle(
                    fontSize: 9.8,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
              if (metaParts.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    metaParts.join('  •  '),
                    style: const pw.TextStyle(fontSize: 8.7, color: _muted),
                  ),
                ),
              ...displayItem.detailLines.map(_summaryLine),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _projectBlock(MonoNovaProjectEntry entry) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(entry.title),
            style: pw.TextStyle(
              fontSize: 9.4,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
          ),
          ...entry.detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _muted,
                  lineSpacing: 1.34,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
          if (entry.url.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(entry.url),
                style: const pw.TextStyle(
                  fontSize: 8.4,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _simpleLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        _sanitizePdfText(line),
        style: const pw.TextStyle(fontSize: 8.8, color: _muted),
      ),
    );
  }
}
